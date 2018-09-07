package App::JsonLogUtils;
# ABSTRACT: Command line utilities for dealing with JSON-formatted log files

=head1 SYNOPSIS

  # From the command line
  tail -f /path/to/log/file.log \
    | jgrep -m message="some pattern" \
    | jcut -f "timestamp priority message" \
    | cols -c "timestamp priority message" -s '|' \
    | column -t -s '|'


  # From code
  use App::JsonLogUtils qw(tail json_log);

  my $log = json_log tail '/path/to/file.log';

  while (my $entry = <$log>) {
    my ($json, $line) = @$entry;
    ...
  }


  # Grepping JSON logs
  use App::JsonLogUtils qw(lines json_log);
  use Iterator::Simple qw(igrep imap);

  my $entries = igrep{ $_->{foo} =~ /bar/ } # filter objects
                imap{ $_->[0] }             # select the object
                json_log                    # parse
                lines '/path/to/file.log';  # read

=head1 DESCRIPTION

Writing logs in JSON, one object per line, makes them very easily machine
readable. Wonderful. Unfortunately, it also makes it unfuriating to deal with
them using the standard unix command line tools. This package provides a few
tools to salve the burn.

=head1 COMMAND LINE TOOLS

=head2 L<jgrep>

=head2 L<App::JsonLogUtils::Grep>

Greps patterns in individual object fields.

=head2 L<jcut>

=head2 L<App::JsonLogUtils::Cut>

Filter the fields included in objects.

=head2 L<jcols>

=head2 L<App::JsonLogUtils::Cols>

Display fields in a format suitable for C<column>.

=head2 L<jshell>

An interactive shell for monitoring JSON log files.

=cut


use strict;
use warnings;

use Fcntl             qw(:seek);
use Iterator::Simple  qw(iterator iter imap);
use JSON::XS          qw(decode_json encode_json);
use Time::HiRes       qw(sleep);
use Term::SimpleColor;

use parent 'Exporter';

our @EXPORT_OK = qw(
  lines
  tail
  json_log
);


#-------------------------------------------------------------------------------
# Internal utilities
#-------------------------------------------------------------------------------
sub log_warn { warn red,    @_, default, "\n" }
sub log_info { warn yellow, @_, default, "\n" }

sub _open {
  my $path = shift || return;
  return $path if ref $path;

  open my $fh, '<', $path or do{
    log_warn $!;
    return;
  };

  return $fh;
}


=head1 EXPORTABLE ROUTINES

If desired, the iterators used to implement the tools above are optionally
exported by the main module.

=head1 lines

Accepts a file path or opened file handle and returns an iterator which yields
the chomped lines from the file.

  my $log = lines '/path/to/file.log';

  while (my $line = <$log>) {
    ...
  }

=cut

sub lines ($) {
  my $path = shift;
  my $fh   = _open $path || return;
  imap{ chomp $_; $_ } iter $fh;
}


=head1 tail

Accepts a file path or opened file handle and returns an iterator while yields
chomped lines from the file as they are appended, starting from the end of the
file. Lines already written to the file when this routine is first called are
ignored (that is, there is no equivalent to C<tail -c 10> at this time).

  my $log = tail '/path/to/file.log';

  while (my $line = <$log>) { # sleeps until lines appended to file
    ...
  }

=cut

sub tail ($) {
  my $path     = shift;
  my $fh       = _open $path || return;
  my $pos      = 0;
  my $notified = 0;
  my $stop     = 0;

  seek $fh, 0, SEEK_END;
  $pos = tell $fh;

  $SIG{INT} = sub{
    log_info 'Stopped';
    $stop = 1;
  };

  iterator{
    LINE:do{
      # Check for control-c
      if ($stop) {
        undef $SIG{INT};
        return;
      }

      # Check for file truncation
      my $eof = eof $fh;
      my $cur = tell $fh;

      seek $fh, 0, SEEK_END;
      my $end = tell $fh;

      if ($end < $cur) {
        log_info 'File truncated';
        $pos = $end;
      }
      else {
        $pos = $cur;
      }

      seek $fh, $pos, SEEK_SET;
      <$fh> if $eof;

      # Return next line
      if (defined(my $line = <$fh>)) {
        $notified = 0;
        chomp $line;
        return $line;
      }

      # At EOF; notify user with how to break loop
      if (!$notified) {
        log_info 'Use control-c to break';
        $notified = 1;
      }

      # Reset position
      seek $fh, $pos, SEEK_SET;

      # Reset EOF condition on handle and wait for new input
      seek $fh, 0, SEEK_CUR;
      sleep 0.2;

      # Try again
      goto LINE;
    };
  };
}


=head1 json_log

Accepts a file iterator (see L</tail> and L</lines>) and returns an iterator
yielding an array ref holding two items, a hash ref of the parsed JSON log
entry, and the original log entry string. Empty lines are skipped with a
warning. JSON decoding errors are ignored with a warning.

  my $lines = json_log tail '/path/to/file.log';

  while (my $entry = <$lines>) {
    my ($object, $line) = @_;
    ...
  }

=cut

sub json_log ($) {
  my $lines = shift;

  iterator{
    while (defined(my $line = <$lines>)) {
      if (!$line) {
        log_info 'empty line';
        next;
      }

      my $obj = eval{ decode_json $line };

      if ($@) {
        log_warn "invalid JSON: $line";
        next;
      }

      return [$obj, $line];
    }

    return;
  };
}


=cut

=head1 SEE ALSO

=head2 L<App::JsonLogUtils::Iter>

=head1 FUTURE PLANS

None, but will happily consider requests and patches.

=cut

1;

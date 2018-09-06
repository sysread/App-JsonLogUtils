package App::JsonLogUtils::Iter;

use strict;
use warnings;

use JSON::XS qw(decode_json encode_json);
use Iterator::Simple qw(iterator);
use Time::HiRes qw(sleep);
use Fcntl qw(:seek);
use App::JsonLogUtils::Log;

use parent 'Exporter';

our @EXPORT = qw(
  icat
  itail
  ijson
  igrep
);

sub _open {
  my $path = shift || return;
  return $path if ref $path;

  open my $fh, '<', $path or do{
    log_warn $!;
    return;
  };

  return $fh;
}

#-------------------------------------------------------------------------------
# Iterators
#-------------------------------------------------------------------------------
sub icat ($) {
  my $path = shift;
  my $fh   = _open $path || return;

  iterator{
    while (defined(my $line = <$fh>)) {
      chomp $line;
      return $line;
    }

    return;
  }
}

sub itail ($) {
  my $path   = shift;
  my $fh     = _open $path || return;
  my $pos    = 0;
  my $notify = 0;
  my $stop   = 0;

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
        undef $notify;
        chomp $line;
        return $line;
      }

      # At EOF; notify user with how to break loop
      unless ($notify) {
        log_info 'Use control-c to break';
        $notify = 0;
      }

      # Reset position
      seek $fh, $pos, SEEK_SET;

      # Reset EOF condition on handle and wait for new input
      seek $fh, 0, SEEK_CUR;
      sleep 0.1;

      # Try again
      goto LINE;
    };
  };
}

sub ijson ($) {
  my $lines = shift;

  iterator{
    while (defined(my $line = <$lines>)) {
      return (undef, undef, "empty line") unless $line;
      my $obj = eval{ decode_json($line) };
      return (undef, undef, "invalid JSON: $line") if $@;
      return ($line, $obj, undef);
    }

    return;
  }
}

sub igrep (&$) {
  my ($filter, $json) = @_;

  iterator{
    while (my ($line, $obj, $err) = <$json>) {
      if ($err) {
        log_info $err;
        next;
      }

      if ($filter->($obj, $line)) {
        return ($obj, $line);
      }

      return;
    }

    return;
  };
}

1;

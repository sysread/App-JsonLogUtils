package App::JsonLogUtils::Iter;
# ABSTRACT: Iterators used internally by App::JsonLogUtils

use strict;
use warnings;

use JSON::XS qw(decode_json encode_json);
use Iterator::Simple qw(iterator iter imap);
use Time::HiRes qw(sleep);
use Fcntl qw(:seek);
use App::JsonLogUtils::Log;

use parent 'Exporter';

our @EXPORT = qw(
  lines
  tail
  entries
  ijson
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
sub lines ($) {
  my $path = shift;
  my $fh   = _open $path || return;
  imap{ chomp $_; $_ } iter $fh;
}

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

sub entries ($) {
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

1;

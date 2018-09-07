package App::JsonLogUtils::Cut;
# ABSTRACT: Field filtering for JSON log files

use strict;
use warnings;

use Carp;
use Iterator::Simple qw(iterator);
use App::JsonLogUtils qw(lines json_log);

sub new {
  my ($class, %param) = @_;
  bless{
    fields  => $param{fields}     || [],
    inverse => $param{complement} || $param{inverse},
  }, $class;
}

sub iter {
  my ($self, $path) = @_;
  my $lines = json_log lines $path;

  iterator{
    while (my $entry = <$lines>) {
      my ($obj, $line) = @$entry;

      if ($self->{inverse}) {
        delete $obj->{$_} foreach @{$self->{fields}};
        return $obj;
      }
      else {
        my %filtered;
        $filtered{$_} = $obj->{$_} foreach @{$self->{fields}};
        return \%filtered;
      }
    }

    return;
  };
}

1;

package App::JsonLogUtils::Cut;

use strict;
use warnings;

use Carp;
use Iterator::Simple qw(iterator);
use App::JsonLogUtils::Iter;
use App::JsonLogUtils::Log;

sub new {
  my ($class, %param) = @_;
  bless{
    fields  => $param{fields}     || [],
    inverse => $param{complement} || $param{inverse},
  }, $class;
}

sub iter {
  my ($self, $path) = @_;
  my $lines = ijson icat $path;

  iterator{
    while (my ($line, $obj, $err) = <$lines>) {
      if ($err) {
        log_info $err;
      }
      elsif ($self->{inverse}) {
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

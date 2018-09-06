package App::JsonLogUtils::Cols;

use strict;
use warnings;

use Carp;
use Iterator::Simple qw(iterator ichain);
use App::JsonLogUtils::Iter;
use App::JsonLogUtils::Log;

sub new {
  my ($class, %param) = @_;
  my $cols = $param{cols} || [];

  if (defined $cols && !ref $cols) {
    $cols = [split /\s+/, $cols];
  }

  bless{cols => $cols, sep => $param{sep} || "\t"}, $class;
}

sub iter {
  my ($self, $path) = @_;
  my $sep   = $self->{sep};
  my @cols  = @{$self->{cols}};
  my $head  = Iterator::Simple::iter([ join($sep, @cols) ]);
  my $lines = ijson icat $path;
  my $rows  = iterator{
    while (my ($line, $obj, $err) = <$lines>) {
      if ($err) {
        log_info $err;
      }
      else {
        return join($sep, map{ $obj->{$_} || '' } @cols);
      }
    }

    return;
  };

  ichain $head, $rows;
}

1;

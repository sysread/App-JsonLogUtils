package App::JsonLogUtils::Cols;
# ABSTRACT: Field selection and formatting for JSON log files in a format suitable for column

use strict;
use warnings;

use Carp;
use Iterator::Simple qw(iterator ichain imap);
use App::JsonLogUtils qw(lines json_log);

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
  my $lines = json_log lines $path;

  my $rows = imap{
    my ($obj, $line) = @$_;
    return join($sep, map{ $obj->{$_} || '' } @cols);
  } $lines;

  ichain $head, $rows;
}

1;

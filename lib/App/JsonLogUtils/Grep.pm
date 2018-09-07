package App::JsonLogUtils::Grep;
# ABSTRACT: Per-field matching for JSON log files

use strict;
use warnings;

use Carp;
use List::Util qw(all);
use Iterator::Simple qw(igrep);
use App::JsonLogUtils::Iter;

sub new {
  my ($class, %param) = @_;
  my $match = (!$param{inverse} && !$param{nocase}) ? sub{ $_[0] =~ /$_[1]/  }
            : (!$param{inverse} &&  $param{nocase}) ? sub{ $_[0] =~ /$_[1]/i }
            : ( $param{inverse} && !$param{nocase}) ? sub{ $_[0] !~ /$_[1]/  }
                                                    : sub{ $_[0] !~ /$_[1]/i };

  bless{
    patterns => $param{patterns} || {},
    match    => $match,
  }, $class;
}

sub iter {
  my ($self, $path) = @_;
  croak 'expected file path or handle' unless $path;
  igrep{ $self->match($_->[0]) } entries lines $path;
}

sub match {
  my ($self, $obj) = @_;
  all{ $self->{match}->($obj->{$_} || '', $self->{patterns}{$_}) }
    keys %{$self->{patterns}};
}

1;

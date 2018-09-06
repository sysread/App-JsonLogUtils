use strict;
use warnings;
use Test2::V0;
use App::JsonLogUtils::Grep;

my $log = <<'EOS';
{"id": 1, "foo": "bar"}
{"id": 2, "foo": "baz"}
{"id": 3, "foo": "bat"}
{"id": 4, "foo": "BAR"}
EOS

subtest basics => sub{
  open my $fh, '<', \$log or die $!;

  ok my $grep = App::JsonLogUtils::Grep->new(
    patterns => {foo => 'bar'},
    inverse  => 0,
    nocase   => 0,
  ), 'ctor';

  ok my $iter = $grep->iter($fh), 'iter';

  my ($obj, $line) = <$iter>;
  is $obj, {id => 1, foo => 'bar'}, 'obj';
  is $line, '{"id": 1, "foo": "bar"}', 'line';
  is <$iter>, U, 'exhausted';
};

subtest inverse => sub{
  open my $fh, '<', \$log or die $!;

  ok my $grep = App::JsonLogUtils::Grep->new(
    patterns => {foo => 'bar'},
    inverse  => 1,
    nocase   => 0,
  ), 'ctor';

  ok my $iter = $grep->iter($fh), 'iter';

  my @expected = (
    [{id => 2, "foo" => "baz"}, '{"id": 2, "foo": "baz"}'],
    [{id => 3, "foo" => "bat"}, '{"id": 3, "foo": "bat"}'],
    [{id => 4, "foo" => "BAR"}, '{"id": 4, "foo": "BAR"}'],
  );

  foreach (@expected) {
    my ($obj, $line) = <$iter>;
    is $obj,  $_->[0], 'obj';
    is $line, $_->[1], 'line';
  }

  is <$iter>, U, 'exhausted';
};

subtest nocase => sub{
  open my $fh, '<', \$log or die $!;

  ok my $grep = App::JsonLogUtils::Grep->new(
    patterns => {foo => 'bar'},
    inverse  => 0,
    nocase   => 1,
  ), 'ctor';

  ok my $iter = $grep->iter($fh), 'iter';

  my @expected = (
    [{id => 1, "foo" => "bar"}, '{"id": 1, "foo": "bar"}'],
    [{id => 4, "foo" => "BAR"}, '{"id": 4, "foo": "BAR"}'],
  );

  foreach (@expected) {
    my ($obj, $line) = <$iter>;
    is $obj,  $_->[0], 'obj';
    is $line, $_->[1], 'line';
  }

  is <$iter>, U, 'exhausted';
};

done_testing;

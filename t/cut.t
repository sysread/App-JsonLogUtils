use strict;
use warnings;
use Test2::V0;
use JSON::XS;
use App::JsonLogUtils::Cut;

my @log = (
  {a => 1, b => 2, c => 3},
  {a => 1, b => 2, c => 3},
  {a => 1, b => 2, c => 3},
);

my $log = join "\n", map{ encode_json $_ } @log;

subtest basics => sub{
  open my $fh, '<', \$log or die $!;

  ok my $cut = App::JsonLogUtils::Cut->new(
    fields  => ['a', 'c'],
    inverse => 0,
  ), 'ctor';

  ok my $iter = $cut->iter($fh), 'iter';

  my @expected = (
    {a => 1, c => 3},
    {a => 1, c => 3},
    {a => 1, c => 3},
  );

  foreach (@expected) {
    is <$iter>, $_, 'expected results';
  }

  is <$iter>, U, 'exhausted';
};

subtest inverse => sub{
  open my $fh, '<', \$log or die $!;

  ok my $cut = App::JsonLogUtils::Cut->new(
    fields  => ['b'],
    inverse => 1,
  ), 'ctor';

  ok my $iter = $cut->iter($fh), 'iter';

  my @expected = (
    {a => 1, c => 3},
    {a => 1, c => 3},
    {a => 1, c => 3},
  );

  foreach (@expected) {
    is <$iter>, $_, 'expected results';
  }

  is <$iter>, U, 'exhausted';
};

done_testing;

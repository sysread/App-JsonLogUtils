use strict;
use warnings;
use Test2::V0;
use JSON::XS;
use App::JsonLogUtils::Cols;

my @log = (
  {a => 1, b => 2, c => 3},
  {a => 1, b => 2, c => 3},
  {a => 1, b => 2, c => 3},
);

my $log = join "\n", map{ encode_json $_ } @log;

open my $fh, '<', \$log or die $!;

ok my $cut = App::JsonLogUtils::Cols->new(
  cols => 'a c',
  sep  => '|',
), 'ctor';

ok my $iter = $cut->iter($fh), 'iter';

my @expected = (
  'a|c',
  '1|3',
  '1|3',
  '1|3',
);

foreach (@expected) {
  is <$iter>, $_, 'expected results';
}

is <$iter>, U, 'exhausted';

done_testing;

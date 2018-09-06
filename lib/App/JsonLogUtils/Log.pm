package App::JsonLogUtils::Log;

use strict;
use warnings;

use Term::SimpleColor;

use parent 'Exporter';

our @EXPORT = qw(
  log_warn
  log_info
);

sub log_warn { warn red,    @_, default, "\n" }
sub log_info { warn yellow, @_, default, "\n" }

1;

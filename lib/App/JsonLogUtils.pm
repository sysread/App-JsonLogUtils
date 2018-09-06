package App::JsonLogUtils;
# ABSTRACT: Command line utilities for dealing with JSON-formatted log files

use strict;
use warnings;

=head1 SYNOPSIS

  tail -f /path/to/log/file.log \
    | jgrep -m message="some pattern" \
    | jcut -f "timestamp priority message" \
    | cols -c "timestamp priority message" -s '|' \
    | column -t -s '|'

=head1 DESCRIPTION

Writing logs in JSON, one object per line, makes them very easily machine
readable. Wonderful. Unfortunately, it also makes it unfuriating to deal with
them using the standard unix command line tools. This package provides a few
tools to salve the burn.

=head1 TOOLS

=head2 L<jgrep>

Greps patterns in individual object fields.

=head2 L<jcut>

Filter the fields included in objects.

=head2 L<jcols>

Display fields in a format suitable for C<column>.

=head2 L<jshell>

An interactive shell for monitoring JSON log files.

=head1 FUTURE PLANS

None, but will happily consider requests and patches.

=cut

1;

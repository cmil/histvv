package Histvv;

use warnings;
use strict;

=head1 NAME

Histvv - The Histvv Application

=head1 VERSION

Version 0.13

=cut

use version; our $VERSION = qv('0.13');

=head1 SYNOPSIS

    perldoc Histvv;

=head1 DESCRIPTION

For now this module is only there to occupy the Histvv namespace and
to provide a version number to the build system.

=cut

our $XMLNS = 'http://histvv.uni-leipzig.de/ns/2007';

use File::ShareDir;

=head2 sharedir

Determine directory for shared resources.

=cut

sub sharedir {
    my $dir;
    eval { $dir = $ENV{HISTVV_SHARE} || File::ShareDir::dist_dir('histvv') };
    return $dir;
}

=head1 AUTHOR

Carsten Milling, C<< <cmil at hashtable.de> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Carsten Milling, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

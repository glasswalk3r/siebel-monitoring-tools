use strict;
use warnings;
package Siebel::Lbconfig;
# VERSION

=pod

=head1 NAME

Siebel::Lbconfig - helper to generate optimied lbconfig file

=head1 DESCRIPTION

Siebel::Lbconfig is just Pod: check other modules for more information.

The distribution Siebel-Lbconfig was created based on classes from L<Siebel::Srvrmgr>.

The command line utility C<lbconfig> will connect to a Siebel Enterprise with C<srvrmgr> and generate a optimized
lbconfig.txt file by search all active AOMs that take can take advantage of the native load balancer.

=cut
1;

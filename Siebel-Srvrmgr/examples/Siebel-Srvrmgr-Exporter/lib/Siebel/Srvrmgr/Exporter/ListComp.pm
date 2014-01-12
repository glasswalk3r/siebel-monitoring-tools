package Siebel::Srvrmgr::Exporter::ListComp;

=pod

=head1 NAME

Siebel::Srvrmgr::Daemon::Action::ListComps - subclass of Siebel::Srvrmgr::Daemon::Action to deal with list comp output

=head1 SYNOPSIS

	use Siebel::Srvrmgr::Daemon::Action::ListComps;

	my $action = Siebel::Srvrmgr::Daemon::Action::ListComps->new({  parser => Siebel::Srvrmgr::ListParser->new(), 
																	params => [$myDumpFile]});

	$action->do(\@output);

=cut

use Moose;
use namespace::autoclean;
use Siebel::Srvrmgr::Daemon::ActionStash;

extends 'Siebel::Srvrmgr::Daemon::Action';

=pod

=head1 DESCRIPTION

This subclass of L<Siebel::Srvrmgr::Daemon::Action> will try to find a L<Siebel::Srvrmgr::ListParser::Output::ListComp> object in the given array reference
given as parameter to the C<do> method and stores the parsed data from this object in a serialized file. 

=head1 METHODS

=head2 do

This methods expects an array reference as parameter containing a given command output.

It will try to identify the first ocurrence of a L<Siebel::Srvrmgr::ListParser::Output::ListComp>: once one is found,
it will call the C<get_servers> method from this class and then iterate over the servers (objects from the class L<Siebel::Srvrmgr::ListParser::Output::ListComp::Server>) 
calling their respective C<store> method to serialize themselves into the OS filesystem.

The name of the filename used for data serialization will be the value of C<dump_file> append with the character '_' and the server name.

This method will return 1 if this operation was executed sucessfuly, 0 otherwise.

=cut

override 'do_parsed' => sub {

    my $self = shift;
    my $obj  = shift;

    my $stash = Siebel::Srvrmgr::Daemon::ActionStash->instance();

    if ( $obj->isa('Siebel::Srvrmgr::ListParser::Output::Tabular::ListComp') ) {

        my $servers_ref = $obj->get_servers();

        warn "Could not fetch servers\n"
          unless ( scalar( @{$servers_ref} ) > 0 );

        foreach my $servername ( @{$servers_ref} ) {

            my $server = $obj->get_server($servername);

            if (
                $server->isa(
                    'Siebel::Srvrmgr::ListParser::Output::ListComp::Server')
              )
            {

                $stash->set_stash( [$server] );

                return 1;

            }
            else {

                warn "could not fetch $servername data\n";

            }

        }

    }

    return 0;

};

=pod

=head1 SEE ALSO

=over 4

=item *

L<Siebel::Srvrmgr::ListParser::Output::ListComp>

=item *

L<Siebel::Srvrmgr::ListParser::Output::ListComp::Server>

=item *

L<Siebel::Srvrmgr::Daemon::Action>

=item *

L<Siebel::Srvrmgr::Daemon::Action::Serializable>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.org<E<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.org<E<gt>

This file is part of Siebel Monitoring Tools.

Siebel Monitoring Tools is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Siebel Monitoring Tools is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Siebel Monitoring Tools.  If not, see <http://www.gnu.org/licenses/>.

=cut

__PACKAGE__->meta->make_immutable;

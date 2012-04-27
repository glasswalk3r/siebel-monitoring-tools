package Siebel::Srvrmgr::Daemon::Action::CheckComps;

=pod

=head1 NAME

Siebel::Srvrmgr::Daemon::Action::CheckComps - subclass of Siebel::Srvrmgr::Daemon::Action to verify components status

=head1 SYNOPSIS

	use Siebel::Srvrmgr::Daemon::Action::CheckComps;

    my $return_data = Siebel::Srvrmgr::Daemon::ActionStash->instance();

    my $comps = [ {name => 'SynchMgr', ok_status => 'Running'}, { name => 'WfProcMgr', ok_status => 'Running'} ];

	my $action = Siebel::Srvrmgr::Daemon::Action::CheckComps->new({  parser => Siebel::Srvrmgr::ListParser->new(), 
																	 params => ['myserver', $comps ] });

	$action->do();

    # do something with $return_data

=cut

use Moose;
use namespace::autoclean;
use Siebel::Srvrmgr::Daemon::ActionStash;

extends 'Siebel::Srvrmgr::Daemon::Action';

=pod

=head1 DESCRIPTION

This subclass of L<Siebel::Srvrmgr::Daemon::Action> will try to find a L<Siebel::Srvrmgr::ListParser::Output::ListComp> object in the given array reference
given as parameter to the C<do> method and compares the status of the components with the array reference given as parameter.

The C<do> method of C<Siebel::Srvrmgr::Daemon::Action::CheckComps> uses L<Siebel::Srvrmgr::Daemon::ActionStash> to enable the program that created the object 
instance to be able to fetch the information returned.

=head1 METHODS

=head2 do

blablabla.

This method will return 1 if this operation was executed sucessfuly, 0 otherwise.

=cut

override 'do' => sub {

    my $self   = shift;
    my $buffer = shift;    # array reference

    my $params = $self->get_params();    # array reference

    super();

    my $servername = $params->[0];
    my $exp_comps  = $params->[1];       # expected comps states

    $self->get_parser()->parse($buffer);

    my $tree = $self->get_parser()->get_parsed_tree();

    my %checked_comps;

    foreach my $obj ( @{$tree} ) {

        if ( $obj->isa('Siebel::Srvrmgr::ListParser::Output::ListComp') ) {

            my $servers_ref = $obj->get_servers();

            die
"Could not fetch servers from the Siebel::Srvrmgr::ListParser::Output::ListComp object returned by the parser"
              unless ( scalar( @{$servers_ref} ) > 0 );

            foreach my $servername ( @{$servers_ref} ) {

                my $server = $obj->get_server($servername);

                if (
                    $server->isa(
                        'Siebel::Srvrmgr::ListParser::Output::ListComp::Server')
                  )
                {

                    if ( $server->get_name() eq $servername ) {

                        foreach my $exp_comp ( @{$exp_comps} ) {

                            my $comp = $server->get_comp( $exp_comp->{name} );

                            if ( defined($comp) ) {

                                my @valid_status =
                                  split( /\|/, $exp_comp->{ok_status} );

                                my $is_ok = 0;

                                foreach my $valid_status (@valid_status) {

                                    if ( $valid_status eq
                                        $comp->cp_disp_run_state() )
                                    {

                                        $is_ok = 1;
                                        last;

                                    }

                                }

                                if ($is_ok) {

                                    $checked_comps{$servername}
                                      ->{ $exp_comp->{name} } = 1;

                                }
                                else {

                                    $checked_comps{$servername}
                                      ->{ $exp_comp->{name} } = 0;

                                    warn 'invalid status got for ',
                                      $exp_comp->{name}, ' ',
                                      $comp->cp_disp_run_state(), "\n"
                                      if ( $ENV{SIEBEL_SRVRMGR_DEBUG} );

                                }

                            }
                            else {

                                die 'Could not find any component with name ',
                                  $exp_comp->{name}, "\n"

                            }

                        }

                    }    # end of foreach comp
                    else {

                        die "Invalid servername returned\n";

                    }

                }
                else {

                    die "could not fetch $servername data\n";

                }

            }    # end of foreach server

        }

    }    # end of foreach Siebel::Srvrmgr::ListParser::Output::ListComp object

    # found some servers
    if ( keys(%checked_comps) ) {

        my $stash = Siebel::Srvrmgr::Daemon::ActionStash->instance();
        $stash->set_stash( \%checked_comps );

        return 1;

    }
    else {

        return 0;

    }

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

L<Siebel::Srvrmgr::Daemon::Action::Stash>

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

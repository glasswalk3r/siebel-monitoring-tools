package Siebel::Srvrmgr::Daemon::Action::CheckComps;

=pod

=head1 NAME

Siebel::Srvrmgr::Daemon::Action::CheckComps - subclass of Siebel::Srvrmgr::Daemon::Action to verify components status

=head1 SYNOPSIS

	use Siebel::Srvrmgr::Daemon::Action::CheckComps;

    my $return_data = Siebel::Srvrmgr::Daemon::ActionStash->instance();

    my $comps = [ {name => 'SynchMgr', ok_status => 'Running'}, { name => 'WfProcMgr', ok_status => 'Running'} ];

	my $action = Siebel::Srvrmgr::Daemon::Action::CheckComps->new({  parser => Siebel::Srvrmgr::ListParser->new(), 
																	 params => [ $server1, $server2 ] });

	$action->do();

    # do something with $return_data

=cut

use Moose;
use namespace::autoclean;
use Moose::Util qw(does_role);
use Siebel::Srvrmgr::Daemon::ActionStash;

extends 'Siebel::Srvrmgr::Daemon::Action';

=pod

=head1 DESCRIPTION

This subclass of L<Siebel::Srvrmgr::Daemon::Action> will try to find a L<Siebel::Srvrmgr::ListParser::Output::ListComp> object in the given array reference
given as parameter to the C<do> method and compares the status of the components with the array reference given as parameter.

The C<do> method of C<Siebel::Srvrmgr::Daemon::Action::CheckComps> uses L<Siebel::Srvrmgr::Daemon::ActionStash> to enable the program that created the object 
instance to be able to fetch the information returned.

This module was created to work close with Nagios concepts, especially regarding threshold levels (see C<new> method for more details).

=head1 METHODS

=head2 new

The new method returns a instance of L<Siebel::Srvrmgr::Daemon::Action::CheckComps>. The parameter expected are the same ones of any subclass of 
L<Siebel::Srvrmgr::Daemon::Action>, but the C<params> attribute has a important difference: it expects an array reference with instances of classes
that have the role L<Siebel::Srvrmgr::Daemon::Action::CheckComps::Server>. The way that the classes will get the 
information about which component to check per server is not important as long as they keep the same methods defined by 
the roles L<Siebel::Srvrmgr::Daemon::Action::CheckComps::Server> and 
L<Siebel::Srvrmgr::Daemon::Action::CheckComps::Component>.
that have the role L<Siebel::Srvrmgr::Daemon::Action::CheckComps::Server>. The way that the classes will get the information about which component 
information is available per server is not important as long as they keep the same methods defined by the roles 
L<Siebel::Srvrmgr::Daemon::Action::CheckComps::Server> for a Siebel server and L<Siebel::Srvrmgr::Daemon::Action::CheckComps::Component> for a Siebel
server component.

See the examples directory of this distribution to check a XML file used for configuration for more details.

=head2 BUILD

Validates if the params array reference have objects with the L<Siebel::Srvrmgr::Daemon::Action::CheckComps::Server> role applied.

=cut

sub BUILD {

    my $self = shift;

    my $role = 'Siebel::Srvrmgr::Daemon::Action::CheckComps::Server';

    foreach my $object ( @{ $self->get_params() } ) {

        die "all params items must be classes with $role role applied"
          unless ( does_role( $object, $role ) );

    }

}

=head2 do

Expects a array reference as the buffer output from C<srvrmgr> program as a parameter.

This method will check the output from C<srvrmgr> program parsed by L<Siebel::Srvrmgr::ListParser::Output::ListComp> object and compare each component recovered status
with the status defined in the array reference given to C<params> method during object creation.

It will return 1 if this operation was executed successfuly and request a instance of L<Siebel::Srvrmgr::Daemon::ActionStash>, calling it's method C<instance> and then
C<set_stash> with a hash reference as it's content. Otherwise, the method will return 0 and no data will be set to the ActionStash object.

The hash reference stored in the ActionStash object will have the following structure:

	$VAR1 = {
			  'foobar_server' => {
								   'CompAlias1' => 0,
								   'CompAlias2' => 1
								 },
			  'foobar2_server' => {
									'CompAlias1' => 1,
									'CompAlias2' => 1
								  }
			};

If the servername passed during the object creation (as C<params> attribute of C<new> method) cannot be found in the buffer parameter, the object will raise an
exception.

Beware that this Action subclass can deal with multiple servers, as long as the buffer output is from a C<list comp>, list all server/components that
are part of the Siebel Enterprise.

=cut

override 'do' => sub {

    my $self   = shift;
    my $buffer = shift;    # array reference

    my $servers = $self->get_params();    # array reference

    super();

    my %servers;    # to locate the expected servers easier

    foreach my $server ( @{$servers} ) {

        $servers{ $server->name() } = $server;

    }

    $self->get_parser()->parse($buffer);

    my $tree = $self->get_parser()->get_parsed_tree();

    my %checked_comps;

    foreach my $obj ( @{$tree} ) {

        if ( $obj->isa('Siebel::Srvrmgr::ListParser::Output::ListComp') ) {

            my $servers_ref = $obj->get_servers();

            confess
"Could not fetch servers from the Siebel::Srvrmgr::ListParser::Output::ListComp object returned by the parser"
              unless ( scalar( @{$servers_ref} ) > 0 );

            foreach my $name ( @{$servers_ref} ) {

                my $server = $obj->get_server($name);

                if (
                    $server->isa(
                        'Siebel::Srvrmgr::ListParser::Output::ListComp::Server')
                  )
                {

                    my $name = $server->get_name();

                    if ( exists( $servers{$name} ) ) {

                        my $exp_srv =
                          $servers{$name};    # the expected server reference

                        foreach my $exp_comp ( @{ $exp_srv->components() } ) {

                            my $comp = $server->get_comp( $exp_comp->name() );

                            if ( defined($comp) ) {

                                my @valid_status =
                                  split( /\|/, $exp_comp->OKStatus() );

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

                                    $checked_comps{ $exp_srv->name() }
                                      ->{ $exp_comp->name() } = 1;

                                }
                                else {

                                    $checked_comps{ $exp_srv->name() }
                                      ->{ $exp_comp->name() } = 0;

# :TODO      :04/06/2013 19:16:51:: must use a environment variable to indicate Log::Log4perl configuration and then enable logging here
#                                    warn 'invalid status got for ',
#                                      $exp_comp->name(), ' ',
#                                      $comp->cp_disp_run_state();

                                }

                            }
                            else {

                                confess
                                  'Could not find any component with name ',
                                  $exp_comp->{name}, "\n"

                            }

                        }

                    }    # end of foreach comp
                    else {

                        confess 'Unexpected servername retrieved from buffer';

                    }

                }
                else {

                    confess "could not fetch $name data";

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

=item *

L<Nagios::Plugin>

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

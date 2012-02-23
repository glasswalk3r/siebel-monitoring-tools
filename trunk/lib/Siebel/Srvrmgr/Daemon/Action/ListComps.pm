package Siebel::Srvrmgr::Daemon::Action::ListComps;

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

extends 'Siebel::Srvrmgr::Daemon::Action';

with 'Siebel::Srvrmgr::Daemon::Action::Serializable';

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

override 'do' => sub {

    my $self   = shift;
    my $buffer = shift;    # array reference

    super();

    $self->get_parser()->parse($buffer);

    my $tree = $self->get_parser()->get_parsed_tree();

    my @comps
      ;   # array of Siebel::Srvrmgr::ListParser::Output::ListComp::Comp objects

    foreach my $obj ( @{$tree} ) {

        if ( $obj->isa('Siebel::Srvrmgr::ListParser::Output::ListComp') ) {

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

                    my $filename =
                      $self->get_dump_file() . '_' . $server->get_name();

                    $server->store($filename);
                    return 1;

                }
                else {

                    warn "could not fetch $servername data\n";

                }

            }

        }

    }    # end of foreach block

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


=cut

__PACKAGE__->meta->make_immutable;

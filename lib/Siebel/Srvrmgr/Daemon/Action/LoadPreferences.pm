package Siebel::Srvrmgr::Daemon::Action::LoadPreferences;

=pod

=head1 NAME

Siebel::Srvrmgr::Daemon::Action::LoadPreferences - dummy subclass of Siebel::Srvrmgr::Daemon::Action to allow execution of load preferences command

=head1 SYNOPSIS

	use Siebel::Srvrmgr::Daemon::Action::LoadPreferences;

	my $action = Siebel::Srvrmgr::Daemon::Action::LoadPreferences->new(parser => Siebel::Srvrmgr::ListParser->new());

	$action->do(\@output);

=cut

use Moose;
use namespace::autoclean;

extends 'Siebel::Srvrmgr::Daemon::Action';

=head1 DESCRIPTION

The only usage for this class is to allow execution of C<load preferences> command by a L<Siebel::Srvrmgr::Daemon> object, allowing the execution
and parsing of the output of the command to be executed in the regular cycle of processing.

Executing C<load preferences> is particullary useful for setting the correct columns and sizing of output of commands like C<list comp>.

=head1 METHODS

=head2 do

C<do> method will not do much: it expects an array reference with the output of the command C<load preferences>. This content will be parsed
by L<Siebel::Srvrmgr::ListParser> object and as soon an L<Siebel::Srvrmgr::ListParser::Output::LoadPreferences> is found the method will return true (1).

If the LoadPreferences object is not found, the method will return false.

=cut

sub do {

    my $self   = shift;
    my $buffer = shift;

    $self->get_parser()->parse($buffer);

    my $tree = $self->get_parser()->get_parsed_tree();

    foreach my $obj ( @{$tree} ) {

        if ( $obj->isa('Siebel::Srvrmgr::ListParser::Output::LoadPreferences') )
        {

            return 1;

        }

    }    # end of foreach block

    return 0;

}

=pod

=head1 SEE ALSO

=over 3

=item *

L<Siebel::Srvrmgr::Daemon>

=item *

L<Siebel::Srvrmgr::Daemon::Action>

=item *

L<Siebel::Srvrmgr::ListParser::Output::LoadPreferences>

=back

=cut

__PACKAGE__->meta->make_immutable;

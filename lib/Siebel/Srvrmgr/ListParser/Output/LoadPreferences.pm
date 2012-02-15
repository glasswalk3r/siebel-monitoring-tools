package Siebel::Srvrmgr::ListParser::Output::LoadPreferences;

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::Output::LoadPreferences - subclass to parse load preferences command.

=cut

use Moose;
use Siebel::Srvrmgr::Regexes;

extends 'Siebel::Srvrmgr::ListParser::Output';

=pod

=head1 SYNOPSIS

See L<Siebel::Srvrmgr::ListParser::Output> for example.

=head1 DESCRIPTION

This class is a subclass of L<Siebel::Srvrmgr::ListParser::Output>. In truth, this is not a parser for a C<list> command, but since the usage of
C<load preferences> is strongly recommended, this subclasses was added to enable usage in L<Siebel::Srvrmgr::Daemon::Action> subclasses.

=head1 ATTRIBUTES

=head2 location

A string of location of the preferences file returned by the C<load preferences> command.

=cut

has 'location' => (
    is     => 'rw',
    isa    => 'Str',
    reader => 'get_location',
    writer => 'set_location'
);

=pod

=head1 METHODS

=head2 get_location

Returns the C<location> attribute.

=head2 set_location

Set the C<location> attribute. Expects and string as parameter.

=head2 parse

Parses the C<load preferences> output stored in the C<raw_data> attribute, setting the C<data_parsed> attribute.

The C<raw_data> attribute will be set to an reference to an empty array.

=cut

sub parse {

    my $self = shift;

    my $data_ref = $self->get_raw_data();

    my %parsed_lines;

    my $response = Siebel::Srvrmgr::Regexes::LOAD_PREF_RESP;
    my $command  = Siebel::Srvrmgr::Regexes::LOAD_PREF_CMD;

    foreach my $line ( @{$data_ref} ) {

        chomp($line);

      SWITCH: {

            if ( $line =~ /$response/ ) {

                my @data = split( /\:\s/, $line );

                $self->set_location( $data[-1] );
                $parsed_lines{answer} = $line;

                last SWITCH;

            }

            if ( $line =~ /$command/ ) {

                $parsed_lines{command} = $line;
                last SWITCH;

            }

            if ( $line eq '' ) {

                last SWITCH;

            }

        }

    }

    warn "Did not found any line with response\n"
      unless ( defined( $self->get_location() ) );

    $self->set_data_parsed( \%parsed_lines );
    $self->set_raw_data( [] );

}

=pod

=head1 SEE ALSO

=over 2

=item *

L<Siebel::Srvrmgr::ListParser::Output>

=item *

L<Moose>

=back

=cut

no Moose;
__PACKAGE__->meta->make_immutable;

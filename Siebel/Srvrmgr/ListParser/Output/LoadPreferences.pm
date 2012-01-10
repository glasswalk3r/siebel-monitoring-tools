package Siebel::Srvrmgr::ListParser::Output::LoadPreferences;
use Moose;
use Siebel::Srvrmgr::Regexes;

extends 'Siebel::Srvrmgr::ListParser::Output';

has 'location' => (
    is     => 'rw',
    isa    => 'Str',
    reader => 'get_location',
    writer => 'set_location'
);

sub BUILD {

    my $self = shift;

    $self->parse();

}

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

                my @data = split( /\s/, $line );

                $self->set_location( $data[2] );
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

no Moose;
__PACKAGE__->meta->make_immutable;

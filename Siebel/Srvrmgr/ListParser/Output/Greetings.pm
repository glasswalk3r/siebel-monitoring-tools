package Siebel::Srvrmgr::ListParser::Output::Greetings;
use Moose;

extends 'Siebel::Srvrmgr::ListParser::Output';

sub BUILD {

    my $self = shift;

    $self->parse();

}

has 'version' => (
    is     => 'rw',
    isa    => 'Str',
    reader => 'get_version',
    writer => 'set_version'
);

has 'patch' =>
  ( is => 'rw', isa => 'Int', reader => 'get_patch', writer => 'set_patch' );

has 'copyright' => (
    is     => 'rw',
    isa    => 'Str',
    reader => 'get_copyright',
    writer => 'set_copyright'
);

has 'total_servers' => (
    is     => 'rw',
    isa    => 'Int',
    reader => 'get_total_servers',
    writer => 'set_total_servers'
);

has 'total_connected' => (
    is     => 'rw',
    isa    => 'Int',
    reader => 'get_total_conn',
    writer => 'set_total_conn'
);

# nothing seems to be interesting to do with the greetings text
sub parse {

    my $self = shift;

    my $data_ref = $self->get_raw_data();

    foreach my $line ( @{$data_ref} ) {

        chomp($line);
        next if $line eq '';

      SWITCH: {

            if ( $line =~
                /^Siebel\sEnterprise\sApplications\sSiebel\sServer\sManager/ )
            {

#Siebel Enterprise Applications Siebel Server Manager, Version 7.5.3 [16157] LANG_INDEPENDENT
                my @words = split( /\s/, $line );

                $self->set_version( $words[7] );
				$words[8] =~ tr/[]//d;
                $self->set_patch( $words[8] );

                last SWITCH;

            }

            if ( $line =~ /^Copyright/ ) {

                #Copyright (c) 2001 Siebel Systems, Inc.  All rights reserved.

                my @words = split( /\s/, $line );

                $self->set_copyright(
                    $words[2] . ' ' . $words[3] . ' ' . $words[4] );

                last SWITCH;
            }

            if ( $line =~ /^Connected/ ) {

       #Connected to 1 server(s) out of a total of 1 server(s) in the enterprise
       #Connected to 2 server(s) out of a total of 2 server(s) in the enterprise
                my @words = split( /\s/, $line );

                $self->set_total_servers( $words[9] );
                $self->set_total_conn( $words[2] );

                last SWITCH;
            }

        }

    }

}

no Moose;
__PACKAGE__->meta->make_immutable;


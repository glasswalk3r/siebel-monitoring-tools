package Siebel::Srvrmgr::ListParser::Output::ListCompDef;
use Moose;

extends 'Siebel::Srvrmgr::ListParser::Output';

has 'comp_params' => (
    is     => 'rw',
    isa    => 'ArrayRef',
    reader => 'get_comp_params',
    writer => 'set_comp_params'
);

# for POD,  this is the list configuration considered by the module
#srvrmgr> configure list comp def
#        CC_NAME (76):  Component name
#        CT_NAME (76):  Component type name
#        CC_RUNMODE (31):  Component run mode (enum)
#        CC_ALIAS (31):  Component alias
#        CC_DISP_ENABLE_ST (61):   Display enablement state (translatable)
#        CC_DESC_TEXT (251):   Component description
#        CG_NAME (76):  Component group
#        CG_ALIAS (31):  Component Group Alias
#        CC_INCARN_NO (23):  Incarnation Number

sub parse {

    my $self = shift;

    my $data_ref = $self->get_raw_data();

    my %parsed_lines;

# removing the three last lines Siebel 7.5.3 (one blank line followed by a line amount of lines returned followed by a blank line)
    for ( 1 .. 3 ) {

        pop( @{$data_ref} );

    }

    foreach my $line ( @{$data_ref} ) {

        chomp($line);

      SWITCH: {

            if ( $line =~ /^\-+\s/ ) {    # this is the header line

                my @columns = split( /\s{2}/, $line );

                my $pattern;

                foreach my $column (@columns) {

                    $pattern .= 'A'
                      . ( length($column) + 2 )
                      ; # + 2 because of the spaces after the "---" that will be trimmed

                }

                $self->set_fields_pattern($pattern);

                last SWITCH;

            }

            if ( $line eq '' ) {

                last SWITCH;

            }

            if ( $line =~ /^CC_NAME\s.*\sCC_INCARN_NO\s*$/ ) { # this is the header

                my @columns = split( /\s{2,}/, $line );

                $self->set_comp_params( \@columns );

                last SWITCH;

            }
            else {

                my @fields_values;

				if ($self->get_fields_pattern()) {
				
                  @fields_values = unpack( $self->get_fields_pattern(), $line );
				
				} else {

					die "Cannot continue since fields pattern was not defined\n";

				}

                my $cc_name = $fields_values[0];

                my $list_len = scalar(@fields_values);

                my $columns_ref = $self->get_comp_params();

                if (@fields_values) {

                    for ( my $i = 0 ; $i < $list_len ; $i++ ) {

                        $parsed_lines{$cc_name}->{ $columns_ref->[$i] } =
                          $fields_values[$i];

                    }

                }
                else {

                    warn "got nothing\n";

                }

            }

        }

    }

    $self->set_data_parsed( \%parsed_lines );
    $self->set_raw_data( [] );

}

no Moose;
__PACKAGE__->meta->make_immutable;

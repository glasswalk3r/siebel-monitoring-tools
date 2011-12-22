package Siebel::Srvrmgr::ListParser::Output::ListComp;
use Moose;

extends 'Siebel::Srvrmgr::ListParser::Output';

has 'last_server' => (
    is      => 'rw',
    isa     => 'Str',
    reader  => 'get_last_server',
    writer  => '_set_last_server',
    default => ''
);

has 'comp_attribs' => (
    is     => 'rw',
    isa    => 'ArrayRef',
    reader => 'get_comp_attribs',
    writer => 'set_comp_attribs'
);

has 'servers' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    reader  => 'get_servers',
    default => sub { return [] }
);

sub set_last_server {

    my $self   = shift;
    my $server = shift;

    $self->_set_last_server($server);
    push( @{ $self->get_servers() }, $server );

}

has 'fields_pattern' => (
    is     => 'rw',
    isa    => 'Str',
    reader => 'get_fields_pattern',
    writer => 'set_fields_pattern'
);

# for POD,  this is the list configuration considered by the module
#srvrmgr> configure list comp
#        SV_NAME (31):  Server name
#        CC_ALIAS (31):  Component alias
#        CC_NAME (76):  Component name
#        CT_ALIAS (31):  Component type alias
#        CG_ALIAS (31):  Component GRoup Alias
#        CC_RUNMODE (31):  Component run mode (enum)
#        CP_DISP_RUN_STATE (61):  Component display run state
#        CP_NUM_RUN_TASKS (11):  Current number of running tasks
#        CP_MAX_TASKS (11):  Maximum tasks configured
#        CP_ACTV_MTS_PROCS (11):  Active MTS control processes
#        CP_MAX_MTS_PROCS (11):  Maximum MTS control processes
#        CP_START_TIME (21):  Component start time
#        CP_END_TIME (21):  Component end time
#        CP_STATUS (251):  Component-reported status
#        CC_INCARN_NO (23):  Incarnation Number
#        CC_DESC_TEXT (251):  Component description
#configure list comp show SV_NAME, CC_ALIAS, CC_NAME, CG_ALIAS, CC_RUNMODE, CP_DISP_RUN_STATE, CP_NUM_RUN_TASKS, CP_MAX_TASKS, CP_ACTV_MTS_PROCS, CP_MAX_MTS_PROCS, CP_START_TIME, CP_END_TIME

sub BUILD {

    my $self = shift;

    $self->parse();

}

sub parse {

    my $self = shift;

    my $data_ref = $self->get_raw_data();

    my %parsed_lines;

    # removing the three last lines Siebel 7.5.3
    for ( 1 .. 3 ) {

        pop( @{$data_ref} );

    }

    foreach my $line ( @{$data_ref} ) {

        chomp($line);

      SWITCH: {

            if ( $line =~ /^\-+\s/ ) {

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

            #SV_NAME     CC_ALIAS
            if ( $line =~ /^SV_NAME\s+CC_ALIAS/ ) {

                my @columns = split( /\s{2,}/, $line );

                #SV_NAME is usuless here
                shift(@columns);

                # component alias do not need to be maintained here
                shift(@columns);

                $self->set_comp_attribs( \@columns );

                last SWITCH;

            }
            else {

                my @fields_values =
                  unpack( $self->get_fields_pattern(), $line );

                my $server = shift(@fields_values);

                # do not need the servername again
                if (   ( $self->get_last_server() eq '' )
                    or ( $self->get_last_server() ne $server ) )
                {

                    $self->set_last_server($server);

                }

                my $comp_alias = shift(@fields_values);

                my $list_len = scalar(@fields_values);

                my $columns_ref = $self->get_comp_attribs();

                if (@fields_values) {

                    for ( my $i = 0 ; $i < $list_len ; $i++ ) {

                        my $server = $self->get_last_server();

                        $parsed_lines{$server}->{$comp_alias}
                          ->{ $columns_ref->[$i] } = $fields_values[$i];

                    }

                }
                else {

                    warn "get nothing\n";

                }

            }

        }

    }

    $self->set_data_parsed( \%parsed_lines );
    $self->set_raw_data( [] );

}

no Moose;
__PACKAGE__->meta->make_immutable;

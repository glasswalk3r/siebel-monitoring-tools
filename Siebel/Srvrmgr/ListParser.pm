package Siebel::Srvrmgr::ListParser;
use Moose;
use FSA::Rules;
use Data::Dumper;
use Carp;
use lib 'c:/temp/monitor';
use Siebel::Srvrmgr::ListParser::Output;
use Siebel::Srvrmgr::ListParser::Buffer;

has 'parsed_tree' => (
    is     => 'rw',
    isa    => 'ArrayRef',
    reader => 'get_parsed_tree',
    writer => '_set_parsed_tree'
);

has 'has_tree' => ( is => 'rw', isa => 'Bool', default => 0 );

has '_list_comp_format' =>
  ( is => 'ro', isa => 'Str', reader => 'get_list_comp_format' );

has 'prompt_regex' => (
    is      => 'rw',
    isa     => 'RegexpRef',
    reader  => 'get_prompt_regex',
    writer  => 'set_prompt_regex',
    default => sub { qr/^srvrmgr(\:\w+)?>(\s[\w\s]+)?/ }
);

has 'hello_regex' => (
    is      => 'rw',
    isa     => 'RegexpRef',
    reader  => 'get_hello_regex',
    writer  => 'set_hello_regex',
    default => sub {
qr/^Siebel\sEnterprise\sApplications\sSiebel\sServer\sManager\,\sVersion*/;
    }
);

has 'last_command' => (
    is      => 'rw',
    isa     => 'Str',
    reader  => 'get_last_command',
    writer  => '_set_last_command',
    default => ''
);

has 'is_cmd_changed' => ( isa => 'Bool', is => 'rw', default => 0 );

has 'buffer' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    reader  => 'get_buffer',
    writer  => '_set_buffer',
    default => sub { return [] }
);

sub set_last_command {

    my $self = shift;
    my $cmd  = shift;

    # trigger for set_buffer method
    $self->is_cmd_changed(1);

    $self->_set_last_command($cmd);

}

sub set_buffer {

    my $self  = shift;
    my $state = shift;

    if ( defined( $state->notes('line') ) ) {

        my $buffer_ref = $self->get_buffer();

# already has something, get the last one (only if the log file is valid this will work)
        if ( scalar( @{$buffer_ref} ) >= 1 ) {

            my $last_buffer = $buffer_ref->[ $#{$buffer_ref} ];

            if ( $self->is_cmd_changed() ) {

# :TODO:07/07/2011 13:05:22:: refactor this to a private method since code is repeated
                my $buffer = Siebel::Srvrmgr::ListParser::Buffer->new(
                    { type => $state->name() } );

                $buffer->set_content( $state->notes('line') );

                push( @{$buffer_ref}, $buffer );
                $self->_set_buffer($buffer_ref);

            }
            else {

                if ( $last_buffer->get_type() eq $state->name() ) {

                    $last_buffer->set_content( $state->notes('line') );

                }
                else {

                    carp 'Command has not changed but type of output has (got '
                      . $state->name()
                      . ' instead of '
                      . $last_buffer->get_type() . ")\n";

                }

            }

        }
        else {

            my $buffer = Siebel::Srvrmgr::ListParser::Buffer->new(
                { type => $state->name() } );

            $buffer->set_content( $state->notes('line') );

            push( @{$buffer_ref}, $buffer );
            $self->_set_buffer($buffer_ref);

        }

    }
    else {

        carp "Undefined content from state received\n";

    }

}

sub clean_buffer {

    my $self = shift;

    $self->_set_buffer( [] );

}

#around BUILDARGS => sub {
#
#    my $orig  = shift;
#    my $class = shift;
#
#    # hash ref
#    my $args = shift;
#
#    $args->{_list_comp_format} = $args->{default_prompt} . 'list comp';
#
#    return $class->$orig($args);
#
#};

sub count_parsed {

    my $self = shift;

    return scalar( @{ $self->get_parsed_tree() } );

}

sub clean_parsed_tree {

    my $self = shift;

    $self->has_tree(0);

}

sub set_parsed_tree {

    my $self   = shift;
    my $output = shift;

    if ( $self->has_tree() ) {

        my $old_parsed_tree = $self->get_parsed_tree();
        push( @{$old_parsed_tree}, $output );
        $self->_set_parsed_tree($old_parsed_tree);

    }
    else {

        $self->_set_parsed_tree( [$output] );

    }

    $self->has_tree(1);

}

sub append_output {

    my $self      = shift;
    my $data_type = shift;
    my $data_ref  = shift;

# :TODO:12/07/2011 16:37:23:: use an abstract factory here; last_command attribute should define which class to create
    my $output = Siebel::Srvrmgr::ListParser::Output->new(
        { data_type => $data_type, data_parsed => $data_ref } );

    $self->set_parsed_tree($output);

}

sub parse {

    my $self = shift;

    # array ref
    my $data_ref = shift;

    die "data parameter must be an array reference\n"
      unless ( ref($data_ref) eq 'ARRAY' );

    my $fsa = FSA::Rules->new(
        first_line => {
            do    => sub { print "Searching for useful data\n" },
            rules => [
                command_submission => sub {

                    my $state = shift;
                    my $line  = $state->notes('line');

                    return ( $state->notes('line') =~
                          $state->notes('parser')->get_prompt_regex() );

                },
                greetings => sub {

                    my $state = shift;

                    return ( $state->notes('line') =~
                          $state->notes('parser')->get_hello_regex() );

                },
                first_line => sub { return 1 }
            ],
            message => 'Line read'

        },
        greetings => {
            do => sub {

                my $state = shift;

                if ( defined( $state->notes('line') ) ) {

                    $state->notes('parser')->set_buffer($state);
                }
            },
            rules => [
                command_submission => sub {

                    my $state = shift;

                    return ( $state->notes('line') =~
                          $state->notes('parser')->get_prompt_regex() );

                },
                greetings => sub { return 1 }
            ],
            message => 'prompt found'
        },
        end => {
            do    => sub { print "Enterprise says 'bye-bye'\n"; },
            rules => [
                first_line => sub {
                    return 1;
                  }
            ],
            message => 'EOF'
        },
        list_comp => {
            do => sub {
                my $state = shift;

                $state->notes('parser')->set_buffer($state);

            },
            on_exit => sub {
                my $state = shift;
                $state->notes('parser')->is_cmd_changed(0);
            },
            rules => [
                command_submission => sub {

                    my $state = shift;

                    return ( $state->notes('line') =~
                          $state->notes('parser')->get_prompt_regex() );

                },
                list_comp => sub { return 1; }
            ],
            message => 'prompt found'
        },
        list_comp_params => {
            do => sub {
                my $state = shift;

                $state->notes('parser')->set_buffer($state);

            },
            on_exit => sub {
                my $state = shift;
                $state->notes('parser')->is_cmd_changed(0);
            },
            rules => [
                command_submission => sub {

                    my $state = shift;

                    return ( $state->notes('line') =~
                          $state->notes('parser')->get_prompt_regex() );

                },
                list_comp_params => sub { return 1; }
            ],
            message => 'prompt found'
        },
        command_submission => {
            do => sub {

                my $state = shift;

                my $cmd =
                  ( $state->notes('line') =~
                      $state->notes('parser')->get_prompt_regex() )[1];

                if ( defined($cmd) ) {

                    # removing spaces from command
                    $cmd =~ s/^\s+//;
                    $cmd =~ s/\s+$//;

                    $state->notes('parser')->set_last_command($cmd);
                }
                else {

                    warn 'got prompt, but no command submitted in line '
                      . $state->notes('line_num') . "\n"
                      unless ( defined($cmd) );

                }

            },
            rules => [
                list_comp => sub {

                    my $state = shift;

                    if ( $state->notes('parser')->get_last_command() eq
                        'list comp' )
                    {

                        return 1;

                    }
                    else {

                        return 0;

                    }

                },
                list_comp_params => sub {

                    my $state = shift;

           # :TODO:20/12/2011 18:05:33:: replace the regex for a precompiled one
                    if ( $state->notes('parser')->get_last_command() =~
                        /list\sparams\sfor\sserver\s\w+\sfor\scomponent\s\w+/ )
                    {

                        return 1;

                    }
                    else {

                        return 0;

                    }

                },

     # :TODO:06/07/2011 13:38:58:: add other possibilities here of list commands
            ],
            message => 'command submitted'
        }
    );

    $fsa->done( sub { ( $self->get_last_command() eq 'exit' ) ? 1 : 0 } );

    my $state;
    my $line_number = 0;

    foreach my $line ( @{$data_ref} ) {

        unless ( defined($state) ) {

            $state = $fsa->start();

# :TODO:07/07/2011 14:56:04:: this should be changed to avoid circular references
            $state->notes( parser => $self );

        }

        $line =~ s/\n$//;
        $state->notes( line_num => $line_number );
        $state->notes( line     => $line );
        $line_number++;
        $fsa->switch() unless ( $fsa->done() );

    }

}

no Moose;
__PACKAGE__->meta->make_immutable;

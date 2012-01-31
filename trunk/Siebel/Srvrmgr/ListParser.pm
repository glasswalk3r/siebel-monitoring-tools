package Siebel::Srvrmgr::ListParser;

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser - state model parser to idenfity which output type was read

=head1 SYNOPSIS

use Siebel::Srvrmgr::ListParser;

my $parser = Siebel::Srvrmgr::ListParser->new({ prompt_regex => $some_prompt });

=cut

use Moose;
use FSA::Rules;
use Carp;
use Siebel::Srvrmgr::ListParser::OutputFactory;
use Siebel::Srvrmgr::ListParser::Buffer;

=pod

=head1 DESCRIPTION

Siebel::Srvrmgr::ListParser is a state machine parser created to parse output of "list" commands executed through srvrmgr program.

The parser can idenfity different types of commands and their outputs from a buffer given as parameter to the module. Foreach 
type of output identified an Siebel::Srvrmgr::ListParser::Buffer object will be created, idenfifying which type of command
was executed and the raw information from it.

At the end of information read from the buffer, this class will call Siebel::Srvrmgr::ListParser::OutputFactory to create
specific Siebel::Srvrmgr::ListParser::Output objects based on the identified type of Buffer object. Each of this objects will
parse the raw output and populate attributes based on this information. After this is easier to obtain the information from
those subclasses of Siebel::Srvrmgr::ListParser::Output.

Siebel::Srvrmgr::ListParser expects to receive output from srvrmgr program in an specific format and is able to idenfity a
limited number of commands and their outputs, raising an exception when those types cannot be identified. See subclasses
of Siebel::Srvrmgr::ListParser::Output to see which classes/types are available.

=head1 ATTRIBUTES

=head2 parsed_tree

An array reference of parsed data. Each index should be a reference to another data extructure, most probably an hash 
reference, with parsed data related from one line read from output of srvrmgr program.

=cut

has 'parsed_tree' => (
    is     => 'rw',
    isa    => 'ArrayRef',
    reader => 'get_parsed_tree',
    writer => '_set_parsed_tree'
);

=pod

=head2 has_tree

A boolean value that identifies if the ListParser object has a parsed tree or not.

=cut

has 'has_tree' => ( is => 'rw', isa => 'Bool', default => 0 );

=pod

=head2 prompt_regex

A regular expression reference of how the srvrmgr prompt looks like.

=cut

has 'prompt_regex' => (
    is      => 'rw',
    isa     => 'RegexpRef',
    reader  => 'get_prompt_regex',
    writer  => 'set_prompt_regex'
);

=pod

=head2 hello_regex

A regular expression reference of how the first line of text received right after the login in one
server (or enterprise).

=cut

has 'hello_regex' => (
    is      => 'rw',
    isa     => 'RegexpRef',
    reader  => 'get_hello_regex',
    writer  => 'set_hello_regex',
	} 
);

=pod

=head2 last_command

A string with the last command identified by the parser. It is used for several things, including changes in the state model machine.

=cut

has 'last_command' => (
    is      => 'rw',
    isa     => 'Str',
    reader  => 'get_last_command',
    writer  => '_set_last_command',
    default => ''
);

=pod

=head2 is_cmd_changed

A boolean value that identified when the last_command attribute has been changed (i.e another command was identified by the parser).

=cut

has 'is_cmd_changed' => ( isa => 'Bool', is => 'rw', default => 0 );

=pod

=head2 buffer

An array reference with each one of the indexes being a C<Siebel::Srvrmgr::ListParser::Buffer> object.

=cut

has 'buffer' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    reader  => 'get_buffer',
    writer  => '_set_buffer',
    default => sub { return [] }
);

=pod

=head2 is_warn_enabled

A boolean value that is used for debugging purpouses during the parsing time. If enabled some debug messages may be printed during this phase.

=cut

has 'is_warn_enabled' => ( isa => 'Bool', is => 'ro', default => 0 );

=pod

=head1 METHODS

=head2 set_last_command

Set the last command found in the parser received data. It also triggers that the command has changed (see method is_cmd_changed).

=head2 is_cmd_changed

Sets the boolean attribute with the same name. If no parameter is given, returns the value stored in the C<is_cmd_changed> attribute. If a parameter is given, 
expects to received true (1) or false (0), otherwise it will return an exception.

=cut

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
                    {
                        type     => $state->name(),
                        cmd_line => $self->get_last_command()
                    }
                );

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
                {
                    type     => $state->name(),
                    cmd_line => $self->get_last_command()
                }
            );

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

    my $self   = shift;
    my $buffer = shift;

    my $output = Siebel::Srvrmgr::ListParser::OutputFactory->create(
        $buffer->get_type(),
        {
            data_type => $buffer->get_type(),
            raw_data  => $buffer->get_content(),
            cmd_line  => $buffer->get_cmd_line()
        }
    );

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
            do => sub {
                print "Searching for useful data\n";
            },
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
        list_comp_type => {
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
                list_comp_type => sub { return 1; }
            ],
            message => 'prompt found'
        },
        list_params => {
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
                list_params => sub { return 1; }
            ],
            message => 'prompt found'
        },
        list_comp_def => {
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
                list_comp_def => sub { return 1; }
            ],
            message => 'prompt found'
        },
        load_preferences => {
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
                list_comp_def => sub { return 1; }
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

                    if ( $state->notes('parser')->is_warn_enabled() ) {

                        warn 'got prompt, but no command submitted in line '
                          . $state->notes('line_num') . "\n"
                          unless ( defined($cmd) );

                    }

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
                list_comp_type => sub {

                    my $state = shift;

                    if ( $state->notes('parser')->get_last_command() eq
                        'list comp type' )
                    {

                        return 1;

                    }
                    else {

                        return 0;

                    }

                },
                list_params => sub {

                    my $state = shift;

           # :TODO:20/12/2011 18:05:33:: replace the regex for a precompiled one
                    if ( $state->notes('parser')->get_last_command() =~
                        /list\sparams(\sfor\sserver\s\w+\sfor\scomponent\s\w+)?/
                      )
                    {

                        return 1;

                    }
                    else {

                        return 0;

                    }

                },
                list_comp_def => sub {

                    my $state = shift;

           # :TODO:20/12/2011 18:05:33:: replace the regex for a precompiled one
                    if ( $state->notes('parser')->get_last_command() =~
                        /list\scomp\sdefs?(\s\w+)?/ )
                    {

                        return 1;

                    }
                    else {

                        return 0;

                    }

                },
                load_preferences => sub {

                    my $state = shift;

                    if ( $state->notes('parser')->get_last_command() eq
                        'load preferences' )
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

    # creates the parsed tree
    my $buffer_ref = $self->get_buffer();

    foreach my $buffer ( @{$buffer_ref} ) {

        $self->append_output($buffer);

    }

}

no Moose;
__PACKAGE__->meta->make_immutable;

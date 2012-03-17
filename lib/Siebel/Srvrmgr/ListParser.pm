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
use Siebel::Srvrmgr::ListParser::OutputFactory;
use Siebel::Srvrmgr::ListParser::Buffer;
use Siebel::Srvrmgr::Regexes qw(SRVRMGR_PROMPT CONN_GREET);

=pod

=head1 DESCRIPTION

Siebel::Srvrmgr::ListParser is a state machine parser created to parse output of "list" commands executed through C<srvrmgr> program.

The parser can idenfity different types of commands and their outputs from a buffer given as parameter to the module. Foreach 
type of output identified an L<Siebel::Srvrmgr::ListParser::Buffer> object will be created, identifying which type of command
was executed and the raw information from it.

At the end of information read from the buffer, this class will call L<Siebel::Srvrmgr::ListParser::OutputFactory> to create
specific L<Siebel::Srvrmgr::ListParser::Output> objects based on the identified type of Buffer object. Each of this objects will
parse the raw output and populate attributes based on this information. After this is easier to obtain the information from
those subclasses of L<Siebel::Srvrmgr::ListParser::Output>.

Siebel::Srvrmgr::ListParser expects to receive output from C<srvrmgr> program in an specific format and is able to idenfity a
limited number of commands and their outputs, raising an exception when those types cannot be identified. See subclasses
of L<Siebel::Srvrmgr::ListParser::Output> to see which classes/types are available.

=head1 ATTRIBUTES

=head2 parsed_tree

An array reference of parsed data. Each index should be a reference to another data extructure, most probably an hash 
reference, with parsed data related from one line read from output of C<srvrmgr> program.

This is an read-only attribute.

=cut

has 'parsed_tree' => (
    is     => 'ro',
    isa    => 'ArrayRef',
    reader => 'get_parsed_tree',
    writer => '_set_parsed_tree'
);

=pod

=head2 has_tree

A boolean value that identifies if the ListParser object has a parsed tree or not.

=cut

has 'has_tree' =>
  ( is => 'ro', isa => 'Bool', default => 0, writer => '_set_has_tree' );

=pod

=head2 prompt_regex

A regular expression reference of how the C<srvrmgr> prompt looks like.

=cut

has 'prompt_regex' => (
    is      => 'rw',
    isa     => 'RegexpRef',
    reader  => 'get_prompt_regex',
    writer  => 'set_prompt_regex',
    default => sub { SRVRMGR_PROMPT }
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
    default => sub { CONN_GREET }
);

=pod

=head2 last_command

A string with the last command identified by the parser. It is used for several things, including changes in the state model machine.

This is a read-only attribute.

=cut

has 'last_command' => (
    is      => 'ro',
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

=head2 is_cmd_changed

Sets the boolean attribute with the same name. If no parameter is given, returns the value stored in the C<is_cmd_changed> attribute. If a parameter is given, 
expects to received true (1) or false (0), otherwise it will return an exception.

=head2 get_parsed_tree

Returns the parsed_tree attribute.

=head2 get_prompt_regex

Returns the regular expression reference from the prompt_regex attribute.

=head2 set_prompt_regex

Sets the prompt_regex attribute. Expects an regular expression reference as parameter.

=head2 get_hello_regex

Returns the regular expression reference from the hello_regex attribute.

=head2 set_hello_regex

Sets the hello_regex attribute. Expects an regular expression reference as parameter.

=head2 get_last_command

Returns an string of the last command read by the parser.

=head2 has_tree

Returns a boolean value (1 for true, 0 for false) if the parser has or not a parsed tree.

=head2 set_last_command

Set the last command found in the parser received data. It also triggers that the command has changed (see method is_cmd_changed).

=cut

sub set_last_command {

    my $self = shift;
    my $cmd  = shift;

    # trigger for set_buffer method
    $self->is_cmd_changed(1);

    $self->_set_last_command($cmd);

}

=pod

=head2 set_buffer

Sets the buffer attribute,  inserting new C<Siebel::Srvrmgr::ListParser::Buffer> objects into the array reference as necessary.

=cut

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

                    warn 'Command has not changed but type of output has (got '
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

        warn "Undefined content from state received\n";

    }

}

=pod

=head2 clear_buffer

Removes the array reference from the buffer attribute and associates a new one with an empty array. This should be used for cleanup purpouses or attemp to free memory.

=cut

sub clear_buffer {

    my $self = shift;

    $self->_set_buffer( [] );

}

=pod

=head2 count_parsed

Returns an integer with the total number of objects available in the parsed_tree attribute.

=cut

sub count_parsed {

    my $self = shift;

    return scalar( @{ $self->get_parsed_tree() } );

}

=pod

=head2 clear_parsed_tree

Removes the reference on parsed_tree attribute. Also, sets has_tree attribute to false.

=cut

sub clear_parsed_tree {

    my $self = shift;

    $self->_set_has_tree(0);

    $self->_set_parsed_tree( [] );

}

=pod

=head2 set_parsed_tree

Sets the parsed_tree attribute, adding references as necessary. Also sets the has_tree attribute to true.

This method should not be called directly unless you know what you're doing. See C<append_output> method.

=cut

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

    $self->_set_has_tree(1);

}

=pod

=head2 append_output

Appends an object to an existing parsed tree. Expects as a parameter an C<Siebel::Srvrmgr::ListParser::Buffer> object as a parameter.

It uses C<Siebel::Srvrmgr::ListParser::OutputFactory> to create the proper 
C<Siebel::Srvrmgr::ListParser::Output> object based on the C<Siebel::Srvrmgr::ListParser::Buffer> type.

=cut

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

=pod

=head2 parse

Parses one or more commands output executed through C<srvrmgr> program.

Expects as parameter an array reference with the output of srvrmgr, including the command executed.

It will create an C<FSA::Rules> object to parse the given array reference, calling C<append_output> method for each C<Siebel::Srvrmgr::ListParser::Buffer> object
found.

This method will raise an exception if a given output cannot be identified by the parser.

=cut

sub parse {

    my $self = shift;

    # array ref
    my $data_ref = shift;

    die "data parameter must be an array reference\n"
      unless ( ref($data_ref) eq 'ARRAY' );

# :TODO:27/2/2012 15:06:20:: treat STDOUT messages adding a "warn" to notes method based on is_warn_enabled attribute
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
        list_comp_types => {
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
                list_comp_types => sub { return 1; }
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
                load_preferences => sub { return 1; }
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
                list_comp_types => sub {

                    my $state = shift;

                    if (
                        (
                            $state->notes('parser')->get_last_command() eq
                            'list comp types'
                        )
                        or ( $state->notes('parser')->get_last_command() eq
                            'list comp type' )
                      )
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

    return 1;

}

=pod

=head1 CAVEATS

Checkout the POD for the C<Siebel::Srvrmgr::ListParser::Output> objects to see details about which kind of output is expected if you're getting errors from the parser. There 
are details regarding how the settings of srvrmgr are expect for output of list commands.

=head1 SEE ALSO

=over 5 

=item *

L<Moose>

=item *

L<FSA::Rules>

=item *

L<Siebel::Srvrmgr::ListParser::Output>

=item *

L<Siebel::Srvrmgr::ListParser::OutputFactory>

=item *

L<Siebel::Srvrmgr::ListParser::Buffer>

=back

=cut

no Moose;
__PACKAGE__->meta->make_immutable;

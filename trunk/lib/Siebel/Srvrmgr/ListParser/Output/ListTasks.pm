package Siebel::Srvrmgr::ListParser::Output::ListTasks;
use Moose;
use Siebel::Srvrmgr::ListParser::Output::ListTasks::Task;
use namespace::autoclean;
use feature qw(switch);

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::Output::ListTasks - subclass to parse list tasks command

=cut

extends 'Siebel::Srvrmgr::ListParser::Output';

=pod

=head1 SYNOPSIS

See L<Siebel::Srvrmgr::ListParser::Output> for examples.

=head1 DESCRIPTION

This class is still a working progress, which means it is not working as expected. Please check CAVEATS for details.

This subclass of L<Siebel::Srvrmgr::ListParser::Output> parses the output of the command C<list tasks>.

It is expected that the C<srvrmgr> program has a proper configuration for the C<list tasks> command. The configuration
can see below:

	srvrmgr> configure list tasks
        SV_NAME (31):  Server name
        CC_ALIAS (31):  Component alias
        TK_TASKID (11):  Internal task id
        TK_PID (11):  Task process id
        TK_DISP_RUNSTATE (61):  Task run state
        CC_RUNMODE (31):  Task run mode
        TK_START_TIME (21):  Task start time
        TK_END_TIME (21):  Task end time
        TK_STATUS (251):  Task-reported status
        CG_ALIAS (31):  Component group alias
        TK_PARENT_TASKNUM (11):  Parent task id
        CC_INCARN_NO (23):  Incarnation Number
        TK_LABEL (76):  Task Label
        TK_TASKTYPE (31):  Task Type
        TK_PING_TIME (11):  Last ping time for task

This output above should be the default but it will be necessary to have the configuration below
(check the difference of size for each column):

srvrmgr> configure list tasks
        SV_NAME (31):  Server name
        CC_ALIAS (31):  Component alias
        TK_TASKID (11):  Internal task id
        TK_PID (11):  Task process id
        TK_DISP_RUNSTATE (61):  Task run state
        CC_RUNMODE (31):  Task run mode
        TK_START_TIME (21):  Task start time
        TK_END_TIME (21):  Task end time
        TK_STATUS (251):  Task-reported status
        CG_ALIAS (31):  Component group alias
        TK_PARENT_TASKNUM (17):  Parent task id
        CC_INCARN_NO (23):  Incarnation Number
        TK_LABEL (76):  Task Label
        TK_TASKTYPE (31):  Task Type
        TK_PING_TIME (12):  Last ping time for task

because this class will expect to have all columns names without being truncated. This class will check those columns names and order and it 
will raise an exception if it found something different from the expected.

To enable that, execute the following commands in the C<srvrmgr> program:

	set ColumnWidth true
    
	configure list tasks show SV_NAME(31), CC_ALIAS(31), TK_TASKID(11), TK_PID(11), TK_DISP_RUNSTATE(61), CC_RUNMODE(31), TK_START_TIME(21), 
	TK_END_TIME(21), TK_STATUS(251), CG_ALIAS(31), TK_PARENT_TASKNUM(17), CC_INCARN_NO(23), TK_LABEL(76), TK_TASKTYPE(31), TK_PING_TIME(12)

Saving this configuration as a preference and loading it everytime is a good idea too.

Order of the fields is important too: everytime those fields are parsed, if they do not follow the order above an exception will be raised.

=head1 ATTRIBUTES

=head2 data_parsed

An hash reference with the data parsed from C<raw_data> attribute.

This hash reference is different from the base class since it expects that the key values to be array references with a list of instances
of Siebel::Srvrmgr::ListParser::Output::ListTasks::Task class.

=cut

has 'data_parsed' => (
    is     => 'rw',
    reader => 'get_data_parsed',
    writer => 'set_data_parsed',
    isa =>
      'HashRef[ArrayRef[Siebel::Srvrmgr::ListParser::Output::ListTasks::Task]]'
);

=head2 attribs

An array reference with the attributes of each Siebel Server listed by C<list servers> command.

=cut

has attribs => (
    is     => 'ro',
    isa    => 'ArrayRef[Str]',
    reader => 'get_attribs'
);

sub _set_attribs {

    my $self = shift;
    my $data = shift;

    my @expected_attribs = (
        'SV_NAME',           'CC_ALIAS',
        'TK_TASKID',         'TK_PID',
        'TK_DISP_RUNSTATE',  'CC_RUNMODE',
        'TK_START_TIME',     'TK_END_TIME',
        'TK_STATUS',         'CG_ALIAS',
        'TK_PARENT_TASKNUM', 'CC_INCARN_NO',
        'TK_LABEL',          'TK_TASKTYPE',
        'TK_PING_TIME'
    );

    for ( my $i = 0 ; $i <= $#expected_attribs ; $i++ ) {

        unless ( $data->[$i] eq $expected_attribs[$i] ) {

            die 'invalid attribute name recovered from output: expected '
              . $expected_attribs[$i]
              . ', got '
              . $data->[$i];

        }

    }

    $self->{attribs} = $data;

}

=pod

=head1 METHODS

=head2 parse

Parses the data stored in the C<raw_data> attribute, setting the C<parsed_lines> attribute.

The C<raw_data> will be set to a reference to an empty array at the end of the process.

=cut

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

        given ($line) {

            when (/^\-+\s/) {    # this is the header line

                my @columns = split( /\s{2}/, $line );

                my $pattern;

                foreach my $column (@columns) {

                    $pattern .= 'A'
                      . ( length($column) + 2 )
                      ; # + 2 because of the spaces after the "---" that will be trimmed

                }

                $self->_set_fields_pattern($pattern);

            }

            when ('') { }    # do nothing

# SV_NAME	CC_ALIAS	TK_TASKID	TK_PID	TK_DISP_RUNSTATE	CC_RUNMODE	TK_START_TIME	TK_END_TIME	TK_STATUS	CG_ALIAS
# TK_PARENT_TASKNUM	CC_INCARN_NO	TK_LABEL	TK_TASKTYPE	TK_PING_TIME

            when (/^SV_NAME\s.*\sTK_PING_TIME(\s+)?$/) {    # this is the header

                my @columns = split( /\s{2,}/, $line );

                $self->_set_attribs( \@columns );

            }

            default {

                my @fields_values;

                if ( defined( $self->get_fields_pattern() ) ) {

                    @fields_values = 
                      unpack( $self->get_fields_pattern(), $line );

                }
                else {

                    confess
                      "Cannot continue without having fields pattern defined";

                }

                my $columns_ref = $self->get_attribs();

                confess "Could not retrieve the name of the fields"
                  unless ( defined($columns_ref) );

                my $list_len    = scalar(@fields_values);
                my $server_name = $fields_values[0];

                $parsed_lines{$server_name} = []
                  unless ( exists( $parsed_lines{$server_name} ) );

                if (@fields_values) {

                    my %attribs = (
                        server_name => $fields_values[0],
                        comp_alias  => $fields_values[1],
                        id          => $fields_values[2],
                        pid         => $fields_values[3],
                        run_mode    => $fields_values[4],
                        comp_alias  => $fields_values[5],
                        start       => $fields_values[6],
                        end         => $fields_values[7],
                        status      => $fields_values[8],
                        cg_alias    => $fields_values[9],
                        incarn_num  => $fields_values[11],
                        type        => $fields_values[13]
                    );

                    $attribs{parent_id} = $fields_values[10]
                      if (  ( defined( $fields_values[10] ) )
                        and ( $fields_values[10] ne '' ) );
                    $attribs{label} = $fields_values[12]
                      if ( defined( $fields_values[12] ) );
                    $attribs{last_ping_time} = $fields_values[15]
                      if ( defined( $fields_values[15] ) );

                    push(
                        @{ $parsed_lines{$server_name} },
                        Siebel::Srvrmgr::ListParser::Output::ListTasks::Task
                          ->new(
                            \%attribs
                          )
                    );

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

=pod

=head1 CAVEATS

Unfornately, to the present moment this class is not working as expected.

Even though a L<Siebel::Srvrmgr::ListParser> instance is capable of identifying a C<list tasks> command output, this class is not being able to properly
parse the output from the command.

The problem is that the output is not following the expected fixed width as setup with the C<configure list tasks show...> command: with that, the output
width is resized depending on the content of each column and thus impossible to predict how to parse it correctly. The result is messy since the output
is not fixed sized neither separated by a character and the content (and width of it) cannot be predicted.

=head1 SEE ALSO

=over 2

=item *

L<Siebel::Srvrmgr::ListParser::Output>

=item *

L<Moose>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.org<E<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.org<E<gt>

This file is part of Siebel Monitoring Tools.

Siebel Monitoring Tools is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Siebel Monitoring Tools is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Siebel Monitoring Tools.  If not, see <http://www.gnu.org/licenses/>.

=cut

__PACKAGE__->meta->make_immutable;
1;

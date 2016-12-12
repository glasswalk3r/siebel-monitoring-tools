package Siebel::Srvrmgr::Daemon::Offline;

=pod

=head1 NAME

Siebel::Srvrmgr::Daemon::Offline - subclass that reads srvrmgr output from a file

=head1 SYNOPSIS

    use Siebel::Srvrmgr::Daemon::Offline;
    my $daemon = Siebel::Srvrmgr::Daemon::Offline->new(
        {
            output_file => File::Spec->catfile('some', 'location', 'to', 'srvrmgr', 'output', 'file')
        }
    );
    $daemon->run();


=head1 DESCRIPTION

This is a subclass of L<Siebel::Srvrmgr::Daemon> used to execute the C<srvrmgr> program in batch mode.

=cut

use Moose 2.0401;
use namespace::autoclean 0.13;
use Siebel::Srvrmgr::Daemon::ActionFactory;
use Carp qw(longmess);
use File::Temp 0.2304 qw(:POSIX);
use Data::Dumper;
use Siebel::Srvrmgr;
use File::BOM 0.14 qw(:all);
use Try::Tiny 0.27;
# VERSION

extends 'Siebel::Srvrmgr::Daemon';

=pod

=head1 ATTRIBUTES

=head2 output_file

A string representing the full pathname to the file that contains all output from srvrmgr program to be parsed.

=cut

has output_file => (
    isa    => 'Str',
    is     => 'ro',
    reader => 'get_output_file',
    writer => '_set_output_file'
);

=head2 run

This method will try to connect to a Siebel Enterprise through C<srvrmgr> program (if it is the first time the method is invoke) or reuse an already open
connection to submit the commands and respective actions defined during object creation. The path to the program is check and if it does not exists the 
method will issue an warning message and immediatly returns false.

Those operations will be executed in a loop as long the C<check> method from the class L<Siebel::Srvrmgr::Daemon::Condition> returns true.

Beware that Siebel::Srvrmgr::Daemon uses a B<single instance> of a L<Siebel::Srvrmgr::ListParser> class to process the parsing requests, so it is not possible
to execute L<Siebel::Srvrmgr::Daemon::Command> instances in parallel.

=cut

override 'run' => sub {
    my $self = shift;
    super();
    my $logger = Siebel::Srvrmgr->gimme_logger( blessed($self) );
    $logger->info('Starting run method');
    my $parser = $self->create_parser();
    my $in;

    try { 
        open_bom( $in, $self->get_output_file(), ':utf8' );
    } catch  {
        $logger->logdie(
            'Cannot read ' . $self->get_output_file() . ': ' . $_ );
    };

# :TODO:22-09-2014 01:32:45:: this might be dangerous if the output is too large
    my @input_buffer = <$in>;
    close($in);

    if ( scalar(@input_buffer) >= 1 ) {

# since everything is read from a file, there is not way to identify if is a error from the file handler,
# so we will "turn off" warning checking
        $self->_check_error( \@input_buffer, 0 );
        $self->normalize_eol( \@input_buffer );

# since we should have all output, we parse everything first to call each action after
        $parser->parse( \@input_buffer );

        if ( $parser->has_tree() ) {
            if ( $logger->is_debug() ) {
                $logger->debug( 'Total number of parsed items = '
                      . $parser->count_parsed() );
            }

            $logger->logdie(
'Number of parsed nodes is different from the number of submitted commands'
            ) unless ( defined($total) );

            my $parsed_ref = $parser->get_parsed_tree();
            $parser->clear_parsed_tree();

            for ( my $i = 0 ; $i < $total ; $i++ ) {

                my $cmd = ( @{ $self->get_commands() } )[$i];

                my $action = Siebel::Srvrmgr::Daemon::ActionFactory->create(
                    $cmd->get_action(),
                    {
                        parser => $parser,
                        params => $cmd->get_params()
                    }
                );

                $action->do_parsed( $parsed_ref->[$i] );

            }

        }
        else {

            $logger->logdie('Parser did not have a parsed tree after parsing');

        }

    }
    else {

        $logger->debug('buffer is empty');

    }

    $self->_set_child_runs( $self->get_child_runs() + 1 );
    $logger->debug( 'child_runs = ' . $self->get_child_runs() )
      if ( $logger->is_debug() );
    $logger->info('Exiting run sub');

    return 1;

};

override _my_cleanup => sub {
    my $self = shift;
    return $self->_del_input_file() && $self->_del_output_file();
};

sub _del_file {

    my $self     = shift;
    my $filename = shift;

    if ( defined($filename) ) {
        if ( -e $filename ) {

            my $ret = unlink $filename;

            if ($ret) {

                return 1;

            }
            else {

                warn "Could not remove $filename: $!";
                return 0;

            }

        }
        else {

            warn "File $filename does not exists";
            return 0;

        }
    }

}

sub _del_input_file {

    my $self = shift;

    return $self->_del_file( $self->get_input_file() );

}

sub _del_output_file {

    my $self = shift;

    return $self->_del_file( $self->get_output_file() );

}

override _setup_commands => sub {

    my $self = shift;

    super();

    my ( $fh, $input_file ) = tmpnam();

    foreach my $cmd ( @{ $self->get_commands() } ) {

        print $fh $cmd->get_command(), "\n";

    }

    close($fh);

    $self->_set_input_file($input_file);

};

override _define_params => sub {

    my $self = shift;

    my $params_ref = super();

    $self->_set_output_file( scalar( tmpnam() ) );

    push(
        @{$params_ref},
        '/b', '/i', $self->get_input_file(),
        '/o', $self->get_output_file()
    );

# :TODO:10/06/2015 07:09:25 PM:: this will expose the parameter when list the running processes
    push( @{$params_ref}, '/p', $self->get_password() );

    return $params_ref;

};

=pod

=head1 SEE ALSO

=over

=item *

L<Moose>

=item *

L<Siebel::Srvrmgr::Daemon::Command>

=item *

L<Siebel::Srvrmgr::Daemon::ActionFactory>

=item *

L<Siebel::Srvrmgr::ListParser>

=item *

L<Siebel::Srvrmgr::Regexes>

=item *

L<POSIX>

=item *

L<Siebel::Srvrmgr::Daemon::Command>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>.

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
along with Siebel Monitoring Tools.  If not, see L<http://www.gnu.org/licenses/>.

=cut

__PACKAGE__->meta->make_immutable;

1;


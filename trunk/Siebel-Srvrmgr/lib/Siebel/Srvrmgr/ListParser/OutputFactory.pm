package Siebel::Srvrmgr::ListParser::OutputFactory;

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::OutputFactory - abstract factory class to create Siebel::Srvrmgr::ListParser::Output objects

=cut

use warnings;
use strict;
use MooseX::AbstractFactory;
use Carp;
use Hash::Util qw(lock_hash);

=pod

=head1 SYNOPSIS

	use Siebel::Srvrmgr::ListParser::OutputFactory;

    my $output = Siebel::Srvrmgr::ListParser::OutputFactory->create(
        $type,
        {
            data_type => $type,
            raw_data  => \@data,
            cmd_line  => 'list something'
        }
    );

	if (Siebel::Srvrmgr::ListParser::OutputFactory->can_create('weirdo')) ? print "can\n" : print "cannot\n";

=head1 DESCRIPTION

This is an abstract factory class to create instances of subclass of L<Siebel::Srvrmgr::ListParser::Output> superclass.

It has the mapping between the types parsed by L<Siebel::Srvrmgr::ListParser> class to the respective class of output. See
C<Siebel::Srvrmgr::ListParser::OutputFactory::table_mapping> for the mapping between types and classes.

=head1 METHODS

All methods below are class methods.

=head2 create

Returns the instance of the class defined by the type given as parameter. Expects two parameters: an string with the type
of output and an hash reference with the parameters expected by the C<new> method of L<Siebel::Srvrmgr::ListParser::Output>.

=head2 can_create

Expects a string as the output type.

Returns true if there is a mapping between the given type and a subclass of L<Siebel::Srvrmgr::ListParser::Output>;
otherwise it returns false;

=head2 get_mapping

Returns an hash reference with the mapping between the parsed types and subclasses of L<Siebel::Srvrmgr::ListParser::Ouput>.

=head1 SEE ALSO

=over

=item *

L<MooseX::AbstractFactory>

=item *

L<Siebel::Srvrmgr::ListParser::Output>

=item *

L<Siebel::Srvrmgr::ListParser>

=back

=cut

my %table_mapping = (
    'list_comp'        => 'Tabular::ListComp',
    'list_params'      => 'Tabular::ListParams',
    'list_comp_def'    => 'Tabular::ListCompDef',
    'greetings'        => 'Enterprise',
    'list_comp_types'  => 'Tabular::ListCompTypes',
    'load_preferences' => 'LoadPreferences',
    'list_tasks'       => 'Tabular::ListTasks',
    'list_servers'     => 'Tabular::ListServers'
);

lock_hash(%table_mapping);

sub get_mapping {

    my %copy = %table_mapping;

    return \%copy;

}

sub can_create {

    my $class = shift;
    my $type  = shift;

    return ( exists( $table_mapping{$type} ) );

}

sub build {

	my $class = shift;
    my $last_cmd_type = shift;
    my $object_data   = shift;    # hash ref

    confess 'object data is required' unless ( defined($object_data) );

    if ( $table_mapping{$last_cmd_type} =~ /^Tabular/ ) {

        my $field_del = shift;

        if ( defined($field_del) ) {

            $object_data->{col_sep}        = $field_del;
            $object_data->{structure_type} = 'delimited';
        }
        else {

            $object_data->{structure_type} = 'fixed';

        }

    }

    $class->create( $last_cmd_type, $object_data );

}

implementation_class_via sub {

    my $last_cmd_type = shift;

    if ( exists( $table_mapping{$last_cmd_type} ) ) {

        return 'Siebel::Srvrmgr::ListParser::Output::'
          . $table_mapping{$last_cmd_type};

    }
    else {

        confess "Cannot defined a class for command '$last_cmd_type'";

    }

};

=pod

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

1;

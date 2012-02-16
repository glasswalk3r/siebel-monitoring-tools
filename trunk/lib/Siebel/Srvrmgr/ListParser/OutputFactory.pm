package Siebel::Srvrmgr::ListParser::OutputFactory;

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::OutputFactory - abstract factory class to create Siebel::Srvrmgr::ListParser::Output objects

=cut

use warnings;
use strict;
use MooseX::AbstractFactory;

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

=head1 DESCRIPTION

This is an abstract factory class to create instances of subclass of L<Siebel::Srvrmgr::ListParser::Output> superclass.

It has the mapping between the types parsed by L<Siebel::Srvrmgr::ListParser> class to the respective class of output. See
C<Siebel::Srvrmgr::ListParser::OutputFactory::table_mapping> for the mapping between types and classes.

=head1 METHODS

=head2 create

Returns the instance of the class defined by the type given as parameter. Expects two parameters: an string with the type
of output and an hash reference with the parameters expected by the C<new> method of L<Siebel::Srvrmgr::ListParser::Output>.

=head2 can_create

Expects a string as the output type.

Returns true if there is a mapping between the given type and a subclass of L<Siebel::Srvrmgr::ListParser::Output>;
otherwise it returns false;

=head1 SEE ALSO

=over 3

=item *

L<MooseX::AbstractFactory>

=item *

L<Siebel::Srvrmgr::ListParser::Output>

=item *

L<Siebel::Srvrmgr::ListParser>

=back

=cut

our %table_mapping = (
    'list_comp'        => 'ListComp',
    'list_params'      => 'ListParams',
    'list_comp_def'    => 'ListCompDef',
    'greetings'        => 'Greetings',
    'list_comp_types'  => 'ListCompTypes',
    'load_preferences' => 'LoadPreferences'
);

sub can_create {

    my $class = shift;
    my $type  = shift;

    return ( exists( $table_mapping{$type} ) );

}

implementation_class_via sub {

    my $last_cmd_type = shift;
    my $object_data   = shift;    # hash ref

    if ( exists( $table_mapping{$last_cmd_type} ) ) {

        return 'Siebel::Srvrmgr::ListParser::Output::'
          . $table_mapping{$last_cmd_type};

    }
    else {

        die "Cannot defined a class for command $last_cmd_type";

    }

};

1;

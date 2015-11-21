package Siebel::Srvrmgr::ListParser::Output::ListComp::Server;

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::Output::ListComp::Server - class to parse and aggregate information about servers and their components

=cut

use Moose 2.0401;
use MooseX::Storage 0.33;
use namespace::autoclean 0.13;
use Siebel::Srvrmgr::ListParser::Output::ListComp::Comp;
use Carp;

=pod

=head1 SYNOPSIS

    use Siebel::Srvrmgr::ListParser::Output::ListComp::Server;

    Siebel::Srvrmgr::ListParser::Output::ListComp::Server->new(
        {
            name => $servername,
            data => $list_comp_data->{$servername}
        }
    );

=head1 DESCRIPTION

This class represents a server in a Siebel Enterprise and it's related components. This class is meant to be instantied by a method from 
L<Siebel::Srvrmgr::ListParser::Output::ListComp> object.

This class inherits from L<MooseX::Storage>, using the L<MooseX::Storage::IO::StorableFile> trait. See the methods C<load> and C<store> for details.

=cut

with Storage( io => 'StorableFile' );

=head1 ATTRIBUTES

=head2 data

An hash reference with the original data used to create the object.

=cut

has data =>
  ( isa => 'HashRef', is => 'ro', required => 1, reader => 'get_data' );

=pod

=head2 name

A string with the name of the server.

=cut

has name => ( isa => 'Str', is => 'ro', required => 1, reader => 'get_name' );

=pod

=head2 comp_attribs

A array reference with the components attributes names

=cut

has 'comp_attribs' => (
    is     => 'ro',
    isa    => 'ArrayRef',
    reader => 'get_comp_attribs'
);

=pod

=head1 METHODS

=head2 get_data

Returns an hash reference from the C<data> attribute.

=head2 get_name

Returns an string from the C<name> attribute.

=head2 load

Load the object data and methods from a previously serialized object.

Expects as a parameter a string the filename (or complete path).

=head2 store

Stores the object data and methods in a serialized file.

Expects as a parameter a string the filename (or complete path).

=head2 get_comps

Returns an array reference with all components aliases available in the server.

=cut

sub get_comps {

    my $self = shift;

    return [ keys( %{ $self->get_data() } ) ];

}

=pod

=head2 get_comp

Expects an string with the component alias.

Returns a L<Siebel::Srvrmgr::ListParser::Output::ListComp::Comp> object if the component exists in the server, otherwise returns C<undef>.

=cut

sub get_comp {

    my $self  = shift;
    my $alias = shift;

    if ( exists( $self->get_data()->{$alias} ) ) {

        my $data_ref = $self->get_data->{$alias};
        return Siebel::Srvrmgr::ListParser::Output::ListComp::Comp->new(
            {
                alias          => $alias,
                name           => $data_ref->{CC_NAME},
                ct_alias       => $data_ref->{CT_ALIAS},
                cg_alias       => $data_ref->{CG_ALIAS},
                run_mode       => $data_ref->{CC_RUNMODE},
                disp_run_state => $data_ref->{CP_DISP_RUN_STATE},
                num_run_tasks  => $data_ref->{CP_NUM_RUN_TASKS},
                max_tasks      => $data_ref->{CP_MAX_TASKS},
                desc_text      => $data_ref->{CC_DESC_TEXT},
                start_datetime => $data_ref->{CP_START_TIME},
                end_datetime   => $data_ref->{CP_END_TIME},
                status         => $data_ref->{CP_STATUS},

# :WORKAROUND:03-02-2015 03:32:57:: in most cases the value from Server Manager is undefined
                actv_mts_procs => $data_ref->{CP_ACTV_MTS_PROCS} || 0,
                incarn_no      => $data_ref->{CC_INCARN_NO}      || 0,
                max_mts_procs  => $data_ref->{CP_MAX_MTS_PROCS}  || 0,

            }
        );

    }
    else {

        return undef;

    }

}

=pod

=head1 SEE ALSO

=over

=item *

L<Moose>

=item *

L<MooseX::Storage>

=item *

L<namespace::autoclean>

=item *

L<Siebel::Srvrmgr::ListParser::Output::ListComp::Comp>

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

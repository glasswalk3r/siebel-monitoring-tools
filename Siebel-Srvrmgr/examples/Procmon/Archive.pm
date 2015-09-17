package Archive;

use Moose;
use Set::Tiny;
use DB_File;

has 'dbm_path' =>
  ( is => 'ro', isa => 'Str', reader => 'get_dbm_path', required => 1 );

with 'Siebel::Srvrmgr::OS::Enterprise::Archive';

sub BUILD {

    my $self = shift;
    my %log_entries;
    tie %log_entries, 'DB_File', $self->get_dbm_path();

    $self->set_archive( \%log_entries );

    $self->_init_last_line();

}

sub reset {

    my $self = shift;
    %{ $self->get_archive() } = ();

}

sub has_digest {

    my $self = shift;
    return exists( $self->get_archive()->{DIGEST} );

}

sub get_digest {

    shift->get_archive()->{DIGEST};

}

sub set_digest {

    my ( $self, $value ) = @_;
    $self->get_archive()->{DIGEST} = $value;

}

sub add {

    my ( $self, $pid, $comp_alias ) = @_;
    $self->get_archive()->{$pid} = $comp_alias;

}

sub remove {

    my ( $self, $pid ) = @_;
    my $archive = $self->get_archive();
    delete( $archive->{$pid} );

}

sub get_alias {

    my ( $self, $pid ) = @_;
    my $archive = $self->get_archive();

    if ( exists( $archive->{$pid} ) ) {

        return $archive->{$pid};

    }
    else {

        return undef;

    }

}

sub get_set {

    my $self = shift;

    my $archive = $self->get_archive();

    return Set::Tiny->new( keys( %{$archive} ) );

}

__PACKAGE__->meta->make_immutable;

package Siebel::Lbconfig::Daemon::Action::ListServers;

# VERSION
use Moose 2.0401;
use namespace::autoclean 0.13;
use Siebel::Srvrmgr::Daemon::ActionStash;
use Carp;
use Scalar::Util qw(blessed);

extends 'Siebel::Srvrmgr::Daemon::Action';

override '_build_exp_output' => sub {
    return 'Siebel::Srvrmgr::ListParser::Output::Tabular::ListServers';
};

override 'do_parsed' => sub {
    my ( $self, $obj ) = @_;
    my %servers;

    if ( $obj->isa( $self->get_exp_output ) ) {
        my $iter = $obj->get_servers_iter;

        while ( my $server = $iter->() ) {
            $servers{ $server->get_name } = $server->get_id;
        }

        my $stash = Siebel::Srvrmgr::Daemon::ActionStash->instance();
        $stash->push_stash( \%servers );
        return 1;

    }
    else {
        confess('object received ISA not '
              . $self->get_exp_output() . ' but '
              . blessed($obj) );
    }

};

__PACKAGE__->meta->make_immutable;

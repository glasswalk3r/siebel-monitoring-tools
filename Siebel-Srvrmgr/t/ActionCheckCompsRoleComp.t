use lib 't';
use Test::Siebel::Srvrmgr::Daemon::Action::CheckComps::Component;
use Test::Most tests => 8;
use Test::Moose;

my $comp = Test::Siebel::Srvrmgr::Daemon::Action::CheckComps::Component->new(
    {
        alias          => 'SynchMgr',
        description    => 'foobar',
        componentGroup => 'foobar',
        OKStatus       => 'Running',
        criticality    => 5
    }
);

does_ok( $comp, 'Siebel::Srvrmgr::Daemon::Action::CheckComps::Component' );

foreach (qw(alias description componentGroup OKStatus criticality)) {

    has_attribute_ok( $comp, $_, "$comp has the attribute $_" );

}

dies_ok(
    sub {
        my $comp =
          Test::Siebel::Srvrmgr::Daemon::Action::CheckComps::Component->new();
    },
    'constructor cannot accept missing attributes declaration'
);

dies_ok(
    sub {
        my $comp =
          Test::Siebel::Srvrmgr::Daemon::Action::CheckComps::Component->new(
            {
                alias          => '',
                description    => 'foo',
                componentGroup => 'foo',
                OKStatus       => 'foo',
                criticality    => '1'
            }
          );
    },
    'constructor cannot accept string based attributes without value'
);

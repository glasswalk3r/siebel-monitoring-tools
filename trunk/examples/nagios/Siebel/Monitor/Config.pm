package Siebel::Monitor::Config;
use XML::Rabbit::Root;

add_xpath_namespace 'ns1' => 'http://foobar.org';

has_xpath_value 'server' =>
  '/ns1:siebelMonitor/ns1:connection/ns1:siebelServer';
has_xpath_value 'gateway' =>
  '/ns1:siebelMonitor/ns1:connection/ns1:siebelGateway';
has_xpath_value 'enterprise' =>
  '/ns1:siebelMonitor/ns1:connection/ns1:siebelEnterprise';
has_xpath_value 'srvrmgrPath' =>
  '/ns1:siebelMonitor/ns1:connection/ns1:srvrmgrPath';
has_xpath_value 'srvrmgrBin' =>
  '/ns1:siebelMonitor/ns1:connection/ns1:srvrmgrExec';
has_xpath_value 'user'     => '/ns1:siebelMonitor/ns1:connection/ns1:user';
has_xpath_value 'password' => '/ns1:siebelMonitor/ns1:connection/ns1:password';

has_xpath_object_list 'servers' =>
  '/ns1:siebelMonitor/ns1:servers/ns1:server' => 'Siebel::Monitor::Server';

# set components status if undefined
sub BUILD {

    my $self = shift;

    foreach my $server ( @{ $self->servers() } ) {

        my %default_status;

        foreach my $compGroup ( @{ $server->componentGroups() } ) {

            $default_status{ $compGroup->name() } = $compGroup->OKStatus();

        }

        foreach my $comp ( @{ $server->components() } ) {

            if ( $comp->OKStatus() eq '' ) {

                if ( ( exists( $default_status{ $comp->componentGroup() } ) )
                    and defined( $default_status{ $comp->componentGroup() } ) )
                {

                    $comp->_set_ok_status(
                        $default_status{ $comp->componentGroup() } );

                }
                else {

                    die 'Undefined value for '
                      . $comp->name() . '->'
                      . $comp->componentGroup();

                }

            }

        }

    }

}

finalize_class();

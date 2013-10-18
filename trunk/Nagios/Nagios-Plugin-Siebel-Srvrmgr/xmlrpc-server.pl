#!/usr/bin/perl
use warnings;
use strict;
use RPC::XML::Server;
use RPC::XML::Procedure;
use Nagios::Cache::Server;
use TryCatch;

#    COPYRIGHT AND LICENCE
#
#    This software is copyright (c) 2013 of Alceu Rodrigues de Freitas Junior, arfreitas@cpan.org
#
#    This file is part of Siebel Monitoring Tools.
#
#    Siebel Monitoring Tools is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    Siebel Monitoring Tools is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with Siebel Monitoring Tools.  If not, see <http://www.gnu.org/licenses/>.

print 'Starting Nagios::Cache::Server...';

my $daemon = Nagios::Cache::Server->new(
    {
        config_file   => 'conf.yml',
        cache_expires => 120
    }
);

print "done\n";

print 'Starting RPC::XML::Server...';
my $rpc_server = RPC::XML::Server->new(
    port       => 80,
    no_default => 1,

# :TODO      :07/08/2013 15:17:43:: must review error codes as defined by XML-RPC specification
    fault_table => {
        'Nagios::Memcached::Exception::InvalidCompAlias' =>
          [ 600 => 'Error: %s' ],
        'Nagios::Memcached::Exception::NotFoundCompAlias' =>
          [ 601 => 'Error: %s' ],
        'Nagios::Memcached::Exception::InvalidServer' => [ 602 => 'Error: %s' ],
        'Nagios::Memcached::Exception::InvalidSrvrmgrData' =>
          [ 603 => 'Error: %s' ],
    }
);
$rpc_server->add_method(
    RPC::XML::Method->new(
        {
            name      => 'siebel.srvrmgr.xmlrpc.checkComponent',
            code      => \&check_comp,
            signature => ['struct string'],
            help =>
'Expects a component alias as parameter, returning a boolean indicating if the component is ok (true) or not (false)',
            version => 1,
            hidden  => 0
        }
    )
);
say 'done';
say 'Ready to accept requests';

$rpc_server->server_loop();

sub check_comp {

    my $self       = shift;
    my $comp_alias = shift;

    my $comp;

    try {

        $comp = $daemon->check_comp($comp_alias);

# :TODO      :24/07/2013 13:06:35:: probably could do this automatically with Moose meta
        return RPC::XML::struct->new(
            {
                name => RPC::XML::string->new( $comp->get_alias() ),
                description =>
                  RPC::XML::string->new( $comp->get_description() ),
                componentGroup =>
                  RPC::XML::string->new( $comp->get_componentGroup() ),
                OKStatus    => RPC::XML::string->new( $comp->get_OKStatus() ),
                criticality => RPC::XML::int->new( $comp->get_criticality() ),
                isOK        => RPC::XML::boolean->new( $comp->get_isOK() )
            }
        );

    }

# :TODO      :31/07/2013 13:11:23:: some exceptions should terminate server execution
    catch($e) {

        if ( ref($e) ) {

            die $self->server_fault( $e->get_name(), $e->get_msg() );

        }
        else {

            die $self->server_fault( 'Unknown exception', $e );

        }

      }

}

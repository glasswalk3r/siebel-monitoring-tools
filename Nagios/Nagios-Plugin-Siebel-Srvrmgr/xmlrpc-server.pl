#!/usr/bin/perl
use warnings;
use strict;
use RPC::XML::Server;
use RPC::XML::Procedure;
use Nagios::Plugin::Siebel::Srvrmgr::Daemon::Cache;
use TryCatch;
use Getopt::Std;

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

my %opts;

getopts( 'c:x:p:', \%opts );

die 'command line parameter -c must have an value'
  unless ( ( exists( $opts{c} ) ) and ( defined( $opts{c} ) ) );

$opts{x} = 120
  unless ( ( exists( $opts{x} ) ) and ( defined( $opts{x} ) ) and ($opts{x} =~ /^\d+$/));

$opts{p} = 0
  unless ( ( exists( $opts{p} ) ) and ( defined( $opts{p} ) ) and ($opts{p} == 1) );

print 'Starting Nagios::Cache::Server...';

# :TODO:20-10-2013:arfreitas: make daemon type configurable by command line option
my $daemon = Nagios::Plugin::Siebel::Srvrmgr::Daemon::Cache->new(
    {
        config_file   => $opts{c}, 
        cache_expires => $opts{x}, 
		use_perl => $opts{p}
    }
);

print "done\n";

print 'Starting RPC::XML::Server...';
my $rpc_server = RPC::XML::Server->new(
    port       => 8080,
    no_default => 1,

# :TODO      :07/08/2013 15:17:43:: must review error codes as defined by XML-RPC specification
    fault_table => {
        'Nagios::Plugin::Siebel::Srvrmgr::Exception::InvalidCompAlias' =>
          [ 600 => 'Error: %s' ],
        'Nagios::Plugin::Siebel::Srvrmgr::Exception::NotFoundCompAlias' =>
          [ 601 => 'Error: %s' ],
        'Nagios::Plugin::Siebel::Srvrmgr::Exception::InvalidServer' =>
          [ 602 => 'Error: %s' ],
        'Nagios::Plugin::Siebel::Srvrmgr::Exception::InvalidSrvrmgrData' =>
          [ 603 => 'Error: %s' ],
    }
);
$rpc_server->add_method(
    RPC::XML::Method->new(
        {
            name      => 'siebel.srvrmgr.xmlrpc.checkComponent',
            code      => \&check_comp,
            signature => ['struct string string'],
            help =>
'Expects a component alias as parameter, returning a boolean indicating if the component is ok (true) or not (false)',
            version => 1,
            hidden  => 0
        }
    )
);
print "done\n";
print "Ready to accept requests\n";

$rpc_server->server_loop();

sub check_comp {

    my $self          = shift;
	my $siebel_server = shift;
    my $comp_alias    = shift;

    my $comp;

    try {

        $comp = $daemon->check_comp($siebel_server, $comp_alias);

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
    catch($e) {

        if ( ref($e) ) {

            die $self->server_fault( $e->get_name(), $e->get_msg() );

        }
        else {

            die $self->server_fault( 'Unknown exception', $e );

        }

    }

}

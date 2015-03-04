use warnings;
use strict;
use Siebel::Srvrmgr::OS::Unix;
use Test::More;
use Test::Moose qw(has_attribute_ok);

use Siebel::Srvrmgr::OS::Unix;
my $procs = Siebel::Srvrmgr::OS::Unix->new(
    {
        enterprise_log => '/somepath/server/filename.log',
        cmd_regex      => '',
        parent_regex   => ''
    }
);

my @attribs =
  (
    qw(enterprise_log parent_regex cmd_regex mem_limit cpu_limit limits_callback)
  );

plan tests => scalar(@attribs);

foreach my $attrib (@attribs) {

    has_attribute_ok( $procs, $attrib );

}

my @methods = (
    'get_ent_log',      'set_ent_log',
    'get_parent_regex', 'set_parent_regex',
    'get_cmd',          'set_cmd',
    'get_mem_limit', 'set_mem_limit'
);

can_ok( $procs, @methods );

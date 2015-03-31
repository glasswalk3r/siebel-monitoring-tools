package Siebel::Srvrmgr::ListParser::Output::ListServers::Server;

use Moose;
use namespace::autoclean;
use Siebel::Srvrmgr::Types;
use MooseX::FollowPBP;

with 'Siebel::Srvrmgr::ListParser::Output::Duration';
with 'Siebel::Srvrmgr::ListParser::Output::ToString';

#        SBLSRVR_NAME (31):  Siebel Server name
has 'name' => ( is => 'ro', isa => 'NotNullStr', 'required' => 1 );

#        SBLSRVR_GROUP_NAME (46):  Siebel server Group name
has 'group' => ( is => 'ro', isa => 'Str' );

#        HOST_NAME (31):  Host name of server machine
has 'host' => (is => 'ro', isa => 'NotNullStr', required => 1);
#        INSTALL_DIR (256):  Server install directory name
has 'install_dir' => (is => 'ro', isa => 'Str');
#        SBLMGR_PID (16):  O/S process/thread ID of Siebel Server Manager
has 'pid' => (is => 'ro', isa => 'Int');
#        SV_DISP_STATE (61):  Server state (started,  stopped,  etc.)
has 'disp_state' => (is => 'ro', isa => 'Str', required => 1);
#        SBLSRVR_STATE (31):  Server state internal (started,  stopped,  etc.)
has 'state' => (is => 'ro', isa => 'Str', required => 1);
#        START_TIME (21):  Time the server was started
#        END_TIME (21):  Time the server was stopped
#        SBLSRVR_STATUS (101):  Server status
has 'status' => (is => 'ro', isa => 'Str', required => 1);

sub BUILD {

	my $self = shift;

	$self->fix_endtime;

}

__PACKAGE__->meta->make_immutable;

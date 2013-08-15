use lib 't';
use Test::Siebel::Srvrmgr::Daemon;

Test::Class->runtests;

sleep(5);
unlink $ENV{SIEBEL_SRVRMGR_LOG_DEL}
  or warn "Cannot remove $ENV{SIEBEL_SRVRMGR_LOG_DEL}: $!";
$ENV{SIEBEL_SRVRMGR_LOG_DEL} = undef;

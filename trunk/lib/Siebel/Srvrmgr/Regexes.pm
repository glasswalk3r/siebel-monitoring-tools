package Siebel::Srvrmgr::Regexes;

use constant SRVRMGR_PROMPT => qr/^srvrmgr(\:\w+)?>\s$/;

#srvrmgr> File: d:\\sea752\\client\\bin\\.Siebel_svrmgr.pref'
use constant LOAD_PREF_RESP => qr/^srvrmgr(\:\w+)?>\sFile\:\s.*\.pref$/;
use constant LOAD_PREF_CMD  => qr/^srvrmgr(\:\w+)?>\sload preferences$/;
use constant CONN_GREET => qr/^Siebel\sEnterprise\sApplications\sSiebel\sServer\sManager\,\sVersion*/;

1;

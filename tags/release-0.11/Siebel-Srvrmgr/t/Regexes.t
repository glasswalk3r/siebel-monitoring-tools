use warnings;
use strict;
use Test::More tests => 5;

BEGIN {
    use_ok( 'Siebel::Srvrmgr::Regexes',
        qw(SRVRMGR_PROMPT LOAD_PREF_RESP LOAD_PREF_CMD CONN_GREET) );
}

my $prompt = 'srvrmgr:SUsrvr> ';

like( $prompt, SRVRMGR_PROMPT, "SRVRMGR_PROMPT matches '$prompt'" );

my $load_pref_resp = 'File: C:\Siebel\8.0\web client\BIN\.Siebel_svrmgr.pref';

like( $load_pref_resp, LOAD_PREF_RESP,
    "LOAD_PREF_RESP matches '$load_pref_resp'" );

my $load_pref_cmd = 'srvrmgr:SUsrvr> load preferences';

like( $load_pref_cmd, LOAD_PREF_CMD, "LOAD_PREF_CMD matches '$load_pref_cmd'" );

my $hello =
'Siebel Enterprise Applications Siebel Server Manager, Version 8.0.0.7 [20426] LANG_INDEPENDENT';

like( $hello, CONN_GREET, "CONN_GREET matches '$hello'" );


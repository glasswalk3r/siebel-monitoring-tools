package Test::Siebel::Srvrmgr::ListParser::Output::Greetings;

use Test::Most;
use base 'Test::Siebel::Srvrmgr::ListParser::Output';
use Test::Moose 'has_attribute_ok';

sub class_attributes : Tests(+6) {

    my $test = shift;

    $test->SUPER::class_attributes();

    my @attributes = (
        'version',         'patch',
        'copyright',       'total_servers',
        'total_connected', 'help'
    );

    foreach my $attrib (@attributes) {

        has_attribute_ok( $test->get_output(), $attrib );

    }

}

sub get_data_type {

	return 'greetings';

}

sub class_methods : Tests(+6) {

    my $test = shift;

    $test->SUPER::class_methods();

    can_ok( $test->get_output(),
        qw(get_version get_patch get_copyright get_total_servers get_total_conn get_help)
    );

    is( $test->get_output()->get_version(),
        '7.5.3', 'can get the correct version' );
    is( $test->get_output()->get_patch(), '16157',
        'can get the correct patch' );
    is( ref( $test->get_output()->get_copyright() ),
        'ARRAY', 'can get the correct copyright' );
    is( $test->get_output()->get_total_servers(),
        1, 'can get the correct number of configured servers' );

    is( $test->get_output()->get_total_conn(),
        1, 'can get the correct number of available servers' );

}

1;

__DATA__
Siebel Enterprise Applications Siebel Server Manager, Version 7.5.3 [16157] LANG_INDEPENDENT 
Copyright (c) 2001 Siebel Systems, Inc.  All rights reserved.

This software is the property of Siebel Systems, Inc., 2207 Bridgepointe Parkway,
San Mateo, CA 94404.

User agrees that any use of this software is governed by: (1) the applicable
user limitations and other terms and conditions of the license agreement which
has been entered into with Siebel Systems or its authorized distributors; and
(2) the proprietary and restricted rights notices included in this software.

WARNING: THIS COMPUTER PROGRAM IS PROTECTED BY U.S. AND INTERNATIONAL LAW.
UNAUTHORIZED REPRODUCTION, DISTRIBUTION OR USE OF THIS PROGRAM, OR ANY PORTION
OF IT, MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES, AND WILL BE
PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.

If you have received this software in error, please notify Siebel Systems
immediately at (650) 295-5000.

Type "help" for list of commands, "help <topic>" for detailed help

Connected to 1 server(s) out of a total of 1 server(s) in the enterprise

srvrmgr:>

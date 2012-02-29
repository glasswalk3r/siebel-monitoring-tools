package Test::Greetings;

use Test::Most;
use base 'Test::Class';

sub class { 'Siebel::Srvrmgr::ListParser::Output::Greetings' }

sub startup : Tests(startup => 1) {
    my $test = shift;
    use_ok $test->class;
}

sub constructor : Tests(9) {

    my $test  = shift;
    my $class = $test->class;

    can_ok( $class, 'new' );

    #extended method tests
    can_ok( $class,
        qw(get_version get_patch get_copyright get_total_servers get_total_conn)
    );

    my @data = <Test::Greetings::DATA>;
    close(Test::Greetings::DATA);

    ok(
        my $hello = $class->new(
            { data_type => 'greetings', raw_data => \@data, cmd_line => '' }
        ),
        '... and the constructor should succeed'
    );

    isa_ok( $hello, $class, '... and the object it returns' );
    is( $hello->get_version(), '7.5.3', 'can get the correct version' );
    is( $hello->get_patch(),   '16157', 'can get the correct patch' );
    is(
        $hello->get_copyright(),
        'Copyright (c) 2001 Siebel Systems, Inc.  All rights reserved.',
        'can get the correct copyright'
    );
    is( $hello->get_total_servers(),
        1, 'can get the correct number of configured servers' );

    is( $hello->get_total_conn(),
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

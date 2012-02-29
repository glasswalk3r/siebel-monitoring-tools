package Test::Buffer;

use Test::Most;
use base 'Test::Class';

sub class { 'Siebel::Srvrmgr::ListParser::Buffer' }

sub startup : Tests(startup => 1) {
    my $test = shift;
    use_ok $test->class;
}

sub constructor : Tests(4) {

    my $test  = shift;
    my $class = $test->class;

    can_ok( $class, 'new' );

    can_ok( $class, qw(get_cmd_line get_content set_content) );

    my @data = <Test::Buffer::DATA>;
    close(Test::Buffer::DATA);

    my $buffer;

    ok( $buffer = $class->new( { type => 'output', cmd_line => '' } ),
        'the constructor should suceed' );

    ok( $buffer->set_content( $data[0] ), 'is ok to add lines to it' );

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

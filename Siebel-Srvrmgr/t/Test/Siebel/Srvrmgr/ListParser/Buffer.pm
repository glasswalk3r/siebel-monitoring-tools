package Test::Siebel::Srvrmgr::ListParser::Buffer;

use Test::Most;
use Test::Moose 'has_attribute_ok';
use base 'Test::Siebel::Srvrmgr';

# forcing to be the first method to be tested
# this predates the usage of setup and startup, but the first is expensive and the second cannot be used due parent class
sub _constructor : Tests(1) {

    my $test = shift;

    ok(
        $test->{buffer} =
          $test->class()->new( { type => 'output', cmd_line => '' } ),
        'the constructor should succeed'
    );

}

sub class_attributes : Tests(3) {

    my $test = shift;

    has_attribute_ok( $test->{buffer}, 'type' );
    has_attribute_ok( $test->{buffer}, 'cmd_line' );
    has_attribute_ok( $test->{buffer}, 'content' );

}

sub class_methods : Tests(2) {

    my $test = shift;

    can_ok( $test->{buffer}, qw(new get_cmd_line get_content set_content) );

    ok( $test->{buffer}->set_content( $test->get_my_data()->[0] ),
        'is ok to add lines to it' );

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

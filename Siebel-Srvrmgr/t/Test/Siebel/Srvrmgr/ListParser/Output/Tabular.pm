package Test::Siebel::Srvrmgr::ListParser::Output::Tabular;

use Test::Most;
use base 'Test::Siebel::Srvrmgr::ListParser::Output';
use Test::Moose 'has_attribute_ok';

# this class cannot have a instance due the methods that must be overrided by subclasses of it

sub is_super { return 1 }

sub _constructor {

    my $test = shift;
    $test->SUPER::_constructor( { structure_type => 'fixed' } );

}

sub class_attributes : Tests {

    my $test = shift;

    $test->SUPER::class_attributes(
        [qw (structure_type known_types expected_fields found_header)] );

}

sub class_methods : Tests {

    my $test = shift;

    $test->SUPER::class_methods(
        [
            qw(_consume_data parse get_known_types get_type get_expected_fields found_header _set_found_header _build_expected)
        ]
    );

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

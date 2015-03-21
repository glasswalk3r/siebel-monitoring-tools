# Introduction #

The Siebel-Srvrmgr-Exporter is another proof of concept of usage of the Siebel-Srvrmgr API and it is part of this Perl distribution (see _examples_ directory).

Siebel-Srvrmgr-Exporter is a Perl distribution itself, and it provides a program that connects to a Siebel Server, recover all information regarding the components available in the server and "dump" their information to standard output in the form of `create component` commands to be executed in `srvrmgr` program itself.

This is quite handy if you need to migrate customized components from an environment to another since doing it manually means a **lot** of typing.

# Details #

The command line options information from the online help:

![http://siebel-monitoring-tools.googlecode.com/files/export_comps0.png](http://siebel-monitoring-tools.googlecode.com/files/export_comps0.png)

A running session: while recovering the data, the program will shown an ASCII progress indicator:

![http://siebel-monitoring-tools.googlecode.com/files/export_comps1.png](http://siebel-monitoring-tools.googlecode.com/files/export_comps1.png)

A result of a running session, using all recovered parameters from the Siebel components that matches the regular expression given:

![http://siebel-monitoring-tools.googlecode.com/files/export_comps2.png](http://siebel-monitoring-tools.googlecode.com/files/export_comps2.png)

A result of a running session, using all recovered parameters **with values** from the Siebel components that matches the regular expression given. Please notice that the generated output is considerable shorter than exporting all parameters:

![http://siebel-monitoring-tools.googlecode.com/files/export_comps3.png](http://siebel-monitoring-tools.googlecode.com/files/export_comps3.png)

## Setup ##

First, installing the Siebel-Srvrmgr Perl distribution is a requirement. Check out PerlDistroSetup for details.

Then go to the _examples_ directory from the Siebel-Srvrmgr distribution, then to _Siebel-Srvrmgr-Exporter_ directory.

Once there, type the commands below:

  1. perl Makefile.PL
  1. make
  1. make install

After installed, the export\_comps.pl script will be available in your path. Check out the online documentation to know how to use the program.
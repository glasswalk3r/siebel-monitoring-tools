README
----------------
These files are a complete Nagios plugin for setup Siebel components monitoring:

- commands.cfg: this file is the Nagios commands configuration file. It contains an example of how the comp_mon.pl should be executed
- comp_mon.pl: this Perl script is the main part of the Nagios Plugin. It must be edited to have the correct parameters to connect to the a Siebel 
Enterprise with srvrmgr program.
- comp_mon.xml: this is the XML file used to configure which Siebel Server and corresponding modules should be monitored
- comp_mon.xsd: the XML Schema to validate comp_mon.xml, if necessary
- NSC.ini: this is an example of NSC client used to monitor the components. The NSC must be installed in a Windows computer
that has the srvrmgr.exe program installed, since comp_mon.pl will use such program to connect to a Siebel Server.

The NSC is not obligatory, but you will need to have srvrmgr program available somewhere (even in the Nagios box) to check the components.

See www.nagios.org for more information about the Nagios project.

Required additional Perl modules to be installed prior utilization of comp_mon.pl:

Nagios::Plugin
XML::Rabbit
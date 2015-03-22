The goal of this project is to make possible to monitor Siebel servers. The objects that are being considered to be monitored are:

  * components status;
  * servers (of the connected Enterprise) status;
  * computer resources consumption by component;
  * tasks information;
  * anything else that might be interesting;

Siebel Monitoring tools enables monitoring by using different methods like fetching information from a Siebel Enterprise from `srvrmgr` program or querying the database.

When the information is retrieved by using the `srvrmgr` output, the costs in terms of computer resources are quite low in the Siebel Servers (if a different server is used to host it), specially regarding memory consumption.

Once the tools can use the `srvrmgr` interactively, there is also no need to connect/disconnect to fetch information, which make it easily to fetch information quite faster than repeating the login/logout process every time.

# What is ready for usage #

Currently, this projects provides:

  * An API to connect and retrieve data from a Siebel Enterprise: this API allows connect to a Siebel Enterprise, execute commands, parse the generated output and do something (hopefully) useful with it, like motoring components and tasks. This API is available for download from [CPAN](http://www.cpan.org/) and much more information can be obtained from the documentation available [here](http://search.cpan.org/perldoc?Siebel::Srvrmgr).
  * Two Nagios plug-ins. Please check out the NagiosPlugins wiki for more details.
  * There are also proofs of concept implementations available in the [distribution](http://search.cpan.org/perldoc?Siebel::Srvrmgr) at CPAN. The SiebelSrvrmgrExporter is a handy tool with absolutely minimum configuration.

# What is not ready yet #

The SNMP MIB is still a goal for the project, but it was not started yet.

The [Siebel::Srvrmgr](http://search.cpan.org/perldoc?Siebel::Srvrmgr) API enable several things to monitor, but until now the monitoring of tasks is not ready yet since there is a known bug to parse the "list tasks" output. This bug is also a issue to get computer resource consumption by components.

# Contributing for the project #

Project contribution is not just code! There is need for testing, reporting bugs, asking for features and even documentation. Feel free to contact the project owner for details if you would like to join the project.

Currently, there is a important area to help that is provide output from different Siebel versions from the `srvrmgr`. This task is **very** easy to accomplish and it will help improve the parsers from the currently API. If you like to help, please check the wiki SrvrmgrOutput for more details.

If coding is your area, please see DeveloperNotes for details about helping developing the project.

# Commercial support #

There is not official support for the tools available for download. If you need it, please contact the project owner for more information.

# Other known monitoring tools for Siebel #

  * Foglight for Siebel (commercial): http://www.quest.com/foglight-for-siebel/
  * Zenoss Siebel CRM Components (open source): http://community.zenoss.org/docs/DOC-12921
  * Oracle Siebel Management Framework API Methods (commercial): http://docs.oracle.com/cd/E14004_01/books/SystAdm/SystAdm_MgtFmwkAPI2.html
  * IBM Tivoli Siebel Agent (commercial): http://publib.boulder.ibm.com/infocenter/tivihelp/v24r1/index.jsp?topic=%2Fcom.ibm.itmfa.doc_6.1%2Fom_net_agent_template08.htm
  * Virtual Administrator 2 (commercial): http://www.recursivetechnology.com/va2.php
  * ComTrade Siebel Management Pack (commercial): http://www.managementproducts.comtrade.com/management_pack/siebel/Pages/default.aspx
  * Makao (commercial): http://exchange.nagios.org/directory/Plugins/Others/check-Siebel-CRM-%28all-platforms%29/details
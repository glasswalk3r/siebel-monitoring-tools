#!/bin/bash

./xmlrpc-client.pl -w 1 -c 3 -h 192.168.1.112 -p 8080 -s siebel1 -a SRProc
./xmlrpc-client.pl -w 1 -c 3 -h 192.168.1.112 -p 8080 -s siebel1 -a FSMSrvr
./xmlrpc-client.pl -w 1 -c 3 -h 192.168.1.112 -p 8080 -s siebel1 -a SSEObjMgr_enu
./xmlrpc-client.pl -w 1 -c 3 -h 192.168.1.112 -p 8080 -s siebel1 -a ServerMgr
./xmlrpc-client.pl -w 1 -c 3 -h 192.168.1.112 -p 8080 -s siebel1 -a SRBroker
./xmlrpc-client.pl -w 1 -c 3 -h 192.168.1.112 -p 8080 -s siebel1 -a SvrTblCleanup
./xmlrpc-client.pl -w 1 -c 3 -h 192.168.1.112 -p 8080 -s siebel1 -a SvrTaskPersist
./xmlrpc-client.pl -w 1 -c 3 -h 192.168.1.112 -p 8080 -s siebel1 -a AdminNotify
./xmlrpc-client.pl -w 1 -c 3 -h 192.168.1.112 -p 8080 -s siebel1 -a SCBroker
./xmlrpc-client.pl -w 1 -c 3 -h 192.168.1.112 -p 8080 -s siebel1 -a SMCObjMgr_enu

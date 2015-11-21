' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2011 - 2015 swissEmbedded GmbH, All rights reserved.
' This example parse ABB CDD microinverter data over xml
kWh = 0
kW = 0
server$="192.168.0.30"
start:
	ABBCDDReader kWh, kW, server$
	print "kW " kW " kWh " kWh
	PAUSE 60000
GOTO start
' * Read plant.xml file from CDD and parse the kWh and kW fields
SUB ABBCDDReader ( kWh, kW, server$ )
	con=TCPOpenClient( 1, server$, 80 )
	IF con <> 1 THEN 
		EXIT SUB ' server not available try next time again
	Endif
	' Testing queries like this telnet could be used on port 80 of the device sending the following message in clear text and see if it send the xml file back
	' Unfortunately the ABB TCP/IP Stack seems to have problems, at least it is very slow 
	PAUSE 2000
	num=TCPWrite( 1, "GET /plant.xml HTTP/1.1",13,10,"Host: ",server$,13,10,"Connection: keep-alive",13,10,"Accept: text/html,application/xml",13,10,13,10 )
	' Wait for TCP buffer to be transmitted
	
	kWS$=StreamSearch$(TCPRead(1),"pout_kW="+CHR$(34),CHR$(34),5000)
	kWhS$=StreamSearch$(TCPRead(1),"etot_kWh="+CHR$(34),CHR$(34),5000)
	kW=val(kWS$)
	kWh=val(kWhS$)
	ret=TCPClose( 1 )
END SUB

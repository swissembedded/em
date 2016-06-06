' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2011 - 2015 swissEmbedded GmbH, All rights reserved.
' This example parse victron BMV702 battery monitor with 
' VE.Direct to RS232 interface cable to
' a USR IOT USR-TCP232-302 RS232 to ethernet gateway.
' Make sure to configure gateway to 19200, 8,n,1 TCP Server port 20108
' 
server$="192.168.0.51"
start:
	VictronBMVReader V, VM, DM, I, P, CE, SOC, TTG, server$	
	PAUSE 60000
GOTO start
' * Read victron battery monitor bmv702
SUB VictronBMVReader ( V, VM, DM, I, P, CE, SOC, TTG, server$ )
	' Victron protocol is available from http://www.victronenergy.com
	' pls read "Data communication with Victron Energy products" white paper and
	' "VE.Direct Text Protocol"
	con=TCPOpenClient( 1, server$, 20108 )
	IF con <> 1 THEN
		EXIT SUB ' server not available try next time again
	Endif 
	' Parse entries in the form "token" 5x space "value", the order is important	
	V=val(StreamSearch$(TCPRead(1),"V     "," ",5000))/1000.0
	VM=val(StreamSearch$(TCPRead(1),"VM     "," ",5000))/1000.0
	DM=val(StreamSearch$(TCPRead(1),"DM     "," ",5000))
	I=val(StreamSearch$(TCPRead(1),"I     "," ",5000))/1000.0
	P=val(StreamSearch$(TCPRead(1),"P     "," ",5000))
	CE=val(StreamSearch$(TCPRead(1),"CE     "," ",5000))/1000.0
	SOC=val(StreamSearch$(TCPRead(1),"SOC     "," ",5000))/10.0
	TTG=val(StreamSearch$(TCPRead(1),"TTG     "," ",5000))
	ret=TCPClose( 1 )
END SUB

' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2011 - 2015 swissEmbedded GmbH, All rights reserved.
' This example controls a homematic wireless switch actor (HM-ES-PMSw1-PI)
' Philis hue led lamp
' EMDO S0 solid state relay
SetVarAccess("READWRITE")
state = 0
color$="red"
'homematic vars
serverhm$="192.168.0.8"
leq$="LEQ0533843"
' philips hue vars
user$="1da0b75c128a616f334d31343c6564e7"
serverph$="192.168.0.14"
hue=65535

start:
	' Set EMDO S0 output solid state relais
	S0Out(1,0,state)
	' Set homematic state
	HomematicSetState leq$, state, serverhm$
	
	' Set Philips HUE Led Color
	If color$="green" Then 
		hue=25500
	Else 
		hue=65535
	Endif
	PhilipsHUE 4,hue,254,user$,serverph$
	' Wait one second 
	PAUSE 1000
GOTO start

'* Connect to Homematic server and set actor state
SUB HomematicSetState ( leq$, state, serverhm$ )
	con=TCPOpenClient( 1, serverhm$, 8181 )
	IF con <> 1 THEN 
		EXIT SUB ' server not available try next time again
	Endif 
	num=TCPWrite( 1, "GET /test.exe?x=dom.GetObject('BidCos-RF.",leq$,":1.STATE').State(",STR$(state),"); HTTP/1.1",13,10,"Accept-Encoding: identity",13,10,13,10 )
	PAUSE 500
	' Wait for TCP buffer to be transmitted
	PAUSE 500
	rsp$=TCPRead$(1,255)
	ret=TCPClose( 1 )
END SUB
'* Philips hue light state changer
SUB PhilipsHUE ( id, hue, sat, user$, serverph$ )
	'Generate message {"hue":value,"sat":value}
	'Double quotes are generated with CHR$(34), pls see ASCII table for reference
	mes$="{"+CHR$(34)+"hue"+CHR$(34)+":"+STR$(hue)+","+CHR$(34)+"sat"+CHR$(34)+":"+STR$(sat)+"}"
	ids$=STR$(id)
	con=TCPOpenClient( 1, serverph$, 80 )
	IF con <> 1 THEN 
		EXIT SUB ' server not available try next time again
	Endif 
	' This is a classical HTTP POST with Content Type and Content Length (message size)
	num=TCPWrite( 1, "PUT /api/", user$, "/lights/", ids$, "/state",13,10, "Content-Type: text/plain",13,10,"Content-Length: ",STR$(len(mes$)), 13, 10, 13, 10, mes$)
	PAUSE 500
	rsp$=TCPRead$(1,255)
	ret=TCPClose( 1 )
END SUB


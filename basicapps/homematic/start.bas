' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2011 - 2015 swissEmbedded GmbH, All rights reserved.
' This example controls a homematic wireless switch actor (HM-ES-PMSw1-PI)
state = 0
serverhm$="192.168.0.8"
leq$="LEQ0533843"
start:
	HomematicSetState leq$, state, serverhm$
	IF state = 0 THEN 
		state=1
	ELSE
		state=0
	ENDIF
	PAUSE 60000
GOTO start
' * Connect to Homematic server and set actor state
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

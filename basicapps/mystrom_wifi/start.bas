' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2011 - 2015 swissEmbedded GmbH, All rights reserved.
' This example controls MyStrom WLAN (ip power plug) switches. 
' Please make sure the switch is configured correctly
server$="192.168.2.3"
' Allow network to come up
pause 5000
relay=0
start:
	MyStromState P, relay, server$
	IF relay = 1 THEN
		relay = 0
    ELSE 
        relay = 1
	ENDIF
	MyStromSwitch relay, server$
    print "Current power " + str$(P) + " state " + str$(relay)
	PAUSE 10000
GOTO start
' * Get MyStrom current state (power, relay)
SUB MyStromState ( P, relay, server$ )
	' For further details see "WLAN Energy Control Switch REST API"
	con=SocketClient( 1, server$, 80 )    
	IF con <=0.0 THEN		
        EXIT SUB ' server not available try next time again
	Endif 
	num=SocketWrite( con,  "GET /report HTTP/1.1",13,10,"Host: ",server$, 13,10,"Connection: keep-alive",13,10,"Accept: text/html,application/xml",13,10,13,10 )
	' Parse entries in the form "token" : value, the order is important
    ' "power"    : 123.4,
    ' "relay"    : true or false
    P=val(StreamSearch$(SocketRead(con),CHR$(34)+"power"+CHR$(34)+":"+CHR$(9),",",5000))
	ry$=StreamSearch$(SocketRead(con),CHR$(34)+"relay"+CHR$(34)+":"+CHR$(9),CHR$(10),1000)                
	IF ry$="true" THEN
	 relay=1
	ELSE
	 relay=0
	ENDIF
	done=SocketClose( con )  
END SUB
' * Set MyStrom relay 
SUB MyStromSwitch ( relay, server$ )
	' For further details see "WLAN Energy Control Switch REST API"
	con=SocketClient( 1, server$, 80 )
	IF con <= 0 THEN
		EXIT SUB ' server not available try next time again
	Endif 
	y$="/relay?state="+str$(relay)
	num=SocketWrite( con,  "GET ",y$," HTTP/1.1",13,10,"Host: ",server$, 13,10,"Connection: keep-alive",13,10,"Accept: text/html,application/xml",13,10,13,10 )
    'pause 1000
	done=SocketClose( con )
END SUB

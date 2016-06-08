' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2011 - 2015 swissEmbedded GmbH, All rights reserved.
' This example controls MyStrom WLAN (ip power plug) switches. 
' Please make sure the switch is configured correctly
server$="192.168.2.3"
start:
	MyStromState P, relay, server$
	IF relay = 1 THEN
		relay = 0
	ENDIF
	MyStromSwitch relay, server$
	PAUSE 60000
GOTO start
' * Get MyStrom current state (power, relay)
SUB MyStromState ( P, relay, server$ )
	' For further details see "WLAN Energy Control Switch REST API"
	con=SocketClient( 1, server$, 80 )
	IF con <> 1 THEN
		EXIT SUB ' server not available try next time again
	Endif 
	num=SocketWrite( con,  "GET /report HTTP/1.1",13,10,"Host: ",server$, 13,10,"Connection: keep-alive",13,10,"Accept: text/html,application/xml",13,10,13,10 )
	
	' Parse entries in the form "token" : value, the order is important
    power=val(StreamSearch$(SocketRead(con),"power"+CHR$(34)+":"+CHR$(34)," ",5000))
	ry$=StreamSearch$(SocketRead(con),"relay"+CHR$(34)+":"," ",5000)
	IF ry$="true" THEN
	 relay=1
	ELSE
	 relay=0
	ENDIF
	ret=SocketClose( con )
END SUB
' * Set MyStrom relay 
SUB MyStromSwitch ( relay, server$ )
	' For further details see "WLAN Energy Control Switch REST API"
	con=SocketClient( 1, server$, 80 )
	IF con <> 1 THEN
		EXIT SUB ' server not available try next time again
	Endif 
	y$="/relay?state="+relay
	num=TCPWrite( con,  "GET ",y$," HTTP/1.1",13,10,"Host: ",server$, 13,10,"Connection: keep-alive",13,10,"Accept: text/html,application/xml",13,10,13,10 )
	ret=SocketClose( con )
END SUB

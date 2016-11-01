' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2011 - 2015 swissEmbedded GmbH, All rights reserved.
' @DESCRIPTION EMDO mystrom lib to control wireless power switch with power meter
' @VERSION 1.0
' Please make sure the switch is configured correctly
' Documentation of the API see https://mystrom.ch/de/
' "WLAN Energy Control Switch REST API"

'Loading Http library, make sure it is installed on EMDO
LIBRARY LOAD "http"

' Some examples on usage 
' server$="192.168.2.3"
' Allow network to come up
'pause 5000
'relay=0
'start:
'	err%=MyStromState(server$, power, relay%)
'   print "Current power " err% str$(power) " state " str$(relay%)
'	IF relay% = 1 THEN
'		relay% = 0
'    ELSE 
'        relay% = 1
'	ENDIF
'	err%=MyStromSwitch(server$, relay%)
'   print "Current power " err%
'	PAUSE 10000
'GOTO start

' Get MyStrom current state
' server$ mystrom device ip
' power current power in kW
' relay% relay state
' return error code if negative value
FUNCTION MyStromState ( server$, power, relay% )
    LOCAL err%, con%, ry$
	err%=HTTPRequest(server$, 80, con%, "GET","/report", "", "" , 5000)
	IF err% <0 THEN
	 MyStromState=err%
	 EXIT FUNCTION
	ENDIF	
	' Parse stream from device with power and state
	power=val(StreamSearch$(HTTPResponse(con%),CHR$(34)+"power"+CHR$(34)+":"+CHR$(9),",",5000))/1000.0
	ry$=StreamSearch$(HTTPResponse(con%),CHR$(34)+"relay"+CHR$(34)+":"+CHR$(9),CHR$(10),1000)                
	IF ry$="true" THEN
	 relay%=1
	ELSE
	 relay%=0
	ENDIF
	err%=HTTPClose(con%)
    MyStromState=err%	
END FUNCTION

' Set MyStrom relay state
' server$ mystrom device url 
' relay%  new relay state
FUNCTION MyStromSwitch ( server$, relay% )
    LOCAL err%, con%, y$
    y$="/relay?state="+str$(relay%)
	err%=HTTPRequest(server$, 80, con%, "GET",y$, "", "" , 5000)
	IF err% <0 THEN
	 MyStromSwitch=err%
	 EXIT FUNCTION
	ENDIF
	err%=HTTPClose(con%)
    MyStromSwitch=err%	
END FUNCTION

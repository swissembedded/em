' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2011 - 2015 swissEmbedded GmbH, All rights reserved.
' @DESCRIPTION EMDO philips hue color led light control, convert information 
' e.g. excess energy available into a lamp signal
' @VERSION 1.0
' Please make sure the philips hue gateway is configured correctly
' You have to create a user on the philips bridge first http://www.developers.meethue.com/documentation/getting-started
' Hue of the light. This is a wrapping value between 0 and 65535. Both 0 and 65535 are red, 25500 is green and 46920 is blue.
' Saturation of the light. 254 is the most saturated (colored) and 0 is the least saturated (white). 
' Please visit site http://www.developers.meethue.com/documentation/lights-api for detailed infos about color space

'Loading Http library, make sure it is installed on EMDO
LIBRARY LOAD "http"

' Some examples on usage 
'Adjust server IP and username to your bridge setting (see developers url below for details)
'user$="1da0b75c128a616f334d31343c6564e7"
'server$="192.168.0.14"
'id=3
'sat=254
'start:
'	for kW= -10 to 10
		'transform kW into color
'		If kW < -0.2 THEN
'			hue=25500
'		Elseif kW> 0.2 THEN
'		    hue=65535
'		Else
'			hue=46920
'		Endif		
'		err%=PhilipsHUE(server$,user$,id%,hue%,sat%)
'		PRINT "kW " kW " hue " hue
'		PAUSE 5000
'	Next kW	
	'GOTO start

' Philips hue light state changer
' server$ philips hue device ip
' user$   philips hue bridge generated user string
' hue%    Hue of the light. This is a wrapping value between 0 and 65535
' sat%    Saturation of the light. 254 is the most saturated (colored) and 0 is the least saturated (white).
' return error code if negative value
FUNCTION PhilipsHUE ( server$, user$, id%, hue%, sat% )
    LOCAL err%, con%, mes$, ids$,n%,rsp$
	'Generate message {"hue":value,"sat":value}
	'Double quotes are generated with CHR$(34), pls see ASCII table for reference	
	mes$="{"+CHR$(34)+"hue"+CHR$(34)+":"+STR$(hue)+","+CHR$(34)+"sat"+CHR$(34)+":"+STR$(sat)+"}"
	ids$=STR$(id)
	
	err%=HTTPRequest(server$, 80, con%, "PUT","/api/"+user$+"/lights/"+ids$+"state", "", "text/plain"+chr$(13)+chr$(10)+"Content-Type: text/plain"+chr$(13)+chr$(10)+"Content-Length: "+STR$(len(mes$)) , 5000)
	IF err% <0 THEN
	 PhilipsHUE=err%
	 EXIT FUNCTION
	ENDIF
	' Write content
	n%=SocketWrite( con%,  mes$)
	IF n% < len(mes$) THEN
	 PhilipsHUE=-1
	 EXIT FUNCTION
	ENDIF
	' We expect "success" reading
	rsp$=StreamSearch$(HTTPResponse(con%),CHR$(34)+"success"+CHR$(34),":",5000)	
    err%=HTTPClose(con%)	
	if len(rsp$)=0 THEN
	 PhilipsHUE=-1
	 EXIT FUNCTION
	ENDIF
	PhilipsHUE=0
END FUNCTION

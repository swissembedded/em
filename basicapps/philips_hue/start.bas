' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2011 - 2015 swissEmbedded GmbH, All rights reserved.
' This example controls a philips hue color led light, transform a kW value into color
' green = go and use the excess energy, red=conserve energy, blue = balanced

'Adjust server IP and username to your bridge setting (see developers url below for details)
user$="1da0b75c128a616f334d31343c6564e7"
serverph$="192.168.0.14"
id=3
sat=254
start:
	' You have to create a user on the philips bridge first http://www.developers.meethue.com/documentation/getting-started
	' Hue of the light. This is a wrapping value between 0 and 65535. Both 0 and 65535 are red, 25500 is green and 46920 is blue.
	' Saturation of the light. 254 is the most saturated (colored) and 0 is the least saturated (white). 
	' Please visit site http://www.developers.meethue.com/documentation/lights-api for detailed infos about color space
	for kW= -10 to 10
		'transform kW into color
		If kW < -0.2 THEN
			hue=25500
		Elseif kW> 0.2 THEN
		    hue=65535
		Else
			hue=46920
		Endif		
		PhilipsHUE id,hue,sat,user$,serverph$
		PRINT "kW " kW " hue " hue
		PAUSE 5000
	Next kW	
	
GOTO start
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

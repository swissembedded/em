' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2011 - 2015 swissEmbedded GmbH, All rights reserved.
' This example parse yahoo weather info in json
humidity = 0
sunset$ = ""
sunrise$ = ""
lastbuild$ =""
code = 0
serveryh$="query.yahooapis.com"
start:
	YahooWeatherReader lastbuild$, humidity, sunrise$, sunset$, code, serveryh$
	print "LastBuild " lastbuild$ " Humidity " humidity " sunrise " sunrise$ " sunset " sunset$ " code " code
	PAUSE 60000
GOTO start
' * Read yahoo weather infos
SUB YahooWeatherReader ( lastbuild$, humidity, sunrise$, sunset$, code, serveryh$ )
	' Pls read https://developer.yahoo.com/weather/#get-started= for details
	' codes for code (weathercondition) can be found here https://developer.yahoo.com/weather/documentation.html
	con=TCPOpenClient( 1, serveryh$, 80 )
	IF con <> 1 THEN
		EXIT SUB ' server not available try next time again
	Endif 
	Pause 2000
	y1$="/v1/public/yql?q=select%20*%20from%20weather.forecast%20where%20woeid%20in%20(select%20woeid%20from%20geo.places(1)%20"
	'change location here double quote is %22
	y2$="where%20text%3D%22baden%2C%20ch%22)%20AND%20u%3D%27c%27&format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys"
	num=TCPWrite( 1,  "GET ", y1$, y2$, " HTTP/1.1",13,10,"Host: ",serveryh$, 13,10,"Connection: keep-alive",13,10,"Accept: text/html,application/xml",13,10,13,10 )
	' Wait for TCP buffer to be transmitted
	' Parse entries in the form "token":"value", the order is important
	lastbuild$=StreamSearch$(TCPRead(1),"lastBuildDate"+CHR$(34)+":"+CHR$(34),CHR$(34),5000)
	humidity=val( StreamSearch$(TCPRead(1),"humidity"+CHR$(34)+":"+CHR$(34),CHR$(34),5000) )
	sunrise$=StreamSearch$(TCPRead(1),"sunrise"+CHR$(34)+":"+CHR$(34),CHR$(34),5000)
	sunset$=StreamSearch$(TCPRead(1),"sunset"+CHR$(34)+":"+CHR$(34),CHR$(34),5000)
	code=val( StreamSearch$(TCPRead(1),"code"+CHR$(34)+":"+CHR$(34),CHR$(34),5000) )
	ret=TCPClose( 1 )
END SUB

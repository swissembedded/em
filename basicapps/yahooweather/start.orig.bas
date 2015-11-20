' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2011 - 2015 swissEmbedded GmbH, All rights reserved.
' This example parse yahoo weather info in json
humidity = 0
sunset$ = ""
sunrise$ = ""
code = 0
serveryh$="query.yahooapis.com"
start:
	YahooWeatherReader humidity, sunrise$, sunset$, code, serveryh$
	print "Humidity " humidity " sunrise " sunrise$ " sunset " sunset$ " code " code
	PAUSE 60000
GOTO start
' * Read yahoo weather infos
SUB YahooWeatherReader ( humidity, sunrise$, sunset$, code, serveryh$ )
	' Pls read https://developer.yahoo.com/weather/#get-started= for details
	' codes for code (weathercondition) can be found here https://developer.yahoo.com/weather/documentation.html
	con=TCPOpenClient( 1, serveryh$, 80 )
	IF con <> 1 THEN
		EXIT SUB ' server not available try next time again
	Endif 
	Pause 2000
	ret=TCPClose( 1 )
END SUB

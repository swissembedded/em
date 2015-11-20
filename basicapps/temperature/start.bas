' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2011 - 2015 swissEmbedded GmbH, All rights reserved.
' This example reads the EMDO101 on board temperature sensor
' Init vars
T = 0.0 ' temperature
' Main loop
START:	
	T=Temp
	PRINT "Temperature is " T
	PAUSE 60000
	GOTO START
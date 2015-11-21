' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2011 - 2015 swissEmbedded GmbH, All rights reserved.
' This example reads the S0 inputs every minute
' Please make sure that the S0 interface is configured
' Init vars
' Main loop
kWh1=0.0
kWh2=0.0
kWh3=0.0
START:	
	S0Reader kWh1, kWh2, kWh2
	PRINT "kWh1 " kWh1 " kWh2 " kWh2 " kWh3 " kWh3
	PAUSE 60000
	GOTO START
' S0 reader subroutine
SUB S0Reader ( kWh1, kWh2, kWh3)
	'Reset counter with reading
	imp1=S0Inp(1,1)
	imp2=S0Inp(2,1)
	imp3=S0Inp(3,1)
	print "Imp1 " imp1 " Imp2 " imp2 " Imp3 " imp3
	print "kW1 " (imp1*60.0/1000.0) " kW2 " (imp2*60.0/1000.0) " kW3 " (imp3*60.0/1000.0)
	' Assume 1000 impulses per hour = 1kWh
	kWh1=kWh1+(imp1/1000.0)
	kWh2=kWh2+(imp2/1000.0)
	kWh3=kWh3+(imp3/1000.0)	
END SUB

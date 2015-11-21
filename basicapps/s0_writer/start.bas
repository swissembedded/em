' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2011 - 2015 swissEmbedded GmbH, All rights reserved.
' This example reads the S0 inputs every minute
' and doubles and halfs the value
' Please make sure that the S0 interface is configured
' Init vars
' Main loop
imp1=0.0
START:	
	S0Writer imp1
	PRINT "Pulses " imp1
	PAUSE 60000
	GOTO START
' S0 writer subroutine
SUB S0Writer (imp1)
	imp1=S0Inp(1,1)
	S0Out(1,imp1*2.0)
	S0Out(2,imp1/2.0)
END SUB

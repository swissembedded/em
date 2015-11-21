' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2011 - 2015 swissEmbedded GmbH, All rights reserved.
' This example reads the D0 IEC interface every minute
' Please make sure that the D0 interface is configured to Mode U (unspecific),9600,7,e,1, no autoread, no local echo, strip parity 
' Init vars
' Main loop
kWh1=0.0
kWh2=0.0
START:	
	D0Reader kWh1, kWh2
	PRINT "kWh1 " kWh1 " kWh2 " kWh2
	PAUSE 2000
	GOTO START
' D0 reader subroutine
SUB D0Reader ( kWh1, kWh2)
	'Pls check easymeter manual for OBIS entries
	'1-0:1.8.0*255(00000001.4607804*kWh)
	'1-0:2.8.0*255(00000001.1400000*kWh)
    lines = 0
	kWh1 = 0.0
	kWh2 = 0.0
	DO
	 line$=D0ReadLn$(5000)
	 PRINT "len " len(line$) " " line$
	 IF MID$(line$,1,14)="1-0:1.8.0*255(" THEN
	 	kWh1=VAL(MID$(line$,15,16))
		lines = lines +1
	 ELSEIF MID$(line$,1,14)="1-0:2.8.0*255(" THEN
	    kWh2=VAL(MID$(line$,15,16))
		lines = lines +1
	 ENDIF	 	 
	LOOP UNTIL lines = 2 
END SUB

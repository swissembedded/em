' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2011 - 2015 swissEmbedded GmbH, All rights reserved.
' This example reads the D0 IEC interface every minute
' Please make sure that the D0 interface is configured to Mode C, D (continues mode) or U (unspecific)
' Set baudrate to the required baudrate. Some devices use special baudrates, 
' e.g. Easymeter use 9600 baud, pls check that example program too
' Set autoread mode for automatic iec6205621 OBIS protocol polling (Mode C).
' Init vars
kWh1=0.0
kWh2=0.0
' Main loop
START:	
	D0Reader kWh1, kWh2
	PRINT "kWh1 " kWh1 " kWh2 " kWh2
	PAUSE 60000
	GOTO START

'* D0 reader subroutine (polled every 15 minutes)
SUB D0Reader ( kWh1, kWh2)
	' Start reading
	sc%=D0Start(1000)
	' Check if the D0 port unused
	IF sc% = 0 THEN RETURN
    ' wait for D0 readout finished
	sc%=D0End(5000)
    
	' Read line, D0 IEC 62056-21
	' We read a max of 20 lines if device is in continues mode
	' We have to parse each line for the register of interest 
	' and current readout e.g.
	' consumption :  1.8.0(017613.595*kWh)
	' feed in grid:  2.8.0(000058.254*kWh)
	' in the format direction.8.tarif  0= total, 1=tarif 1 , 2=tarif 2
	' pls check the readout, there are differences from manufacturer to manufacturer
	DO
	     line$=RTRIM$(D0ReadLn$(1000))
         IF len(line$) > 0 THEN
	        IF MID$(line$,1,6)="1.8.0(" THEN
	            PRINT "len=" len(line$) " [" line$ "]"
	 	        kWh1=VAL(MID$(line$,7,10))
	        ELSEIF MID$(line$,1,6)="2.8.0(" THEN
	            PRINT "len=" len(line$) " [" line$ "]"
	            kWh2=VAL(MID$(line$,7,10))
	        ENDIF	 
        ELSE
            EXIT
        ENDIF
	LOOP UNTIL 0
END SUB

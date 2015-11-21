' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2011 - 2015 swissEmbedded GmbH, All rights reserved.
' This example reads the D0 IEC interface every minute and switches loads
' Please make sure that the D0 interface is configured to Mode C or D (continues mode)
' on and off
' Init vars
kWh1 = 0.0 ' energy consumption
kWh2 = 0.0 ' excess energy
lastkWh1 = 0.0 ' last value
lastkWh2 = 0.0 ' last value
kW1 = 0.0 ' power consumption 
kW2 = 0.0 ' excess power
reg1 = 0 ' regulation state load 1
reg2 = 0 ' regulation state load 2
reg3 = 0 ' regulation state load 2
starttime=Unixtime ' Init main loop variables
lasttime=starttime
' Main loop
START:	
	D0Reader kWh1, kWh2
	' calculte delta time and scale it to hours unix time is seconds since 1.1.1970
	deltatime=(starttime-lasttime)/3600
	kW1=(kWh1-lastkWh1)/deltatime
	kW2=(kWh1-lastkWh1)/deltatime
	IF kW1 < 0.0 THEN kW1 = 0.0 ' D0 reading error
	IF kW2 < 0.0 THEN kW2 = 0.0 ' D0 reading error
	Load1 kW1, kW2, reg1
	Load2 kW1, kW2, reg2
	Load3 kW1, kW2, reg3
	' Wait one minute
	PAUSE 60000
	' Update vars for next iteration
	lasttime = starttime
	starttime = Unixtime	
	lastkWh1=kWh1
	lastkWh2=kWh2
	GOTO START
' D0 reader subroutine
SUB D0Reader ( kWh1, kWh2)
	' Start reading
	start=D0START(1000)
	' Check if the D0 port unused
	IF start = 0 THEN RETURN
	' Read line, D0 IEC 62056-21
	' We read a max of 20 lines if device is in continues mode
	' We have to parse each line for the register of interest 
	' and current readout e.g.
	' consumption :  1.8.0(017613.595*kWh)
	' feed in grid:  2.8.0(000058.254*kWh)
	' in the format direction.8.tarif  0= total, 1=tarif 1 , 2=tarif 2
	' pls check the readout, there are differences from manufacturer to manufacturer
    lines = 0
	kWh1 = 0.0
	kWh2 = 0.0
	DO
	 line$=D0ReadLn$(5000)
	 PRINT line$
	 IF MID$(line$,1,6)="1.8.0(" THEN
		kWh1=VAL(MID$(line$,7,10))
	 ELSE IF MID$(line$,1,6)="2.8.0(" THEN
	    kWh2=VAL(MID$(line$,7,10))
	 ENDIF	 
	 lines = lines +1
	LOOP UNTIL (len(line$) = 0) OR ( lines > 20 )
	D0End
END SUB
' Load switching S0 Output 1 (solid state output)
SUB Load1 ( kWh1, kWh2, reg1 )
 ' Rules:
 ' switch on if excess energy available for at least 5 minutes
 ' switch off if power consumption above 2kW for at least 15 minutes
 IF kWh1 > 2.0 THEN 
    IF reg1 < 0.0 THEN reg1 = 0
	reg1 = reg1 + 1
	IF reg1 > 15 THEN ' switch off
 ELSE IF kWh2 > 0.0 THEN
	IF reg1 > 0.0 THEN reg1 = 0
	reg1 = reg1 -1
	if reg1 < -5 THEN ' switch on
 ENDIF
END SUB
' Load switching S0 Ouptut 2 (solid state output)
SUB Load2 ( kWh1, kWh2, reg2 )
' Rules:
 ' switch on if excess energy available for at least 5 minutes or 5min on every 45 minutes
 ' switch off if power consumption above 1kW for at least 15 minutes
 IF kWh1 > 1.0 THEN 
    IF reg2 < 0.0 THEN reg2 = 0
	reg2 = reg2 + 1
	IF reg2 > 15 THEN ' switch off
 ELSE IF kWh2 > 0.0 THEN
	IF reg2 > 0.0 THEN reg2 = 0
	reg2 = reg2 -1
	if reg2 < -15 THEN ' switch on
 ENDIF
 IF reg2 > 60 THEN 
 ' switch on
  IF reg2 > 65 THEN reg2 = 15
 END 
END SUB
' Load switching S0 Output 3 (relais output)
SUB Load3 ( kWh1, kWh2, reg3 )
' Rules:
 ' switch on /off every 15 minutes
 IF reg3 < 15 THEN 
 ' switch off 
 ELSE IF reg3 < 30 THEN
  'switch on
 ELSE
  reg3 = 0 
 ENDIF
 reg3 = reg3 + 1
END SUB

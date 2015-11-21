' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2011 - 2015 swissEmbedded GmbH, All rights reserved.
' This example reads the D0 interface every 15 minutes and logs it on flash
' Please make sure that the D0 interface is configured to Mode C, D (continues mode) or U (unspecific)
' Set baudrate to the required baudrate. Some devices use special baudrates, 
' e.g. Easymeter use 9600 baud, pls check that example program too
' Set autoread mode for automatic iec6205621 OBIS protocol polling (Mode C).
' Init vars
kWh1=0.0
kWh2=0.0
kWhDay1=0.0
kWhDay2=0.0
kWhLast1=0.0
kWhLast2=0.0
stamp$=""
' Main loop
D0Reader kWh1, kWh2
START:	
	' Wait for 15 minutes 00, 15, 30, 45	
	ts$=Timestamp$	
	dates$=date$
	print "timestamp " + dates$
	hours$=mid$(dates$,12,2)
	mins$=mid$(dates$,15,2)	

	If mins$="00" OR mins$="15" OR mins$="30" OR mins$="45" Then
		print "logging " + hours$ + ":" + mins$
		' Update the energy log values from D0
		kWhLast1=kWh1
		kWhLast2=kWh2
		D0Reader kWh1, kWh2
		' Update values the power log for quaterhour
		kW1=(kWh1-kWhLast1)*4.0
		kW2=(kWh2-kWhLast2)*4.0		
		' Generate Quarterhour log		
		stamp$=mid$(dates$,9,2)+mid$(dates$,4,2)+mid$(dates$,1,2)
		log$=ts$+","+FORMAT$(kW1,"%.3f")+","+FORMAT$(kW2,"%.3f")
		LogWriter log$, stamp$, "Date,kW1,kW2",  "/output/graphlog.csv"
		' Update values for the energy log for the day
		kWhDay1=kWhDay1+(kWh1-kWhLast1)
		kWhDay2=kWhDay2+(kWh2-kWhLast2)		
		If hours$="00" AND mins$="00" Then
			' Generate Day log
			stamp$=mid$(dates$,9,2)
			log$=ts$+","+FORMAT$(kWhDay1,"%.3f")+","+FORMAT$(kWhDay2,"%.3f")			
			LogWriter log$, stamp$, "Date,kWh1,kWh2", "/output/graphlog.csv"
			' Reset counter
			kWhDay1=0.0
			kWhDay2=0.0			
		Endif
		' Just make sure that it does not retrigger a log, wait at least two minute
		PAUSE 120000
	Endif
	' Sleep a second
	PAUSE 1000
	Goto Start	
'* D0 reader subroutine (polled every 15 minutes)
SUB D0Reader ( kWh1, kWh2)
	' Start reading
	start=D0Start(1000)
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
	 line$=D0OBISReadLn$(5000)
	 
	 PRINT "len " len(line$) " " line$
	 IF MID$(line$,1,6)="1.8.0(" THEN
	 	kWh1=VAL(MID$(line$,7,10))
	 ELSEIF MID$(line$,1,6)="2.8.0(" THEN
	    kWh2=VAL(MID$(line$,7,10))
	 ENDIF	 
	 lines = lines +1
	 ' Last line is !
	LOOP UNTIL (len(line$) = 3) OR ( lines > 23 )
	end=D0End(5000)
END SUB
'* Write Log for every 15 minutes or day
SUB LogWriter ( log$, stamp$, hdr$, logdir$  )	
	filename$="/output/"+stamp$+".csv"
	Open filename$ For Random AS #1
	If LOF(#1) = 0 Then
		' this is a new file, write header to the log 
		' and make an entry in the graphlog to plot it in the webinterface
		PRINT #1, hdr$
		Open logdir$ For Random AS #2
		PRINT #2, stamp$
		Close #2
	Endif
	print log$
	PRINT #1, log$
	Close #1
END SUB

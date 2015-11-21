' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2011 - 2015 swissEmbedded GmbH, All rights reserved.
' This example reads the S0 inputs every 15 minutes and logs it on flash
' Please make sure that the S0 interface is configured
' Init vars
kWh1=0.0
kWh2=0.0
kWh3=0.0
kWhDay1=0.0
kWhDay2=0.0
kWhDay3=0.0
stamp$=""
' Main loop
START:	
	' Wait for 15 minutes 00, 15, 30, 45	
	ts$=Timestamp$	
	dates$=date$
	print "timestamp " + dates$
	hours$=mid$(dates$,12,2)
	mins$=mid$(dates$,15,2)	

	
	If mins$="00" OR mins$="15" OR mins$="30" OR mins$="45" Then
		print "logging " + hours$ + ":" + mins$
		' Update the energy log values from S0
		S0Reader kWh1, kWh2, kWh2
		' Update values the power log for quaterhour
		kW1=kWh1*4.0
		kW2=kWh2*4.0
		kW3=kWh3*4.0
		' Generate Quarterhour log		
		stamp$=mid$(dates$,9,2)+mid$(dates$,4,2)+mid$(dates$,1,2)
		log$=ts$+","+FORMAT$(kW1,"%.3f")+","+FORMAT$(kW2,"%.3f")+","+FORMAT$(kW3,"%.3f")		
		LogWriter log$, stamp$, "Date,kW1,kW2,kW3", "/output/graphlog.csv"
		' Update values for the energy log for the day
		kWhDay1=kWhDay1+kWh1
		kWhDay2=kWhDay2+kWh2
		kWhDay3=kWhDay3+kWh3
		If hours$="00" AND mins$="00" Then
			' Generate Day log
			stamp$=mid$(dates$,9,2)
			log$=ts$+","+FORMAT$(kWhDay1,"%.3f")+","+FORMAT$(kWhDay2,"%.3f")+","+FORMAT$(kWhDay3,"%.3f")			
			LogWriter log$, stamp$, "Date,kWh1,kWh2,kWh3", "/output/graphlog.csv"
			' Reset counter
			kWhDay1=0.0
			kWhDay2=0.0
			kWhDay3=0.0
		Endif
		' Just make sure that it does not retrigger a log, wait at least two minute
		PAUSE 120000
	Endif
	' Sleep a second
	PAUSE 1000
	Goto Start	
'* S0 reader subroutine (polled every 15 minutes)
SUB S0Reader ( kWh1, kWh2, kWh3)
	'Reset counter with reading
	imp1=S0Inp(1,1)
	imp2=S0Inp(2,1)
	imp3=S0Inp(3,1)
	print "Imp1 " imp1 " Imp2 " imp2 " Imp3 " imp3	
	' Assume 1000 impulses per hour = 1kWh
	kWh1=(imp1/1000.0)
	kWh2=(imp2/1000.0)
	kWh3=(imp3/1000.0)	
END SUB
'* Write Log for every 15 minutes or day
SUB LogWriter ( log$, stamp$, hdr$, logdir$ )	
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

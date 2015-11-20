' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2011 - 2015 swissEmbedded GmbH, All rights reserved.
' This example reads the ABBCDD inverter device every 15 minutes and logs it on flash
' Pls make sure the server IP address is configured correctly
' Init vars
kWh1=0.0
kW1=0.0
kWhDay1=0.0
kWhLast1=0.0
stamp$=""
server$="192.168.0.30"
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
		' Update the energy log values from D0
		kWhLast1=kWh1		
		ABBCDDReader kWh1, kW1, server$
		' Update values the power log for quaterhour
		' Generate Quarterhour log		
		stamp$=mid$(dates$,9,2)+mid$(dates$,4,2)+mid$(dates$,1,2)
		log$=ts$+","+FORMAT$(kW1,"%.3f")
		LogWriter log$, stamp$, "Date,kW1",  "/output/graphlog.csv"
		' Update values for the energy log for the day
		kWhDay1=kWhDay1+(kWh1-kWhLast1)
		If hours$="00" AND mins$="00" Then
			' Generate Day log
			stamp$=mid$(dates$,9,2)
			log$=ts$+","+FORMAT$(kWhDay1,"%.3f")
			LogWriter log$, stamp$, "Date,kWh1", "/output/graphlog.csv"
			' Reset counter
			kWhDay1=0.0			
		Endif
		' Just make sure that it does not retrigger a log, wait at least two minute
		PAUSE 120000
	Endif
	' Sleep a second
	PAUSE 1000
	Goto Start	
' * Read plant.xml file from CDD and parse the kWh and kW fields
SUB ABBCDDReader ( kWh, kW, server$ )
	con=TCPOpenClient( 1, server$, 80 )
	IF con <> 1 THEN 
		EXIT SUB ' server not available try next time again
	Endif
	' Testing queries like this telnet could be used on port 80 of the device sending the following message in clear text and see if it send the xml file back
	' Unfortunately the ABB TCP/IP Stack seems to have problems, at least it is very slow 
	PAUSE 2000
	num=TCPWrite( 1, "GET /plant.xml HTTP/1.1",13,10,"Host: ",server$,13,10,"Connection: keep-alive",13,10,"Accept: text/html,application/xml",13,10,13,10 )
	' Wait for TCP buffer to be transmitted
	
	kWS$=StreamSearch$(TCPRead(1),"pout_kW="+CHR$(34),CHR$(34),5000)
	kWhS$=StreamSearch$(TCPRead(1),"etot_kWh="+CHR$(34),CHR$(34),5000)
	kW=val(kWS$)
	kWh=val(kWhS$)
	ret=TCPClose( 1 )
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

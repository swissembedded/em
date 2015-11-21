' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2011 - 2015 swissEmbedded GmbH, All rights reserved.
' This example shows howto read the AEConversion Inverter production info
' Please make sure that rs485 bus is terminated properly (9600,8,n,1)
' Init vars
DIM id(32)
' Probe the inverters on rs485 bus
Print "Probing inverters "
AECProbe id
Print "Inverterlist" id
Print "Starting main loop"
' Main loop
START:	
	' Wait for 15 minutes 00, 15, 30, 45	
	ts$=Timestamp$	
	dates$=date$
	print "timestamp " + dates$
	hours$=mid$(dates$,12,2)
	mins$=mid$(dates$,15,2)	

	' Check if new log is needed
	If mins$="00" OR mins$="15" OR mins$="30" OR mins$="45" Then
		print "logging " + hours$ + ":" + mins$		
		stampQuart$=mid$(dates$,9,2)+mid$(dates$,4,2)+mid$(dates$,1,2)
		stampDay$=mid$(dates$,9,2)
		descQuart$="Date"
		descDay$="Date"
		logQuart$=ts$
		logDay$=ts$
		kWSum=0.0
		kWhSum=0.0
		num=0
		FOR y= 1 TO 32
			' Only read the data from the inverter if it was previously found
			If id(y) Then
				' Update the energy log values from inverter				
				AECRead y, kW, kWh
				kW=kW
				kWh=kWh
				kWSum=kWSum+kW
				kWhSum=kWhSum+kWh
				logQuart$=logQuart$+","+FORMAT$(kW,"%.3f")
				logDay$=logDay$+","+FORMAT$(kWh,"%.3f")
				descQuart$=descQuart$+",kW"
				descDay$=descDay$+",kWh"
				num=num+1
			Endif
		NEXT y
		If num > 1 Then 
			logQuart$=logQuart$+","+FORMAT$(kWSum,"%.3f")
			logDay$=logDay$+","+FORMAT$(kWhSum,"%.3f")
			descQuart$=descQuart$+",kWTotal"
			descDay$=descDay$+",kWhTotal"
		Endif		
		' Generate Quarterhour log		
		LogWriter logQuart$, stampQuart$, descQuart$,  "/output/graphlog.csv"
		' Daily log
		If hours$="00" AND mins$="00" Then
				LogWriter logDay$, stampDay$, descDay$, "/output/graphlog.csv"
		Endif
		' Just make sure that it does not retrigger a log, wait at least two minute
		PAUSE 120000
	Endif
	' Sleep a second
	PAUSE 1000
	Goto Start	
'**
' Write Log for every 15 minutes or day
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
'**
' Subroutine to configure AEConversion inverter 
SUB AECRead ( id, kW, kWh )
  devid$ = FORMAT$(id,"%02g")
  qy$ = "#" + devid$ + "0"
  AECRS485 qy$,rsp$
  ' *140   0  54.2  4.10     0 243.3  0.67   217  50     79
  '123456789012345678901234567890123456789012345678901234567890 
  '         1         2         3         4         5         6
  kW = VAL(MID$(rsp$,41,5))/1000.0
  kWh = VAL(MID$(rsp$,51,5))/1000.0
END SUB
'**
' Subroutine to probe AEConversion inverter, we take the one with the highest number
SUB AECProbe ( id )
  FOR y=1 TO 32
   devid$ = FORMAT$(y,"%02g") 
   qy$ = "#" + devid$ + "9" 
   AECRS485 qy$, rsp$
   IF LEN(rsp$)>0 THEN 
    id(y) = 1
    Print "Found device " y
   ELSE
    id(y) = 0
    'Print "No device found " y
   ENDIF
  NEXT y
END SUB
'**
' Subroutine to communicate with AEConversion inverter
SUB AECRS485 ( qy$,rsp$ )
  LOCAL w
  'print "qy " qy$
  w = RS485Write(qy$,13)
  rsp$ = RS485ReadLn$(2000,CHR$(13))
  'print "rsp " rsp$ 
  'print "len" len(rsp$)
END SUB

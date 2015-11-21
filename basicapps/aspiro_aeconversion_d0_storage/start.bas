' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2015 swissEmbedded GmbH, All rights reserved.
' This example shows howto control Aspiro charger and AEConversion Inverter
' as a simple but inexpensiv and versatile battery storage solution with lead acid batteries
' Please make sure that rs485 bus is terminated properly (9600,8,n,1)
' And the aspiro is configured correcty for the attached lead acid batteries
' Init some vars
aspiro$="192.168.0.240"
PowerInvOffset=0.05 ' Do not feed from battery to the grid
PowerChargerOffset=0.00 ' Offset of the charger, it does not matter if we use some power from the grid to charge
UBatMin = 45.4
lastmin=-1.0
kWhDailyPV=0.0
kWhDailyGrid=0.0
kWhDailyExcess=0.0
kWhDailyCharger=0.0
kWhDailyBattery=0.0
kWhQuartPV=0.0
kWhQuartGrid=0.0
kWhQuartExcess=0.0
kWhQuartCharger=0.0
kWhQuartBattery=0.0
DIM id(32)
D0Reader kWhGrid, kWhExcess
' Probe the inverters on rs485 bus
Print "Probing inverters "
AECProbe id
Print "Starting main loop"
' Main loop
START:
	' Control loop every minute
	' Log every 15 minutes 00,15,30,45
	' Weather info every hour
	ts$=Timestamp$	
	dates$=date$
	'print "timestamp " + dates$
	hour=VAL(mid$(dates$,12,2))
	min=VAL(mid$(dates$,15,2))
	
	
	' A minute passed?
	If min <> lastmin Then
		' Minute has changed, new control loop
		'PRINT "control loop " + str$(hour) + ":" + str$(min)
		' Read S0 interface (input for PV production)
		S0Reader kWhPV, dummy1, dummy2
		kWhQuartPV=kWhQuartPV+kWhPV
		kWPV=kWhPV*60.0
		' Read D0 interface (input for house grid usage, excess energy)
		kWhGridLast=kWhGrid : kWhExcessLast=kWhExcess 
		D0Reader kWhGrid, kWhExcess
		kWhQuartGrid = kWhQuartGrid + (kWhGrid-kWhGridLast) : kWhQuartExcess = kWhQuartExcess + (kWhExcess-kWhExcessLast)
		kWExcess=(kWhExcess-kWhExcessLast)*60.0 : kWGrid=(kWhGrid-kWhGridLast)*60.0
	
		' Sanity checks before we use this for control loop and logging
		If lastmin = -1.0 Then
		 lastmin=min
		 Goto START
		Endif

		' Calculate the time 
		If hour >= 22 or hour <= 6 Then
			night = 1
		Else
			night = 0
		Endif
		
		' Control battery charger (excess) and inverters (usage)
		' Calculate power of the inverters and average battery voltage
		n=0.0 : v=0.0 : p=0.0
		For y = 1 TO 32
			If id(y) = 1 Then
				AECGetStatus y, volt, cur, kW
				p=p+kW : v=v+volt : n=n+1
			Endif
		Next y
		UBat=v/n
		' Read aspiro data (this is from last cycle)
		AspiroGet ( aspiro$, 2,5, TBatAspiro )
		AspiroGet ( aspiro$, 2,1, UBatAspiro ) : UBatAspiro=UBatAspiro/100.0
		AspiroGet ( aspiro$, 2,3, IBatAspiro ) : IBatAspiro=IBatAspiro/10.0
		AspiroGet ( aspiro$, 2,4, IRectAspiro ) : IRectAspiro=IRectAspiro/10.0
		kWBattery=UBatAspiro*IBatAspiro/1000.0
		kWCharger=UBatAspiro*IRectAspiro/1000.0
		'Calculate the power of the inverter and charger with offset
		PowerInv = (kWGrid+p)-kWExcess-PowerInvOffset
		PowerCharger = kWExcess - kWGrid - PowerChargerOffset
		
		If PowerInv < 0.0 OR night = 1 OR UBatAspiro < UBatMin Then
			' Charger active
			PowerInv=0.0
			Mode=0.0
			' Make sure there is some minimal charging, or maximal charging at the night
			If night = 1 OR UBatAspiro < UBatMin Then PowerCharger=5.0
			If PowerCharger < 0.1 Then PowerCharger=0.1
		Else
			' Inverter active
			PowerCharger=0.0
			Mode=2.0
		Endif
		' Update the inverters	
		kWInverter=0.0
		For y = 1 TO 32
			If id(y) = 1 Then
				If UBat <= 0.0 OR PowerInv = 0.0 Then
					AECStop y
				Elseif PowerInv > 0.48 Then
					AECSetConf y, 480.0/UBat
					kWInverter = kWInverter + 0.48 : PowerInv = PowerInv - 0.48
				Else
					AECSetConf y, PowerInv*1000.0/UBat
					kWInverter = kWInverter + PowerInv : PowerInv = 0.0
				Endif
			Endif
		Next y
		' Update charger
		If Mode <> 2.0 Then 
			' Charge mode, normal mode (U1), boost mode (U2) or spare (U4)
			Current=PowerCharger*1000.0/UBat
			If Current > 50.0 Then 
				Current = 50.0
				AspiroSet ( aspiro$, 3,1, 0.0 ) 'normal operation mode
				AspiroSet ( aspiro$, 3,41, 0.0 ) 'no current limit
			Else 
				AspiroSet ( aspiro$, 3,1, 0.0 ) 'normal operation mode
				AspiroSet ( aspiro$, 3,42, Current*10.0 ) 'set current limit
				AspiroSet ( aspiro$, 3,41, 1.0 ) 'current limit enabled
			Endif
		Else
			' Discharge 
			AspiroSet ( aspiro$, 3,1, 2.0 ) 'test operation mode, rectifier disconnected
			kWCharger=0.0
		Endif
		kWhQuartBattery = kWhQuartBattery + (kWBattery / 60.0)
		kWQuartCharger = kWhQuartCharger + (kWCharger / 60.0)
		kWQuartInverter = kWhQuartInverter + (kWInverter / 60.0)
		msg$="CL " + dates$ + " Grid " + FORMAT$(kWGrid,"%02.3f") + " Excess " + FORMAT$(kWExcess,"%02.3f") + " PV " +  FORMAT$(kWPV,"%02.3f") 
		msg$=msg$ + " Inverter " + FORMAT$(kWInverter,"%02.3f")
		msg$=msg$ + " Charger " + FORMAT$(kWCharger,"%02.3f") + " Battery " + FORMAT$(kWBattery,"%02.3f") + " Mode " + str$(Mode)
		Print msg$
		' Finally Write logs if needed
		If min=0 OR min=15 OR min=30 OR min=45 Then
			' Quater hour log
			stamp$=mid$(dates$,9,2)+mid$(dates$,4,2)+mid$(dates$,1,2)
			log$=ts$+","+FORMAT$(kWhQuartGrid*4.0,"%.3f")+","+FORMAT$(kWhQuartExcess*4.0,"%.3f")+","+FORMAT$(kWhQuartPV*4.0,"%.3f")+","
			log$=log$+FORMAT$(kWhQuartCharger*4.0,"%.3f")+","+FORMAT$(kWhQuartBattery*4.0,"%.3f")
			LogWriter log$, stamp$, "Date,kWGrid,kWExcess,kWPV,kWCharger,kWBattery", "/output/graphlog.csv"
			kWhDailyGrid=kWhDailyGrid+kWhQuartGrid : kWhDailyExcess=kWhDailyExcess+kWhQuartExcess : kWhDailyPV=kWhDailyBattery+kWhQuartPV
			kWhDailyCharger=kWhDailyCharger+kWhQuartCharger : kWhDailyBattery=kWhDailyBattery+kWhQuartBattery
			kWhQuartGrid=0.0 : kWhQuartExcess=0.0 : kWhQuartPV=0.0 : kWhQuartCharger=0.0 : kWhQuartBattery=0.0
		Endif
		If hour=0 AND min=0 Then
			' Daily log
			stamp$=mid$(dates$,9,2)
			log$=ts$+","+FORMAT$(kWhDayGrid,"%.3f")+","+FORMAT$(kWhDayExcess,"%.3f")+","+FORMAT$(kWhDayPV,"%.3f")+","+FORMAT$(kWhDayCharger,"%.3f")+","
			log$=log$+FORMAT$(kWhDayBattery,"%.3f")
			LogWriter log$, stamp$, "Date,kWhGrid,kWhExcess,kWhPV,kWhCharger,kWhBattery", "/output/graphlog.csv"
			' Cleanup
			kWhDailyGrid=0.0 : kWhDailyExcess=0.0 : kWhDailyPV=0.0 : kWhDailyCharger=0.0 : kWhDailyBattery=0.0
		Endif
		lastmin=min
	Endif	
	' Sleep a second
	PAUSE 1000
Goto START
'**
' Subroutine to get status from AEConversion inverter 
SUB AECGetStatus ( id, Voltage, Current, kW)
  devid$ = FORMAT$(id,"%02g")  
  pause 500
  qy$ = "#" + devid$ + "0"
  AECRS485 qy$,rsp$
  ' *140   0  54.2  4.10     0 243.3  0.67   217  50     79
  '123456789012345678901234567890123456789012345678901234567890 
  Voltage = VAL(MID$(rsp$,11,5))
  Current = VAL(MID$(rsp$,17,5))
  kW = VAL(MID$(rsp$,41,5))/1000.0
END SUB
'**
' Subroutine to configure AEConversion inverter 
SUB AECSetConf ( id, Current)
  devid$ = FORMAT$(id,"%02g")  
  pause 500
  qy$ = "#" + devid$ + "B 2 45.2"
  AECRS485 qy$,rsp$
  cur$=FORMAT$(Current,"%02.1f") : IF len(cur$)=3 THEN cur$ = "0"+cur$
  print cur$
  pause 500
  qy$ = "#" + devid$ + "S " + cur$
  AECRS485 qy$,rsp$  
END SUB
'**
' Subroutine to stop output power of the AEConverion inverter
SUB AECStop ( id )  
  qy$ = "#"+ FORMAT$(id,"%02g") +"L 001"
  AECRS485 qy$, rsp$
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
  rsp$ = RS485ReadLn$(1000,CHR$(13))
  'print "rsp " rsp$ 
  'print "len" len(rsp$)
END SUB
'**
' Subroutine to read aspiro
SUB AspiroGet ( aspiro$, x,y, value )
' Get request v2c 1.3.6.1.4.1.5961.5.X.Y.0
' at the end 05 00 is termination, the octets before the termination are the object identifier, it starts with 06 which is type object identifier, followed by the length of the oi
' the length might vary depending on the oi, values above 127 are encoded in two bytes
' oi e.g. 1.3.6.1.4.1.5961.5.2.1.0 which is encoded to  06 0B 2B 06 01 04 01 AE 49 05 02 01 00
' 2B = 1.3., 06=6, 01=1...AE49=5961 where AE = 128 + 46 and 49 is the remainer 5961-(46*128)
' request id &H01,&H02,&H03,&H04
' There is a a good introduction from Rane RaneNote "SNMP: Simple? Network Management Protocol"
 con=UDPOpenClient( 1, aspiro$, 161 )
 msg$=CHR$(&H30)+CHR$(&H2D)+CHR$(&H02)+CHR$(&H01)+CHR$(&H01)+CHR$(&H04)+CHR$(&H07)+CHR$(&H61)+CHR$(&H63)+CHR$(&H63)
 msg$=msg$+CHR$(&H72)+CHR$(&H65)+CHR$(&H61)+CHR$(&H64)+CHR$(&HA0)+CHR$(&H1F)+CHR$(&H02)+CHR$(&H04)+CHR$(&H01)+CHR$(&H02)
 msg$=msg$+CHR$(&H03)+CHR$(&H04)+CHR$(&H02)+CHR$(&H01)+CHR$(&H00)+CHR$(&H02)+CHR$(&H01)+CHR$(&H00)+CHR$(&H30)+CHR$(&H11)
 msg$=msg$+CHR$(&H30)+CHR$(&H0F)+CHR$(&H06)+CHR$(&H0B)+CHR$(&H2B)+CHR$(&H06)+CHR$(&H01)+CHR$(&H04)+CHR$(&H01)+CHR$(&HAE)
 msg$=msg$+CHR$(&H49)+CHR$(&H05)+CHR$(x)+CHR$(y)+CHR$(&H00)+CHR$(&H05)+CHR$(&H00)
 ret=UDPWrite(1,msg$)
 PAUSE 500
 rsp$=UDPRead$(1,255)
 num=len(rsp$)
 ret=UDPClose(1)
 IF num=57 THEN 
	value=256*ASC(MID$(rsp$,56,1))+ASC(MID$(rsp$,57,1))
 ELSE
	value=ASC(MID$(rsp$,56,1))
 ENDIF
END SUB
'**
' Subroutine to write aspiro
SUB AspiroSet ( aspiro$, x,y, value )
 con=UDPOpenClient( 1, aspiro$, 161 )
 lo=value MOD 256
 hi=(value-lo)/256
 'PRINT hi lo
 msg$=CHR$(&H30)+CHR$(&H2F)+CHR$(&H02)+CHR$(&H01)+CHR$(&H01)+CHR$(&H04)+CHR$(&H07)+CHR$(&H61)+CHR$(&H63)+CHR$(&H63)
 msg$=msg$+CHR$(&H77)+CHR$(&H72)+CHR$(&H69)+CHR$(&H74)+CHR$(&HA3)+CHR$(&H21)+CHR$(&H02)+CHR$(&H04)+CHR$(&H01)+CHR$(&H02)
 msg$=msg$+CHR$(&H03)+CHR$(&H04)+CHR$(&H02)+CHR$(&H01)+CHR$(&H00)+CHR$(&H02)+CHR$(&H01)+CHR$(&H00)+CHR$(&H30)+CHR$(&H13)
 msg$=msg$+CHR$(&H30)+CHR$(&H11)+CHR$(&H06)+CHR$(&H0B)+CHR$(&H2B)+CHR$(&H06)+CHR$(&H01)+CHR$(&H04)+CHR$(&H01)+CHR$(&HAE)
 msg$=msg$+CHR$(&H49)+CHR$(&H05)+CHR$(x)+CHR$(y)+CHR$(&H00)+CHR$(&H02)+CHR$(&H02)+CHR$(hi)+CHR$(lo)
 ret=UDPWrite(1,msg$)
 PAUSE 500
 rsp$=UDPRead$(1,255)
 num=len(rsp$)
 'print "len " num
 ret=UDPClose(1)
 IF num=58 THEN 
	value=256*ASC(MID$(rsp$,57,1))+ASC(MID$(rsp$,58,1))
 ELSEIF num=57 THEN
	value=ASC(MID$(rsp$,57,1))
 ELSE
  print "Aspiro not responding, pls check config"
 ENDIF
END SUB
'**
' D0 reader subroutine (polled every 15 minutes)
SUB D0Reader ( kWh1, kWh2 )
	start=D0Start(1000)
	IF start=0 THEN
		EXIT SUB
	ENDIF
    lines = 0
	kWh1 = 0.0
	kWh2 = 0.0
	DO
	 line$=D0OBISReadLn$(5000)	 
	 IF MID$(line$,1,6)="1.8.0(" THEN
	 	kWh1=VAL(MID$(line$,7,10))
	 ELSEIF MID$(line$,1,6)="2.8.0(" THEN
	    kWh2=VAL(MID$(line$,7,10))
	 ENDIF
	 lines = lines +1	 
	LOOP UNTIL (len(line$) = 3) OR ( lines > 23 )
	end=D0End(5000)
	END SUB
'**
' S0 reader subroutine
SUB S0Reader ( kWh1, kWh2, kWh3)
	'Reset counter with reading
	imp1=S0Inp(1,1)
	imp2=S0Inp(2,1)
	imp3=S0Inp(3,1)
	' Assume 1000 impulses per hour = 1kWh
	kWh1=(imp1/1000.0)
	kWh2=(imp2/1000.0)
	kWh3=(imp3/1000.0)	
END SUB
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

' This script is an example of the EMDO101, EMDO102, EMDO103 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2017 swissEmbedded GmbH, All rights reserved.
' EMDO Landis & Gyr Energy Meter E450 Customer Information Interface (CII) MBUS example
' EMDO Landis & Gyr Energy Meter E350 D0 Interface
' S0 input for any energy meter with impulse output

' check values from previous start
ts0%=0
EI0=rrdRead( 0, ts0% )
EE0=rrdRead( 1, ts0% )

mode$="CII/MBUS"
IF mode$="CII/MBUS" THEN
 SYS.SET "mbus", "baud=2400 parity=e protocol=1"
 LIBRARY LOAD "mbus"
 LIBRARY LOAD "cosem"
 ON COSEM ciiHandler
ELSE IF mode$="D0" THEN
 SYS.SET "d0", "mode=C autoread=1"
ELSE IF mode$="S0" THEN 
ENDIF

' start cron job for every minute update
minCronDesc%=CrontabAdd("* * * * *")
IF minCronDesc% < 0 THEN 
 ERROR "Failed to add CRON entry"
ELSE 
 ON CRON minCronDesc% minCron
 print "Cron " minCronDesc%
ENDIF

start:
Dispatch -1
GOTO start

' Log every minute
FUNCTION minCron(id%,elapsed%)  
 IF mode$="CII/MBUS" THEN
 ELSE IF mode$="D0" THEN
  D0Handler()
 ELSE IF mode$="S0" THEN
  LOCAL oEE$,oEI$
  oEI$=obis_1.8.0$
  oEE$=obis_2.8.0$
  S0Handler()
  obis_1.7.0$=str$(val(obis_1.8.0$)-val(oEI$))
  obis_2.7.0$=str$(val(obis_2.8.0$)-val(oEE$))
 ENDIF
 ' Check if day has changed, read last value from database
 ' EIDay
 ' EEDay
 LOCAL vl,ts%,yd%,yd0%
 yd0%=DateYearday(ts0%)
 yd%=DateYearday(Unixtime())
 EI=val(obis_1.8.0$)
 EE=val(obis_2.8.0$)
 IF yd0%<>yd% THEN
  sc%=rrdWrite( 0, EI )
  sc%=rrdWrite( 1, EE )
  EI0=EI
  EE0=EE
  yd0%=yd%
 ENDIF
 EIDay=EI-EI0
 EEDay=EE-EE0
END FUNCTION

' CII handler
' ts% - timestamp of Data_Notification PDU
' dnCtr% - all pairs within one Data_Notification PDU will have equal counter value
' obis$ - OBIS code
' type% - type of value
' value$ - value
FUNCTION ciiHandler( ts%, dnCtr%, obis$, type%, value$ )
 LOCAL txt$,p1%,ln%,ob$,obk$,obv$
 PRINT ISOTime$(ts%), dnCtr%, obis$ +" " ;
 obv$=CSText(type%, value$)  
 PRINT obv$
 ' A-B:C.D.E.F, using C.D.E only
 ob$=split$(1,obis$,":")
 ln%=len(split$(3,ob$,"."))+1
 ' set value (visible in dash)
 obk$=left$(ob$,len(ob$)-ln%)
 $("obis_"+obk$+"$",obv$)
END FUNCTION

' D0 handler
FUNCTION D0Handler()
 LOCAL sc%,line$,obk$,obv$
 ' Start reading D0 interface
 sc%=D0Start(1000)
 ' Check if the D0 port unused
 IF sc% = 0 THEN RETURN
 sc%=D0End(5000)
    
 ' Read line, D0 IEC 62056-21
 ' consumption :  1.8.0(017613.595*kWh)
 DO
  line$=RTRIM$(D0ReadLn$(1000))
   IF len(line$) > 0 THEN
    PRINT "[" line$ "]"
    obk$=split$(0,line$,"(")
    obv$=split$(0,split$(1,line$,"("),"*")
    $("obis_"+obk$+"$",obv$)
   ELSE
    EXIT FUNCTION
   ENDIF
 LOOP UNTIL true
END FUNCTION

' S0 handler
FUNCTION S0Handler()
 ' S0 preprocessing
 obis_1.8.0$=str$(S0In ( 0 , 1 ) / 1000.0)
 obis_2.8.0$=str$(S0In ( 1 , 1 ) / 1000.0)
 END FUNCTION
 
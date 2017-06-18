' This script is an example of the EMDO101, EMDO102, EMDO103 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2017 swissEmbedded GmbH, All rights reserved.
' S0 In1 production photovoltaic
' S0 In2 consumption
' Rel 1 and Rel 2 consumer

' 5 Tariff for electricity on monthly basis
DIM TkWh(3)=(50.0,150.0,300.0,600.0)
DIM TC(3)=(19.75,94.64,200.69,475.95)
TL%=4
S0Type=1000.0
' check values from previous start
ts0%=0
' Monthly written values
EPm=rrdRead( 0, tsm% )
ECm=rrdRead( 1, tsm% )
' Daily written values
EPd=rrdRead( 2, tsd% )
ECd=rrdRead( 3, tsd% )
' Quarterly written values
EPq=rrdRead( 4, tsq% )
ECq=rrdRead( 5, tsq% )

' init
LIBRARY LOAD "logger"

' start cron job for every minute update
minCronDesc%=CrontabAdd("* * * * *")
IF minCronDesc% < 0 THEN 
 ERROR "Failed to add CRON entry"
ELSE 
 ON CRON minCronDesc% minCron
 print "Cron " minCronDesc%
ENDIF

' start cron job for every 15 minutes update
quartCronDesc%=CrontabAdd("*/15 * * * *")
IF quartCronDesc% < 0 THEN 
 ERROR "Failed to add CRON entry"
ELSE 
 ON CRON quartCronDesc% quartCron
 print "Cron " quartCronDesc%
ENDIF

' start cron job for midnight update
midCronDesc%=CrontabAdd("0 0 * * *")
IF midCronDesc% < 0 THEN 
 ERROR "Failed to add CRON entry"
ELSE 
 ON CRON midCronDesc% midCron
 print "Cron " midCronDesc%
ENDIF

start:
Dispatch -1
GOTO start

' Log every midnight
FUNCTION midCron(id%,elapsed%)
  LOCAL lgr$
  EPd=EPq
  ECd=ECq
  tsd%=tsq%
  sc%=rrdWrite( 2, EPd)
  sc%=rrdWrite( 3, ECd)
  ' Write to daily log
  lr$=LGRecStart$(ts0%)+LGRecItem$(EP0)+LGRecItem$(EC0)
  LGWriter( lr$, LGGetYear$(ts0%), "Date,PV Energy[kWh],Consumed Energy[kWh]")
  IF m%=DateMonthDay(ts%,1) = 1 THEN
   ' new month, reset month counter
   sc%=rrdWrite( 0, EPd)
   sc%=rrdWrite( 1, ECd)
  ENDIF
END FUNCTION

' Log midnight
FUNCTION minCron(id%,elapsed%)  
  LOCAL ts%,min%,hour%, PD
  ' Read S0 Inputs
  PP=S0In ( 0 , "p" ) / S0Type*60.0
  PC=S0In ( 1 , "p" ) / S0Type*60.0
  PD=PC-PP
  IF PD<=0.0 THEN
   PE=-PD
   PI=0.0
  ELSE
   PI=PD
   PE=0.0
  ENDIF
  ControlMinLoad()
END FUNCTION


' Log every 15 minutes
FUNCTION quartCron(id%,elapsed%)
  LOCAL min%,hour%,dEP,dEC,err%
  'get time
  ts%=Unixtime()
  min%=DateMinutes(ts%,1)
  hour%=DateHour(ts%,1)
  ' Convert the number of pulses to kWh (delta since last quarter hour) and sum it up
  dEP=S0In ( 0 , 1 ) / S0Type
  dEC=S0In ( 1 , 1 ) / S0Type
  EPq=EPq+dEP
  ECq=ECq+dEC
  sc%=rrdWrite( 4, EPq)
  sc%=rrdWrite( 5, ECq)
  ' Calculate the new tariff
  'err=getTariff(ts%,EmI,EmP,EeI,EeP,Elm,Eld,cpkWh)
  ' Write to quaterly hour log
  lr$=LGRecStart$(tsq%)+LGRecItem$(EPq)+LGRecItem$(ECq)
  LGWriter( lr$, LGGetDate$(ts%), "Date,PV Energy[kWh],Consumed Energy[kWh]")
  ' Control the loads
  ControlQuartLoad()
END FUNCTION

' Based on current monthly electricity consumption, predict the price, and daily and monthly limit
' ts% unix timestamp
' EmI imported energy this month
' EmP produced energy this month
' EmI imported energy estimate for this month
' EmP produced energy estimate for this month
' Elm monthly limit
' Eld daily limit based on monthly limit
' cpkWh cost per kWh based on estimated monthly limit
FUNCTION getTariff(ts%,EmI,EmP,EeI,EeP,Elm,Eld,cpkWh)
 LOCAL md%,m%,d%,y%,i,EeI,EeP
 md%=DateMonthDay(ts%,1)
 m%=DateMonth(ts%,1)
 y%=DateYear(ts%,1)
 ' Calculated the number of days this month
 d%=31
 IF m%=2 THEN
  d%=28
  ' Leap year
  IF ((y%-2016) MOD 4) = 0 THEN
   d%=29
  ENDIF
 ELSE IF m%=4 OR m%=6 OR m%=9 OR m%=11 THEN
  d%=30
 ENDIF
 
 ' Estimate Elm and Eld based on EI
 EeI=EmI/md%*d%
 EeP=EmP/md%*d%
 ' Find the tariff
 FOR i=0 TO (TL%-1)
  IF EeI <= TkWh(i) THEN
   Elm=TkWh(i)
   Eld=TC(i)/TkWh(i)/d%
   cpkWh=TC(i)/TkWh(i)
  ENDIF
 NEXT i
 getTariff=0
END FUNCTION

' Control the loads on mintue base, pls note loads should not switched on off too quickly
SUB ControlMinLoad()
 IF PE > 0.0 THEN
  ' We are exporting energy, reduce inverter power or switch loads on
 ELSE IF PI > 0.0 THEN
  ' We are importing energy, increase inverter power or switch loads off
 ENDIF
END SUB

' Control the loads on quaterly base, pls note loads should not switched on off too quickly
SUB ControlQuartLoad()
 IF PE > 0.0 THEN
  ' We are exporting energy, reduce inverter power or switch loads on 
 ELSE IF PI > 0.0 THEN
  ' We are importing energy, increase inverter power or switch loads off
 ENDIF
END SUB
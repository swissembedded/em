' This script is an example of the EMDO101, EMDO102, EMDO103 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2017 swissEmbedded GmbH, All rights reserved.
' S0 In1 production photovoltaic
' S0 In2 consumption
' Rel 1 and Rel 2 consumer

' Relais config
' PMax: consumption power > Limit
' DayOrange
' DayRed
' MonthOrange
' MonthRed
rel1$="DayOrange"
relp1=0.0
rel2$="MonthRed,MonthOrange"
relp2=0.0
dayo=0.0
dayr=0.0
montho=0.0
monthr=0.0

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
EIm=rrdRead( 2, tsm% )
EEm=rrdRead( 3, tsm% )
' Daily written values
EPd=rrdRead( 4, tsd% )
ECd=rrdRead( 5, tsd% )
EId=rrdRead( 6, tsd% )
EEd=rrdRead( 7, tsd% )
' Quarterly written values
EPq=rrdRead( 8, tsq% )
ECq=rrdRead( 9, tsq% )
EIq=rrdRead( 10, tsq% )
EEq=rrdRead( 11, tsq% )

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

' Cron midnight
FUNCTION midCron(id%,elapsed%)
  LOCAL lr$
  EPd=EPq
  ECd=ECq
  EId=EIq
  EEd=EEq
  tsd%=tsq%
  sc%=rrdWrite( 4, EPd)
  sc%=rrdWrite( 5, ECd)
  sc%=rrdWrite( 6, EId)
  sc%=rrdWrite( 7, EEd)

  ' Write to daily log
  lr$=LGRecStart$(tsd%)+LGRecItem$(EPd)+LGRecItem$(ECd)+LGRecItem$(EId)+LGRecItem$(EEd)
  LGWriter( lr$, LGGetYear$(tsd%), "Date,PV Energy[kWh],Consumed Energy[kWh],Imported Energy[kWh],Exported Energy[kWh]")
  IF m%=DateMDay(ts%,1) = 1 THEN
   ' new month, reset month counter
   sc%=rrdWrite( 0, EPd)
   sc%=rrdWrite( 1, ECd)
   sc%=rrdWrite( 2, EId)
   sc%=rrdWrite( 3, EEd)
   EPm=EPd
   ECm=ECd
   EIm=EId
   EEm=EEd
   tsm%=tsd%
  ENDIF
END FUNCTION

' Cron every minute
FUNCTION minCron(id%,elapsed%)  
  LOCAL ts%,min%,hour%, PD
  ' Read S0 Inputs
  PP=S0In( 0 , "P" ) / S0Type*60.0
  PC=S0In( 1 , "P" ) / S0Type*60.0
  PD=PC-PP
  IF PD<=0.0 THEN
   PE=-PD
   PI=0.0
  ELSE
   PI=PD
   PE=0.0
  ENDIF
  PP_status$=str$(PP)+" Watt"
  PC_status$=str$(PC)+" Watt"
  PI_status$=str$(PI)+" Watt"
  PE_status$=str$(PE)+" Watt"
  ControlMinLoad()
END FUNCTION


' Cron every 15 minutes
FUNCTION quartCron(id%,elapsed%)
  LOCAL min%,hour%,err%
  'get time
  tsq%=Unixtime()
  min%=DateMinutes(tsq%,1)
  hour%=DateHours(tsq%,1)
  ' Convert the number of pulses to kWh (delta since last quarter hour) and sum it up
  dEP=S0In( 0 , 1 ) / S0Type
  dEC=S0In( 1 , 1 ) / S0Type
  EPq=EPq+dEP
  ECq=ECq+dEC
  IF dEP > dEC THEN
   EEq=EEq+dEP-dEC
  ELSE
   EIq=EEq+dEC-dEP
  ENDIF
  sc%=rrdWrite( 8, EPq)
  sc%=rrdWrite( 9, ECq)
  sc%=rrdWrite( 10, EIq)
  sc%=rrdWrite( 11, EEq)
  ' Calculate the new tariff
  getTariff()
  ' Write to quaterly hour log
  lr$=LGRecStart$(tsq%)+LGRecItem$(EPq)+LGRecItem$(ECq)+LGRecItem$(EIq)+LGRecItem$(EEq)
  LGWriter( lr$, LGGetDate$(tsq%), "Date,PV Energy[kWh],Consumed Energy[kWh],Imported Energy[kWh],Exported Energy[kWh]")
  ' Control the loads
  ControlQuartLoad()
   ' Set status
   m_EC=ECq-ECm
   m_EP=EPq-EPm
   m_EI=EIq-EIm
   m_EE=EEq-EEm
   d_EC=ECq-ECd
   d_EP=EPq-EPd
   d_EI=EIq-EId
   d_EE=EEq-EEd

END FUNCTION

' Based on current monthly electricity consumption, predict the price, and daily and monthly limit
SUB getTariff()
 LOCAL md%,m%,d%,y%,i
 md%=DateMDay(tsq%,1)
 m%=DateMonth(tsq%,1)
 y%=DateYear(tsq%,1)
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
 
 ' Estimate monthly extrapolation
 EeP=(EPq-EPm)/md%*d%
 EeC=(ECq-ECm)/md%*d%
 EeI=(EIq-EIm)/md%*d%
 EeE=(EEq-EEm)/md%*d%
 ' Find the tariff and set montly limit (ElmI) and daily limit (EldI)
 FOR i=0 TO (TL%-1)
  IF EeI <= TkWh(i) THEN
   ElmI=TkWh(i)
   EldI=TC(i)/TkWh(i)/d%
   cpkWh=TC(i)/TkWh(i)
  ENDIF
 NEXT i
 getTariff=0
END SUB

' PMax: consumption power > Limit
' DayOrange
' DayRed
' MonthOrange
' MonthRed

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
 LOCAL st1%, st2%, tp%
 IF PE > 0.0 THEN
  ' We are exporting energy, reduce inverter power or switch loads on 
 ELSE IF PI > 0.0 THEN
  ' We are importing energy, increase inverter power or switch loads off
 ENDIF
  ' Check relays
 IF r1_force% THEN 
  st1%=1
 ELSE IF Instr(1,rel1$,"PMax")>0 AND PI>relp1 THEN
  st1%=0
 ELSE IF Instr(1,rel1$,"DayOrange")>0 AND (EIq-EId)>dayo THEN
  st1%=0
 ELSE IF Instr(1,rel1$,"DayRed")>0 AND (EIq-EId)>dayr THEN
  st1%=0
 ELSE IF Instr(1,rel1$,"MonthOrange")>0 AND (EIq-EIm)>montho THEN
  st1%=0
 ELSE IF Instr(1,rel1$,"MonthRed")>0 AND (EIq-EIm)>monthr THEN
  st1%=0
 ELSE
  st1%=1
 ENDIF

 IF r2_force% THEN
  st2%=1
 ELSE IF Instr(1,rel2$,"PMax")>0 AND PI>relp2 THEN
  st2%=0
 ELSE IF Instr(1,rel2$,"DayOrange")>0 AND (EIq-EId)>dayo THEN
  st2%=0
 ELSE IF Instr(1,rel2$,"DayRed")>0 AND (EIq-EId)>dayr THEN
  st2%=0
 ELSE IF Instr(1,rel2$,"MonthOrange")>0 AND (EIq-EIm)>montho THEN
  st2%=0
 ELSE IF Instr(1,rel2$,"MonthRed")>0 AND (EIq-EIm)>monthr THEN
  st2%=0
 ELSE
  st2%=1
 ENDIF
 
 ' Set status and relay
 IF st1% THEN 
  r1_status$="On"
  SYS.SET "s0_out2", "state=1"
 ELSE
  r1_status$="Off"
  SYS.SET "s0_out2", "state=0"
 ENDIF
 
 tp%=SYS.GET "type"
 if tp%=0 THEN
  r2_status$="absent"
  r1_force%=0
  EXIT SUB
 ENDIF
 
 IF st2% THEN 
  r2_status$="On"
  SYS.SET "s0_out3", "state=1"
 ELSE
  r2_status$="Off"
  SYS.SET "s0_out3", "state=0"
 ENDIF
END SUB


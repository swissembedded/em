' This script is an example of the EMDO101, EMDO102, EMDO103 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2017 swissEmbedded GmbH, All rights reserved.
' Electric vehicle charger
' Supported charger ABL, Keba, Phoenix Contact EV
' Monitoring energie meters
' Cloud communication to www.ednme.com

' Load all required libraries
LIBRARY LOAD "modbus"
LIBRARY LOAD "eastron"
LIBRARY LOAD "logger"
LIBRARY LOAD "abl"
LIBRARY LOAD "keba"
LIBRARY LOAD "phoenixevcharge"
LIBRARY LOAD "dash"

' init interfaces
SYS.Set "rs485", "baud=9600 data=8 stop=1 parity=n term=1"
SYS.Set "rs485-2", "baud=38400 data=8 stop=1 parity=n term=1"

' check values from previous start
ts0%=0
EI0=rrdRead( 0, ts0% )
EE0=rrdRead( 1, ts0% )
EEVTot0=rrdRead( 2, ts0% )
EEV10=rrdRead( 3, ts0% )
EEV20=rrdRead( 4, ts0% )
EEV30=rrdRead( 5, ts0% )

' Init vars
DIM evm$(3) LENGTH 10 = ("Unplugged","Charging","Ended","Stopped")
' Phoenix
EV3Amp%=0
EV3En%=0
EV3St$=""
EV3Prox%=0
EV3Tch%=0
' start cron job for every minute update
minCronDesc%=CrontabAdd("* * * * *")
IF minCronDesc% < 0 THEN 
 ERROR "Failed to add CRON entry"
ELSE 
 ON CRON minCronDesc% minCron
 print "Cron " minCronDesc%
ENDIF

start:

' Phoenix EV
err%=PhoenixEVControl("TCP:192.168.10.20:502",180, EV3En%, EV3Amp%, EV3St$, EV3Prox%, EV3Tch%)
IF err% >=0 THEN
 IF EV3St$="A" THEN 
  st$=evm$(0)
 ELSE IF EV3St$="B" THEN
  st$=evm$(2)
 ELSE IF EV3St$="C" OR EV3St$="E" THEN
  st$=evm$(1)
 ELSE IF EV3St$="F" THEN
  st$=evm$(3)
 ENDIF
 ev3_status$=st$
ENDIF
Dispatch 1000
GOTO start

' Log every minute
FUNCTION minCron(id%,elapsed%)  
  ' read energy meter for household
 LOCAL Uac1, Uac2, Uac3, Iac1, Iac2, Iac3, kW1, kW2, kW3, kWhI1, kWhI2, kWhI3, kWhE1, kWhE2, kWhE3, P
 err%=EastronEnergyMeter("TCP:192.168.10.22:502",1, Uac1, Uac2, Uac3, Iac1, Iac2, Iac3, kW1, kW2, kW3, kWhI1, kWhI2, kWhI3, kWhE1, kWhE2, kWhE3)
 P=kW1+kW2+kW3
 if err% >= 0 THEN
  IF P >= 0.0 THEN 
   PE=0.0
   PI=P
  ELSE
   PE=-P
   PI=0.0
  ENDIF
   meter_status$="Import:"+chr$(10)+ds_num$(err%,PI,"%.3f"," kW")+chr$(10)+"Export:"+chr$(10)+ds_num$(err%,PE,"%.3f"," kW")
   EI=kWhI1+kWhI2+kWhI3
   EE=kWhE1+kWhE2+kWhE3
 ENDIF
 ' read energy meter for electric vehicle
 err%=EastronEnergyMeter("RTU:RS485:1",1, Uac1, Uac2, Uac3, Iac1, Iac2, Iac3, kW1, kW2, kW3, kWhI1, kWhI2, kWhI3, kWhE1, kWhE2, kWhE3)
 if err% >= 0 THEN
   PEVTot=kW1+kW2+kW3
   charger_status$="Load:"+chr$(10)+ds_num$(err%,PEVTot,"%.3f"," kW")
   EEVTot=kWhI1+kWhI2+kWhI3+kWhE1+kWhE2+kWhE3
 ENDIF
 ' Calculate daily energy, start logger and update counter
 LOCAL vl,ts%,yd%,yd0%,lr$,min%
 ts%=Unixtime()
 yd0%=DateYearday(ts0%)
 yd%=DateYearday(ts%)
 EI=val(obis_1.8.0$)
 EE=val(obis_2.8.0$)
 EIDay=EI-EI0
 EEDay=EE-EE0
 EEVTotDay=EEVTot-EEVTot0
 EEV1Day=EEV1-EEV10
 EEV2Day=EEV2-EEV20
 EEV3Day=EEV3-EEV30
 min%=DateMinutes()
 IF min%=0 OR min%=15 OR min%=30 OR min%=45 THEN
  IF ts%<>0 THEN
   lr$=LGRecStart$(ts%)+LGRecItem$(PI)+LGRecItem$(PE)+LGRecItem$(PEVTot)+LGRecItem$(PEV1)+LGRecItem$(PEV2)+LGRecItem$(PEV3)
   LGWriter( lr$, LGGetDate$(ts%), "Datum,Power Import [kW],Power Export [kW],Power EV Total [kW],Power EV Abl [kW],Power EV Keba [kW],Power EV Phoenix [kW]")
  ENDIF
 ENDIF
 
 IF yd0%<>yd% THEN
  lr$=LGRecStart$(ts0%)+LGRecItem$(EI)+LGRecItem$(EE)+LGRecItem$(EEVTot)+LGRecItem$(EEV1)+LGRecItem$(EEV2)+LGRecItem$(EEV3)
  LGWriter( lr$, LGGetYear$(ts0%), "Datum,Energy Import [kWh],Energy Export [kWh],Energy EV Total [kWh],Energy EV Abl [kWh],Energy EV Keba [kWh],Energy EV Phoenix [kWh]")
  sc%=rrdWrite( 0, EI )
  sc%=rrdWrite( 1, EE )
  sc%=rrdWrite( 2, EEVTot )
  sc%=rrdWrite( 3, EEV1 )
  sc%=rrdWrite( 4, EEV2 )
  sc%=rrdWrite( 5, EEV3 )
  EI0=EI
  EE0=EE
  EEVTot0=EEVTot
  EEV10=EEV1
  EEV20=EEV2
  EEV30=EEV3
  
  EIDay=0
  EEDay=0
  EEVTot=0
  EEV1Day=0
  EEV2Day=0
  EEV3Day=0
  ts0%=ts%
 ENDIF
END FUNCTION

 
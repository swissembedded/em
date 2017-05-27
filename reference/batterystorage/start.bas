' This script is an example of the EMDO101, EMDO102, EMDO103 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2017 swissEmbedded GmbH, All rights reserved.
' Self made battery storage solution
' Config
' don't probe, use order the inverters INV500-90 are mounted on the rail
AECIds$=chr$(26)+chr$(14)+chr$(24)+chr$(4)
'AECIds$=""
' init interfaces
SYS.Set "rs485", "baud=2400 data=8 stop=1 parity=n term=1"
SYS.Set "rs485-2", "baud=9600 data=8 stop=1 parity=n term=0"

' Load all required libraries
LIBRARY LOAD "aesgi"
IF AECIds$="" THEN
 AECIds$=AECProbe$("RS485:2")
ENDIF

LIBRARY LOAD "modbus"
LIBRARY LOAD "eastron"
LIBRARY LOAD "vedirect"
LIBRARY LOAD "pidcontrol"
LIBRARY LOAD "logger"
LIBRARY LOAD "dash"

' Config power control loop
pcTimerDesc%=SetTimer(5000)
IF pcTimerDesc% < 0 THEN 
 ERROR "Failed to add Timer entry"
ELSE 
 ON TIMER pcTimerDesc% pcTimer
 print "pcTimer " pcTimerDesc%
ENDIF
Dispig=0
Disperr=0
Chapig=0
Chaperr=0

count%=0
start:
 dispatch 1000
 goto start
 
 ' Control loop every 5 seconds (timer based)
' id% cron identifier
' elapsed% time in ms elapsed since last schedule
FUNCTION pcTimer(id%)  
 PRINT "pcTimer id=" id% " date=" Date$()
  ' read energy meter for household
 'LOCAL Uac1, Uac2, Uac3, Iac1, Iac2, Iac3, kW1, kW2, kW3, kWhI1, kWhI2, kWhI3, kWhE1, kWhE2, kWhE3, P
 err1%=EastronEnergyMeter("TCP:192.168.10.22:502",1, Uac1, Uac2, Uac3, Iac1, Iac2, Iac3, kW1, kW2, kW3, kWhI1, kWhI2, kWhI3, kWhE1, kWhE2, kWhE3) 
 err2%=EastronEnergyMeterP1("RTU:RS485:1",1, Uac, Iac, kW, kWhI, kWhE)

 if err1% >=0 and err2% >=0 THEN
  P=Round(kW1+kW2+kW3,3)
  IF P >= 0.0 THEN 
   PE=0.0
   PI=P
  ELSE
   PE=-P
   PI=0.0
  ENDIF
  meter_status$="Import:"+chr$(10)+ds_num$(err%,PI,"%.3f"," kW")+chr$(10)+"Export:"+chr$(10)+ds_num$(err%,PE,"%.3f"," kW")+chr$(10)
  PS=Round(kW,3)
  if PS > 0 THEN
   s$="Charging"
   PD=0.0
   PC=PS
  else
   s$="Discharging:"
   PC=0.0
   PD=-PS
  endif
  meter_status$=meter_status$+s$+chr$(10)+ds_num$(err%,PD+PC,"%.3f"," kW")
 ENDIF

 ' read battery manager
 'LOCAL vl%, vls$,bat$,a$
 bat$="192.168.10.11:20108"
 err%=VEDirectHex(bat$,"7",&Hed8d,"un16",vl%, vls$)
 UBat=vl%/100.0
 a$=ds_num$(err%,UBat,"%.1f","V")+"("
 err%=VEDirectHex(bat$,"7",&H0383,"un16",vl%, vls$)
 a$=a$+ds_num$(err%,vl%/10.0,"%.1f","%)")+chr$(10)
 err%=VEDirectHex(bat$,"7",&Hed8f,"sn16",vl%, vls$)
 IBat=vl%/10.0
 a$=a$+ds_num$(err%,IBat,"%.1f","A")+chr$(10)
 err%=VEDirectHex(bat$,"7",&Heeff,"sn32",vl%, vls$)
 IhBat=vl%/10.0
 a$=a$+ds_num$(err%,IhBat,"%.1f","Ah")+chr$(10)
 err%=VEDirectHex(bat$,"7",&Hed8e,"sn16",vl%, vls$)
 PBat=vl%/1000.0
 a$=a$+ds_num$(err%,PBat,"%.3f","kW")+chr$(10)
 err%=VEDirectHex(bat$,"7",&H0fff,"un16",vl%, vls$)
 SoCBat=vl%/100.0
 a$=a$+ds_num$(err%,SoCBat,"%.2f","%")+chr$(10)
 battery_status$=a$
 IF PD >= 0.0 THEN
  ' control variable is inverter ac power
  PInv=PIDControl(30,(PI-PE+PD-PC)*1000.0,5,Dispig,Disperr,-1.0,0.0,0.0)
  IInv=PInv/UBat*1.1/len(AECIds$)
  IF IInv<0.0 THEN
   IInv=0.0
  ENDIF
  IF IInv>11.0 THEN
   IInv=11.0
  ENDIF
  print "PID Inverter PInv " PInv/1000.0 "/IInv " IInv "/pig " Dispig "/err " Disperr
ENDIF
 'IF PI = 0.0 AND PE > 0.0 THEN
 ' PInv=0.0
 ' IInv=0.0
 ' Dispig=0.0
 ' Disperr=0.0
 'ENDIF
 ' Set inverter
 aec$="RS485:2"
 'IInv=0.0
 for id%=1 TO len(AECIds$)
   dev%=asc(mid$(AECIds$,id%,1))
   err%=AECGetOperationMode(aec$,dev%,mode%,Udc)
   if err%<0 then
    count%=coun%+1
   endif
   print "GOP " err% dev% mode% Udc
   IF err%<0 OR mode%<>2 OR Udc<>45.2 THEN
    err%=AECSetOperationMode(aec$,dev%,2,45.2)   
    print "SOP " err% dev%
   ENDIF 
   err%=AECSetCurrentLimit(aec$,dev%,IInv)
   if err%<0 then
    count%=coun%+1
   endif
   print "CUR " err% dev% IInv
   print "count" count%
 next id%
 'err%=AECSetOutputPowerB(aec$,0)
 'err%=AECSetOutputPowerB(aec$,100)
 pcTimer=0
END FUNCTION

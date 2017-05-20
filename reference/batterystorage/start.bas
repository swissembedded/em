' This script is an example of the EMDO101, EMDO102, EMDO103 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2017 swissEmbedded GmbH, All rights reserved.
' Self made battery storage solution

' init interfaces
SYS.Set "rs485", "baud=2400 data=8 stop=1 parity=n term=1"
SYS.Set "rs485-2", "baud=9600 data=8 stop=1 parity=n term=1"

' Load all required libraries
LIBRARY LOAD "aesgi"
s$=AECProbe$("RS485:2")
print len(s$)
LIBRARY LOAD "modbus"
LIBRARY LOAD "eastron"
LIBRARY LOAD "vedirect"
LIBRARY LOAD "pidcontrol"
LIBRARY LOAD "logger"
LIBRARY LOAD "dash"

start:
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
   PD=PS
  endif
  meter_status$=meter_status$+s$+chr$(10)+ds_num$(err%,PS,"%.3f"," kW")
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

 ' Set inverter
 err%=AECSetOutputPowerB("RS485:2",0)
 pause 1000
 goto start
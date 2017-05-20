' This script is an example of the EMDO101, EMDO102, EMDO103 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2017 swissEmbedded GmbH, All rights reserved.
' Self made battery storage solution

' Load all required libraries
LIBRARY LOAD "modbus"
LIBRARY LOAD "eastron"
LIBRARY LOAD "logger"
LIBRARY LOAD "dash"

' init interfaces
SYS.Set "rs485", "baud=2400 data=8 stop=1 parity=n term=1"
SYS.Set "rs485-2", "baud=9600 data=8 stop=1 parity=n term=1"
start:
 ' read energy meter for household
 'LOCAL Uac1, Uac2, Uac3, Iac1, Iac2, Iac3, kW1, kW2, kW3, kWhI1, kWhI2, kWhI3, kWhE1, kWhE2, kWhE3, P
 err1%=EastronEnergyMeter("TCP:192.168.10.22:502",1, Uac1, Uac2, Uac3, Iac1, Iac2, Iac3, kW1, kW2, kW3, kWhI1, kWhI2, kWhI3, kWhE1, kWhE2, kWhE3) 
 err2%=EastronEnergyMeterP1("RTU:RS485:1",1, Uac, Iac, kW, kWhI, kWhE)

 if err1% >=0 and err2% >=0 THEN
  P=kW1+kW2+kW3
  IF P >= 0.0 THEN 
   PE=0.0
   PI=P
  ELSE
   PE=-P
   PI=0.0
  ENDIF
  meter_status$="Import:"+chr$(10)+ds_num$(err%,PI,"%.3f"," kW")+chr$(10)+"Export:"+chr$(10)+ds_num$(err%,PE,"%.3f"," kW")+chr$(10)
  PS=kW
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

 pause 1000
 goto start
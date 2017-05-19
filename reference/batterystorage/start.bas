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
 'LOCAL Uac1, Uac2, Uac3, Iac1, Iac2, Iac3, kW1, kW2, kW3, kWhI1, kWhI2, kWhI3, kWhE1, kWhE2, kWhE3, P
 err%=EastronEnergyMeterP1("RTU:RS485:1",1, Uac, Iac, kW, kWhI, kWhE)
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

 pause 1000
 goto start
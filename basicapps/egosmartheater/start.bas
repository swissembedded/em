' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2015-2016 swissEmbedded GmbH, All rights reserved.
' Ego smart heater control with excess energy over modbus TCP and RTU
' Set this value from energy meter measurement (e.g. S0 / D0 interface)
SYS.Set "rs485", "baud=19200 data=8 stop=1 parity=e"
kW=0.0
slv%=247
itf$="RS485:1"
start:
 EgoSmartHeater(itf$,slv%,kW,st%,T%,Tmax%)
 print "Ego " st% T% Tmax%
 pause 30000
 goto start

' Ego smart heater controller
' This function must be called at least every 60 seconds,
' otherwise the ego smart heater will switch off
' itf$ modbus interface (see EMDO modbus library for details)
' slv% ego smart heater slave address default 247, 
' kW home energy at energy meter neg. value = excess energy
' st% 1=500W on, 2=1000W on, 4=2000W on, e.g. 3=500+1000W
' T is the boiler temperature
' Tmax is the max boiler temperature set by external control
SUB EgoSmartHeater(itf$,slv%,kW,st%,T%,Tmax%)
 ' Read ManufacturerId, ProductId, ProductVersion, FirmwareVersion
 err%= mbFunc(itf$,slv%,3,&H2000,1,rmId$,500) OR mbFunc(itf$,slv%,3,&H2001,1,rpId$,500) 
 IF err% THEN
  print "Ego error on read" err%
  EXIT SUB
 ENDIF
 ' Check if Ego is known
 mId%=conv("bbe/u16",rmId$)
 pId%=conv("bbe/u16",rpId$)
 
 IF mId% = &H14ef AND pId% = &Hff37 THEN
  ' Power Regulation
  ' Set PowerNominalValue to -1 and HomeTotalPower power
  pNv$=conv("i16/bbe",-1)
  hTp$=conv("i32/bbe",kW*1000.0)
  err%=mbFunc(itf$,slv%,6,&H1300,1,pNv$,500) OR mbFunc(itf$,slv%,16,&H1301,2,hTp$,500)  
  IF err% THEN
   print "Ego error on write"
   EXIT SUB
  ENDIF
  ' Read ActualTemperaturBoiler,UserTemperaturNominalValue, RelaisStatus
  err%= mbFunc(itf$,slv%,3,&H1404,1,raT$,500) OR mbFunc(itf$,slv%,3,&H1407,1,ruT$,500) OR mbFunc(itf$,slv%,3,&H1408,1,rrS$,500)
  print err%
  IF err% THEN
   print "Ego error on write"
   EXIT SUB
  ENDIF 
  T%=conv("bbe/i16",raT$)
  Tmax%=conv("bbe/i16",ruT$)
  st%=conv("bbe/u16",rrS$) 
 ENDIF
END SUB

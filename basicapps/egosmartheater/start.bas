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
FUNC EgoSmartHeater(itf$,slv%,kW,st%,T,Tmax)
 ' Read ManufacturerId, ProductId, ProductVersion, FirmwareVersion
 err%= mbFuncRead(itf$,slv%,3,&H2000,1,rmId$,500) OR mbFuncRead(itf$,slv%,3,&H2001,1,rpId$,500) OR mbFuncRead(itf$,slv%,3,&H2002,1,rpV$,500) OR mbFuncRead(itf$,slv%,3,&H2003,1,rfV$,500)
 if err% then
  print "Ego error on read"
  exit func
 end if
 ' Check if Ego is known
 mId%=conv("bbe/i16",rmId$)
 pId%=conv("bbe/i16",rpId$)
 pV%=conv("bbe/i16",rpV$) 
 fV%=conv("bbe/i16",rfV$) 
 if mId% = &H14ef and pId% = &Hff37 and pV% = &Hebaf and fV% = &H0000 then
  ' Power Regulation
  ' Set PowerNominalValue to -1 and HomeTotalPower power
  pNv$=conv("i16/bbe",-1)
  hTp$=conv("i16/bbe",kW*1000.0)
  %err=mbFuncWrite(itf$,slv%,6,&H1300,1,pNv$,500) OR mbFuncWrite(itf$,slv%,6,&H1301,1,pNv$,500)
  if err% then
   print "Ego error on write"
   exit func
  end if
  ' Read ActualTemperaturBoiler,UserTemperaturNominalValue, RelaisStatus
  err%= mbFuncRead(itf$,slv%,3,&H1404,1,raT$,500) OR mbFuncRead(itf$,slv%,3,&H1407,1,ruT$,500) OR mbFuncRead(itf$,slv%,3,&H1408,1,rrS$,500)
  if err% then
   print "Ego error on write"
  exit func
  T%=conv("bbe/i16",raT$)
  Tmax%=conv("bbe/i16",ruT$)
  st%=conv("bbe/i16",rrS$) 
 end if  
END FUNC

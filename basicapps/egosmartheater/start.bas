' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2015-2016 swissEmbedded GmbH, All rights reserved.
' Ego smart heater control with excess energy over modbus TCP and RTU
' Set this value from energy meter measurement (e.g. S0 / D0 interface)
'SYS.Set "rs485", "baud=19200 data=8 stop=1 parity=e"
'kW=0.0
'slv%=247
'itf$="RS485:1"
'start:
' err%=EgoSmartHeater(itf$,slv%,kW,st%,T%,Tmax%)
' print "Ego " err% st% T% Tmax%
' pause 30000
' goto start

' Ego smart heater controller
' This function must be called at least every 60 seconds,
' otherwise the ego smart heater will switch off
' itf$ modbus interface (see EMDO modbus library for details)
' slv% ego smart heater slave address default 247, 
' kW home energy at energy meter neg. value = excess energy
' st% 1=500W on, 2=1000W on, 4=2000W on, e.g. 3=500+1000W
' T is the boiler temperature
' Tmax is the max boiler temperature set by external control
' return negative value on error
FUNCTION EgoSmartHeater(itf$,slv%,kW,st%,T%,Tmax%)
 LOCAL err%, rmId$, rpId$, raT$, ruT$,rrS$
 ' Read ManufacturerId, ProductId, ProductVersion, FirmwareVersion
 err%= mbFunc(itf$,slv%,3,&H2000,1,rmId$,500) OR mbFunc(itf$,slv%,3,&H2001,1,rpId$,500) 
 IF err% THEN
  EgoSmartHeater=err%
  EXIT FUNCTION
 ENDIF
 ' Check if Ego is known 
 IF conv("bbe/u16",rmId$) = &H14ef AND conv("bbe/u16",rpId$) = &Hff37 THEN
  ' Power Regulation
  ' Set PowerNominalValue to -1 and HomeTotalPower power
  err%=mbFunc(itf$,slv%,6,&H1300,1,conv("i16/bbe",-1),500) OR mbFunc(itf$,slv%,16,&H1301,2,conv("i32/bbe",kW*1000.0),500)  
  IF err% THEN
   EgoSmartHeater=err%
   EXIT FUNCTION
  ENDIF
  ' Read ActualTemperaturBoiler,UserTemperaturNominalValue, RelaisStatus
  err%= mbFunc(itf$,slv%,3,&H1404,1,raT$,500) OR mbFunc(itf$,slv%,3,&H1407,1,ruT$,500) OR mbFunc(itf$,slv%,3,&H1408,1,rrS$,500)
  IF err% THEN
   EgoSmartHeater=err%
   EXIT FUNCTION
  ENDIF 
  T%=conv("bbe/i16",raT$)
  Tmax%=conv("bbe/i16",ruT$)
  st%=conv("bbe/u16",rrS$) 
 ENDIF
 EgoSmartHeater=0
END FUNCTION

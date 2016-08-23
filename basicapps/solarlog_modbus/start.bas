' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2015-2016 swissEmbedded GmbH, All rights reserved.
' Solarlog 200,300,500,1000,1200,2000
' Documentation http://www.solar-log.uk/gb-en/service-support/downloads/manuals/united-kingdom.html 
' Firmware > Version 3 required
slv%=1
itf$="TCP:192.168.0.1:502"

start:
 SolarlogReader(itf$,slv%,lUp%, Pac%, Pdc%, Uac%, Udc%, dY%, ldY%, yY%,PacCon%, dYCon%, ldYCon%, mYCon%, yYCon%, tYCon%, tP%)
 print "Solarlog " lUp% Pac% Pdc% Uac% Udc% dY% ldY% mY% yY% PacCon% dYCon% ldYCon% mYCon% yYCon% tYCon% tP%
 pause 30000
 goto start

' Solarlog logger models 200,300,500,1000,1200,2000
' itf$ modbus interface (see EMDO modbus library for details)
' slv% solarlog slave address default 1 
' lUp% lastUpdate Unixtime
' Pac% AC power
' Pdc% DC power
' Uac% AC voltage
' Udc% DC voltage
' dY%  daily yield
' ldY% yesterday yield (last day)
' mY%  monthly yield
' yY%, yearly yield
' PacCon% AC power consumption
' dYCon%  daily yield consumption
' ldYCon% yesterday yield consumption (last day)
' mYCon%  monthly yield consumption
' yYCon%  yearly yield consumption
' tYCon%  total yield consumption
' tP%     total power [wh/Wp]
FUNC SolarlogReader(itf$,slv%,lUp%, Pac%, Pdc%, Uac%, Udc%, dY%, ldY%, mY%, yY%,PacCon%, dYCon%, ldYCon%, mYCon%, yYCon%, tYCon%, tP%)
 ' Page 251(appendix)
 err%= mbFuncRead(itf$,slv%,4,0,30,rD$,500)
 if err% then
  print "Solarlog error on read"
  exit func
 end if
 ' Convert register values to int32 and int16
 lUp%=conv("bbe/i32",mid$(rD$,1,4)
 Pac%=conv("bbe/i32",mid$(rD$,5,4)
 Pdc%=conv("bbe/i32",mid$(rD$,9,4)
 Uac%=conv("bbe/i16",mid$(rD$,13,4)
 Udc%=conv("bbe/i16",mid$(rD$,15,4)
 dY%=conv("bbe/i32",mid$(rD$,17,4)
 ldY%=conv("bbe/i32",mid$(rD$,21,4)
 mY%=conv("bbe/i32",mid$(rD$,25,4)
 yY%=conv("bbe/i32",mid$(rD$,29,4)
 PacCon%=conv("bbe/i32",mid$(rD$,33,4)
 dYCon%=conv("bbe/i32",mid$(rD$,37,4)
 ldYCon%=conv("bbe/i32",mid$(rD$,41,4)
 mYCon%=conv("bbe/i32",mid$(rD$,45,4)
 yYCon%=conv("bbe/i32",mid$(rD$,49,4)
 tYCon%=conv("bbe/i32",mid$(rD$,53,4)
 tP%=conv("bbe/i32",mid$(rD$,57,4)
END FUNC

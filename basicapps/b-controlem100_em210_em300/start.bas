' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2015-2016 swissEmbedded GmbH, All rights reserved.
' B-Control EM100, EM210, EM300 energy meter family EMDO modbus example
' Documentation can be found at
' http://www.b-control.com/fileadmin/Webdata/b-control/Uploads/Energiemanagement_PDF/B-control_Energy_Manager_Modbus_Master.0100.pdf
SYS.Set "rs485", "baud=19200 data=8 stop=1 parity=e"
slv%=247
itf$="RS485:1"

start:
 BControlEnergyMeter(itf$,slv%, kWI,kWE, kWhI, kWhE)
 print "B-Control " kWI kWE kWhI kWhE
 pause 30000
 goto start

' B-Control EM100, EM210, EM300 energy meter
' if$ modbus interface (see EMDO modbus library for details)
' slv% B-Control energy meter slave address default 247 
' kW1-3 up to three phase power with sign, negative = excess power to grid
' kWh1-3 up to three phase energy with sign, negative = excess energy to grid
FUNC BControlEnergyMeter(itf$,slv%, kWI,kWE, kWhI, kWhE)
 ' Read kW
 err%= mbFuncRead(itf$,slv%,3,0,2,rkWI$,500) OR mbFuncRead(itf$,slv%,3,2,2,rkWE$,500)
 if err% then
  print "Eastron error on read"
  exit func
 end if
 ' Convert register values to int32
 kWI=conv("bbe/i32",rkWI$)
 kWE=conv("bbe/i32",rkWE$)

 ' Read kWh
 err%= mbFuncRead(itf$,slv%,3,512,2,rkWhI$,500) OR mbFuncRead(itf$,slv%,3,516,2,rkWhE$,500)
 if err% then
  print "Eastron error on read"
  exit func
 end if
 ' Convert register values to int32
 kWhI=conv("bbe/i32",rkWhI$)
 kWhE=conv("bbe/i32",rkWhE$) 
END FUNC

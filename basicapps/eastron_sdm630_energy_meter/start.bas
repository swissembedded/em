' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2015-2016 swissEmbedded GmbH, All rights reserved.
' Eastron SDM630 energy meter EMDO modbus example

start:
 EastronEnergyMeter(if$,slv%,kW1,kW2,kW3, kWh1, kWh2, kWh3)
 print "Eastron " kW1 kW2 kW3 kWh1 kWh2 kWh3
 pause 30000
 goto start

' Eastron energy meter SDM630
' if$ modbus interface (see EMDO modbus library for details)
' slv% eastron energy meter sdm630 slave address default 1 
' kW1-3 up to three phase power with sign, negative = excess power to grid
' kWh1-3 up to three phase energy with sign, negative = excess energy to grid
FUNC EastronEnergyMeter(if$,slv%,kW1,kW2,kW3, kWh1, kWh2, kWh3)
 ' Read kW
 err%= mbFuncRead(if$,slv%,3,30013,1,rkW1$,500) OR mbFuncRead(if$,slv%,3,30015,1,rkW2$,500) OR mbFuncRead(if$,slv%,3,30017,1,rkW3$,500)
 if err% then
  print "Eastron error on read"
  exit func
 end if
 ' Convert register values to float32
 kW1=conv("bbe/f32",rkW1$)
 kW2=conv("bbe/f32",rkW2$)
 kW3=conv("bbe/f32",rkW3$) 

 ' Read kWh
 err%= mbFuncRead(if$,slv%,3,30359,1,rkWh1$,500) OR mbFuncRead(if$,slv%,3,30361,1,rkWh2$,500) OR mbFuncRead(if$,slv%,3,30363,1,rkWh3$,500)
 if err% then
  print "Eastron error on read"
  exit func
 end if
 ' Convert register values to float32
 kWh1=conv("bbe/f32",rkWh1$)
 kWh2=conv("bbe/f32",rkWh2$)
 kWh3=conv("bbe/f32",rkWh3$) 
END FUNC

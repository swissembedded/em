' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2015-2016 swissEmbedded GmbH, All rights reserved.
' Wattnode energy meter
' WNC-3Y-208-MB, WNC-3Y-400-MB, WNC-3Y-480-MB, WNC-3Y-600-MB
' WNC-3D-240-MB, WNC-3D-400-MB, WNC-3D-480-MB 
' EMDO modbus example
' Documentation somewhere in the internet
SYS.Set "rs485", "baud=9600 data=8 stop=1 parity=n"
slv%=1
itf$="RS485:1"

start:
 WattnodeEnergyMeter(itf$,slv%,kW, kWhI, kWhE)
 print "Wattnode " kW kWhI kWhE
 pause 30000
 goto start

' Wattnode energy meter WNC family
' itf$ modbus interface (see EMDO modbus library for details)
' slv% Wattnode energy meter slave address default 1 
' kW real power 
' kWhI energy imported from the grid
' kWhE energy exported to the grid
FUNC WattnodeEnergyMeter(itf$,slv%,kW, kWhI, kWhE)
 ' Read kW
 err%= mbFuncRead(itf$,slv%,3,1009,2,rkW$,500)
 if err% then
  print "Wattnode error on read"
  exit func
 end if
 ' Convert register values to float32
 kW=conv("bbe/f32",rkW$)

 ' Read kWh
 err%= mbFuncRead(itf$,slv%,3,1007,2,rkWhI$,500) OR mbFuncRead(itf$,slv%,3,1115,2,rkWhE$,500)
 if err% then
  print "Wattnode error on read"
  exit func
 end if
 ' Convert register values to float32
 kWhI=conv("bbe/f32",rkWhI$)
 kWhE=conv("bbe/f32",rkWhE$) 
END FUNC

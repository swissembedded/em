' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2015-2016 swissEmbedded GmbH, All rights reserved.
' Phoenix Contact EEM-MA250 (EEM-MA200 without modbus interface) energy meter EMDO modbus example
' See phoenix contact homepage at www.phoenixcontact.com under the product at the download section
SYS.Set "rs485", "baud=9600 data=8 stop=1 parity=n"
slv%=1
itf$="RS485:1"
start:
 PhoenixEnergyMeter(itf$,slv%,kW1,kW2,kW3, kWh1)
 print "Phoenix " kW1 kW2 kW3 kWh1
 pause 30000
 goto start

' Phoenix Contact energy meter EEM-MA250
' itf$ modbus interface (see EMDO modbus library for details)
' slv% Phoenix energy meter sdm630 slave address default 1 
' kW1-3 up to three phase power with sign, negative = excess power to grid
' kWh1-3 up to three phase energy with sign, negative = excess energy to grid
FUNC EastronEnergyMeter(itf$,slv%,kW1,kW2,kW3, kWh1)
 ' Read kW
 err%= mbFuncRead(itf$,slv%,3,50544,1,rkW1$,500) OR mbFuncRead(itf$,slv%,3,50545,1,rkW2$,500) OR mbFuncRead(itf$,slv%,3,50546,1,rkW3$,500)
 if err% then
  print "Eastron error on read"
  exit func
 end if
 ' Convert register values to float32
 kW1=conv("bbe/i16",rkW1$)/100.0
 kW2=conv("bbe/i16",rkW2$)/100.0
 kW3=conv("bbe/i16",rkW3$)/100.0

 ' Read kWh
 err%= mbFuncRead(itf$,slv%,3,50850,1,rkWh1$,500)
 if err% then
  print "Eastron error on read"
  exit func
 end if
 ' Convert register values to i16
 kWh1=conv("bbe/i16",rkWh1$)
END FUNC

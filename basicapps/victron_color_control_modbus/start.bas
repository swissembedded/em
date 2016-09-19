' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2015-2016 swissEmbedded GmbH, All rights reserved.
' Victron Color Control energy meter EMDO modbus example
' Documentation https://www.victronenergy.com/live/ccgx:modbustcp_faq
slv%=1
itf$="TCP:192.168.0.1"

start:
 err%=VictronColorCtlBattery(itf$,slv%,Ubat, Ibat, Tbat, Umid, SoC,SoH, Ech,Ed, Cc )
 print "Victron " err% Ubat Ibat Tbat Umid SoC SoH Ech Ed Cc
 pause 30000
 goto start

' Victron Color Control Modbus Reader Batterieparameters
' itf$ modbus interface (see EMDO modbus library for details)
' slv% Victron Color Control slave address
' Ubat Battery Voltage [V]
' Ibat Battery Current [V]
' Tbat Battery Temperature [°C]
' Umid Battery Midpoint Voltage [V]
' SoC  State of Charge [%]
' SoH  State of Health [%]
' Ech  Total energy charged [kWh]
' Ed   Total energy discharged [kWh]
' Cc   Charge Cycles
FUNC VictronColorCtlBattery(itf$,slv%,Ubat, Ibat, Tbat, Umid, SoC, SoH, Ech, Ed, Cc)
 Local rBat$
 ' Read registers 
 err%= mbFuncRead(itf$,slv%,3,259,46,rBat$,500)
 if err% then
  VictronColorCtlBattery=err%
  exit func
 end if 
 ' Convert register values
 ' Index (Register - 259)*2+1
 Ubat=conv("bbe/u16",mid$(rBat$,1,2))/100.0
 Ibat=conv("bbe/u16",mid$(rBat$,3,2))/100.0
 Tbat=conv("bbe/u16",mid$(rBat$,7,2))/10.0
 Umid=conv("bbe/u16",mid$(rBat$,9,2))/100.0
 SoC=conv("bbe/u16",mid$(rBat$,15,2))/10.0
 SoH=conv("bbe/u16",mid$(rBat$,91,2))/10.0
 Ech=conv("bbe/u16",mid$(rBat$,87,2))/10.0
 Ed=conv("bbe/u16",mid$(rBat$,85,2))/10.0
 Cc=conv("bbe/u16",mid$(rBat$,51,2))
 VictronColorCtlBattery=0
END FUNC

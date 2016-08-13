' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2015-2016 swissEmbedded GmbH, All rights reserved.
' Phoenix EV electric car charger with excess energy over modbus TCP and RTU
' Testet with Wallb-e Pro
SYS.Set "rs485", "baud=9600 data=8 stop=1 parity=n"
kW=0.0
slv%=180
if$="TCP:192.168.0.114:502"
start:
 PhoenixEV(if$,slv%,kW,st%)
 print "Phoenix " st% T
 pause 30000
 goto start
 
' Phoenix EV electric car charger controller
' This function must be called at least every 60 seconds,
' if$ modbus interface (see EMDO modbus library for details)
' slv% slave address of charger (default 180)
' kW home energy at energy meter neg. value = excess energy
' st% device status
FUNC PhoenixEV(if$,slv%,kW,st%)
 ' Read EV Status
 err%= mbFuncRead(slv$,3,&H100,8,reG$,500) OR mbFuncRead(slv$,2,&H200,8,reD$,500) OR mbFuncRead(slv$,3,&H300,2,reC$,500) OR mbFuncRead(slv$,1,&H400,16,reR$,500)
 if err% then
  print "EV error on read"
  exit func
 end if
 ' Status 
 eS$=mid$(reG$,2,1)
 ' Proximity charge current in A
 eP%=conv("bbe/i16",mid$(reG$,3,2))
 ' Charging time in s
 eT%=conv("bbe/i32",mid$(reG$,5,4))
 ' Firmware version e.g. 430 = 4.30
 eV%=conv("bbe/i32",mid$(reG$,11,4))
 ' Error code
 eE%=conv("bbe/i16",mid$(reG$,15,2))
 ' Discrete inputs 
 eD%=asc(left$(reD$,1)
 ' Charge current
 eC%=conv("bbe/i16",left$(reC$,2))
 ' Charge control register
 eR%=conv("bbe/i16",left$(reR$,2))
 select case eS$
  case "A"
   ' Charger is not connected to car
  case "B"
   ' Charger is connected to car
   ' or charging ended
  case "C"
   ' Charging without ventilation
  case "E"
   ' Charging with ventilation
  case "F"
   ' Missing proximity plug
   ' Or car stops charging
  case else  
   ' Unknown status
 end select
END FUNC
 
' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2015-2016 swissEmbedded GmbH, All rights reserved.
' Phoenix EV electric car charger with excess energy over modbus TCP and RTU
' Testet with Wallb-e Pro
'SYS.Set "rs485", "baud=9600 data=8 stop=1 parity=n term=1"
'kW=0.0
'slv%=180
'itf$="TCP:192.168.0.114:502"
'start:
' err%=PhoenixEV(itf$,slv%,kW,st%)
' print "Phoenix " err% st%
' pause 30000
' goto start
 
' Phoenix EV electric car charger controller
' This function must be called at least every 60 seconds,
' itf$ modbus interface (see EMDO modbus library for details)
' slv% slave address of charger (default 180)
' kW home energy at energy meter neg. value = excess energy
' st% device status
FUNCTION PhoenixEV(itf$,slv%,kW,st%)
 LOCAL err%, reG$, reD$, reC$, reR$
 ' Read EV Status
 err%= mbFunc(itf$,slv%,4,100,8,reG$,500) OR mbFunc(itf$,slv%,2,200,8,reD$,500) OR mbFunc(itf$,slv%,3,300,2,reC$,500) OR mbFunc(itf$,slv%,1,400,16,reR$,500)
 IF err% THEN
  PhoenixEV=err%
  EXIT FUNCTION
 ENDIF
 ' Status 
 eS$=mid$(reG$,2,1)
 ' Proximity charge current in A
 eP%=conv("bbe/u16",mid$(reG$,3,2))
 ' Charging time in s
 eT%=conv("bbe/u32",mid$(reG$,5,4))
 ' Firmware version e.g. 430 = 4.30
 eV%=conv("bbe/u32",mid$(reG$,11,4))
 ' Error code
 eE%=conv("bbe/u16",mid$(reG$,15,2))
 ' Discrete inputs 
 ' Enable, External Release, Lock Detection, Manual Lock, Charger Ready, Locking Request, Vehicle Ready, Error
 eD%=asc(left$(reD$,1))
 ' Charge current
 eC%=conv("bbe/u16",left$(reC$,2))
 ' Charge control register 
 ' Enable charge process, reuqest digital communication, manual charging available, manual locking
 ' Activate overcurrent shutdown
 ' "Voltage status A/B detected" - function activated
 ' "Status D, reject vehicle" function activated
 ' Reset charging controller
 ' Voltage in status A/B detected
 ' Status D, reject vehilce
 ' Configuration of input ML
 eR%=conv("ble/u16",left$(reR$,2))
 enaD%=eD% and 1 ' Enable
 xrD%=eD% and 2 ' External release
 ldD%=eD% and 4 ' Lock detection
 mlD%=eD% and 8 ' Manual lock
 crD%=eD% and 16 ' Charger Ready
 lrD%=eD% and 32 ' Locking Request
 vrD%=eD% and 64 ' Vehicle Ready
 erD%=eD% and 128 ' Error
 enR%=eR% and 1 ' Enable charge process
 rdcR%=eR% and 2 ' Request digital communication
 csaR%=eR% and 4 ' Charging station available
 mlR%=eR% and 8 ' Manual locking
 aosR%=eR% and 512 ' Activate overcurrent shutdown
 ' Request charging
 
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
 PhoenixEV=0
END FUNCTION
' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2015-2016 swissEmbedded GmbH, All rights reserved.
' Stiebel Eltron Wärmepumpe (Heat Pump) Modbus TCP ISG EMDO modbus example
' Documentation available from manufacturer (ask support)
slv%=1
itf$="TCP:192.168.0.1:502"

start:
 StiebelEltronGetMode(itf$,slv%,mode%)
 'StiebelEltronSetMode(itf$,slv%,mode%)
 print "StiebelEltron " mode%
 StiebelEltronGetTempHeating(itf$,slv%,Tcom1, Teco1, Tcom2, Teco2)
 print "StiebelEltron " Tcom1 Teco1 Tcom2 Teco2
 StiebelEltronGetTempWater(itf$,slv%,Tcom, Teco)
 print "StiebelEltron " Tcom Teco
 pause 30000
 goto start

' Stiebel Eltron Get Operation Mode
' itf$ modbus interface (see EMDO modbus library for details)
' slv% heat pump slave address default 1 
' mode Betriebsart (Operation mode) of the heatpump 
'  0 = Notbetrieb 
'  1= Bereitschaftsbetrieb
'  2= Programmbetrieb
'  3= Komfortbetrieb
'  4= Eco-Betrieb
'  5= Warmwasserbetrieb 
FUNC StiebelEltronGetMode(itf$,slv%,mode%)
 ' Read mode
 err%= mbFunc(itf$,slv%,3,1501,1,rMode$,500)
 StiebelEltronGetMode=err%
 if err% then
  print "StiebelEltron error on read"
  exit func
 end if
 ' Convert register values
 mode%=conv("bbe/u16",rMode$)
END FUNC

' Stiebel Eltron Set Operation Mode
' itf$ modbus interface (see EMDO modbus library for details)
' slv% heat pump slave address default 1 
' mode Betriebsart (Operation mode) of the heatpump 
'  0 = Notbetrieb 
'  1= Bereitschaftsbetrieb
'  2= Programmbetrieb
'  3= Komfortbetrieb
'  4= Eco-Betrieb
'  5= Warmwasserbetrieb 
FUNC StiebelEltronSetMode(itf$,slv%,mode%)
 ' Write mode
 ' Convert register values to float32
 rMode$=conv("u16/bbe",mode$)
 err%= mbFunc(itf$,slv%,6,1501,1,rMode$,500)
 StiebelEltronSetMode=err%
 if err% then
  print "StiebelEltron error on read"
  exit func
 end if 
END FUNC

' Stiebel Eltron Get Heating Temperatures
' itf$ modbus interface (see EMDO modbus library for details)
' slv% heat pump slave address default 1 
' Tcom1 Komfort Temperatur Heizkreis 1 
' Teco1  Eco Temperatur Heizkreis 1
' Tcom2 Komfort Temperatur Heizkreis 2 
' Teco2  Eco Temperatur Heizkreis 2
FUNC StiebelEltronGetTempHeating(itf$,slv%,Tcom1, Teco1, Tcom2, Teco2)
 ' Read Temperatures
 err%= mbFunc(itf$,slv%,3,1502,1,rTcom1$,500) OR mbFunc(itf$,slv%,3,1503,1,rTeco1$,500) OR mbFunc(itf$,slv%,3,1505,1,rTcom2$,500) OR mbFunc(itf$,slv%,3,1506,1,rTeco2$,500)
 StiebelEltronGetTempHeating=err%
 if err% then
  print "StiebelEltron error on read"
  exit func
 end if
 ' Convert register values
 Tcom1=conv("bbe/i16",rTcom1$)/100.0
 Teco1=conv("bbe/i16",rTeco1$)/100.0
 Tcom2=conv("bbe/i16",rTcom2$)/100.0
 Teco2=conv("bbe/i16",rTeco2$)/100.0
END FUNC

' Stiebel Eltron Set Heating Temperatures
' itf$ modbus interface (see EMDO modbus library for details)
' slv% heat pump slave address default 1 
' Tcom1 Komfort Temperatur Heizkreis 1 
' Teco1  Eco Temperatur Heizkreis 1
' Tcom2 Komfort Temperatur Heizkreis 2 
' Teco2  Eco Temperatur Heizkreis 2
FUNC StiebelEltronSetTempHeating(itf$,slv%,Tcom1, Teco1, Tcom2, Teco2)
 ' Write Temperatures
 ' Convert register values
 rTcom1$=conv("bbe/i16",Tcom1*100.0)
 rTeco1$=conv("bbe/i16",Teco1*100.0)
 rTcom2$=conv("bbe/i16",Tcom2*100.0)
 rTeco2$=conv("bbe/i16",Teco2*100.0)
 err%= mbFunc(itf$,slv%,6,1502,1,rTcom1$,500) OR mbFunc(itf$,slv%,6,1503,1,rTeco1$,500) OR mbFunc(itf$,slv%,6,1505,1,rTcom2$,500) OR mbFunc(itf$,slv%,3,1506,1,rTeco2$,500)
 StiebelEltronSetTempHeating=err%
 if err% then
  print "StiebelEltron error on read"
  exit func
 end if
END FUNC

' Stiebel Eltron Get Water Temperatures
' itf$ modbus interface (see EMDO modbus library for details)
' slv% heat pump slave address default 1 
' Tcom Komfort Temperatur Warmwasser 
' Teco  Eco Temperatur Warmwasser
FUNC StiebelEltronGetTempWater(itf$,slv%,Tcom, Teco)
 ' Read Temperatures
 err%= mbFunc(itf$,slv%,3,1510,1,rTcom$,500) OR mbFunc(itf$,slv%,3,1511,1,rTeco$,500)
 StiebelEltronGetTempWater=err%
 if err% then
  print "StiebelEltron error on read"
  exit func
 end if
 ' Convert register values
 Tcom=conv("bbe/i16",rTcom$)/100.0
 Teco=conv("bbe/i16",rTeco$)/100.0
END FUNC

' Stiebel Eltron Set Water Temperatures
' itf$ modbus interface (see EMDO modbus library for details)
' slv% heat pump slave address default 1 
' Tcom Komfort Temperatur Warmwasser 
' Teco  Eco Temperatur Warmwasser
FUNC StiebelEltronSetTempWater(itf$,slv%,Tcom, Teco)
 ' Write Temperatures
 ' Convert register values
 rTcom$=conv("bbe/i16",Tcom*100.0)
 rTeco$=conv("bbe/i16",Teco*100.0)
 err%= mbFunc(itf$,slv%,6,1510,1,rTcom1$,500) OR mbFunc(itf$,slv%,6,1511,1,rTeco1$,500)
 StiebelEltronSetTempWater=err%
 if err% then
  print "StiebelEltron error on read"
  exit func
 end if
END FUNC


' Copy Modbus library goes here
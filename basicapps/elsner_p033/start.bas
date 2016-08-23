' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2015-2016 swissEmbedded GmbH, All rights reserved.
' Elsner P03/3 Modbus Weatherstation
' Documentation http://www.elsner-elektronik.de/shop/de/produkte-shop/gebaeudetechnik-konventionell/modbus-sensoren/p03-3-modbus-398.html
SYS.Set "rs485", "baud=19200 data=8 stop=1 parity=n"
slv%=1
itf$="RS485:1"

start:
 ElsnerWeatherstation(itf$,slv%,Tout,SunS%,SunW%, SunE%, Lgt%, Wind, Rain%)
 print "Elsner " Tout SunS% SunW% SunE% Lgt% Wind Rain%
 pause 30000
 goto start

' Elsner weather station P03/3
' itf$ modbus interface (see EMDO modbus library for details)
' slv% elsner energy meter sdm630 slave address default 1 
' Tout outside temperature
' SunS% sun sensor south 1..99 kilolux
' SunW% sun sensor west 1..99 kilolux
' SunE% sun sensor east 1..99 kilolux
' Lgt% light 0...999lux
' Wind wind m/s
' Rain% 1=raining 0=no rain
FUNC EastronEnergyMeter(itf$,slv%,Tout,SunS%,SunW%, SunE%, Lgt%, Wind, Rain%)
 ' Page 12 german documentation
 err%= mbFuncRead(itf$,slv%,3,0,7,rD$,500)
 if err% then
  print "Elsner error on read"
  exit func
 end if
 ' Convert register values to int16
 Tout=conv("bbe/i16",mid$(rD$,0,2)/10.0
 SunS%=conv("bbe/i16",mid$(rD$,2,2)
 SunW%=conv("bbe/i16",mid$(rD$,4,2)
 SunE%=conv("bbe/i16",mid$(rD$,6,2)
 Lgt%=conv("bbe/i16",mid$(rD$,8,2)
 Wind=conv("bbe/i16",mid$(rD$,10,2)/10.0
 Rain%=asc(mid$(rD$,13,1)) AND 1
END FUNC

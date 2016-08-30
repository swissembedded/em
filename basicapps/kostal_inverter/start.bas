' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2015-2016 swissEmbedded GmbH, All rights reserved.
' Kostal Inverter EMDO modbus example
' Documentation available from Kostal (NDA required)
' 20.3.2014
addr%=255
server$="192.168.1.1"
start:
 err%=KostalVoltageCurrentPower(server$,addr%, timeout%, Udc1, Idc1, Pdc1, Udc2, Idc2, Pdc2, Udc3, Idc3, Pdc3, Uac1, Iac1, Pac1, Uac2, Iac2, Pac2, Uac3, Iac3, Pac3)
 print "Kostal " err% Udc1 Idc1 Pdc1 Udc2 Idc2 Pdc2 Udc3 Idc3 Pdc3 Uac1 Iac1 Pac1 Uac2 Iac2 Pac2 Uac3 Iac3 Pac3
 err%=KostalTotalEnergy(server$, timeout%, kWh)
 print "Kostal " err% kWh
 err%=KostalStatus(server$, timeout%, status%, fault%, code%)
 print "Kostal " err% status%, fault%, code%
 err%=KostalName(server$, timeout%, iName$)
 print "Kostal " err% iName$
 err%=KostalSerialOld(server$, timeout%, iSerial$)
 print "Kostal " err% iSerial$
 err%=KostalSerial(server$, timeout%, iSerial$)
 print "Kostal " err% iSerial$
 err%=KostalDailyEnergy(server$, timeout%, kWh)
 print "Kostal " err% kWh
 err%=KostalPropertiesOld(server$, timeout%, sNum%, pNum%)
 print "Kostal " err% sNum% pNum%
 err%=KostalProperties(server$, timeout%, tDe$,sNum%, pNum%, pC%)
 print "Kostal " err% tDe$ sNum% pNum% pC%
 err%=KostalAnalog(server$, timeout%, aNa1, aNa2, aNa3, aNa4)
 print "Kostal " err% aNa1 aNa2 aNa3 aNa4
 err%=KostalFeedin(server$, timeout%, Tfeed%)
 print "Kostal " err% Tfeed%

 pause 30000
 goto start

' Kostal inverter reading voltage, current power
' Server$  IP address of the inverter
' Addr%    inverter address 
' Timeout% timeout in ms
' Udc1-3   voltage string 1-3
' Idc1-3   current string 1-3
' Putdc1-3 power string 1-3
' Uac1-3   voltage phase 1-3
' Iac1-3   current phase 1-3
' Putac1-3 power phase 1-3
FUNCTION KostalVoltageCurrentPower(server$,addr%, timeout%, Udc1, Idc1, Pdc1, Udc2, Idc2, Pdc2, Udc3, Idc3, Pdc3, Uac1, Iac1, Pac1, Uac2, Iac2, Pac2, Uac3, Iac3, Pac3)
 LOCAL err%, rp$
 err%=KostalTransfer(server$, addr%, timeout%, &H43, 73, rp$)
 IF err% =0 THEN
  Udc1=conv("ble/i16",mid$(rp$,6,2))/10.0
  Idc1=conv("ble/i16",mid$(rp$,8,2))/100.0
  Pdc1=conv("ble/i16",mid$(rp$,10,2))
  Udc2=conv("ble/i16",mid$(rp$,16,2))/10.0
  Idc2=conv("ble/i16",mid$(rp$,18,2))/100.0
  Pdc2=conv("ble/i16",mid$(rp$,20,2))
  Udc3=conv("ble/i16",mid$(rp$,26,2))/10.0
  Idc3=conv("ble/i16",mid$(rp$,28,2))/100.0
  Pdc3=conv("ble/i16",mid$(rp$,30,2))
  Uac1=conv("ble/i16",mid$(rp$,36,2))/10.0
  Iac1=conv("ble/i16",mid$(rp$,38,2))/100.0
  Pac1=conv("ble/i16",mid$(rp$,40,2))
  Uac2=conv("ble/i16",mid$(rp$,44,2))/10.0
  Iac2=conv("ble/i16",mid$(rp$,46,2))/100.0
  Pac2=conv("ble/i16",mid$(rp$,48,2))
  Uac3=conv("ble/i16",mid$(rp$,52,2))/10.0
  Iac3=conv("ble/i16",mid$(rp$,54,2))/100.0
  Pac3=conv("ble/i16",mid$(rp$,56,2))
 ENDIF 
 KostalVoltageCurrentPower=err% 
END FUNCTION

' Kostal inverter reading total energy
' server$  IP address of the inverter
' addr%    Inverter address 
' timeout% Timeout in ms
' kWh      Inverter Total Energy
FUNCTION KostalTotalEnergy(server$, timeout%, kWh)
 LOCAL err%, rp$
 err%=KostalTransfer(server$, addr%, timeout%, &H45, 73, rp$)
 IF err% =0 THEN
  kWh=conv("ble/i32",mid$(rp$,6,4))/1000.0
 ENDIF 
 KostalTotalEnergy=err%  
END FUNCTION

' Kostal inverter status
' server$  IP address of the inverter
' addr%    Inverter Address 
' timeout% Timeout in ms
' status%  Status of the Inverter
'          0 = Off
'          1 = Idling
'          2 = Starting
'          3 = Feed-in MPP
'          4 = Regulated feed-in
'          5 = Feed-in
' fault%   Inverter fault
'          0 = no fault
'          not 0 fault
' code%    Fault code (only valid if fault% is non zero) 
FUNCTION KostalStatus(server$, timeout%, status%, fault%, code%)
 LOCAL err%, rp$
 err%=KostalTransfer(server$, addr%, timeout%, &H57, 15, rp$)
 IF err% =0 THEN
  status%=asc(mid$(rp$,6,1))
  fault% = asc(mid$(rp$,7,1))
  code% = conv("ble/i16", mid$(rp$,8,2))
 ENDIF 
 KostalStatus=err%  
END FUNCTION

' Kostal inverter reading name
' server$  IP address of the inverter
' addr%    Inverter Address 
' timeout% Timeout in ms
' iName$   Inverter Name
FUNCTION KostalName(server$, timeout%, iName$)
 LOCAL err%, rp$
 err%=KostalTransfer(server$, addr%, timeout%, &H44, 22, rp$)
 IF err% =0 THEN
  iName$=mid$(rp$,6,15)
 ENDIF 
 KostalName=err%  
END FUNCTION

' Kostal inverter serial number (old encoding < version 3.5)
' server$  IP address of the inverter
' addr%    Inverter Address 
' timeout% Timeout in ms
' iSerial$   Inverter Name
FUNCTION KostalSerialOld(server$, timeout%, iSerial$)
 LOCAL err%, rp$
 err%=KostalTransfer(server$, addr%, timeout%, &H50, 12, rp$)
 IF err% =0 THEN
  iSerial$=hex$(asc(mid$(rp$,6,1)))+left$(hex$(asc(mid$(rp,8,1))),1)+hex$(asc(mid$(rp$,7,1)))+hex$(asc(mid$(rp$,10,1)))+hex$(asc(mid$(rp$,9,1)))
 ENDIF 
 KostalSerialOld=err%  
END FUNCTION

' Kostal inverter serial number (new encoding >= version 3.5)
' server$  IP address of the inverter
' addr%    Inverter Address 
' timeout% Timeout in ms
' iSerial$   Inverter Name
FUNCTION KostalSerial(server$, timeout%, iSerial$)
 LOCAL err%, rp$
 err%=KostalTransfer(server$, addr%, timeout%, &H50, 20, rp$)
 IF err% =0 THEN
  iSerial$=mid$(rp$,6,13))
 ENDIF 
 KostalSerial=err%  
END FUNCTION

' Kostal inverter daily energy
' server$  IP address of the inverter
' addr%    Inverter Address 
' timeout% Timeout in ms
' kWh      Daily Energy
FUNCTION KostalDailyEnergy(server$, timeout%, kWh)
 LOCAL err%, rp$
 err%=KostalTransfer(server$, addr%, timeout%, &H9D, 11, rp$)
 IF err% =0 THEN
  kWh=conv("ble/i32",mid$(rp$,6,4))/1000.0
 ENDIF 
 KostalDailyEnergy=err%  
END FUNCTION

' Kostal inverter properties (old encoding version < 4.0) 
' server$  IP address of the inverter
' addr%    Inverter Address 
' timeout% Timeout in ms
' sNum%    Number of Strings
' pNum%    Number of AC Phases
FUNCTION KostalPropertiesOld(server$, timeout%, sNum%, pNum%)
 LOCAL err%, rp$
 err%=KostalTransfer(server$, addr%, timeout%, &H90, 31, rp$)
 IF err% =0 THEN
  sNum%=asc(mid$(rp$,22,1))
  pNum%=asc(mid$(rp$,29,1))
 ENDIF 
 KostalPropertiesOld=err%  
END FUNCTION

' Kostal inverter properties (encoding version >= 4.0) 
' server$  IP address of the inverter
' addr%    Inverter Address 
' timeout% Timeout in ms
' tDe$     Type Designator
' sNum%    Number of Strings
' pNum%    Number of AC Phases
' pC%      Performance category (Watt)
FUNCTION KostalProperties(server$, timeout%, tDe$,sNum%, pNum%, pC%)
 LOCAL err%, rp$
 err%=KostalTransfer(server$, addr%, timeout%, &H90, 35, rp$)
 IF err% =0 THEN
  tDe$=mid$(rp,6,16)
  pNum%=asc(mid$(rp$,22,1))
  sNum%=asc(mid$(rp$,28,1))
  pNum%=conv("ble/i32",mid$(rp$,29,4))
 ENDIF 
 KostalProperties=err%  
END FUNCTION

' Kostal inverter analog input 
' server$  IP address of the inverter
' addr%    Inverter Address 
' timeout% Timeout in ms
' aNa1     Analog Input 1
' aNa2     Analog Input 2
' aNa3     Analog Input 3
' aNa4     Analog Input 4
FUNCTION KostalAnalog(server$, timeout%, aNa1, aNa2, aNa3, aNa4)
 LOCAL err%, rp$
 err%=KostalTransfer(server$, addr%, timeout%, &H6A, 15, rp$)
 IF err% =0 THEN
  aNa1=conv("ble/i16",mid$(rp$,8,2))*10.0/1023.0
  aNa2=conv("ble/i16",mid$(rp$,10,2))*10.0/1023.0
  aNa3=conv("ble/i16",mid$(rp$,12,2))*10.0/1023.0
  aNa4=conv("ble/i16",mid$(rp$,14,2))*10.0/1023.0
 ENDIF 
 KostalAnalog=err%  
END FUNCTION

' Kostal inverter feedin 
' server$  IP address of the inverter
' addr%    Inverter Address 
' timeout% Timeout in ms
' Tfeed%   Feed-in time of the inverter
FUNCTION KostalFeedin(server$, timeout%, Tfeed%)
 LOCAL err%, rp$
 err%=KostalTransfer(server$, addr%, timeout%, &H46, 11, rp$)
 IF err% =0 THEN
  Tfeed%=conv("ble/i32",mid$(rp$,6,4))
 ENDIF 
 KostalFeedin=err%  
END FUNCTION

' Kostal inverter data transfer
' server$ IP address of the inverter
' addr%    inverter address 
' timeout% timeout in ms
' magic%   magic command byte
' rpl%     inverter expected response length
' rp$      inverter response
' return   < 0 on error 
FUNCTION KostalTransfer(server$, addr%, timeout%, magic%, rpl%, rp$)
 LOCAL con%, n%
 ' Open connection to the inverter
 con%=SocketClient( 1, server$, 81 )    
 IF con% <=0 THEN
  ' no connection
  KostalTransfer=con%-1
  EXIT FUNCTION
 ENDIF 
 n%=SocketOption(con%,"SO_RCVTIMEO",timeout%)
 n%=SocketOption(con%,"SO_SNDTIMEO",timeout%)    
	
 n%=SocketWrite( con%, &H62, addr%, 3, addr%, 0, magic, (0-(&H65+magic%+(2*addr%))) AND 255 , 0)
 rp$=SocketRead(con%,rpl%)
 IF len(rsp$) <> rpl% then
  KostalTransfer=-1
  EXIT FUNCTION
 ENDIF
 n%=SocketClose( con% )  
END FUNCTION


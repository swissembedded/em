' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2015-2016 swissEmbedded GmbH, All rights reserved.
' Mastervolt Inverter EMDO modbus example
' Documentation not available from manufacturer, but from internet.
' Best see https://github.com/teding/SolaDin
SYS.Set "rs485", "baud=9600 data=8 stop=1 parity=n term=1"
start:
 err%=MastervoltProbe(slv%)
 print "Soladin " err% slv%
 err%=MastervoltInfo(slv%,iId%,iVer%,iDate%)
 print "Soladin " err% slv% iId% iVer% iDate%
 err%=MastervoltStatistic(slv%, iFlags%, Udc, Idc, Fac, Uac, Pac, Eac, Td, Top)
 print "Soladin " err% iFlags% Udc Idc Fac Uac Pac Eac Td Top
 err%=MastervoltMaxPower(slv%,Pac)
 print "Soladin " err% Pac
 'err%=MastervoltResetMaxPower(slv%)
 err%=MastervoltHistory(slv%,0,Eac, Top)
 print "Soladin " err% Eac Top
 pause 30000
 goto start

' Mastervolt Soladin inverter probe
' addr%    Inverter address 
' return   < 0 on error
' TX: 00 00 00 00 C1 00 00 00 C1
' RX: 00 00 11 00 C1 F3 00 00 C5
FUNCTION MastervoltProbe(addr%)
 LOCAL err%, rsp$ 
 err%=MastervoltTransfer(0,0, &HC1, 9, rsp$)
 IF err% <0 THEN
  MastervoltProbe=err% 
  EXIT FUNCTION
 ENDIF 
 ' No clue about multiple devices on the bus
 addr%=conv("ble/u16",mid$(rsp$,3,2))
 MastervoltProbe=0
END FUNCTION

' Mastervolt Soladin firmware info
' addr%    Inverter address 
' iId%     Firmware Id
' iVer%    Firmware Version
' iDate%   Firmware Date
' return   < 0 on error
' TX: 11 00 00 00 B4 00 00 00 C5
' RX: 00 00 11 00 B4 F3 00 00 00 00 00 00 00 E3 00 04 01 34 06 00 00 00 00 00 00 00 00 00 00 00 DA
FUNCTION MastervoltInfo(addr%, iId%, iVer%, iDate%)
 LOCAL err%, rsp$ 
 err%=MastervoltTransfer(addr%,0, &HB4, 31, rsp$)
 IF err% <0 THEN
  MastervoltInfo=err% 
  EXIT FUNCTION
 ENDIF 
 iId%=conv("ble/u16",mid$(rsp$,14,2))
 iVer%=conv("ble/u16",mid$(rsp$,16,2))
 iDate%=conv("ble/u16",mid$(rsp$,18,2))
 MastervoltInfo=0
END FUNCTION

' Mastervolt Soladin Device Statistic
' addr%    Inverter address 
' iFlags%  Inverter flags
'          1=Udc too high
'          2=Udc too low
'          4=No grid
'          8=Uac too high
'       &H10=Uac too low
'       &H20=Frequency AC too high
'       &H40=Frequency AC too low
'       &H80=Temperature too high
'      &H100=Hardware failure
'      &H200=Starting
'      &H400=Max power (limit)
'      &H800=Max current (limit)
' Udc      Inverter DC voltage
' Idc      Inverter DC current
' Fac      Grid AC frequency
' Uac      Inverter AC voltage
' Pac      Inverter AC power [kW]
' Eac      Inverter AC Energy [kWh]
' Td       Inverter Device Temperature
' Top      Operation time [hours]
' return   < 0 on error
TX: 11 00 00 00 B6 00 00 00 C7
RX: 00 00 11 00 B6 F3 00 00 04 03 35 00 8A 13 F4 00 00 00 24 00 90 0B 00 1F DB BC 01 00 00 00 FD
FUNCTION MastervoltStatistic(addr%, iFlags%, Udc, Idc, Fac, Uac, Pac, Eac, Td, Top)
 LOCAL err%, rsp$ 
 err%=MastervoltTransfer(addr%,0, &HB6, 31, rsp$)
 IF err% <0 THEN
  MastervoltStatistic=err% 
  EXIT FUNCTION
 ENDIF 
 iFlags%=conv("ble/u16",mid$(rsp$,7,2))
 Udc=conv("ble/u16",mid$(rsp$,9,2))/10.0
 Idc=conv("ble/u16",mid$(rsp$,11,2))/100.0
 Fac=conv("ble/u16",mid$(rsp$,13,2))/100.0
 Uac=conv("ble/u16",mid$(rsp$,15,2))
 Pac=conv("ble/u16",mid$(rsp$,19,2))/1000.0
 Eac=conv("ble/u32",mid$(rsp$,21,3)+chr$(0))*100.0
 Td=asc(mid$(rsp$,24,1))
 Top=conv("ble/u16",mid$(rsp$,25,4))/60.0
 MastervoltStatistic=0
END FUNCTION

' Mastervolt Soladin Read Maximum Power
' addr%    Inverter address 
' Pac     Inverter maximum power [kW]
' return   < 0 on error
' TX: 11 00 00 00 B9 00 00 CA
' RX: 00 00 11 00 B9 F3 00 00 20 00 00 00 1B 00 21 00 22 00 00 00 E5 02 7E 48 36 00 00 00 00 00 1E
FUNCTION MastervoltMaxPower(addr%, Pac)
 LOCAL err%, rsp$ 
 err%=MastervoltTransfer(addr%,0, &HB9, 31, rsp$)
 IF err% <0 THEN
  MastervoltMaxPower=err% 
  EXIT FUNCTION
 ENDIF 
 Pac%=conv("ble/u16",mid$(rsp$,25,2)) / 1000.0
 MastervoltMaxPower=0
END FUNCTION

' Mastervolt Soladin Reset Maximum Power
' addr%    Inverter address 
' return   < 0 on error
' TX: 11 00 00 00 97 01 00 00 A9
' RX: 00 00 11 00 97 01 00 00 A9
FUNCTION MastervoltResetMaxPower(addr%)
 LOCAL err%, rsp$ 
 err%=MastervoltTransfer(addr%,0, &H97, 9, rsp$)
 IF err% <0 THEN
  MastervoltResetMaxPower=err% 
  EXIT FUNCTION
 ENDIF 
 MastervoltResetMaxPower=0
END FUNCTION

' Mastervolt Soladin History Data
' addr%    Inverter address
' dHist%   History, 0=today, 1=yesterday...9=9days before today
' Eac      Energie Production (kWh)
' Top      Daily operation time (hours) 
' return   < 0 on error
' TX: 11 00 00 00 9A 00 00 AB
' RX: 00 00 11 00 9A 54 05 04
FUNCTION MastervoltHistory(addr%,dHist%,Eac, Top)
 LOCAL err%, rsp$ 
 err%=MastervoltTransfer(addr%,0, &H9A+(dHist%*256), 8, rsp$)
 IF err% <0 THEN
  MastervoltHistory=err% 
  EXIT FUNCTION
 ENDIF 
 Top=asc(mid$(rsp$,5,1))*5.0/60.0
 Eac=conv("ble/u16",mid$(rsp$,6,2)) * 100.0
 MastervoltHistory=0
END FUNCTION

' Mastervolt Soladin data transfer
' sAddr% Source Address (typically 0)
' dAddr% Destination Address
' cmd%   Command
' rspl%  Expected Response Length
' rsp$   Data Response
FUNCTION MastervoltTransfer(sAddr%, dAddr%, cmd%,rspl%, rsp$)
 LOCAL n%,dta%,s%,i
 ' Send it over rs485    
 DO WHILE RS485Read(1,0) >=0
 LOOP
 dta$=conv("u16/ble",sAddr%)+conv("u16/ble",dAddr%)+conv("u16/ble",cmd%)+chr$(0)
 ' Some commands are 8 some are 9 bytes long
 IF cmd%=&HC1 OR cmd%=&HB4 OR cmd%=B6 THEN
  dta$=dta$+chr$(0)
 ENDIF
 s%=0
 for i=1 to len(dta$)
  s%=s%+asc(mid$(dta$,i,1))
 next i
 dta$=dta$+chr$(s% and 255)
 n%=RS485Write(dta$)
 rsp$=RS485Read$(rpl%,1000)  
 IF len(rsp$) <> rspl% THEN
  MastervoltTransfer=-1
  EXIT FUNCTION
 ENDIF
 ' 6 character is always F3
 IF asc(mid$(rsp$,6,1))<>&HF3 THEN
  MastervoltTransfer=-2
  EXIT FUNCTION
 ENDIF
 ' Checksumm correct?
 s%=0
 for i=1 to (rspl%-1)
  s%=s%+asc(mid$(rsp$,i,1))
 next i
 IF (chr$(s% AND 255)!=mid$(rsp$,rspl%,1)) THEN
  MastervoltTransfer=-3
  EXIT FUNCTION
 ENDIF
 ' source address correct?
 IF (conv("u16/ble",sAddr%)<>mid$(rsp$,1,2)) THEN
  MastervoltTransfer=-4
  EXIT FUNCTION
 ENDIF
 ' destination address correct and not broadcast (0)?
 IF (conv("u16/ble",dAddr%)<>mid$(rsp$,3,2)) AND (dAddr%<>0) THEN
  MastervoltTransfer=-5
  EXIT FUNCTION
 ENDIF 
 ' commando correct?
 IF asc(mid$(rsp$,5,1))<>cmd% THEN
  MastervoltTransfer=-6
  EXIT FUNCTION
 ENDIF  
 MastervoltTransfer=0
END FUNCTION


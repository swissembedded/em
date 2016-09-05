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
 addr%=conv("bbe/u16",mid$(rsp$,3,2))
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
 ' No clue about multiple devices on the bus
 iId%=conv("bbe/u16",mid$(rsp$,14,2))
 iVer%=conv("bbe/u16",mid$(rsp$,16,2))
 iDate%=conv("bbe/u16",mid$(rsp$,18,2))
 MastervoltInfo=0
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
 dta$=conv("u16/ble",sAddr%)+conv("u16/ble",dAddr%)+chr$(cmd%)+chr$(0)+chr$(0)+chr$(0)
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


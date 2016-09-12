' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2015-2016 swissEmbedded GmbH, All rights reserved.
' GMDE hybrid inverter data communication protocol
' Documentation available from manufacturer
SYS.Set "rs485", "baud=9600 data=8 stop=1 parity=n"
slv%=1
itf$="RS485:1"

start:
pause 30000
goto start

' GMDE Data Transfer
' itf$  Interface with string.Example "RS485:1" or "192.168.0.1:90"
' sAddr%  Source Address
' dAddr%  Destination Address
' cc%     Control Code
        0=Register
  		  1=Read
  		  2=Write
  		  3=Execute
' fnc%    Function Code
' dta$    Data
' rsp$    Response (framing, crc removed)
' tmo%    Timeout
FUNCTION GMDETransfer(itf$, sAddr%, dAddr%, cc%, fnc%, dta$, rsp$, tmo%)
LOCAL interf$, num$, msg$, s%, i, req$, n%, ln%
interf$=split$(0,itf$,":")
num$=split$(1,itf$,":")
' Header, src address, dst address, control code, function code, data, checksum 16 bit
msg$=chr$(&HAA)+chr$(&HAA)+conv("u16/bbe",sAddr%)+conv("u16/bbe",dAddr%)+chr$(cc%)+chr$(fnc%)+chr$(LEN(dta$))+dta$
' Checksum is simple sum
s%=0
for i=1 to len(msg$)
  s%=s%+asc(mid$(msg$,i,1))
next i
req$=msg$+conv("u16/bbe",s%)

IF interf$="RS485" THEN
  DO WHILE RS485Read(1,0)>=0
  LOOP
  n%=RS485Write(req$)

  i=0

 ' We should receive at least 11 bytes (no data)
 msg$=RS485Read$(11,tmo%)

 IF LEN(msg$)<>11 THEN
   GMDETransfer=-1
   EXIT FUNCTION
 ENDIF
 'reply is not for current sAddress$
 IF sAddr% <> conv("bbe/u16",MID$(msg$,5,2)) THEN
    GMDETransfer=-2
    EXIT FUNCTION
 ENDIF
 'get the length data
 ln%=ASC(MID$(msg$,9,1))
 msg$=msg$+RS485Read$(ln%,tmo%)
 IF (left$(msg$,2)<>(chr$(&HAA)+chr$(&HAA))) OR (len(msg$)<>(11+ln%)) OR () THEN
   GMDETransfer=-3
   EXIT FUNCTION
 ENDIF
 s%=0
 FOR  i=1 to len(msg$)
   s%=s%+asc(mid$(msg$,i,1))
 NEXT i
 IF (s%<>conv("bbe/u16",right$(msg$,2))) THEN
   GMDETransfer=-4
   EXIT FUNCTION
 ENDIF
 ELSE
   ' Ethernet not implemented yet
 ENDIF
'remove header and checksum
 rsp$=mid$(msg$,3,len(msg$)-4)
 GMDETransfer=0
END FUNCTION

' itf$  : Interface with string.Example "RS485:1" or "192.168.0.1:90"
'iAddrs%: register address are assigned from 1 to 254
'tmo%   : timeout
FUNCTION GMDERegister(itf$, sAddr%, tmo%)
 LOCAL i, err,err2,iAddrs%,dta$,rsp$,sn$
 iAddrs%=0
 dta$=""
 err=0
 i=0
 ' do until no more response
 DO WHILE (i<3) AND (err=0)
   err=GMDETransfer(itf$, sAddr%, &H0, &H0, &H10, dta$, rsp$, tmo%)
   ' validate control code and function code returned
   IF (err=0) AND (ASC(MID($rsp$,5,1))=$H0) AND (ASC(MID($rsp$,6,1))=$H90) THEN
     sn$=MID$(rsp$,8, ASC(MID$(rsp$,7,1)))
     dta$=sn$+CHR$(iAddrs%+1)
     err2=GMDETransfer(itf$, sAddr%, &H0, &H0, &H11, dta$, rsp$, tmo%)
     IF (err2=0) AND (ASC(MID$($rsp$,5,1))=$H0) AND (ASC(MID$($rsp$,6,1))=$H91) AND (ASC(MID$(rsp$,8,1))=&H06) THEN
        iAddrs%=iAddrs%+1
     ENDIF
     i=i+1
    ENDIF
 LOOP
 GMDERegister=iAddrs%
END FUNCTION

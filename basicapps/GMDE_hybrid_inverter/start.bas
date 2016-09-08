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
' fc%     Function Code
' dta$    Data
' rsp$    Response (framing, crc removed)
' tmo%    Timeout
FUNCTION GMDETransfer(itf$,slv%,sAddr%, dAddr%, cc%, fc%, dta$,tmo%)
 LOCAL interf$, num$, msg$,n%, i, req$
 interf$=split$(0,itf$,":")
 num$=split$(1,itf$,":") 
 ' Header, src address, dst address, control code, function code, data, checksum 16 bit
 msg$=chr$(&HAA)+chr$(&HAA)+conv("u16/bbe",sAddr%)+conv("u16/bbe",dAddr%)+chr$(cc%)+chr$(fc%)+dta$
 ' Checksum is simple sum
 s%=0
 for i=1 to len(msg$)
  s%=s%+asc(mid$(msg$,i,1))
 next i
 req$=msg$+conv("u16/bbe",s%)
 
 IF interf$="RS485" THEN
  DO WHILE RS485Read(1,0) >=0
  LOOP
  n%=RS485Write(req$)  
  
  ' We should receive at least 11 bytes (no data)
  msg$=RS485Read$(11,tmo%)  
  IF len(msg$)<>11 THEN
   GMDETransfer=-1
   EXIT FUNCTION
  ENDIF
  ln%=asc(mid$(msg$,9,1))
  msg$=msg$+RS485Read$(ln%,tmo%)  
  IF (left$(msg$,2)<>(chr$(&HAA)+chr$(&HAA))) OR (len(msg$)<>(11+ln%)) THEN
   GMDETransfer=-2
   EXIT FUNCTION
  ENDIF
  s%=0
  for i=1 to len(msg$)
   s%=s%+asc(mid$(msg$,i,1))
  next i  
  IF (s%<>conv("bbe/u16",right$(msg$,2))) THEN
   GMDETransfer=-3
   EXIT FUNCTION
  ENDIF

  ELSE
  ' Ethernet not implemented yet
 ENDIF
 rsp$=mid$(msg$,3,len(msg$)-4)
 GMDETransfer=0
END FUNCTION
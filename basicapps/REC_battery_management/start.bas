' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2015-2016 swissEmbedded GmbH, All rights reserved.
' REC battery management system
' Documentation available from manufacturer
SYS.Set "rs485", "baud=56000 data=8 stop=1 parity=n"
slv%=1
itf$="RS485:1"

start:
 pause 30000
 goto start

' REC BMS Data Transfer
' itf$  Interface with string.Example "RS485:1" or "192.168.0.1:90"
' slv%  Slave Address
' rq$   Request send to the BMS
' rp$   Response (excluding framing and checksum)
FUNCTION RecTransfer(itf$,slv%,rq$,rp$,tmo%)
 LOCAL interf$, num$, n%,req$,msg$,ln%
 interf$=split$(0,itf$,":")
 num$=split$(1,itf$,":") 
 ' STX, destination address, source address,  payload len, payload, CRC16, ETX
 msg$=chr$(slv%)+chr$(0)+chr$(len(rq$))
 req$=chr$(&H55)+CRC$(0,msg$)+chr$(&HAA)
 
 IF interf$="RS485" THEN
  DO WHILE RS485Read(1,0) >=0
  LOOP
  n%=RS485Write(req$)  
  
  ' We should receive at least 7 bytes STX, dst, src, len, CRC16, ETX
  msg$=RS485Read$(7,tmo%)  
  IF len(msg$)<>7 OR left$(msg$,1)<>chr$(&H55) THEN
   RecTransfer=-1
   EXIT FUNCTION
  ENDIF
  ln%=asc(mid$(msg$,4,1))
  msg$=msg$+RS485Read$(ln%,tmo%)  
  IF (right$(msg$,1)<>chr$(&HAA)) OR (len(msg$)<>(7+ln%)) OR (CRC$(0,mid$(msg$,2,ln%+3))<>mid$(msg$,len(msg$)-2,2)) THEN
   RecTransfer=-2
   EXIT FUNCTION
  ENDIF
 ELSE
  ' Ethernet not implemented yet
 ENDIF
 rp$=mid$(msg$,2,ln%+3)
 RecTransfer=0
END FUNCTION
' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2015-2016 swissEmbedded GmbH, All rights reserved.
' REC battery management system
' Documentation available from manufacturer
SYS.Set "rs485", "baud=56000 data=8 stop=1 parity=n"
slv%=1
itf$="RS485:1"

start:
 err%=RecMainData(itf$,slv%,UCmin, UCmax, Ibat, Tmax, Ubat, SoC, SoH)
 print "RecMainData " err% UCmin UCmax Ibat Tmax Ubat SoC SoH
 pause 30000
 goto start

' REC BMS Main Data
' itf$  Interface with string.Example "RS485:1" or "192.168.0.1:90"
' slv%  Slave Address
' UCmin  Min cell voltage
' UCmax  Max cell voltage
' Ibat   Battery current
' Tmax   Battery maximal temperature
' Ubat   Battery voltage
' SoC   Battery state of charge
' SoH   Battery state of health
 FUNCTION RecMainData(itf$,slv%,UCmin, UCmax, Ibat, Tmax, Ubat, SoC, SoH)
  LOCAL err%,rp$  
  err%=RecTransfer(itf$,slv%,"LCD1?",rp$,1000)
  IF err% OR (len(rp$)<>(5+7*4)) OR (asc(mid$(rp$,3,1))!=28) THEN
   RecMainData=err%
   EXIT FUNCTION
  ENDIF
  UCmin=conv("ble/f32", mid$(rp$,4,4))
  UCmax=conv("ble/f32", mid$(rp$,8,4))
  Ibat=conv("ble/f32", mid$(rp$,12,4))
  Tmax= conv("ble/f32", mid$(rp$,16,4))
  Ubat=conv("ble/f32", mid$(rp$,20,4))
  SoC=conv("ble/f32", mid$(rp$,24,4))
  SoH=conv("ble/f32", mid$(rp$,28,4))
  RecMainData=0
 END FUNCTION
 
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
' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2015-2016 swissEmbedded GmbH, All rights reserved.
' REC battery management system 4-16S
' Documentation available from manufacturer
SYS.Set "rs485", "baud=56000 data=8 stop=1 parity=n"
slv%=1
itf$="RS485:1"

start:
 err%=RecMainData1(itf$,slv%,UCmin, UCmax, Ibat, Tmax, Ubat, SoC, SoH)
 print "RecMainData " err% UCmin UCmax Ibat Tmax Ubat SoC SoH
 err%=RecMainData3(itf$,slv%,, minBMSa%, minBMSn%, maxBMSa%, maxBMSn%, maxtBMSa%, maxtBMSn%, Ah%)
 print "RecMainData " err% minBMSa% minBMSn% maxBMSa% maxBMSn% maxtBMSa% maxtBMSn% Ah%
 pause 30000
 goto start

' REC BMS Identification 
' itf$  Interface with string.Example "RS485:1" or "192.168.0.1:90"
' slv%  Slave Address
' return 0 if Identification equals("REC - BATERY MANAGEMENT SYSTEM")
 FUNCTION RecIdentification(itf$,slv%)
  LOCAL err%,rp$
  err%=RecTransfer(itf$,slv%,"*IDN?",rp$,1000)
  IF err%
   RecIdentification=err%
   EXIT FUNCTION
  ENDIF
  IF (rp$<>"REC - BATERY MANAGEMENT SYSTEM") THEN
   RecIdentification=-4
   EXIT FUNCTION
  ENDIF
  RecIdentification=0
 END FUNCTION
 
' REC BMS Main Data 1
' itf$  Interface with string.Example "RS485:1" or "192.168.0.1:90"
' slv%  Slave Address
' UCmin Min cell voltage
' UCmax Max cell voltage
' Ibat  Battery current
' Tmax  Battery maximal temperature
' Ubat  Battery voltage
' SoC   Battery state of charge
' SoH   Battery state of health
 FUNCTION RecMainData1(itf$,slv%,UCmin, UCmax, Ibat, Tmax, Ubat, SoC, SoH)
  LOCAL err%,rp$  
  err%=RecTransfer(itf$,slv%,"LCD1?",rp$,1000)
  IF err% OR (len(rp$)<>(3+7*4)) THEN
   RecMainData1=err%
   EXIT FUNCTION
  ENDIF
  UCmin=conv("ble/f32", mid$(rp$, 4,4))
  UCmax=conv("ble/f32", mid$(rp$, 8,4))
  Ibat =conv("ble/f32", mid$(rp$,12,4))
  Tmax =conv("ble/f32", mid$(rp$,16,4))
  Ubat =conv("ble/f32", mid$(rp$,20,4))
  SoC  =conv("ble/f32", mid$(rp$,24,4))
  SoH  =conv("ble/f32", mid$(rp$,28,4))
  RecMainData1=0
 END FUNCTION
 
' REC BMS Main Data 3
' itf$  Interface with string.Example "RS485:1" or "192.168.0.1:90"
' slv%  Slave Address
' minBMSa% min cell BMS address
' minBMSn% min cell number
' maxBMSa% max cell BMS address
' maxBMSn% max cell number
' maxtBMSa% max temperature sense BMS address
' maxtBMSn% max temperature sense number
' Ah Ampere hours
 FUNCTION RecMainData3(itf$,slv%, minBMSa%, minBMSn%, maxBMSa%, maxBMSn%, maxtBMSa%, maxtBMSn%, Ah%)
  LOCAL err%,rp$  
  err%=RecTransfer(itf$,slv%,"LCD3?",rp$,1000)
  IF err% OR (len(rp$)<>(3+8)) THEN
   RecMainData3=err%
   EXIT FUNCTION
  ENDIF
  minBMSa%  = asc(mid$(rp$, 4,1))
  minBMSn%  = asc(mid$(rp$, 5,1))
  maxBMSa%  = asc(mid$(rp$, 6,1))
  maxBMSn%  = asc(mid$(rp$, 7,1))
  maxtBMSa% = asc(mid$(rp$, 8,1))
  maxtBMSn% = asc(mid$(rp$, 9,1))
  Ah% = conv("bbe/u16",mid$(rp$,10,2))
  RecMainData3=0
 END FUNCTION
 
' REC BMS GetError 
' itf$    Interface with string.Example "RS485:1" or "192.168.0.1:90"
' slv%    Slave Address
' isErr%  0 – no error; 1 – error
' bms%    BMS unit
' errNum% error number (1-13) in
' idNum%  number of the cell, temp. sensor where the error occurred
FUNCTION RecGetError(itf$,slv%,isErr%,bms%,errNum%,idNum%)
 LOCAL err%,rp$
 err%=RecTransfer(itf$,slv%,"ERRO?",rp$,1000)
 IF err% THEN
  RecGetError=err%
  EXIT FUNCTION
 ENDIF
 isErr%  = asc(mid$(rp$, 4,1))
 bms%    = asc(mid$(rp$, 5,1))
 errNum% = asc(mid$(rp$, 6,1))
 idNum%  = asc(mid$(rp$, 7,1))
 RecGetError= 0
END FUNCTION

' REC BMS Error 
' itf$  Interface with string.Example "RS485:1" or "192.168.0.1:90"
' slv%  Slave Address
' cmd$   "GET"/"SET"
' errNum% error number (1-13) in
FUNCTION RecError(itf$,slv%,cmd$,errNum%)
 LOCAL err%,rp$
 if cmd$="GET"
   err%=RecTransfer(itf$,slv%,"ERRD?",rp$,1000)
 else if cmd$="SET"
   err%=RecTransfer(itf$,slv%,"ERRD"+chr$(errNum%),rp$,1000)
 else   
 endif
 IF err% THEN 
  RecError=err%
  EXIT FUNCTION
 ENDIF 
 errNum% = asc(mid$(rp$, 4,1))
 RecError=0
END FUNCTION

' REC BMS Get/Set  a Byte Value
' itf$  Interface with string.Example "RS485:1" or "192.168.0.1:90"
' slv%  Slave Address
' intr$    Request send to the BMS
' cmd$   "GET"/"SET"
' value% Byte value to GET/SET
FUNCTION RecByteValue(itf$,slv%,intr$,cmd$,value%)
 LOCAL err%,rp$
 if cmd$="GET"
   err%=RecTransfer(itf$,slv%,intr$,rp$,1000)
 else if cmd$="SET"
   err%=RecTransfer(itf$,slv%,intr$+chr$(value%),rp$,1000)
 else   
 endif
 IF err% THEN
  RecByteValue=err%
  EXIT FUNCTION
 ENDIF
 errNum% = asc(mid$(rp$, 4,1))
 RecByteValue=0
END FUNCTION

' REC BMS Get/Set  a Integer Value
' itf$  Interface with string.Example "RS485:1" or "192.168.0.1:90"
' slv%  Slave Address
' intr$    Request send to the BMS
' cmd$   "GET"/"SET"
' value% Integer value to GET/SET
FUNCTION RecIntValue(itf$,slv%,intr$,cmd$,value%)
 LOCAL err%,rp$
 if cmd$="GET"
   err%=RecTransfer(itf$,slv%,intr$,rp$,1000)
 else if cmd$="SET"
   err%=RecTransfer(itf$,slv%,intr$+conv("i16/ble", value%),rp$,1000)
 else
 endif
 IF err% THEN
  RecIntValue=err%
  EXIT FUNCTION
 ENDIF
 value=conv("ble/i16", mid$(rp$, 4,2))
 RecIntValue=0
END FUNCTION

' REC BMS Get/Set  a Float Value
' itf$  Interface with string.Example "RS485:1" or "192.168.0.1:90"
' slv%  Slave Address
' intr$    Request send to the BMS
' cmd$   "GET"/"SET"
' value Float value to GET/SET
FUNCTION RecFloatValue(itf$,slv%,intr$,cmd$,value)
 LOCAL err%,rp$
 if cmd$="GET"
   err%=RecTransfer(itf$,slv%,intr$,rp$,1000)
 else if cmd$="SET"
   err%=RecTransfer(itf$,slv%,intr$+conv("f32/ble", value),rp$,1000)
 else
 endif
 IF err% THEN
  RecFloatValue=err%
  EXIT FUNCTION
 ENDIF
 value=conv("ble/f32", mid$(rp$, 4,4))
 RecFloatValue=0
END FUNCTION

' REC BMS Data Transfer
' itf$   Interface with string.Example "RS485:1" or "192.168.0.1:90"
' dAdrr% Destination Address
' intr$    Request send to the BMS
' rp$    Response (excluding STX,CRC16,ETX and checksum)
FUNCTION RecTransfer(itf$,dAdrr%,instr$,rp$,tmo%)
 LOCAL interf$, num$, n%, req$, msg$, ln%, rts$
 
 IF dAdrr% < &H01 OR dAdrr%>&H10 THEN
   RecTransfer=-1
   EXIT FUNCTION
  ENDIF
  
 interf$=split$(0,itf$,":")
 num$=split$(1,itf$,":") 
 ' STX, destination address, sender address,  bytes to send, instruction, CRC16, ETX
 msg$=chr$(dAdrr%)+chr$(0)+chr$(len(instr$))+instr$
 req$=chr$(&H55)+msg$+CRC$(0,msg$)+chr$(&HAA)
 
 IF interf$="RS485" THEN
  DO WHILE RS485Read(1,0)>=0
  LOOP
  n%=RS485Write(req$)
  
  ' We should receive at least 7 bytes STX, dst, src, len, CRC16, ETX
  msg$=RS485Read$(7,tmo%)
  IF len(msg$)<>7 OR left$(msg$,1)<>chr$(&H55) THEN
   RecTransfer=-2
   EXIT FUNCTION
  ENDIF
  ln%=asc(mid$(msg$,4,1))
  msg$=msg$+RS485Read$(ln%,tmo%)
  rts$=mid$(msg$,2,len(msg$)-3)
  IF (right$(msg$,1)<>chr$(&HAA)) OR (len(msg$)<>(7+ln%)) OR (CRC$(0,rts$)<>mid$(msg$,len(msg$)-2,2)) THEN
   RecTransfer=-3
   EXIT FUNCTION
  ENDIF
 ELSE
  ' Ethernet not implemented yet
 ENDIF
 rp$=rts$
 RecTransfer=0
END FUNCTION

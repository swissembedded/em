' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2015-2016 swissEmbedded GmbH, All rights reserved.
' Ego smart heater control with excess energy over modbus TCP and RTU
' Set this value from energy meter measurement (e.g. S0 / D0 interface)
SYS.Set "rs485", "baud=19200 data=8 stop=1 parity=e"
kW=0.0
slv%=247
if$=""
start:
 EgoSmartHeater(if$,slv%,kW,st%,T%,Tmax%)
 print "Ego " st% T% Tmax%
 pause 30000
 goto start

' Ego smart heater controller
' This function must be called at least every 60 seconds,
' otherwise the ego smart heater will switch off
' if$ modbus interface (see EMDO modbus library for details)
' slv% ego smart heater slave address default 247, 
' kW home energy at energy meter neg. value = excess energy
' st% 1=500W on, 2=1000W on, 4=2000W on, e.g. 3=500+1000W
' T is the boiler temperature
' Tmax is the max boiler temperature set by external control
FUNC EgoSmartHeater(if$,slv%,kW,st%,T,Tmax)
 ' Read ManufacturerId, ProductId, ProductVersion, FirmwareVersion
 err%= mbFuncRead(slv$,3,&H2000,1,rmId$,500) OR mbFuncRead(slv$,3,&H2001,1,rpId$,500) OR mbFuncRead(slv$,3,&H2002,1,rpV$,500) OR mbFuncRead(slv$,3,&H2003,1,rfV$,500)
 if err% then
  print "Ego error on read"
  exit func
 end if
 ' Check if Ego is known
 mId%=conv("bbe/i16",rmId$)
 pId%=conv("bbe/i16",rpId$)
 pV%=conv("bbe/i16",rpV$) 
 fV%=conv("bbe/i16",rfV$) 
 if mId% = &H14ef and pId% = &Hff37 and pV% = &Hebaf and fV% = &H0000 then
  ' Power Regulation
  ' Set PowerNominalValue to -1 and HomeTotalPower power
  pNv$=conv("i16/bbe",-1)
  hTp$=conv("i16/bbe",kW*1000.0)
  %err=mbFuncWrite(slv$,6,&H1300,1,pNv$,500) OR mbFuncWrite(slv$,6,&H1301,1,pNv$,500)
  if err% then
   print "Ego error on write"
   exit func
  end if
  ' Read ActualTemperaturBoiler,UserTemperaturNominalValue, RelaisStatus
  err%= mbFuncRead(slv$,3,&H1404,1,raT$,500) OR mbFuncRead(slv$,3,&H1407,1,ruT$,500) OR mbFuncRead(slv$,3,&H1408,1,rrS$,500)
  if err% then
   print "Ego error on write"
  exit func
  T%=conv("bbe/i16",raT$)
  Tmax%=conv("bbe/i16",ruT$)
  st%=conv("bbe/i16",rrS$) 
 end if  
END FUNC
<<<<<<< HEAD
=======

'----------------------------------------
' ** Read a modbus Holding registers with function 3
'numRegs= nums registers to read
'----------------------------------------
FUNCTION ModbusFC03$(deviceType, slv, register, numRegs)
   LOCAL functionCode = &H03
   
   IF NumRegs>=1 AND NumRegs <= 125 THEN
      IF validateAddress(register) AND numRegs>= 1 and numRegs<= 125 THEN 
          ' convert the register number to hex string and fill it up with 0 at the start for 4 chars
         mb_req_pdu$=pdu$(functionCode, 0, registerHex$(convertWordFilled$(register-1)) + convertWordFilled$(numRegs))
         req$=adu$(deviceType, slv, pdu$(functionCode, 0, mb_req_pdu$)

         num=mbRequest(req$)
         'n' should be a global Variable
         n=1000
         DO            
            num=getFrameSize()
            IF num<7 THEN PAUSE 1
            n=n-1
         LOOP UNTIL num>=7 OR n=0
        
         IF n > 0 THEN
            rsp$=mbResponse$()
            functionCodeRsp=peek(VAR rsp$,1)
            IF functionCodeRsp=fucntionCode THEN 
              mb_rsp_pdu$=rsp$
            ELSE
                mb_rsp_pdu$=mbException$(functionCode, peek(VAR rsp$,2))
                Hexdump rsp$, out$
                PRINT "Modbus Problem (ModbusFC03) " len(rsp$)  " hex " out$
                value = 0
            ENDIF
      ELSE  
         mb_rsp_pdu$=mbException$(functionCode, 2)
      ENDIF
   ELSE
        mb_rsp_pdu$=mbException$(functionCode, 3)
   ENDIF
   ModbusFC03$=mb_rsp_pdu$
END function

'----------------------------------------
' ** Read a modbus Input registers with function 4
'numRegs= nums registers to read
'----------------------------------------
FUNCTION ModbusFC04$(deviceType, slv, register, numRegs)
   LOCAL functionCode = &H04
   
   IF NumRegs>=1 AND NumRegs <= 125 THEN
      IF validateAddress(register) AND numRegs>= 1 and numRegs<= 125 THEN 
          ' convert the register number to hex string and fill it up with 0 at the start for 4 chars
         mb_req_pdu$=pdu$(functionCode, 0, registerHex$(convertWordFilled$(register-1)) + convertWordFilled$(numRegs))
         req$=adu$(deviceType, slv, pdu$(functionCode, 0, mb_req_pdu$)

         num=mbRequest(req$)
         'n' should be a global Variable
         n=1000
         DO            
            num=getFrameSize()
            IF num<7 THEN PAUSE 1
            n=n-1
         LOOP UNTIL num>=7 OR n=0
        
         IF n > 0 THEN
            rsp$=mbResponse$()
            functionCodeRsp=peek(VAR rsp$,1)
            IF functionCodeRsp=fucntionCode THEN 
              mb_rsp_pdu$=rsp$
            ELSE
                mb_rsp_pdu$=mbException$(functionCode, peek(VAR rsp$,2))
                Hexdump rsp$, out$
                PRINT "Modbus Problem (ModbusFC03) " len(rsp$)  " hex " out$
                value = 0
            ENDIF
      ELSE  
         mb_rsp_pdu$=mbException$(functionCode, 2)
      ENDIF
   ELSE
        mb_rsp_pdu$=mbException$(functionCode, 3)
   ENDIF
   ModbusFC04$=mb_rsp_pdu$
end function

'----------------------------------------
' ** Write a modbus Single register with function 6
'numRegs= nums registers to read
'----------------------------------------
FUNCTION ModbusFC06$(deviceType, slv, register, value)
   LOCAL functionCode = &H06
   
   IF validateAddress(register) AND value>= 0 and numRegs<= 65535 THEN
      ' convert the register number to hex string and fill it up with 0 at the start for 4 chars
      mb_req_pdu$=pdu$(functionCode, 0, registerHex$(convertWordFilled$(register-1)) + convertWordFilled$(value))
      req$=adu$(deviceType, slv, pdu$(functionCode, 0, mb_req_pdu$)
      num=mbRequest(req$)
      'n' should be a global Variable
      n=1000
      DO            
        num=getFrameSize()
        IF num<7 THEN PAUSE 1
            n=n-1
         LOOP UNTIL num>=7 OR n=0
        
         IF n > 0 THEN
            rsp$=mbResponse$()
            functionCodeRsp=peek(VAR rsp$,1)
            IF functionCodeRsp=fucntionCode THEN 
              mb_rsp_pdu$=rsp$
            ELSE
                mb_rsp_pdu$=mbException$(functionCode, peek(VAR rsp$,2))
                Hexdump rsp$, out$
                PRINT "Modbus Problem (ModbusFC03) " len(rsp$)  " hex " out$
                value = 0
            ENDIF
      ELSE  
         mb_rsp_pdu$=mbException$(functionCode, 2)
      ENDIF
   ModbusFC06$=mb_rsp_pdu$E
end function

'----------------------------------------
'
'----------------------------------------
FUNCTION Request03()
functionCodeRsp=peek(VAR rsp$,1)
IF functionCodeRsp=fucntionCode THEN 
  count=PEEK(VAR rsp$,2)*256+peek(VAR rsp$,3)
  reqPdu=""
  FOR i= 4 TO count+4 STEP 2
    reqPdu = reqPdu+PEEK(VAR rsp$,i)+peek(VAR rsp$,(i+1))
                    
    value=PEEK(VAR rsp$,i*256+peek(VAR rsp$,(i+1))
  NEXT
  ELSE

ENDIF
end function

'----------------------------------------
'
'----------------------------------------
FUNCTION pdu$(functionCode, functionSubcode, data$)
    pdu$=CHR$(functionCode)+data$
END FUNCTION

FUNCTION adu$(slv, pdu$)
    SELECT CASE deviceType
        CASE 1
            adu$=CHR$(slv)+pdu$
            adu$=adu$+CRC$(0,adu$)

        CASE 2
            
        CASE 3
            
        ELSE

    END SELECT
END FUNCTION

'----------------------------------------
'
'----------------------------------------
FUNCTION validateAddress(address)
    validateAddress=(address>=&H00 AND address<=&HFFFF)
END FUNCTION

'----------------------------------------
'
'----------------------------------------
FUNCTION mbException$(functionCode, exceptionCode)
    mb_excep_rsp_pdu$ = CHR$(functionCode+128) + convertWordFilled$(exceptionCode)
END FUNCTION

FUNCTION mbRequest$(deviceType, aduRequest$)
    SELECT CASE deviceType
        CASE 1
            'mbRequest$=TCPWrite(aduRequest$)
        CASE 2
            mbRequest$=RS485Write(aduRequest$)            
        CASE 3
            'mbRequest$=RS232Write(aduRequest$)
        ELSE
        
    END SELECT
END FUNCTION

'----------------------------------------
'
'----------------------------------------
FUNCTION mbResponse$()
    SELECT CASE deviceType
        CASE 1
            'mbResponse$=TCPRead()
        CASE 2
            mbResponse$=RS485Read$(RS485Rq)
        CASE 3
            'mbResponse$=RS232Read$(RS485Rq)
        ELSE

    END SELECT
END FUNCTION

'----------------------------------------
'
'----------------------------------------
FUNCTION getFrameSize()
    SELECT CASE deviceType
        CASE 1
            'getFrameSize=TCPRq
        CASE 2
            getFrameSize=RS485Rq
        CASE 3
            'getFrameSize=RS485Rq
        ELSE

    END SELECT
END FUNCTION

'----------------------------------------
'
'----------------------------------------
FUNCTION convertWordFilled$(word, fill$)
    LOCAL value$=hex$(word)
    convertWordFilled$=string$(4-len(fill$),"0")+value$
END FUNCTION

'----------------------------------------
'
'----------------------------------------
FUNCTION registerHex$(register)
    registerString$=CHR$(val("&H"+left$(register$,2)))+CHR$(val("&H"+right$(register$,2)))
END FUNCTION

'----------------------------------------
'
'----------------------------------------
FUNCTION registerHexInv$(register)
    registerString$=CHR$(val("&H"+right$(register$,2)))+CHR$(val("&H"+left$(register$,2)))
END FUNCTION

'----------------------------------------
'
'----------------------------------------
FUNCTION convertWordFilled$(word, fill$)
    LOCAL value$=hex$(word)
    convertWordFilled$=string$(4-len(fill$),"0")+value$
END FUNCTION
>>>>>>> origin/master

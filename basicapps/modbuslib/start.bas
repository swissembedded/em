' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2015-2016 swissEmbedded GmbH, All rights reserved.
' EMDO modbus master library


FUNC mbFuncRead(if$,slv%,fc%,addr%,num%,da$,timeout%)
 err%=0
 da$=""
 ' Check address range to be valid		 
 if slv% < 0 OR addr% > &HFF then
  err% = 1 ' slave out of range
  mbFuncRead=err%
  exit func			
 end if

 if addr% < 0 OR addr% > &HFFFF then
  err% = 2 ' address out of range
  mbFuncRead=err%
  exit func			
 end if
 
 select case (st% and &h30)
  case 1 ' Real Coils
  case 2 ' Read Discrete Inputs
  case 3 ' Read Holding Register
   if num% < 1 OR num% > 125 then
    err%=3
    mbFuncRead=err%
    exit func			
   end if
   tx$=chr$(slv)+chr$(&H03)+conv("i16/bbe",addr)+conv("i16/bbe",num)
   ' send 
   err%=mbCom(if$,slv%,tx$,rx$,1+2+num*2,timeout%)
   if err% then
    mbFuncRead=err%
	exit func
   end if   
   da$=right$(rx$,num*2)
  case 4 ' Read Input Register 
 end select
 mbFuncRead=err%
END FUNC

FUNC mbFuncWrite(if$,slv%,fc%,addr%,len%,da$,timeout%)
 err%=0
 select case (st% and &h30)
  case 5 ' Write Single Coil
  case 6 ' Write Single Register
  case 15 ' Write Multiple Coils   
  case 16 ' Write Multiple Register   
 end select
 mbFuncWrite=err%
END FUNC

' if$ RTU:RS485:1 or TCP:192.168.0.1:90
FUNC mbCom(if$,tx$,rx$,rxlen%,timeout%)
 err%=0
 ' parse if$ for either RTU, TCP on RS485 or ETH
 prot$=split(0,if$)
 if$=split(1,if$)
 num$=split(2,if$)
 ' add framing with checksum to data
 if prot$ = "RTU"
  crc$=CRCCalc$(0,tx$) ' CRC16
  msg$=tx$+crc$
 else
  crc$=CRCCalc$(0,tx$) ' CRC16
  tn$=conv("i16/bbe", Unixtime())
  len$=conv("i16/bbe",rxlen)
  msg$=tn$+chr$(0)+chr$(0)+len$+tx$
 end if 
 ' send request from tx$
 if if$="RS485" then
  ' Send it over rs485
 else
  ' Send it over ethernet
 end if 
 ' wait for response or timeout
 ' update rx$ and validate checksum
 mbCom=err%
END FUNC

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
' ** Write a modbus Multiple register with function 16
'numRegs= nums registers to read
'----------------------------------------
FUNCTION ModbusFC16$(deviceType, slv, register, numRegs, numBytes, values$)
   LOCAL functionCode = &H16
   
   IF (NumRegs>=1 AND NumRegs <= 123) AND (numBytes) THEN
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

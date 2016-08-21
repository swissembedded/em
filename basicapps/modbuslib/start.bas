' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2015-2016 swissEmbedded GmbH, All rights reserved.
' EMDO modbus master library

START:
	reg$=mbFuncRead$("TCP:192.168.3.30:90",0,3,30015,2,"2",500)
	PAUSE 5000
GOTO start

'----------------------------------------
' Parameters
' itf$    : Interface with string.Example "RTU:RS485:1" or "TCP:192.168.0.1:90"
' slv%    : Slave Address
' func%   : FUNCTION Code
' addr%   : Modbus Address. Don't need subtract less 1
' num%    : Number of Registers/Bits to Read/Write or single value to Read/Write. 
'           In Func=16 it is not necessary
' data$   : Data for Read/Write
' timeout%: is the timeout in ms
'----------------------------------------
FUNCTION mbFuncRead$(itf$,slv%,func%,addr%,num%,data$,timeout%)
  mb_rsp_pdu$=mbFunc$(itf$,slv%,func%,addr%,num%,data$,timeout%)
  IF funcOk(func, mb_rsp_pdu$) THEN
    mbFuncRead$=right$(mb_rsp_pdu$,getRspLen(mb_req_pdu$))
  ELSE
    ' return the error code
    mbFuncRead$=mid$(mb_rsp_pdu$,2,1) 
  ENDIF 
END FUNCTION

'----------------------------------------
' Parameters
' itf$    : Interface with string.Example "RTU:RS485:1" or "TCP:192.168.0.1:90"
' slv%    : Slave Address
' func%   : FUNCTION Code
' addr%   : Modbus Address. Don't need subtract less 1
' num%    : Number of Registers/Bits to Read/Write or single value to Read/Write. 
'           In Func=16 it is not necessary
' data$   : Data for Read/Write
' timeout%: is the timeout in ms
'----------------------------------------
FUNCTION mbFuncWrite$(if$,slv%,func%,addr%,num%,data$,timeout%)
  mb_rsp_pdu$=mbFunc$(itf$,slv%,func%,addr%,num%,data$,timeout%)
  IF funcOk(func, mb_rsp_pdu$)
    mbFuncWrite$=right$(mb_rsp_pdu$,getRspLen(mb_req_pdu$))
  ELSE
  ENDIF
END FUNCTION

'----------------------------------------
' Return the Response or Error PDU
' Parameters
' itf$    : Interface with string.Example "RTU:RS485:1" or "TCP:192.168.0.1:90"
' slv%    : Slave Address
' func%   : FUNCTION Code
' addr%   : Modbus Address. Don't need subtract less 1
' num%    : Number of Registers/Bits to Read/Write or single value to Read/Write. 
'           In Func=16 it is not necessary
' data$   : Data for Read/Write
' timeout%: is the timeout in ms
'----------------------------------------
FUNCTION mbFunc$(itf$,slv%,func%,addr%,num%,data$,timeout%)
IF valFuncCode(func) THEN
  IF valAddress(add)
    IF valDataValue(func, data$) THEN
      IF func=16 THEN
        mb_req_pdu$=pdu$(func, 0, conv("i16/bbe",addr-1)+conv("i16/bbe",num)+data$)
      ELSE
        mb_req_pdu$=pdu$(func, 0, conv("i16/bbe",addr-1)+data$)
      ENDIF
      mb_rsp_pdu$=mbCom(itf$,slv,func,mb_req_pdu$,timeout%)
    ELSE
      mb_rsp_pdu$=mbException$(func, 3)
    ENDIF
  ELSE 
     mb_rsp_pdu$=mbException$(func, 2)
  ENDIF 
ELSE
  mb_rsp_pdu$=mbException$(func, 1)
ENDIF
mbFunc$=mb_rsp_pdu
END FUNCTION

'----------------------------------------
' itf$ RTU:RS485:1 or TCP:192.168.0.1:90
'
'----------------------------------------
FUNCTION mbCom(itf$,slv%,func%,mb_req_pdu$,timeout%)
 
 err%=0
 ' parse if$ for either RTU, TCP on RS485 or ETH
 prot$=split(0,itf$,":")
 interf$=split(1,itf$,":")
 num$=split(2,itf$,":")
 
 req$=adu$(prot$,interf$,slv,mb_req_pdu$)

 ' send request from mb_req_pdu$
 ' wait for response or timeout
 ' update rspLen$ and validate checksum
 rspLen%=getReqLen(mb_req_pdu$)
 
 IF if$="RS485" THEN
   ' Send it over rs485
   n%=RS485Write(req$)
   mb_rsp_pdu$=RS485Reads(rspLen%,timeout%)
   mbLog(interf$,reg$,mb_rsp_pdu$,"ETH:")
 ELSE
   ' Send it over ethernet
   con%=SocketClient( 1, interf$, num$ ) 
   IF con% >0 THEN
     n%=SocketOption(con%,"SO_RCVTIMEO",timeout%)
     n%=SocketOption(con%,"SO_SNDTIMEO",timeout%)    
     n%=SocketWrite( con%, reg$ )
     
     mb_req_pdu$=SockRead$(con%,rspLen%)
     done%=SocketClose( con% )
     mbLog(itf$,req$,mb_req_pdu$,"ETH:")
   ELSE
     mb_rsp_pdu=mbException$(func%, 10)
   ENDIF
 ENDIF 
 mbCom=mb_rsp_pdu$
END FUNCTION

'----------------------------------------
' log a telegram
'
'----------------------------------------
SUB mbLog(itf$,tx$,rx$,msg$)
 s$=msg$+"itf:"+itf$+" tx:"
 FOR i=1 TO len(tx$)
  s$=s$+hex$(asc(mid$(tx$,i,1)))
 NEXT
 print s$
 s$=" rx:"
 FOR i=1 TO LEN(rx$)
  s$=s$+hex$(asc(mid$(rx$,i,1)))
 NEXT
 PRINT s$
END SUB
'----------------------------------------
'
'----------------------------------------
FUNCTION pdu$(FUNCTIONCode, FUNCTIONSubcode, data$)
    pdu$=CHR$(FUNCTIONCode)+data$
END FUNCTION

'----------------------------------------
'
'----------------------------------------
FUNCTION adu$(prot$, itf$, slv, pdu$)

IF prot$ = "RTU" THEN
  msg$=CHR$(slv)+pdu$
  adu$=reg$+CRCCalc$(0,msg$) ' CRC16
ELSE
  tn$=conv("i16/bbe", Ticks())
  len$=conv("i16/bbe",len(pdu$))
  adu$=tn$+chr$(0)+chr$(0)+len$+CHR$(slv)+pdu$
ENDIF
END FUNCTION

'----------------------------------------
'Validate if the Response PDU is not an Error PDU
'----------------------------------------
FUNCTION funcOk(func%,mb_rsp_pdu$)
    funcOk=(func=toNum(mid$(mb_rsp_pdu$,1,1)))
END FUNCTION

'----------------------------------------
'
'----------------------------------------
FUNCTION valFuncCode(func%)
    validateFUNCTIONCode=((func>=1 AND func<=6) OR (func>=15 AND func<=16) OR (func>=22 AND func<=23))
END FUNCTION

'----------------------------------------
'
'----------------------------------------
FUNCTION valAddress(address)
    validateAddress=(address>=&H00 AND address<=&HFFFF)
END FUNCTION

'----------------------------------------
'
'----------------------------------------
FUNCTION valDataValue(func%, num%, data$)
validateDataValue=((func=1 or func=2) and (num >= 1 and num <= 2000)) OR
                  ((func=3 or func=4) and (num >= 1 and num <=  125)) OR
                  ((func=5 ) and (num  = 0  OR num  = &HFF00)) OR
                  ((func=6 ) and (num >= 0 and num <= &HFFFF)) OR
                  ((func=15) and (num >= 1 and num <= &H07B0) AND len(data$)=toNum(mid$(data$,1,1))+1)) OR
                  ((func=16) and (num >= 1 and num <= &H007B) AND len(data$)=toNum(mid$(data$,1,1))*2+1 AND 
                    num*2=toNum(mid$(data$,1,1))) OR
                  ((func=22) and len(data$)=4 and toNum(mid$(data$,1,2))>=0 and toNum(mid$(data$,1,2)) <= &HFFFF and 
                    toNum(mid$(data$,3,2))>=0 and toNum(mid$(data$,3,2)) <= &HFFFF) OR
                  ((func=23) and (num >= 1 and num <= &H007D) and len(data$)=5+toNum(mid$(data$,5,1)) and 
                    toNum(mid$(data$,1,2))>=0 and toNum(mid$(data$,1,2)) <= &HFFFF AND    
                    toNum(mid$(data$,3,2))>=1 and toNum(mid$(data$,3,2)) <= &H0079)
END FUNCTION

'----------------------------------------
'
'----------------------------------------
FUNCTION mbException$(FUNCTIONCode%, exceptionCode%)
    mb_excep_rsp_pdu$=CHR$(FUNCTIONCode+128) + conv("i16/bbe",exceptionCode)
END FUNCTION

'----------------------------------------
'
'----------------------------------------
FUNCTION getReqLen(func%, pdu$)
    SELECT CASE func
        CASE 1
            getResponseSize=2+toNum(mid$(pdu$,4,2))
        CASE 2
            getResponseSize=2+toNum(mid$(pdu$,4,2))
        CASE 3
            getResponseSize=2+toNum(mid$(pdu$,4,2))*2
        CASE 4
            getResponseSize=2+toNum(mid$(pdu$,4,2))*2
        CASE 5
            getResponseSize=5
        CASE 6
            getResponseSize=5
        CASE 15
            getResponseSize=5
        CASE 16
            getResponseSize=5
        CASE 22
            getResponseSize=7
        CASE 23
            getResponseSize=2+toNum(mid$(pdu$,4,2))*2
        ELSE
    END SELECT
END FUNCTION

'----------------------------------------
'
'----------------------------------------
FUNCTION getRspData$(func%, pdu$)
    SELECT CASE func
        CASE 1
            getRspData$=right$(pdu$, toNum(mid$(pdu$,2,1)))
        CASE 2
            getRspData$=2+toNum(mid$(pdu$,4,2))
        CASE 3
            getRspData$=2+toNum(mid$(pdu$,4,2))*2
        CASE 4
            getRspData$=2+toNum(mid$(pdu$,4,2))*2
        CASE 5
            getRspData$=5
        CASE 6
            getRspData$=5
        CASE 15
            getRspData$=5
        CASE 16
            getRspData$=5
        CASE 22
            getRspData$=7
        CASE 23
            getRspData$=2+toNum(mid$(pdu$,4,2))*2
        ELSE
    END SELECT
END FUNCTION

'----------------------------------------
'Convert an String (lenght=1 or =2) to Number
'----------------------------------------
FUNCTION toNum(value$)
IF len(value$)=1 THEN
  toNum=asc(value$)
ELSE
  toNum=asc(left$(value$,1))*256 + ASC(right$(value$,1))
ENDIF
END FUNCTION

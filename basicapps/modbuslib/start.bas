' Add current EMDO modbus library here
' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2015-2016 swissEmbedded GmbH, All rights reserved.
' EMDO modbus master library
' Protocols are freely available from www.modbus.org
' http://www.modbus.org/docs/Modbus_Application_Protocol_V1_1b.pdf
' Overview https://en.wikipedia.org/wiki/Modbus
' Modbus RTU framing
' 1     Slave Address
' 1     Function code 
' n     data
' 2     CRC
' Modbus TCP framing
' Bytes Description
' 2     Transaction identifier
' 2     Protocol identifier (zero)
' 2     Number of remaining bytes in the frame
' 1     Slave address
' 1     Function code
' n     Payload
 

' Modbus function all (master)
' itf$  Interface with string.Example "RTU:RS485:1" or "TCP:192.168.0.1:90"
' slv%  Slave Address
' fnc%  Function Codes:
'       1=Read Coils (bits)
'       2=Read Discrete Inputs
'   	3=Read Holding Register
'       4=Read Input Registers 
'		5=Write Single Coil (bits)
'		6=Write Single Register
'      15=Write Multiple Coils (bits)
'      16=Write Multiple Register
' addr% Modbus Address
' num%  Number of Registers/Bits
' data$ Data for Read/Write (fnc%=5 data must be &HFF00 or &H0000)
' tmo%  Timeout in ms
' return   0 = ok, negative value = error
FUNCTION mbFunc(itf$,slv%,fnc%,addr%,num%,dta$,tmo%)
 ' Validate call first 
 IF NOT ((addr% >= 0 AND addr%<=&HFFFF)) THEN
  ' Address is out of range
  mbFunc=-10   
  EXIT FUNCTION
 ELSE IF NOT (slv%>=0 AND slv%<255) THEN
  ' Slave address range invalid
  mbFunc=-11    
  EXIT FUNCTION
 ELSE IF NOT ((fnc%>=1 AND fnc%<=6) OR (fnc%>=15 AND fnc%<=16) OR (fnc%>=22 AND fnc%<=23)) THEN
  ' Function code is invalid 
  mbFunc=-12    
  EXIT FUNCTION
 ELSE IF NOT tmo% > 100 THEN
  ' Minimal timeout needed to transfer data
  mbFunc=-13    
  EXIT FUNCTION   
 ELSE IF num% < 1 OR num% > 100 THEN
  ' We limit the number to 100 registers, MMBASIC is limited to 255 chars per string
  mbFunc=-14
  EXIT FUNCTION
 ELSE IF (fnc%=5 OR fnc%=6) AND len(dta$)<>2 THEN 
  ' Write single coil and write single register needs one word of data
  mbFunc=-15
  EXIT FUNCTION 
 ELSE IF (fnc%=15) AND (len(dta$)*8)<(num%) THEN 
  ' Write single coil and write single register needs one word of data
  mbFunc=-16
  EXIT FUNCTION 
 ELSE IF (fnc%=16) AND len(dta$)<>(num%*2) THEN 
  ' Write single coil and write single register needs one word of data
  mbFunc=-16
  EXIT FUNCTION 
 ENDIF
 
 Local rq$
 Local n%, rpl%, py%, err%

 ' Make request
 IF fnc%=1 OR fnc%=2 THEN
  ' Function code 1 (8 bits in a byte, round up bytes)
  rq$=chr$(fnc%)+conv("u16/bbe",addr%)+conv("u16/bbe",num%)
  n%=num%/8
  IF n%*8 < num% THEN
   n%=n%+1
  ENDIF   
  rpl%=2+n%
  py%=n%
 ELSE IF fnc%=3 OR fnc%=4 THEN
  ' Function code 3,4  
  rq$=chr$(fnc%)+conv("u16/bbe",addr%)+conv("u16/bbe",num%)  
  rpl%=2+2*num%
  py%=2*num%
 ELSE IF fnc% = 5 OR fnc% = 6 THEN 
  ' Function code 5, 6
  rq$=chr$(fnc%)+conv("u16/bbe",addr%)+dta$  
  rpl%=5
  py%=2
 ELSE IF fnc% = 15 OR fnc%=16 THEN 
  ' Function code 15
  rq$=chr$(fnc%)+conv("u16/bbe",addr%)+conv("u16/bbe",num%)+CHR$(len(dta$))+dta$  
  rpl%=5
  py%=0
 ENDIF  
 ' Send request and receive response 
 err%=mbCom(itf$,slv%,fnc%,rq$,rpl%, py%, rp$, tmo%) 
 dta$=rp$
 mbFunc=err%
END FUNCTION

' Modbus low level function for data exchange
' itf$  Interface with string.Example "RTU:RS485:1" or "TCP:192.168.0.1:90"
' slv%  Slave Address
' fnc%  Function Code
' rq$   Request Data
' rpl%  Expected response length
' py%   Expected payload length
' rp$   Response Data
' tmo%  Timeout in ms
' return Error code 0 = ok, negative value = error
FUNCTION mbCom(itf$,slv%,fnc%,rq$,rpl%, py%, rp$, tmo%)

LOCAL interf$, ln$, msg$, num$, prot$, req$, rp$, rsp$, tn$
LOCAL n%, con%, err%, rpl%, trans%

 ' parse if$ for either RTU, TCP on RS485 or ETH 
 prot$=split$(0,itf$,":")
 interf$=split$(1,itf$,":")
 num$=split$(2,itf$,":")
 
 ' add framing
 IF prot$ = "RTU" THEN
  msg$=CHR$(slv%)+rq$
  req$=msg$+CRCCalc$(0,msg$) ' CRC16
 ELSE
  trans% = Ticks() and &HFFFF
  tn$=conv("u16/bbe", trans%)
  ln$=conv("u16/bbe",len(rq$)+1)
  req$=tn$+chr$(0)+chr$(0)+ln$+CHR$(slv%)+rq$
 ENDIF
 
 IF interf$="RS485" THEN
  ' Send it over rs485
  n%=RS485Write(req$)
  rsp$=RS485Reads(rpl%+3,tmo%)
  mbLog(interf$,req$,rsp$,"RS485")
 ELSE
  ' Send it over ethernet
  con%=SocketClient( 1, interf$, val(num$) )   
  IF con% >0 THEN
   n%=SocketOption(con%,"SO_RCVTIMEO",tmo%)
   n%=SocketOption(con%,"SO_SNDTIMEO",tmo%)    
   n%=SocketWrite( con%, req$ )    
   rsp$=SocketRead$(con%,rpl%+7)
   done%=SocketClose( con% )
   mbLog(interf$,req$,rsp$,"ETH")   
  ELSE
   mbCom=-20
   EXIT FUNCTION
  ENDIF
 ENDIF  
 ' Finally check response to be valid  
 IF prot$ = "RTU" THEN
  ' Check if this is an exception
  IF len(rsp$) = 5 THEN
   ' Size fits exception
   IF asc(mid$(rsp$,1,1))=slv% AND asc(mid$(rsp$,2,1))=(fnc% OR &H80) THEN
    ' This is an exception
    IF CRCCalc$(0,mid$(rsp$,2,2)<>mid$(rsp$,2,2) THEN
	 ' Checksum bad
	 mbCom=-31
	 EXIT FUNCTION
	ENDIF 
	' return exception code
    print "Exception"
	mbCom=-asc(mid$(rsp$,3,1))
	EXIT FUNCTION
   ENDIF
  ENDIF
  ' Check if regular message
  IF len(rsp$)<(rpl%+3) THEN
   mbCom=-32
   EXIT FUNCTION
  ELSE IF slv% <> asc(left$(rsp$,1)) THEN
   ' check slv address must match
   mbCom=-33
   EXIT FUNCTION
  ELSE IF CRCCalc$(0,mid$(rsp$,2,rpl%)<>right$(rsp$,2) THEN
   ' Checksum bad
   mbCom=-34
   EXIT FUNCTION
  ENDIF
  ' cut the response data out
  rp$=mid$(rsp$,len(rp$)-py%,py%)
 ELSE
  ' Check if this is an exception  
  IF len(rsp$) = 9 THEN
   ' Size fits exception      
   IF left$(rsp$,2)=tn$ AND asc(mid$(rsp$,7,1))=slv% AND asc(mid$(rsp$,8,1))=(fnc% OR &H80) THEN
	' return exception code
    print "Exception"
	mbCom=-asc(mid$(rsp$,9,1))	
	EXIT FUNCTION
   ENDIF
  ENDIF
  ' Check if regular message
  IF len(rsp$)<(rpl%+7) THEN
   mbCom=-22
   EXIT FUNCTION
  ELSE IF tn$ <> left$(rsp$,2) THEN
   ' check slv address must match
   mbCom=-23
   EXIT FUNCTION
  ELSE IF slv% <> asc(mid$(rsp$,7,1)) THEN
   ' check slv address must match
   mbCom=-24
   EXIT FUNCTION  
  ENDIF
  ' cut the response data out
  rp$=right$(rsp$,py%)  
 ENDIF 
 mbCom=0
END FUNCTION

'----------------------------------------
' log a telegram
' print a modbus telegram on the console
'----------------------------------------
SUB mbLog(itf$,tx$,rx$,msg$)
LOCAL s$, h$
LOCAL i
 s$=msg$+":"+itf$+" tx:"
 FOR i=1 TO len(tx$)
  h$=hex$(asc(mid$(tx$,i,1)))
  IF len(h$) = 1 THEN 
   h$="0"+h$
  ENDIF
  s$=s$+h$
 NEXT
 print s$
 s$=" rx:"
 FOR i=1 TO LEN(rx$)
   h$=hex$(asc(mid$(rx$,i,1)))
   IF len(h$) = 1 THEN 
    h$="0"+h$
   ENDIF
  s$=s$+h$
 NEXT
 PRINT s$
END SUB

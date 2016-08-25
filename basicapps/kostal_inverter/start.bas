' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2015-2016 swissEmbedded GmbH, All rights reserved.
' Eastron SDM630 energy meter EMDO modbus example
' Documentation available from Kostal (NDA required)
addr%=255
server$="192.168.1.1"
start:
 KostalReaderTotalEnergy(server$,addr%,2000,kWh)
 print "Kostal " kWh
 pause 30000
 goto start

' Kostal inverter reading
' server$ IP address of the inverter
' addr% rs485 address of the inverter (check inverter config, default 255) 
' timeout% timeout in ms
' kWh inverter total energy
FUNC KostalReaderTotalEnergy(server$,addr%, timeout%, kWh)
 ' Open connection to the inverter
 con%=SocketClient( 1, server$, 81 )    
 IF con% <=0.0 THEN		
  EXIT SUB ' inverter not available try next time again
 Endif 
 n%=SocketOption(con%,"SO_RCVTIMEO",timeout%)
 n%=SocketOption(con%,"SO_SNDTIMEO",timeout%)    
	
 num=SocketWrite( con, &H62, addr%, 3, addr%, 0, &H45, (0-(&HAA+(2*addr%))) AND 255 , 0)
 rsp$=SocketRead(con,11)
 IF len(rsp$) <> 11 then
  EXIT SUB 0 ' inverter response is too long
 Endif
 kWh=conv("ble/i32",mid$(rsp$,6,4))/1000.0
 done=SocketClose( con% )  
END FUNC

' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2015-2016 swissEmbedded GmbH, All rights reserved.
' Advantech ADAM-4117, ADAM-4118, ADAM-4150, ADAM-4168
' Documentation http://www.advantech.de/products/1-2mlc85/adam-4168/mod_4fc0023a-80ae-476d-9fd4-81a68b3471b4
' http://downloadt.advantech.com/ProductFile/Downloadfile1/1-1011MRM/UM-ADAM-4100-Ed%202-1-EN.pdf
SYS.Set "rs485", "baud=9600 data=8 stop=1 parity=n"
slv%=1
itf$="RS485:1"

start:
 ADAM4117(itf$,slv%)
 print "ADAM4117 " 
 pause 30000
 goto start

' ADAM detect device
FUNC ADAMInf(itf$,slv%,mod%, ver%)
' Read 
 err%= mbFuncRead(itf$,slv%,3,40211,2,rMod$,500) OR mbFuncRead(itf$,slv%,3,40213,2,rVer$,500)
 if err% then
  print "ADAM error on read"
  exit func
 end if
 mod%=conv("bbe/i32",rMod$)
 ver%=conv("bbe/i32",rVer$)
END FUNC
 
' ADAM - 4117
' itf$ modbus interface (see EMDO modbus library for details)
' slv% adam slave address default 1 
FUNC ADAM4117(itf$,slv%,)
 ' Read kW
 err%= mbFuncRead(itf$,slv%,3,30013,2,rkW1$,500) OR mbFuncRead(itf$,slv%,3,30015,2,rkW2$,500) OR mbFuncRead(itf$,slv%,3,30017,2,rkW3$,500)
 if err% then
  print "ADAM error on read"
  exit func
 end if
 ' Convert register values to float32
 kW1=conv("bbe/f32",rkW1$)
 kW2=conv("bbe/f32",rkW2$)
 kW3=conv("bbe/f32",rkW3$) 
END FUNC

' ADAM - 4118
' itf$ modbus interface (see EMDO modbus library for details)
' slv% adam slave address default 1 
FUNC ADAM4117(itf$,slv%,)
 ' Read kW
 err%= mbFuncRead(itf$,slv%,3,30013,2,rkW1$,500) OR mbFuncRead(itf$,slv%,3,30015,2,rkW2$,500) OR mbFuncRead(itf$,slv%,3,30017,2,rkW3$,500)
 if err% then
  print "ADAM error on read"
  exit func
 end if
 ' Convert register values to float32
 kW1=conv("bbe/f32",rkW1$)
 kW2=conv("bbe/f32",rkW2$)
 kW3=conv("bbe/f32",rkW3$) 
END FUNC

' ADAM - 4150
' itf$ modbus interface (see EMDO modbus library for details)
' slv% adam slave address default 1 
FUNC ADAM4117(itf$,slv%,)
 ' Read kW
 err%= mbFuncRead(itf$,slv%,3,30013,2,rkW1$,500) OR mbFuncRead(itf$,slv%,3,30015,2,rkW2$,500) OR mbFuncRead(itf$,slv%,3,30017,2,rkW3$,500)
 if err% then
  print "ADAM error on read"
  exit func
 end if
 ' Convert register values to float32
 kW1=conv("bbe/f32",rkW1$)
 kW2=conv("bbe/f32",rkW2$)
 kW3=conv("bbe/f32",rkW3$) 
END FUNC

' ADAM - 4168
' itf$ modbus interface (see EMDO modbus library for details)
' slv% adam slave address default 1 
FUNC ADAM4117(itf$,slv%,)
 ' Read kW
 err%= mbFuncRead(itf$,slv%,3,30013,2,rkW1$,500) OR mbFuncRead(itf$,slv%,3,30015,2,rkW2$,500) OR mbFuncRead(itf$,slv%,3,30017,2,rkW3$,500)
 if err% then
  print "ADAM error on read"
  exit func
 end if
 ' Convert register values to float32
 kW1=conv("bbe/f32",rkW1$)
 kW2=conv("bbe/f32",rkW2$)
 kW3=conv("bbe/f32",rkW3$) 
END FUNC

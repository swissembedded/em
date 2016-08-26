' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2015-2016 swissEmbedded GmbH, All rights reserved.
' AEConversion AESGI protocol V1.7, control microinverters 
' INV250, INV350 and INV500 over RS485 (requirement)
' Documentation available from manufacturer on request
' http://www.aeconversion.de/
' Depending on firmware version, some commands do not work
SYS.Set "rs485", "baud=9600 data=8 stop=1 parity=n term=1"

 dim idl%(32)
 id%=14
 frac%=10
start: 
 AECProbe ( idl%() )
 'id%=idl%(1)
 AECGetType(id%,st%, tp$)
 print "AE is INV" tp$ st% 
 'AECGetStatus( id%, st%, Udc, Idc, Pdc, Uac, Iac, Pac, T,Ed)
 'print "AE Status " st% Udc Idc Pdc Uac Iac Pac T Ed
 'AECGetOutputPower ( id%, st%, frac% )
 'AECSetOutputPower(id%, frac%) 
 'AECSetOutputPowerBroadcast(frac%) 
 'print "AE Power " st% frac%
 'AECGetAutotest ( id%, st%, Ueff, Freq, UMax, TUMax%, UMin, TUMin%, FMin, TFMin%, FMax, TFMax%, Res%)
 'print "AE Test " st% Ueff Freq UMax TUMax% UMin TUMin% FMin TFMin% FMax TFMax% Res%
 'AECGetOffGridParams ( id%, st%, Ueff, Freq, UMax, TUMax%, UMin, TUMin%, FMin, TFMin%, FMax, TFMax%)
 'print "AE Off " st% Ueff Freq UMax TUMax% UMin TUMin% FMin TFMin% FMax TFMax%
 'AECGetErrorLog ( id%, st%, T%, EC1%, T1%, EC2%, T2%,  EC3%, T3%, EC4%, T4%, EC5%, T5%, EC6%, T6% )
 'print "AE Err " st% T% EC1% T1% EC2% T2% EC3% T3% EC4% T4% EC5% T5% EC6% T6% 
 'AECGetCurrentLimit ( id%, st%, Idc) 
 'AECSetCurrentLimit ( id%, st%, Idc)  
 'print "AE Current " st% Idc
 'AECGetOperationMode ( id%, st%, mode%, Udc)
 'AECSetOperationMode ( id%, st%, mode%, Udc)
 'print "AE Mode " st% mode% Udc
 pause 10000
 goto start

 '**
' Subroutine to communicate with AEConversion inverter
' qy$ query send to inverter
' rsp$ response from the inverter
SUB AECRS485Com ( qy$,rsp$ )
  LOCAL w
  'print "qy " qy$
  w = RS485Write(qy$,13)
  rsp$ = RS485ReadLn$(2000,CHR$(13)) 
  if len(rsp$) > 3 then
   ' remove checksum
   'print "rsp " mid$(rsp$,1,len(rsp$)-3)   
  endif
END SUB

'**
' Subroutine to probe AEConversion inverter, we take the one with the highest number
' it returns an array of id% with active devices
SUB AECProbe ( idl%() )  
  x%=1
  FOR y%=1 TO 32
   AECGetType(y%, st%,tp$)   
   IF st% >= 0 THEN     
    Print "Found device " y%
    idl%(x%) = y%
	x%=x%+1
   ENDIF
  NEXT y%
END SUB

'**
' Subroutine to get AEConversion inverter type
' id% inverter id 1-32
' st% -1 = no response
' tp$ inverter type string e.g. 500-90
SUB AECGetType ( id%, st%, tp$)
  qy$ = "#"+FORMAT$(id%,"%02g")+"9"  
  AECRS485Com (qy$,rsp$)   
  if len(rsp$) = 0 then
   st%=-1
  else
  st%=0
  ' *149 500-90 3   
  '12345678901234
   tp$=MID$(rsp$,7,5)
  endif 
END SUB
 
'**
' Subroutine to get status from AEConversion inverter 
' id% inverter id 1-32
' st% inverter status, -1 = no response
' Udc dc input voltage V
' Idc dc input current I
' Pdc dc input power Watt
' Uac ac output voltage V
' Iac ac output current A
' Pac ac output power W
' T inverter temperature °C
' Ed daily energy Wh
SUB AECGetStatus ( id%, st%, Udc, Idc, Pdc, Uac, Iac, Pac, T,Ed)
  qy$ = "#" + FORMAT$(id%,"%02g") + "0"
  AECRS485Com(qy$,rsp$)
  ' *140   0  54.2  4.10     0 243.3  0.67   217  50     79
  '123456789012345678901234567890123456789012345678901234567890 
  if len(rsp$) = 0 then
   st% = -1
  else
   st%=VAL(MID$(rsp$,7,3))
   Udc=VAL(MID$(rsp$,11,5))
   Idc=VAL(MID$(rsp$,17,5))
   Pdc=VAL(MID$(rsp$,23,5))
   Uac=VAL(MID$(rsp$,29,5))
   Iac=VAL(MID$(rsp$,35,5))
   Pac=VAL(MID$(rsp$,41,5))
   T=VAL(MID$(rsp$,47,3))
   Ed=VAL(MID$(rsp$,51,6))
  endif
END SUB

'**
' Subroutine to set reduced power production from AEConversion inverter 
' Note: value is reset on device restart (sporadic restart on net spikes)
' id% inverter id 1-32
' frac% fraction of nominal inverter power
SUB AECSetOutputPower ( id%, frac%)
  qy$ = "#" + FORMAT$(id%,"%02g") + "L "+ FORMAT$(frac%,"%03g")  
  ' #14L 050
  w = RS485Write(qy$,13)
  ' no response send from inverter
END SUB

'**
' Subroutine to set reduced power production from AEConversion inverter 
' Broadcast to all devices
' Note: value is reset on device restart (sporadic restart on net spikes)
' frac% fraction of nominal inverter power
SUB AECSetOutputPowerBroadcast ( frac% )
  qy$ = "#" + "b018 "+ FORMAT$(frac%,"%03g")  
  ' #b018 050
  w = RS485Write(qy$,13)
  ' no response send from inverter
END SUB

'**
' Subroutine to set reduced power production from AEConversion inverter 
' Note: value is reset on device restart (sporadic restart on net spikes)
' id% inverter id 1-32
' st% inverter status, -1 = no response
' frac% fraction of nominal inverter power
SUB AECGetOutputPower ( id%, st%, frac% )
  qy$ = "#" + FORMAT$(id%,"%02g") + "L"
  ' #14L
  AECRS485Com(qy$,rsp$)  
  ' *14L 050 0
  '12345678901
  if len(rsp$) = 0 then
   st% = -1   
  else   
   st%=0   
   frac%=VAL(MID$(rsp$,7,3))
  endif
END SUB

'**
' Subroutine to autotest grid from AEConversion inverter 
' This is not working with my firmware
' id% inverter id 1-32
' st% inverter status, -1 = no response
' Ueff effective Voltage AC
' Freq Grid frequency
' UMax upper  voltage
' TUMax% off-grid time
' UMin lower off-grid voltage
' TUMin% off-grid time
' FMin% lower off-grid frequency
' TFMin% lower off-grid time
' FMax upper off-grid frequency
' TFMax% lower off-grid time
' Res% result
SUB AECGetAutotest ( id%, st%, Ueff, Freq, UMax, TUMax%, UMin, TUMin%, FMin, TFMin%, FMax, TFMax%, Res%)
  qy$ = "#" + FORMAT$(id%,"%02g") + "A"
  ' #14A
  AECRS485Com(qy$,rsp$)  
  if len(rsp$) = 0 then
   st% = -1
  else
   st%=0
   Ueff=VAL(MID$(rsp$,7,5))
   Freq=VAL(MID$(rsp$,13,4))
   UMax=VAL(MID$(rsp$,18,5))
   TUMax%=VAL(MID$(rsp$,24,4))
   UMin=VAL(MID$(rsp$,29,5))
   TUMin%=VAL(MID$(rsp$,35,4))
   d=VAL(MID$(rsp$,40,5))
   if d <> 0 then
    FMin=1502500.0/d
   else 
    FMin=-1
   endif   
   TFMin%=VAL(MID$(rsp$,46,4))
   d=VAL(MID$(rsp$,51,5))
   if d <> 0 then
    FMax=1502500.0/d
   else 
    FMax=-1
   endif   
   TFMax%=VAL(MID$(rsp$,57,4))
   Res%=VAL(MID$(rsp$,62,5))
  endif
END SUB

'**
' Subroutine to read off-grid parameter range from AEConversion inverter 
' id% inverter id 1-32
' st% inverter status, -1 = no response
' Ueff effective Voltage AC
' Freq Grid frequency
' UMax upper  voltage
' TUMax% off-grid time
' UMin lower off-grid voltage
' TUMin% off-grid time
' FMin% lower off-grid frequency
' TFMin% lower off-grid time
' FMax upper off-grid frequency
' TFMax% lower off-grid time
SUB AECGetOffGridParams ( id%, st%, Ueff, Freq, UMax, TUMax%, UMin, TUMin%, FMin, TFMin%, FMax, TFMax%)
  qy$ = "#" + FORMAT$(id%,"%02g") + "P"
  AECRS485Com(qy$,rsp$)  
  if len(rsp$) = 0 then
   st% = -1   
  else
   st%=0
   ' *14P 230.0 50.0 264.5 0140 184.0 0140 31631 0160 29186 0160 
   '123456789012345678901234567890123456789012345678901234567890 
   Ueff=VAL(MID$(rsp$,7,5))
   Freq=VAL(MID$(rsp$,13,4))
   UMax=VAL(MID$(rsp$,18,5))
   TUMax%=VAL(MID$(rsp$,24,4))
   UMin=VAL(MID$(rsp$,29,5))
   TUMin%=VAL(MID$(rsp$,35,4))
   d=VAL(MID$(rsp$,40,5))
   if d <> 0 then
    FMin=1502500.0/d
   else 
    FMin=-1
   endif     
   TFMin%=VAL(MID$(rsp$,46,4))
   d=VAL(MID$(rsp$,51,5))
   if d <> 0 then
    FMax=1502500.0/d
   else 
    FMin=-1
   endif   
   TFMax%=VAL(MID$(rsp$,57,4))   
  endif
END SUB

'**
' Subroutine to read error log from AEConversion inverter
' We can log up to 6 events
' id% inverter id 1-32
' st% inverter status, -1 = no response
' T1% time since start
' EC1% errorcode
' T2% time since start
' EC2% errorcode
' T3% time since start
' EC3% errorcode
' T4% time since start
' EC4% errorcode
' T5% time since start
' EC5% errorcode
' T6% time since start
' EC6% errorcode
SUB AECGetErrorLog ( id%, st%, T%, EC1%, T1%, EC2%, T2%,  EC3%, T3%, EC4%, T4%, EC5%, T5%, EC6%, T6% )
  qy$ = "#" + FORMAT$(id%,"%02g") + "F"
  AECRS485Com(qy$,rsp$)  
  if len(rsp$) = 0 then
   st% = -1   
  else
   ' *14F 23004 018 11012 018 11017 018 11798 018 11799 018 11801 018 11803  
   '123456789012345678901234567890123456789012345678901234567890123456789012 
   st%=0
   T%=VAL(MID$(rsp$,7,5))
   EC1%=VAL(MID$(rsp$,13,3))
   T1%=VAL(MID$(rsp$,17,5))
   EC2%=VAL(MID$(rsp$,23,3))
   T2%=VAL(MID$(rsp$,27,5))
   EC3%=VAL(MID$(rsp$,33,3))
   T3%=VAL(MID$(rsp$,37,5))
   EC4%=VAL(MID$(rsp$,43,3))
   T4%=VAL(MID$(rsp$,47,5))
   EC5%=VAL(MID$(rsp$,53,3))
   T5%=VAL(MID$(rsp$,57,5))
   EC6%=VAL(MID$(rsp$,63,3))
   T6%=VAL(MID$(rsp$,67,3))
  endif
END SUB

'**
' Subroutine to set current limit from AEConversion inverter 
' id% inverter id 1-32
' st% inverter status, -1 = no response
' Idc set DC current limit for output 
' (see inverter datasheet for range)
SUB AECSetCurrentLimit ( id%, st%, Idc)
  cur$=FORMAT$(Idc,"%02.1f")  
  IF len(cur$)=3 THEN 
   cur$ = "0"+cur$ 
  endif  
  qy$ = "#" + FORMAT$(id%,"%02g") + "S "+ cur$
  AECRS485Com(qy$,rsp$)  
  if len(rsp$) = 0 then   
   st% = -1
  else   
   ' *14S  0.5
   '1234567890123
   st%= 0
   Idc=VAL(MID$(rsp$,7,4))
   print Idc
  endif
END SUB

'**
' Subroutine to get current limit from AEConversion inverter 
' id% inverter id 1-32
' st% inverter status, -1 = no response
' Idc set DC current limit for output 
' (see inverter datasheet for range)
SUB AECGetCurrentLimit ( id%, st%, Idc)
  qy$ = "#" + FORMAT$(id%,"%02g") + "S"
  AECRS485Com(qy$,rsp$)
  ' *14S  0.0
  '123456789012345  
  if len(rsp$) = 0 then
   st% = -1
  else   
   st%= 0
   Idc=VAL(MID$(rsp$,7,4))
  endif
END SUB

'**
' Subroutine to set operation mode from AEConversion inverter 
' Note: value is reset on device restart (sporadic restart on net spikes)
' id% inverter id 1-32
' st% inverter status, -1 = no response
' mode% 0=mppt mode, 2=voltage mode
' Udc min voltage where the inverter stops operating
' (see inverter datasheet for range)
SUB AECSetOperationMode ( id%, st%, mode%, Udc)
  volt$=FORMAT$(Idc,"%02.1f")
  IF len(volt$)=3 THEN 
   volt$ = "0"+volt$ 
  endif
  qy$ = "#" + FORMAT$(id%,"%02g") + "B "+ FORMAT$(mode%,"%01g")+" "+volt$
  AECRS485Com(qy$,rsp$)
  if len(rsp$) = 0 then
   st% = -1
  else
   ' *14B 0  0.0
   '123456789012345  
   st%= 0
   mode%=VAL(MID$(rsp$,7,1))
   Udc=VAL(MID$(rsp$,9,4))
  endif
END SUB

'**
' Subroutine to get operation mode from AEConversion inverter 
' Note: value is reset on device restart (sporadic restart on net spikes)
' id% inverter id 1-32
' st% inverter status, -1 = no response
' mode% 0=mppt mode, 2=voltage mode
' Udc min voltage where the inverter stops operating
' (see inverter datasheet for range)
SUB AECGetOperationMode ( id%, st%, mode%, Udc)
  qy$ = "#" + FORMAT$(id%,"%02g") + "B"
  AECRS485Com(qy$,rsp$)
  if len(rsp$) = 0 then
   st% = -1
  else
   ' *14B 0  0.0 
   '123456789012345  
   st%= 0
   mode%=VAL(MID$(rsp$,7,1))
   Udc=VAL(MID$(rsp$,9,4))
  endif
END SUB

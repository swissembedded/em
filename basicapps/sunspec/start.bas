' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2015 - 20116 swissEmbedded GmbH, All rights reserved.
' This example reads a sunspec compatible inverter over modbus
' Please make sure that the inverters RS485 interface 
' is configured correctly. If multiple inverters are connected on a serial
' line make sure each device has a unique modbus slave address configured.
' Cable must be twisted pair with correct end termination on both ends
' Documentations
' SunSpec-EPRI-Rule21-Interface-Profile
' Fronius Datamanager TCP & RTU
' SMA SunSpec Modbus Schnittstelle
' Technical Note SunSpec Logging in Solaredge Inverters
SYS.Set "rs485", "baud=9600 data=8 stop=1 parity=n term=1"
kW = 0.0
kWh = 0.0
opst = 0
itf$="RTU:rs485:1"
slv1%=1
slv2%=1
START:
	err%=SunspecReader ( itf%, slv1%, iMan$, iMod$, iVer$, iSer$, pNum%, Iac1, Iac2, Iac3, Uac1, Uac2, Uac3, Pac, Fac, VA, VAR, PF, E, Idc, Udc, Pdc, T1, T2, T3, T4, Status%, Code% )
	PRINT "Inverter1:"  err% iMan$ iMod$ iVer$ iSer$ pNum% Iac1 Iac2 Iac3 Uac1 Uac2 Uac3 Pac Fac VA VAR PF E Idc Udc Pdc T1 T2 T3 T4 Status% Code% 
	err%=SunspecReader ( itf%, slv2%, iMan$, iMod$, iVer$, iSer$, pNum%, Iac1, Iac2, Iac3, Uac1, Uac2, Uac3, Pac, Fac, VA, VAR, PF, E, Idc, Udc, Pdc, T1, T2, T3, T4, Status%, Code% )
	PRINT "Inverter2:"  err% iMan$ iMod$ iVer$ iSer$ pNum% Iac1 Iac2 Iac3 Uac1 Uac2 Uac3 Pac Fac VA VAR PF E Idc Udc Pdc T1 T2 T3 T4 Status% Code% 
	PAUSE 5000
GOTO start


' Sunspec reader for Solaredge, SMA, Fronius
' iMan$ Inverter Manufacturer
' iMod$ Inverter Model
' iVer$ Inverter Version
' iSer$ Inverter Serial Number
' pNum% Number of AC Phases
' Iac1  AC Current Phase 1
' Iac2  AC Current Phase 2 (if available)
' Iac3  AC Current Phase 3 (if available)
' Uac1  AC Voltage Phase 1
' Uac2  AC Voltage Phase 2 (if available)
' Uac3  AC Voltage Phase 3 (if available)
' Pac   AC Power
' Fac   AC Frequency
' VA    Apparent Power
' VAR   Reactive Power
' PF    Power Factor
' E     AC Lifetime Energy Production
' Idc   DC Current
' Udc   DC Voltage
' Pdc   DC Power
' T1    Temperature 1 (Cabinet)
' T2    Temperature 2 (Coolant)
' T3    Temperature 3 (Transformer)
' T4    Temperature 4 (other)
' Status% Device Status
'  Solaredge only supports 1,2,4:
'  Fronius/SMA all:
'  1=off
'  2=auto shutdown
'  3=starting
'  4=normal operation
'  5=power limit activ
'  6=inverter shuting down
'  7=one or more error occured
'  8=standby
' Code% vendor specific code (see vendor sunspec documentation for details)
FUNCTION SunspecReader ( itf%, slv%, iMan$, iMod$, iVer$, iSer$, pNum%, Iac1, Iac2, Iac3, Uac1, Uac2, Uac3, Pac, Fac, VA, VAR, PF, E, Idc, Udc, Pdc, T1, T2, T3, T4, Status%, Code% )
 LOCAL err%, base%, rRsp$, ln%, id%, Iacsf, Uacsf, Pacsf, Facsf, VAsf, VARsf, PFsf, Esf, Idcsf, Udcsf, Pdcsf, Tsf
 ' Pls see the referenced document below for manufacturer dependent registers
 ' Check common sunspec registers
 ' Free documents SunSpec-EPRI-CA-Rule-21-Interface-Profile, SunSpec-Inverter-Models-12020 and
 ' SunSpec-Information-Models-12041
 ' we try 40001, 50001 and 00001
 base%=40001
 err%=mbFunc(itf$,slv%,3,base%-1,2,rRsp$,500)
 IF err% THEN
  ' Base not working try next
  base%=50001
  err%=mbFunc(itf$,slv%,3,base%-1,2,rRsp$,500)
  IF err% THEN
   base%=1
   err%=mbFunc(itf$,slv%,3,base%-1,2,rRsp$,500)
   IF err% THEN
    ' We finally give up
    SunspecReader=err%
    EXIT FUNCTION
   ENDIF  
  ENDIF  
 ENDIF
 
 
 ' Expect SunSpec "SunS" magic and Common Model Block (1)  
 ' Block is at least 65 registers 
 IF conv("bbe/u32", rRsp$)<> &H053756e53 THEN
  SunspecReader=-100
  EXIT FUNCTION
 ENDIF
 
 
 ' Now we iterate through the blocks,  base% is always the ID block, followed by L register
 base%=base%+2
 DO
  ' Read ID and L of the block
  err%=mbFunc(itf$,slv%,3,base%,4,rRsp$,500)
  IF err% THEN
  SunspecReader=err%
  EXIT FUNCTION
  ENDIF
  id%=conv("bbe/u16",left$(rRsp$,2)
  ln%=conv("bbe/u16",right$(rRsp$,2)
  IF id% = 1 THEN
   ' Common Model Block is common for all models  
   ' Parse manufacturer, Model, Version, SerialNumer
   err%=mbFunc(itf$,slv%,3,base%+4-1,32,iMan$,500) OR mbFunc(itf$,slv%,3,base%+20-1,32,iMod$,500) OR mbFunc(itf$,slv%,3,base%+44-1,16,iVer$,500) OR mbFunc(itf$,slv%,3,base%+52-1,32,iSer$,500)
   IF err% THEN
    SunspecReader=err%
    EXIT FUNCTION
   ENDIF
  ELSEIF id%=101 OR id%=102 OR id% = 103 THEN  
   ' Sunspec Inverter Modbus Map
   err%=mbFunc(itf$,slv%,3,base%+2-1,40,rRsp$,500)
   IF err% THEN
    SunspecReader=err%
    EXIT FUNCTION
   ENDIF  
   pNum%=id%-110
   Iacsf=10.0^conv("bbe/i16",mid$(rRsp$,9,2))
   Iac1=conv("bbe/u16",mid$(rRsp$,3,2))*Iacsf
   Iac2=conv("bbe/u16",mid$(rRsp$,5,2))*Iacsf
   Iac3=conv("bbe/u16",mid$(rRsp$,7,2))*Iacsf
   Uacsf=10.0^conv("bbe/i16",mid$(rRsp$,23,2))
   Uac1=conv("bbe/u16",mid$(rRsp$,17,2))*Uacsf
   Uac2=conv("bbe/u16",mid$(rRsp$,19,2))*Uacsf
   Uac3=conv("bbe/u16",mid$(rRsp$,21,2))*Uacsf
   Pacsf=10.0^conv("bbe/i16",mid$(rRsp$,27,2))
   Pac=conv("bbe/i16",mid$(rRsp$,25,2))*Pacsf
   Facsf=10.0^conv("bbe/i16",mid$(rRsp$,31,2))
   Fac=conv("bbe/u16",mid$(rRsp$,29,2))*Facsf
   VAsf=10.0^conv("bbe/i16",mid$(rRsp$,35,2))
   VA=conv("bbe/i16",mid$(rRsp$,33,2))*VAsf
   VARsf=10.0^conv("bbe/i16",mid$(rRsp$,39,2))
   VAR=conv("bbe/i16",mid$(rRsp$,37,2))*VARsf
   PFsf=10.0^conv("bbe/i16",mid$(rRsp$,43,2))
   PF=conv("bbe/i16",mid$(rRsp$,41,2))*PFsf
   Esf=10.0^conv("bbe/u16",mid$(rRsp$,49,4))
   E=conv("bbe/u32",mid$(rRsp$,45,4))*Esf
   Idcsf=10.0^conv("bbe/i16",mid$(rRsp$,53,2))
   Idc=conv("bbe/u16",mid$(rRsp$,51,2))*Idcsf
   Udcsf=10.0^conv("bbe/i16",mid$(rRsp$,57,2))
   Udc=conv("bbe/u16",mid$(rRsp$,55,2))*Udcsf
   Pdcsf=10.0^conv("bbe/i16",mid$(rRsp$,61,2))
   Pdc=conv("bbe/i16",mid$(rRsp$,59,2))*Pdcsf
   Tsf=10.0^conv("bbe/i16",mid$(rRsp$,67,2))
   T1=conv("bbe/i16",mid$(rRsp$,61,2))*Tsf
   T2=conv("bbe/i16",mid$(rRsp$,63,2))*Tsf
   T2=conv("bbe/i16",mid$(rRsp$,64,2))*Tsf
   T2=conv("bbe/i16",mid$(rRsp$,65,2))*Tsf
   Status%=conv("bbe/u16",mid$(rRsp$,69,2))
   Code%=conv("bbe/u16",mid$(rRsp$,71,2)) 
   SunspecReader=0
   EXIT FUNCTION
  ELSEIF id%=111 OR id%=112 OR id% = 113 THEN 
   ' Sunspec Inverter Modbus Map (float, Fronius Style)
   err%=mbFunc(itf$,slv%,3,base%+2-1,40,rRsp$,500)
   IF err% THEN
    SunspecReader=err%
    EXIT FUNCTION
   ENDIF  
   pNum%=id%-100
   Iac1=conv("bbe/f32",mid$(rRsp$,5,2))
   Iac2=conv("bbe/f32",mid$(rRsp$,9,2))
   Iac3=conv("bbe/f32",mid$(rRsp$,13,2))
   Uac1=conv("bbe/f32",mid$(rRsp$,25,2))
   Uac2=conv("bbe/f32",mid$(rRsp$,29,2))
   Uac3=conv("bbe/f32",mid$(rRsp$,33,2))
   Pac=conv("bbe/f32",mid$(rRsp$,37,2))
   Fac=conv("bbe/f32",mid$(rRsp$,41,2))
   VA=conv("bbe/f32",mid$(rRsp$,45,2))
   VAR=conv("bbe/f32",mid$(rRsp$,49,2))
   PF=conv("bbe/f32",mid$(rRsp$,53,2))
   E=conv("bbe/u32",mid$(rRsp$,57,4))
   Idc=conv("bbe/f32",mid$(rRsp$,61,2))
   Udc=conv("bbe/f32",mid$(rRsp$,65,2))
   Pdc=conv("bbe/f32",mid$(rRsp$,69,2))
   T1=conv("bbe/f32",mid$(rRsp$,73,2))
   T2=conv("bbe/f32",mid$(rRsp$,77,2))
   T3=conv("bbe/f32",mid$(rRsp$,81,2))
   T4=conv("bbe/f32",mid$(rRsp$,85,2))   
   Status%=conv("bbe/u16",mid$(rRsp$,89,2))
   Code%=conv("bbe/u16",mid$(rRsp$,91,2)) 
   SunspecReader=0
   EXIT FUNCTION
   ELSEIF id%=65535 THEN 
    ' This is the end device model block
	SunspecReader=-101
    EXIT FUNCTION
  ENDIF    
  
  base%=base%+ln%+2 
 LOOP 
END FUNCTION

' Modbus library goes here
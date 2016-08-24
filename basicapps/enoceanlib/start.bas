' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2015-2016 swissEmbedded GmbH, All rights reserved.
' EMDO enocean library, based on Enocean EPP 2.6.3 specification
' the enocean protocol description, see referenced pages below in source code
' http://www.enocean-alliance.org/eep
' Eltako enocean devices (see page 10 and following)
' http://www.eltako.com/fileadmin/downloads/en/_main_catalogue/Gesamt-Katalog_ChT_gb_highRes.pdf
' Omnio enocean devices (protocol details see individual modules)
' http://www.awag.ch/ekat/page_de/awagpg_n_5.html
start:
 'Poll the stack 
 eoReceive()
 goto start
 
 ' Send a RPS/1BS message over enocean
 ' 
 ' eoTransmitRPS(&H50, &H30, &H00000000, &HFFFFFFFF, &H00) -> switch light on
 ' eoTransmitRPS(&H70, &H30, &H00000000, &HFFFFFFFF, &H00) -> switch light off
SUB eoTransmitRPS(db0%, st%, txid%, rxid%, enc%)
 ' Pls see enocean EEP 2.6.2 specification and ESP3 specification
 ' Type = 1 is radio
 ' Data = F6 (RORG = RPS / 1BS), switch state (0x50 = on, 0x70 = off)
 ' OptData = 03 (send) Boardcast FF FF FF FF, dBm (FF), 00 (unencrypted)	 
  msg$ = chr$(&hF6)
  msg$ += chr$(db0%)  
  msg$ += conv("i32/bbe",txid%)
  ' &H30 'T21=1, NU = 1
  ' &H20 'T21=1, NU = 0
  ' &H10 'T21=0, NU = 1   
  ' &H00 'T21=0, NU = 0   
  msg$ += chr$(st%) 
  ' Send  
  msg$ += chr$(&H03)
  ' Broadcast &Hffffffff or actuator id
  msg$+=conv("i32/bbe",rxid%)
  msg$ += chr$(&HFF)
  ' no encryption &H00
  msg$+=chr$(enc%)	
  num% = EnoceanTransmit(1, msg$)	
END SUB

' Poll this routine periodically to parse the enocean packets on the stack. EMDO can hold 8 packets on its stack.
SUB eoReceive()
 n%=EnoceanReceive(tp%,da$,oda$) 
 IF NOT n% THEN    
  'check rx packet 
  'e.g. F6002A42DF20 / 1FFFFFFFF360
  '     A5005081823D780 / 1FFFFFFFF560
  'first two characters are rorg  
  rorg%=asc(left$(da$,1))  
  select case rorg%
   case &hf6 
   ' RPS telegram: DB0, Sender ID, Status (page 11)    
    ' Rocker switches come here 	
	db0%=asc(mid$(da$,2,1))
	id%=conv("bbe/i32",mid$(da$,3,4))    
	st%=asc(mid$(da$,7,1))
	eoRxRocker(tp%,id%,db0%,st%)
	EXIT SUB
   case &hd5
    ' Contacts and Switches
	' 1BS telegram: DB0, Sender ID, Status (page 11)
	eoLog(tp%,da$,oda$,"eo rx")  
	EXIT SUB
   case &ha5  
    ' 4BS telegram: DB3-DB0, Sender ID, Status (page 12)
    ' Temperature Sensors
	' Temperature and Humidity Sensor
	' Barometric Sensor
	' Light Sensor
	' Occupancy Sensor
	' Light, Temperature and Occupancy Sensor
	' Gas Sensor
	' Room Operating Panel
	' Controller Status
	' Automated Meter Reading
	' Environmental Applications
	' Multi-Func Sensor
	' HVAC Components
	' Digital Input
	' Energy Management
	' Central Commands
	' Universal	
    eoLog(tp%,da$,oda$,"eo rx") 
    db3%=asc(mid$(da$,2,1))
	db2%=asc(mid$(da$,3,1))
	db1%=asc(mid$(da$,4,1))
	db0%=asc(mid$(da$,5,1))
	id%=conv("bbe/i32",mid$(da$,6,4))    
	st%=asc(mid$(da$,10,1))
	eoRxSensor(tp%,id%,db3%,db2%,db1%,db0%,st%)	
	EXIT SUB
   case &hd2
    ' VLD telegram: DB_13-DB0 (depending on length), Sender ID, Status, CRC8
    ' Room Control Panel
	' Electronic switches and dimmers
	' Sensors for Temperature, Illumination, Occupancy and smoke
	' Light, Switching + Blind Control
	' CO2, Humidity, Temperature, Day / NIght and Autonomy
	' Blinds Control for Position and Angle
    eoLog(tp%,da$,oda$,"eo rx")  
	db$=mid$(da$, 2,len(da$)-7)
	id%=conv("bbe/i32",mid$(da$,len(da$)-6,4))    
	st%=asc(mid$(da$,len(da$)-1,1))
	crc8%=asc(right$(da$,1))
	eoRxVariable(tp%,id%,db$,st%,crc8%)
    EXIT SUB
	case else
	 eoLog(tp%,da$,oda$,"eo unknown rx ")  
  end select
 ENDIF ' rx
END SUB

' log a telegram
SUB eoLog(tp%,da$,oda$,msg$)
 s$=msg$+" tp:"+str$(tp%)+" da:"
  for i=1 TO len(da$)
   s$=s$+hex$(asc(mid$(da$,i,1)))
  next
  s$=s$+" oda:"
  for i=1 TO len(oda$)
  s$=s$+hex$(asc(mid$(oda$,i,1)))
 next
 print s$
END SUB

' Receive Rocker Switch, 2 Rocker, page 15
' We get type info and two bits on status which help us to interpret
' Depending on switch type press and release events can be parsed
SUB eoRxRocker(tp%,id%,db0%,st%)
 select case (st% and &h30)
  case &H30 ' T21=1, NU = 1
   rock1%=(db0% and &he0)/32
   bow1%=(db0% and &h10)/16
   rock2%=(db0% and &h0e)/2
   ac2%=(db0% and &h1)
   print "eoRxRocker30:" hex$(id%) tp% rock1% bow1% rock2% ac2%   
   ' add your code here press event on rock1% (switch 1-4) ptm210
  case &H20 'T21=1, NU = 0
   num%=(db0% and &he0)/32
   bow%=(db0% and &h10)/16  
   print "eoRxRocker20:" hex$(id%) tp% num% bow%  
   ' add your code here for release event on bow% ptm210
  case &H10 'T21=0, NU = 1   
   rock1%=(db0% and &he0)/32
   bow1%=(db0% and &h10)/16
   rock2%=(db0% and &h0e)/2
   ac2%=(db0% and &h1)
   print "eoRxRocker10:" hex$(id%) tp% rock1% bow1% rock2% ac2%   
   ' add your code here  
  case &H00 'T21=0, NU = 0   
   num%=(db0% and &he0)/32
   bow%=(db0% and &h10)/16  
   print "eoRxRocker00:" hex$(id%) tp% num% bow%  
   ' add your code here  
 end select
END SUB

' Receive Sensor info, page 15
SUB eoRxSensor(tp%,id%,db3%,db2%,db1%,db0%,st%)	
 print "eoRxSensor:" hex$(id%) tp% db3% db2% db1% db0% st%
 ' add your code here you can make subcalls here to your own routines
 select case id%
  case &H01823D78 ' your sensor id (from sensor backside)
   ' Enocean sensor STM3xx from demo kit
   ' 255=0 degree celsius, 0=40 degree celsius 
   print db1% (255-db1%)/255.0*40.0
 end select 
 ' Pressac Version 1 CT Clamp A5-12-01
 ' http://www.pressac.com/current-transducer-enocean-ct-clamp
 ' scale% = db0 AND 3 
 ' meter = (db3%*256 + db2%)*256 + db1%
 ' if scale% = 1 then
 '  meter = ((db3%*256 + db2%)*256 + db1%)*0.1
 ' else if scale% = 2 then
 '  meter = ((db3%*256 + db2%)*256 + db1%)*0.01
 ' else if scale% = 3 then
 '  meter = ((db3%*256 + db2%)*256 + db1%)*0.001
 ' else 
 '  meter = ((db3%*256 + db2%)*256 + db1%)
 ' end if
 ' cum% = db0% and 4
 ' lrn% =  not (db0% and 8)
 
 ' The following infos are taken from the Eltako documentation 
 ' referenced in the header (see page 10))
 ' Eltako FABH65S+FBH65B+FBH65S+FBH65TFB
 ' lux = db2% *2048.0/255.0
 ' lrn% = not (db0% and 8)
 ' motion% = not (db0% and 2)
 
 ' FAFT60+FIFT65S+FBH65TFB
 ' charge = db3% * 4.0 / 155.0
 ' humidity = db2% * 100.0 / 250.0
 ' temp = (db1% * 80.0 / 250.0)-20.0
 ' lrn% = not (db0% and 8)
 
 ' FAH60+FAH65S+FIH65S+FAH60B
 ' lux  = db3%*100.0
 ' lux2 = 300 + db2%*(30000-300)/255.0
 ' lrn% =  not (db0% and 8)
 
 ' FIH65B 
 ' lux = db2%*1024.0/255.0
 ' lrn% =  not (db0% and 8)
 
 ' FASM60+FSM14+FSM61+FSU65D
 ' status = db3%
 
 ' FSM60B
 ' status1 = db3%
 ' status2 = db1%

 ' FCO2TF65
 ' humidity = db3%*100.0/200.0*40
 ' co2      = db2%*2550.0/255.0
 ' temperature = db1%*51.0/255.5
  
 ' FKC+FKF
 ' status = db3%
 
 ' FRW
 ' status = db3%
 
 ' FSS12+FWZ12+FWZ61 
 ' value = db3% * &HFFFF
 ' value += db2% * &HFF
 ' value += db1%
 ' tariff = db0 and 16
 ' LRN_Button = db0 and 8
 ' switchover = db0 and 4
 '  if(db0% = 0x09){
 '     meterstatus$ = "meter status normal rate"
 ' }
 ' else if(db0% = 0x19){
 '     meterstatus$ = "meter status off-peak rate"
 ' }
 '  else if(db0% = 0x0C){
 '     meterstatus$ = "momentary power in W, normal"
 ' }
 ' else if(db0% = 0x1C){
 '     meterstatus$ = "momentary power in W, off-peak"
 ' }
 
 ' F4T65+FT4F+FT55
 ' status = db3%
 
END SUB

' Receibe variable length telegram
SUB eoRxVariable(tp%,id%,db$,st%,crc8%)
print "eoRxSensor:" hex$(id%) tp% db3% db2% db1% db0% st%
 ' add your code here you can make subcalls here to your own routines
 ' Versions 2&3 Single Phase CT Clamps -  D2-32-00
 ' http://www.pressac.com/enocean-single-phase-ct-clamp-v2
 ' pf% = asc(left$(db$,1)) AND 128
 ' div% = asc(left$(db$,1)) 64
 ' meter = (asc(mid$(db$,2,1))*16)+ (asc(right$(db$,1))/16)
 ' if div% then
 '   meter = meter * 0.1
 ' end if
 
 ' Version 2 &3 Dual Phase CT Clamps - D2-32-01         
 ' http://www.pressac.com/2-phase-current-transducer-enocean-ct-clamp
 ' pf% = asc(left$(db$,1)) AND 128
 ' div% = asc(left$(db$,1)) 64
 ' meter1 = (asc(mid$(db$,2,1))*16)+ (asc(mid$(db$,3,1))/16)
 ' meter2 = ((asc(mid$(db$,3,1)) AND &H0f)*256)+ asc(right$(db$,1))
 ' if div% then
 '   meter1 = meter1 * 0.1
 '   meter2 = meter2 * 0.1
 ' end if
 
 ' Version 2 &3 Three phase CT Clamps - D2-32-02
 ' http://www.pressac.com/3-phase-current-transducer-enocean-ct-clamp
 ' pf% = asc(left$(db$,1)) AND 128
 ' div% = asc(left$(db$,1)) 64
 ' meter1 = (asc(mid$(db$,2,1))*16)+ ((asc(mid$(db$,3,1)) and &Hf0) /16)
 ' meter2 = ((asc(mid$(db$,3,1)) AND &H0f)*256)+ asc(mid$(db$,4,1))
 ' meter3 = (asc(mid$(db$,5,1))*16)+ (asc(right$(db$,1))/16)
 ' if div% then
 '   meter1 = meter1 * 0.1
 '   meter2 = meter2 * 0.1
 '   meter3 = meter3 * 0.1
 ' end if
 
END SUB
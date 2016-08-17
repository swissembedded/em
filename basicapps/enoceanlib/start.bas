' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2015-2016 swissEmbedded GmbH, All rights reserved.
' EMDO enocean library, based on Enocean EPP 2.6.3 specification
' the document EnOcean_Equipment_Profiles_EEP_V2.6.3_public.pdf
start:
 eoReceive()
 goto start

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
    ' Rocker switches come here 
	' RPS telegram: DB0, Sender ID, Status (page 11)    
	db0%=asc(mid$(da$,2,1))
	id%=conv("bbe/i32",mid$(da$,3,4))    
	st%=asc(mid$(da$,7,1))
	eoRxRocker(tp%,id%,db0%,st%)
	EXIT SUB
   case &hd5
    ' Contacts and Switches
	eoLog(tp%,da$,oda$,"eo rx")  
	EXIT SUB
   case &ha5    
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
	' 4BS telegram: DB3-DB0, Sender ID, Status (page 12)
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
    eoLog(tp%,da$,oda$,"eo rx")  
    ' Room Control Panel
	' Electronic switches and dimmers
	' Sensors for Temperature, Illumination, Occupancy and smoke
	' Light, Switching + Blind Control
	' CO2, Humidity, Temperature, Day / NIght and Autonomy
	' Blinds Control for Position and Angle
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

 Receive Sensor info, page 15
SUB eoRxSensor(tp%,id%,db3%,db2%,db1%,db0%,st%)	
 print "eoRxSensor:" hex$(id%) tp% db3% db2% db1% db0% st%
 ' add your code here e.g. 255=0 degree celsius, 0=40 degree celsius
 ' STM3xx from demo kit
 print db1% (255-db1%)/255.0*40.0
END SUB

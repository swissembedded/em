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
  'first two characters are rorg  
  eoLog(tp%,da$,oda$,"rx ")  
  rorg%=val("&H"+left$(da$,2))  
  print "RORG " rorg%  
  select case rorg%
   case &hf6 
    ' Rocker switches come here 
	' RPS telegram: DB0, Sender ID, Status (page 11)    
	db0%=val("&H"+mid$(da$,3,2))
	id%=val("&H"+mid$(da$,5,8))    
	st%=val("&H"+mid$(da$,11,2))
    print "rocker" db0% id% st%
    select case tp%
     case &h02 
      eoRxRocker2(id%,db0%,st%)
     case &h03
      eoRxRocker4(id%,db0%,,st%)
     case &h04
      eoRxPos(id%,db0%,st%)
     case &h05
      eoRxDet(id%,db0%,st%)
     case &h10
      eoRxMech(id%,db0%,st%)
    end select
	EXIT SUB
   case &hd5
    ' Contacts and Switches
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
	EXIT SUB
   case &hd2
    ' Room Control Panel
	' Electronic switches and dimmers
	' Sensors for Temperature, Illumination, Occupancy and smoke
	' Light, Switching + Blind Control
	' CO2, Humidity, Temperature, Day / NIght and Autonomy
	' Blinds Control for Position and Angle
    EXIT SUB
  end select
 ENDIF ' rx
END SUB

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
' We get two types of packets
' &H30) button info
' &H20) number of buttons pressed
SUB eoRxRocker2(id%,db0%,st%)
 select case (st% and &h30)
  case &H30 ' T21=1, NU = 1
   rock1%=(db% and &he0)/32
   bow1%=(db% and &h10)/16
   rock2%=(db% and &h0e)/2
   ac2%=(db% and &h1)
   print "eoRxRocker2" hex$(id%) st% rock1% bow1% rock2% ac2%   
   ' add your code here
  case &H20 'T21=1, NU = 0
   num%=(db% and &he0)/32
   bow%=(db% and &h10)/16  
   print "eoRxRocker2" hex$(id%) num% bow%   
 end select
END SUB

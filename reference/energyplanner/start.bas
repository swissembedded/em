' Copyright (c) 2017 swissEmbedded GmbH, All rights reserved.
' Energy planner
' Documentation 
' @DESCRIPTION Plan energy consumer to use as much photovoltaic energy as possible
' @VERSION 1.0

trace extended
owkey$="21254ca4c403151ea2540fa0f1545e6d"
owpos$="q=Baden+CH"
owlng$="de"
owunit$="metric"
owcb$="owC"
owcnt%=1
eTo%=0
eEo=0
eIo=0
ePo=0
eSo=0
' init rs485
SYS.Set "rs485", "baud=19200 data=8 stop=1 parity=e term=1"
SYS.Set "rs485-2", "baud=19200 data=8 stop=1 parity=e term=1"

LIBRARY LOAD "vedirect"
LIBRARY LOAD "dash"
LIBRARY LOAD "eastron"
LIBRARY LOAD "egosmartheater"
LIBRARY LOAD "phoenixevcharge"
LIBRARY LOAD "elsnerp03"
LIBRARY LOAD "enocean"
LIBRARY LOAD "mystrom"
LIBRARY LOAD "openweather"
LIBRARY LOAD "planning"

' midnight counters restore
metererr%=pgLoadEnergy(1,eTo%,eEo,eIo,ePo,eSo)
print "Meter load " metererr% eTo% eEo eIo ePo eSo

sc%=pgSaveEnergy(1,Unixtime(),0,0,0,0)

start:
 dispatch 2000
 goto start

' Read meter
FUNCTION pgMC(pE,pI,pP,pS)
 LOCAL err%, pwr, rly%, now%,a$
 eT%=Unixtime() 
 'print "called"
 ' dish washer
 err%=msState("192.168.0.173",pwr,rly%)
 powerplug3_status$=ds_num$(err%,pwr,"%.3f"," kW") 
 powerplug3_value%=ds_status(err%,rly%) 
' laundry washer
 err%=msState("192.168.0.175",pwr,rly%)
 powerplug4_status$=ds_num$(err%,pwr,"%.3f"," kW") 
 powerplug4_value%=ds_status(err%,rly%) 
 ' laundry dryer
 err%=msState("192.168.0.172",pwr,rly%)
 powerplug5_status$=ds_num$(err%,pwr,"%.3f"," kW") 
 powerplug5_value%=ds_status(err%,rly%)  
' room dryer
 err%=msState("192.168.0.169",pwr,rly%)
 powerplug6_status$=ds_num$(err%,pwr,"%.3f"," kW") 
 powerplug6_value%=ds_status(err%,rly%) 
 ' coffee maker
 err%=msState("192.168.0.174",pwr,rly%)
 powerplug7_status$=ds_num$(err%,pwr,"%.3f"," kW") 
 powerplug7_value%=ds_status(err%,rly%) 
 ' fish light
 err%=msState("192.168.0.207",pwr,rly%)
 powerplug11_status$=ds_num$(err%,pwr,"%.3f"," kW") 
 powerplug11_value%=ds_status(err%,rly%) 
 ' fish uv
 err%=msState("192.168.0.208",pwr,rly%)
 powerplug12_status$=ds_num$(err%,pwr,"%.3f"," kW") 
 powerplug12_value%=ds_status(err%,rly%) 
 print "fish uv" powerplug12_status$ powerplug12_value%
 ' read energy meter for household
 LOCAL Uac1, Uac2, Uac3, Iac1, Iac2, Iac3, kW1, kW2, kW3, kWhI1, kWhI2, kWhI3, kWhE1, kWhE2, kWhE3, P
 err%=EastronEnergyMeter("TCP:192.168.0.24:502",1, Uac1, Uac2, Uac3, Iac1, Iac2, Iac3, kW1, kW2, kW3, kWhI1, kWhI2, kWhI3, kWhE1, kWhE2, kWhE3)
 P=kW1+kW2+kW3
 if err% >= 0 THEN
  IF P >= 0.0 THEN 
   pE=0.0
   pI=P
  ELSE
   pE=-P
   pI=0.0
  ENDIF
   meter2_status$="Import:"+chr$(10)+ds_num$(err%,pI,"%.3f"," kW")+chr$(10)+"Export:"+chr$(10)+ds_num$(err%,pE,"%.3f"," kW")
   print meter2_status$
   eI=kWhI1+kWhI2+kWhI3
   eE=kWhE1+kWhE2+kWhE3
 ENDIF
  ' read energy meter for pv
 err%=EastronEnergyMeter("TCP:192.168.0.24:502",2, Uac1, Uac2, Uac3, Iac1, Iac2, Iac3, kW1, kW2, kW3, kWhI1, kWhI2, kWhI3, kWhE1, kWhE2, kWhE3)
 if err% >= 0 THEN
  pP=-(kW1+kW2+kW3)
  a$="Power:"+chr$(10)+ds_num$(err%,pP,"%.3f"," kW")+chr$(10)
  a$=a$+ds_num$(err%,-kW1,"%.1f","/")+ds_num$(err%,-kW2,"%.1f","/")+ds_num$(err%,-kW3,"%.1f"," kW")+chr$(10)
  a$=a$+"Energy:"+chr$(10)+ds_num$(err%,eP-ePo,"%.3f"," kWh")
  inverter2_status$=a$
  print "Production " inverter2_status$
  inverter2_error=0
  eP=kWhE1+kWhE2+kWhE2
 ELSE
  inverter2_error=1
 ENDIF
 ' read storage
 LOCAL vl%, vls$
 err%=VEDirectHex("192.168.0.25:20108","7",&Hed8d,"un16",vl%, vls$)
 a$=ds_num$(err%,vl%/100.0,"%.1f","V")+"("
 err%=VEDirectHex("192.168.0.25:20108","7",&H0383,"un16",vl%, vls$)
 a$=a$+ds_num$(err%,vl%/10.0,"%.1f","%)")+chr$(10)
 err%=VEDirectHex("192.168.0.25:20108","7",&Hed8f,"sn16",vl%, vls$)
 a$=a$+ds_num$(err%,vl%/10.0,"%.1f","A")+chr$(10)
 err%=VEDirectHex("192.168.0.25:20108","7",&Heeff,"sn32",vl%, vls$)
 a$=a$+ds_num$(err%,vl%/10.0,"%.1f","Ah")+chr$(10)
 err%=VEDirectHex("192.168.0.25:20108","7",&Hed8e,"sn16",vl%, vls$)
 a$=a$+ds_num$(err%,vl%/1000.0,"%.3f","kW")+chr$(10)
 err%=VEDirectHex("192.168.0.25:20108","7",&H0fff,"un16",vl%, vls$)
 a$=a$+ds_num$(err%,vl%/100.0,"%.2f","%")+chr$(10)
 battery_status$=a$
 pS=0.0

 ' EV 1
 LOCAL amp%,en%,sts$,prox%,tch%
 amp%=0
 err%=PhoenixEVControl("TCP:192.168.0.27:502",180, en%, amp%, sts$, prox%, tch%)
 if en% then 
  a$="Enabled"+chr$(10)
 else
  a$="Disabled"+chr$(10)
 endif
 if sts$="A" then 
  a$="Unplugged"+chr$(10)
 else if sts$="B" then
  a$="Connected"+chr$(10)
 else if sts$="C" or sts$="E" then
  a$="Charging"+chr$(10)
 else if sts$="F" then
  a$="Stopped"+chr$(10)
 endif
 a$=a$+ds_num$(err%,amp%,"%g","A")+chr$(10)
 a$=a$+ds_num$(err%,tch%/60.0,"%.1f","min")+chr$(10)
 ev1_status$=a$
 'print err% ev1_status$
 
 ' some calculation
 print "datecheck"
 IF (DateYearday(eT%) <> DateYearday(eTo%)) OR (metererr%<0) THEN 
  metererr%=pgSaveEnergy(1,eT%,eE,eI,eP,eS)
  print "Meter saved " metererr% eT% eE eI eP eS
  eTo%=eT%
  eEo=eE
  eIo=eI  
  ePo=eP
  eSo=eS
 ENDIF
 
 ' elsner weather station
 LOCAL Tout, SunS%, SunW%, SunE%, Lgt%, Wind, Rain%, GPS%, day%, month%, year%, hour%, min%, sec%, azi, ele, lon, lat
 err%=ElsnerWeatherstation("RTU:RS485:2", 1, Tout, SunS%, SunW%, SunE%, Lgt%, Wind, Rain%, GPS%, day%, month%, year%, hour%, min%, sec%, azi, ele, lon, lat)
 
 a$=ds_num$(err%,Tout,"%.1f",ds_special$("C*"))+ds_num$(err%,Wind,"%.1f","m/s")+chr$(10)+ds_num$(err%,(SunS%+SunW%+SunE%)/3.0,"%.1f","klx")+chr$(10)
 IF Rain% THEN
  a$=a$+"Rain"
 ELSE
  a$=a$+"No Rain"
 ENDIF
 meter1_status$=a$

 LOCAL kW, st%, T%,TMax%
 ' ego smart heater
 kW=0
 err%=EgoSmartHeater("RTU:RS485:1",247,kW,st%,T%,Tmax%)
 a$="Temperature:"+chr$(10)+ds_num$(err%,T%,"%.1f",ds_special$("C*"))
 a$=a$+"of "+ds_num$(err%,Tmax%,"%.1f",ds_special$("C*"))
 a$=a$+"Power:"+chr$(10)+ds_num$(err%,st%*500.0,"%g","kW")
 ds_boiler$=a$
 'update dash
 LOCAL eCd,sc,ss
 err%=ds_quote(eE,eI,eP,eS,eEo,eIo,ePo,eSo,ss,sc,eCd)
 sufficiency=cint(ss*100.0)
 consumption=cint(sc*100.0)
 kWhDayE=cint((eE-eEo)*10.0)/10.0
 kWhDayI=cint((eI-eIo)*10.0)/10.0
 kWhDayC=cint(eCD*10.0)/10.0
 kWhDayP=cint((eP-ePo)*10.0)/10.0
 kWhDayS=cint((eS-eSo)*10.0)/10.0
END FUNCTION

' Enocean callback handler
FUNCTION eoRxRadio(tp%,da$,oda$,rorg%,id%)
 LOCAL err%,hum,tmp,lrn%,ts%,ttp%,co%,utf8celsius$
 print "sensor " hex$(id%)
 IF tp%<>1 THEN
  EXIT FUNCTION
 ENDIF
 ' Check  all radio messages 
 IF id%=&H019C738D AND rorg%=&HA5 THEN
  err%=eoRxA504xx(tp%,da$,oda$,&H01,hum,tmp,lrn%,ts%,ttp%)
  IF err% >=0 THEN 
   sensor1_status$=ds_num$(err%,tmp,"%.1f",ds_special$("C*"))+ds_num$(err%,hum,"%.1f","%")
   print "Sensor 1 " sensor1_status$
  ENDIF 
 ELSE IF id%=&H18C5A6B AND rorg%=&HD5 THEN
  err%=eoRxD50001(tp%,da$,oda$,lrn%,co%)
  sensor4_status%=ds_status(err%,NOT co%)
  print "Sensor 4 " sensor4_status%
 ENDIF
END FUNCTION

FUNCTION owC(sunRise%,sunSet%,tiFr%,tiTo%,sym%,symN$,symV$,pre,preU$,preT$,wiDir,wiDiC$,wiDiN$,wiSp,wiSpN$,teAv,teMin,teMax,teU$,pr,hum,cl,clN$)
 weather_img$=symV$+".png"
 weather_status$=clN$+chr$(10)+str$(cint(teAv))+ds_special$("C*")+str$(cl)+"%"
print weather_status$
END FUNCTION


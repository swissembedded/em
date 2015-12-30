' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2011 - 2015 swissEmbedded GmbH, All rights reserved.
' This example reads the EMDO101 on board temperature sensor
' and send the value over LoRa. If a message is received from another sender, it is echoed.
' Please make sure the LoRa expansion board is correctly mounted.
' For testing we recommend the Microchip PICtail Daugther Board with USB interface
' Expansion board uses LoRa module from microchip (RN2483)
' Pls check RN2483 manuals at microchip homepage for details.
' http://ww1.microchip.com/downloads/en/DeviceDoc/40001784C.pdf
' Init vars
'id$="123"
id$="321"
'Module init sequence
rsp$=LoRaChat$("sys reset")
print rsp$
' Pause mac
rsp$=LoRaChat$("mac pause")
print rsp$
' Set max tx (you should adjust to minimum)
rsp$=LoRaChat$("radio set pwr 15")
print rsp$
' Set watchdog for rx and tx timeout
rsp$=LoRaChat$("radio set wdt 5000")
print rsp$
' Main loop
START:	
	rsp$=LoRaChat$("mac pause")
	print "mac pause " rsp$
	T=Temp
	' Transmit data, second parameter is converted to a hex string e.g. 2F454D444F3132333A32382F
	rsp$=LoRaChat$("radio tx ","/EMDO"+id$+":"+Format$(T,"%g")+"/",5000)
	print "radio tx " rsp$
	' Wait up to 5 second for transmission
	rsp$=LoRaChat$("","",5000)
	print "radio tx status " rsp$
	pause 2000
	rsp$=LoRaChat$("mac pause")
	print "mac pause " rsp$
	rsp$=LoRaChat$("radio rx 0")
	print "radio rx " rsp$
	' Wait up to 5 second for reception
	rsp$=LoRaChat$("","",5000)
	print "radio rx status " rsp$
	pause 2000
	GOTO START


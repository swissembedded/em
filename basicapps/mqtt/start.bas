' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2011 - 2015 swissEmbedded GmbH, All rights reserved.
' This example reads the EMDO101 on board temperature sensor and publish the value on MQTT
' Init vars
server$="192.168.0.43"
port=1883
T = 0.0 ' temperature
' Just connect with clean session with Q0, no nothing
con=MQTTConnect(server$,port,"C0","EMDO101","","","","")

' if send = 0 we should retry, mqtt client is busy
Do
	send=MQTTSubscribe("0","EMDO/test")
Loop Until send = 1
' Main loop
START:	
	T$="Temperature is " + str$(Temp)
	Do
		send=MQTTPublish("0","EMDO/test",T$)
	Loop Until send = 1
	
	Do
		rec=MQTTSubscription(q$,topic$,payload$)
	Loop Until rec = 1
	PAUSE 60000
	
	PRINT "Message " q$ " topic " topic$ " payload " + payload$
	
	GOTO START
	
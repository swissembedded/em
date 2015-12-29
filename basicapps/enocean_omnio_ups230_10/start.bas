' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2011 - 2015 swissEmbedded GmbH, All rights reserved.
' This example requires a EMDO Enocean Expansion Board (Enocean TCM310 chip). 
' Pls make sure the board is correctly mounted.
' In this example a PTM215 switch from the ESK 300 Energy Harvest starter kit is emulated to switch on / off
' an Omnio UPS230/10 actor. The actor was teached in to switch on / off with the PTM215 and EMDO (see Omnio manual). 
' The EMDO emulates the signals from the PTM215 with its own id.
' USB 300 Enocean Transceiver with Dolphin View Basic is recommended for programming and easy debugging
switchid$ = chr$(&H00)+chr$(&H00)+chr$(&H00)+chr$(&H00)

START:
	' Pls see enocean EEP 2.6.2 specification and ESP3 specification
	' Type = 1 is radio
	' Data = F6 (RORG = RPS / 1BS), switch state (0x50 = on, 0x70 = off)
	' OptData = 03 (send) Boardcast FF FF FF FF, dBm (FF), 00 (unencrypted)
	' Push button 1
	num=EnoceanTransmit( 1, chr$(&HF6) + chr$(&H50) + switchid$ + chr$(&H30), chr$(&H03)+chr$(&HFF)+chr$(&HFF)+chr$(&HFF)+chr$(&HFF)+chr$(&HFF)+chr$(&H00)  )
	pause 1000
	' Push button relase
	num=EnoceanTransmit( 1, chr$(&HF6) + chr$(&H00) + switchid$ + chr$(&H20), chr$(&H03)+chr$(&HFF)+chr$(&HFF)+chr$(&HFF)+chr$(&HFF)+chr$(&HFF)+chr$(&H00)  )
	Pause 1000
	' Push button 2
	num=EnoceanTransmit( 1, chr$(&HF6) + chr$(&H70) + switchid$ + chr$(&H30), chr$(&H03)+chr$(&HFF)+chr$(&HFF)+chr$(&HFF)+chr$(&HFF)+chr$(&HFF)+chr$(&H00)  )
	pause 1000
	' Push button release
	num=EnoceanTransmit( 1, chr$(&HF6) + chr$(&H00) + switchid$ + chr$(&H20), chr$(&H03)+chr$(&HFF)+chr$(&HFF)+chr$(&HFF)+chr$(&HFF)+chr$(&HFF)+chr$(&H00)  )
	Pause 1000
	do
		num=EnoceanReceive(type,data$,optdata$)
		If num=1 Then
			Print "New packet type"  type  " len "  len(data$)  " optlen "  len(optdata$)
		Endif
	loop until num <> 1
GOTO start

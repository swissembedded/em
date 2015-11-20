' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2011 - 2015 swissEmbedded GmbH, All rights reserved.
' This example write to SC2004MBS-B modbus slave display
' pls make sure EMDO RS485 and display are correctly configured
' and the termination resistor is placed on the display too.
	DisplayPrint 1,0,"EMDO says"
	DisplayPrint 1,1,"H E L L O"
	DisplayPrint 1,2,"to all Kickstarters"

START:
	DisplayPrint 1,3,Date$
	Pause 500
GOTO start
'* Modbus writer
SUB DisplayPrint ( sly, line, text$ )
' Modbus telegram, pls see "MODBUS Application Protocol Specification V1.1b3 page 15, available at www.modbus.org
 '     SL FC ADDR REGSNUM BC CRC 
 ' Tx: 01 10 00XX 00XX    XX YY  - Write multiple registers (0x10)
 ' Rx: we don't care
 ' Trim the text or fill it up to 20 chars per line
	If len(text$) < 20 Then 
		txt$=text$+space$(20-len(text$))
	Else
		txt$=left$(text$,20)
	Endif
    msg$=CHR$(sly)+CHR$(&H10)+CHR$(&H0)+CHR$(10*line)+CHR$(&H00)+CHR$(&H0A)+CHR$(&H14)+txt$
	crc$=CRCCalc$(0,msg$)
	req$=msg$+crc$
	num=RS485Write(req$)
	' just read and drop
	pause 500
	rsp$=RS485Read$(255)
END SUB

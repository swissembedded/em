' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2011 - 2015 swissEmbedded GmbH, All rights reserved.
' This example reads a sunspec compatible inverter such as Solaregde
' over modbus. Please make sure that the RS485 interface and Solaredge 
' inverters are configured correctly.
kW = 0.0
kWh = 0.0
opst = 0
START:
	SunspecReader 0, 1, kW,kWh, opst
	PRINT "kW:"  kW " kWh:" kWh " State:" opst
	PAUSE 5000
GOTO start
' Sunspec reader for Solaredge, SMA, Fronius
SUB SunspecReader ( type, slv, kW, kWh, opst )
' Pls see the following document below for reference
' and make sure inverters and EMDO101 are properly configured
' Other manufacturers use same mechanism, but use different register addresses
' which requires manual adjustment of the following source code
' Modbus telegram, pls see "MODBUS Application Protocol Specification V1.1b3 page 15, available at www.modbus.org
 IF type = 0 THEN 'SOLAREDGE SUNSPEC
 ' Technical Note - SunSpec Logging in SolarEdge Inverters, 
 ' Protocol page 6
 '     SL FC ADDR NUM    CRC   - All modbus address have an offset of -1 to the modbus address
 ' Tx: 01 03 9C 40 00 7A EB AD - Read 122 (0x7a) registers starting at address 40001 (0x9c41).
 ' Rx: 01 03 F4 53 75 ... [Registers data] ... FF FF 12 1B (53 75 is SunS value)
 ' 40084 (0x9c94) AC Power value (int16)
 ' 40085 (0x9c95) AC Power value scale factor (int16)
 ' 40094 (0x9c9e) AC Livetime Energy production (acc32)
 ' 40095 (0x9c9f) AC Livetime Energy production scale factor (int16)
 ' 40108 (0x9cac) Operating State (unint16) 0=off, 2=night mode, 4=producing power
    msg$=CHR$(slv)+CHR$(&H03)+CHR$(&H9C)+CHR$(&H40)+CHR$(&H00)+CHR$(&H7A)
	crc$=CRCCalc$(0,msg$)
	req$=msg$+crc$
	num=RS485Write(req$)
	PAUSE 500
	rsp$=RS485Read$(122+9)
	PRINT "len" len(rsp$)
	FOR i = 1 TO len(rsp$)
		print i  "2 0x"  HEX$(ASC(MID$(rsp$,i,1)))
	NEXT i
	IF len(rsp$)<> 131 THEN 
	 kW=0.0
	 kWh=0.0
	 opst=0
	 RETURN
	ENDIF
	' Check for MODBUS Func 3 response 
	IF ASC(MID$(rsp$,1,1)) = 1 AND ASC(MID$(rsp$,2,1))=3 AND ASC(MID$(rsp$,3,1))=&HF4 THEN
	 ' Check for SunS (0x53756e53)
	 IF ASC(MID$(rsp$,4,1))=&H53 AND ASC(MID$(rsp$,5,1))=&H75 AND ASC(MID$(rsp$,6,1))=&H6E AND ASC(MID$(rsp$,5,1))=&H53 THEN
	  ' Parse kW reg 40084 and 40085
	  kW=(ASC(MID$(rsp$,4+(84*2),1))*256+ASC(MID$(rsp$,4+(84*2)+1,1)))*(ASC(MID$(rsp$,4+(85*2),1))*256+ASC(MID$(rsp$,4+(85*2)+1,1))) THEN
	  ' Parse kWh regs 40094 and 40095
	  kWh=(ASC(MID$(rsp$,4+(94*2),1))*256*256*256+ASC(MID$(rsp$,4+(94*2)+1,1))*256*256+ASC(MID$(rsp$,4+(94*2)+2,1))*256+ASC(MID$(rsp$,4+(94*2)+3,1)))*(ASC(MID$(rsp$,4+(95*2),1))*256+ASC(MID$(rsp$,4+(95*2)+1,1)))
	  ' Parse Operation State
	  opst=ASC(MID$(rsp$,4+(108*2),1)
	 ENDIF
	ENDIF
 ELSEIF type = 1 THEN ' SMA SUNSPEC
 ' SMA (Technische Beschreibung SunSpec®-Modbus®-Schnittstelle) page 21
 ' 40200 (0x9D08) AC Power value (int16)
 ' 40201 (0x9D09) AC Power scale factor (int 16)
 ' 40210 (0x9D12) AC Livetime Energy production (acc32)
 ' 40212 (0x9d14) AC Livetime Energy production scale factor (sunssf)
 ' 40224 (0x9D20) Operating state (enum 16) 1=off, 2=wait of pv voltage, 3=start, 4=MPP, 
 '  5=reduced output power, 6=shutdown, 7=error, 
 '  8=wait for energ provider
 ' Not implemented yet
 ELSEIF type = 2 THEN ' Fronius SUNSPEC
 ' Fronius (Fronius Datamanager Modbus TCP & RTU) page 18
 ' 40092 (0x9C9C) AC Power value (float32)
 ' 40102 (0x9CA6) AC Lifetime Energy production (float32)
 ' 40118 (0x9CB6) Operating State (enum 16) 1=off, 2=in operation, 3 = run up, 4=normal operation
 '  5=power reduction, 6 = switch off, 7 = error, 8 = standby
 ' Not implemented yet
 ENDIF 
END SUB

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
	PRINT "kW1:"  kW " kWh1:" kWh " State:" opst
	SunspecReader 0, 2, kW,kWh, opst
	PRINT "kW2:"  kW " kWh2:" kWh " State:" opst
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
 ' 40001, 40002 0x53756e53 "SunS"
 ' 40084 (0x9c94) AC Power value (int16)
 ' 40085 (0x9c95) AC Power value scale factor (int16)
 ' 40094 (0x9c9e) AC Lifetime Energy production (acc32)
 ' 40096 (0x9c9f) AC Lifetime Energy production scale factor (int16)
 ' 40108 (0x9cac) Operating State (unint16) 0=off, 2=night mode, 4=producing power
	ModbusFC3Read slv, 40084-1, power
	ModbusFC3Read slv, 40085-1, powerscale	
	SunSpecScale powerscale, scale
	kW=power*scale/1000.0
	'print "kW" power " powerscale " powerscale " factor " scale " kW " kW
	ModbusFC3Read slv, 40094-1, energyh
	ModbusFC3Read slv, 40095-1, energyl
	ModbusFC3Read slv, 40096-1, energyscale	
	SunSpecScale energyscale, scale
	kWh=(energyl/1000.0*scale)+(energyh*(65536.0/1000.0)*scale)
	ModbusFC3Read slv, 40108-1, opst
 ELSEIF type = 1 THEN ' SMA SUNSPEC
 ' SMA (Technische Beschreibung SunSpec-Modbus-Schnittstelle) page 21
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
' ** Read a modbus register with function 3
SUB ModbusFC3Read ( slv, register, value )
    ' convert the register number to hex string and fill it up with 0 at the start for 4 chars
	regs$=hex$(register)
	regs$=string$(4-len(regs$),"0")+regs$
	msg$=CHR$(slv)+CHR$(&H03)+CHR$(val("&H"+left$(regs$,2)))+CHR$(val("&H"+right$(regs$,2)))+CHR$(&H00)+CHR$(&H01)
	crc$=CRCCalc$(0,msg$)
	req$=msg$+crc$
	num=RS485Write(req$)
	n=1000
	DO
	 num=RS485Rq
	 if num<7 then Pause 1
	 n=n-1
	LOOP UNTIL num>=7 OR n=0
	rsp$=RS485Read$(RS485Rq)
	if n > 0 then
		value=peek(VAR rsp$,4)*256+peek(VAR rsp$,5)
	else	
		Hexdump rsp$, out$
		print "modbus problem " len(rsp$)  "hex " out$
		value = 0
	endif
END SUB
' ** Convert scale factor to multiplier
SUB SunSpecScale ( sf, factor )
if sf < 10 then 
factor = 10^sf
elseif sf > 65525 then
 factor = 10^(sf-65536)
else
 factor= 1
endif
END SUB
' ** Dump a string in hex 
SUB Hexdump ( msg$, out$ )
	out$=""
	for i = 1 TO len(msg$)
	h$=hex$(peek(VAR msg$,i))
	if len(h$) = 1 then h$="0"+h$
	 out$=out$+h$
	next i 
END SUB

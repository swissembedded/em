' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2015 - 20116 swissEmbedded GmbH, All rights reserved.
' This example reads a sunspec compatible inverter over modbus
' Please make sure that the inverters RS485 interface 
' is configured correctly. If multiple inverters are connected on a serial
' line make sure each device has a unique modbus slave address configured.
' Cable must be twisted pair with correct end termination on both ends
SYS.Set "rs485", "baud=9600 data=8 stop=1 parity=n term=1"
kW = 0.0
kWh = 0.0
opst = 0
itf$="RTU:rs485:1"
slv1%=1
slv2%=1
START:
	SunspecReader (ift$, slv1%, kW,kWh, opst)
	PRINT "Inverter1 kW1:"  kW " kWh1:" kWh " State:" opst
	SunspecReader (itf$, slv2%, kW,kWh, opst
	PRINT "Inverter2 kW2:"  kW " kWh2:" kWh " State:" opst
	PAUSE 5000
GOTO start
' Sunspec reader for Solaredge, SMA, Fronius
FUNCTION SunspecReader ( itf%, slv%, kW, kWh, opst )
 LOCAL err%, rSun$, sun$, rMan
 ' Pls see the referenced document below for manufacturer dependent registers
 ' Check common sunspec registers
 err%=mbFunc(itf$,slv%,3,40001-1,3,rSun$,500)
 IF err% THEN
  SunspecReader=err%
  EXIT FUNCTION
 ENDIF
 ' Expect sunspec magic
 sun$=conv("u32/bbe",&H053756e53)+conv("u16/bbe",&H0001)
 IF rSun$<>sun$ THEN
  SunspecReader=-100
  EXIT FUNCTION
 ENDIF

 
 ' Check manufacturer
 err%=mbFunc(itf$,slv%,3,40005-1,16,rMan$,500)
 IF err% THEN
  SunspecReader=err%
  EXIT FUNCTION
 ENDIF

 ' Read from long to start manufacturer names
 IF mid$(rMan$,1,10)="SolarEdge" THEN
 ELSEIF mid$(rMan$,1,7)="Fronius" THEN
 ELSEIF mid$(rMan$,1,3)="SMA" THEN
 ELSE
  ' Manufacturer not supported yet
  SunspecReader=-101
  EXIT FUNCTION  
 ENDIF
 
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
 ' 40210 (0x9D12) AC Lifetime Energy production (acc32)
 ' 40212 (0x9d14) AC Lifetime Energy production scale factor (sunssf)
 ' 40224 (0x9D20) Operating state (enum 16) 1=off, 2=wait of pv voltage, 3=start, 4=MPP, 
 '  5=reduced output power, 6=shutdown, 7=error, 
 '  8=wait for energ provider
 ' Not tested yet
	ModbusFC3Read slv, 40200-1, power
	ModbusFC3Read slv, 40201-1, powerscale	
	SunSpecScale powerscale, scale
	kW=power*scale/1000.0
	ModbusFC3Read slv, 40210-1, energyh
	ModbusFC3Read slv, 40211-1, energyl
	ModbusFC3Read slv, 40212-1, energyscale	
	SunSpecScale energyscale, scale
	kWh=(energyl/1000.0*scale)+(energyh*(65536.0/1000.0)*scale)
	ModbusFC3Read slv, 40224-1, opst
 ELSEIF type = 2 THEN ' Fronius SUNSPEC
 ' Fronius (Fronius Datamanager Modbus TCP & RTU) page 18
 ' 40092 (0x9C9C) AC Power value (float32)
 ' 40102 (0x9CA6) AC Lifetime Energy production (float32)
 ' 40118 (0x9CB6) Operating State (enum 16) 1=off, 2=in operation, 3 = run up, 4=normal operation
 '  5=power reduction, 6 = switch off, 7 = error, 8 = standby
 ' Not tested yet
	ModbusFC3Read slv, 40092-1, powerh
	ModbusFC3Read slv, 40093-1, powerl	
	ModbusFloat32 powerh, powerl, power
	kW=power/1000.0
	ModbusFC3Read slv, 40102-1, energyh
	ModbusFC3Read slv, 40103-1, energyl	
	ModbusFloat32 energyh, energyl, energy
	kWh=energy/1000.0
	ModbusFC3Read slv, 40118-1, opst

 ENDIF 
END FUNCTION

' Modbus library goes here
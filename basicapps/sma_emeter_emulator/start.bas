' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2015-2016 swissEmbedded GmbH, All rights reserved.
' SMA energy meter emulator EMDO example
' Documentation http://www.sma.de/fileadmin/content/global/Partner/Documents/SMA_Labs/EMETER-Protokoll-TI-en-10.pdf

server$="239.12.255.254"
susyid%=&H010E
serno%=&H0102
kWh1=0.0
kWh2=0.0
start:
 ts%=Ticks()
 err%=SMAEnergyMeterData(server$, susyid%, serno% ,ts%,kWh1,kWh2)
 print "SMA " err% kWh1 kWh2
 kWh1=kWh1+1.0
 kWh2=kWh2+1.0
 pause 30000
 goto start

' SMA energy meter data emulator
' id$ energy meter identifier string
' ts% timestamp [ms]
' kWh1 energy consumed from grid 
' kWh2 energy feed into grid
FUNCTION SMAEnergyMeterData(server$,susyid%, serno% ,ts%,kWh1,kWh2)
 LOCAL id$,msg$, con%,num%
 ' id, idlen, tag, group, length two entries,tag, protocol id
 id$="SMA"+CHR$(0)
 msg$=id$+conv("u16/bbe",len(id$))+conv("u16/bbe",&H02A0)+conv("u16/bbe",&H0001)+conv("u16/bbe",12+2*12)+conv("u16/bbe",&H0010)+conv("u16/bbe",&H6069)
 ' Add susyid%, serno%, current tick (resolution ms)
 msg$=msg$+conv("u16/bbe",susyid%)+chr$(0)+chr$(0)+conv("u16/bbe",serno%)+conv("u32/bbe",ts%)
 'Add channel 1, index, ...
 msg$=msg$+chr$(1)+chr$(1)+chr$(8)+chr$(0)+conv("i64/bbe",kWh1*1000.0)
 'Add channel 2, index, ...
 msg$=msg$+chr$(1)+chr$(2)+chr$(8)+chr$(0)+conv("i64/bbe",kWh2*1000.0)
 ' End
 msg$=msg$+chr$(0)+chr$(0)+chr$(0)+chr$(0)
 con%=SocketClient( 0, server$, 9522 )
 IF con% < 0 THEN
  SMAEnergyMeterData=con%
  EXIT FUNCTION
 ENDIF
 num%=SocketWrite( con%, msg$ )
 IF num%<>len(msg$) THEN
  SMAEnergyMeterData=-1
  num%=SocketClose( con% )
  EXIT FUNCTION
 ENDIF 
 num%=SocketClose( con% ) 
 SMAEnergyMeterData=0
END FUNCTION

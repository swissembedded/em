' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2015-2016 swissEmbedded GmbH, All rights reserved.
' SMA energy meter emulator EMDO example
' Documentation http://www.sma.de/fileadmin/content/global/Partner/Documents/SMA_Labs/EMETER-Protokoll-TI-en-10.pdf
slv%=1

start:
 err%=SMAEnergyMeter(susyid%, serno% ,ts%,kWh1,kWh2)
 print "SMA " err% kWh1 kWh2
 pause 30000
 goto start

' SMA energy meter emulator
' id$ energy meter identifier string
' ts% timestamp [ms]
' kWh1 energy consumed from grid 
' kWh2 energy feed into grid
FUNCTION SMAEnergyMeter(susyid%, serno% ,ts%,kWh1,kWh2)
 LOCAL id$,msg$
 ' id, idlen, tag, group
 id$="SMA"+CHR$(0)
 msg$=id$+conv("u16/bbe",len(id$))+conv("u16/bbe",&H02A0)+conv("u16/bbe",&H0001)
 ' Add susyid%, serno%, current tick (resolution ms)
 msg$=msg$+conv("u16/bbe",susyid%)+chr$(0)+chr$(0)+conv("u16/bbe",serno%)+conv("u32/bbe",Ticks())
 SMAEnergyMeter=0
END FUNCTION

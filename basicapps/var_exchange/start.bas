' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2011 - 2015 swissEmbedded GmbH, All rights reserved.
' This example to test the live data in the graph and some other JSON based functionality
' Init vars
SetVarAccess("READWRITE") ' Set as default for all following variables
house_power$ = "123.12"
battery_power$ = "123.12"
pv_power$ = "123.12"
wind_power$ = "123.12"
message_power$="this is a test"
n=0
SetVarAccess("READONLY")
read=0
SetVarAccess("WRITEONLY")
write=0


DIM test(5)
test(1)=123
START:	
	n=n+1
	read=write
	GOTO START
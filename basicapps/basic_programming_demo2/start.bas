' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2016 swissEmbedded GmbH, All rights reserved.
' This is a simple introduction to MMBASIC 
' Read S0 Inputs
kWh = 0.0
start:
    ' Read first input, reset counter after read
    counts=S0Inp(1,1)
    ' Regular input with 1000 impulses per kWh 
    ' 1 hour = 60 min, we poll every minute
    kWh = kWh + counts/1000.0
    kW  = counts/1000.0*60.0
    print "kWh=" kWh " kW=" kW
    ' Wait a minute
    Pause 60000    
    goto start
' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2015-2016 swissEmbedded GmbH, All rights reserved.
' Ego smart heater control with excess energy over modbus TCP and RTU
' Set this value from energy meter measurement (e.g. S0 / D0 interface)
kW=0.0
slv%=247
if$=""
start:
 EgoSmartHeater(if$,slv%,kW,st%,T)
 print "Ego " st% T
 pause 30000
 goto start
 
' Ego smart heater controller
' This function must be called at least every 60 seconds,
' otherwise the ego smart heater will switch off
' if$ modbus interface (see EMDO modbus library for details)
' slv% ego smart heater slave address default 247, 
' kW home energy at energy meter neg. value = excess energy
' st% 1=500W on, 2=1000W on, 4=2000W on, e.g. 3=500+1000W
FUNC EgoSmartHeater(if$,slv%,kW,st%,T)
 
END FUNC
 
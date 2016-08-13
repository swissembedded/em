' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2015-2016 swissEmbedded GmbH, All rights reserved.
' Phoenix EV electric car charger with excess energy over modbus TCP and RTU
' Testet with Wallb-e Pro
kW=0.0
slv%=180
if$=""
start:
 PhoenixEV(if$,slv%,kW,st%)
 print "Phoenix " st% T
 pause 30000
 goto start
 
' Phoenix EV electric car charger controller
' This function must be called at least every 60 seconds,
' if$ modbus interface (see EMDO modbus library for details)
' slv% slave address of charger (default 180)
' kW home energy at energy meter neg. value = excess energy
' st% device status
FUNC PhoenixEV(if$,slv%,kW,st%)
 
END FUNC
 
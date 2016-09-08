' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2015-2016 swissEmbedded GmbH, All rights reserved.
' GMDE hybrid inverter data communication protocol
' Documentation available from manufacturer
SYS.Set "rs485", "baud=56000 data=8 stop=1 parity=n"
slv%=1
itf$="RS485:1"

start:
 pause 30000
 goto start


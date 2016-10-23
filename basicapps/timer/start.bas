' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2015 - 2016 swissEmbedded GmbH, All rights reserved.
' This example uses the internal timer mechanism to schedule an internal function

' start timer to tick every 5 second
numt%=0
tid%=SetTimer(5000)
' One shot timer can be defined like this tid%=SetTimer(5000,1)
IF tid% < 0 THEN ERROR "Failed to create timer"
ON TIMER tid% thandler

start:
' Check for timer event for a second
 Dispatch 1000
 ' do something else here if needed
 print numt%
' sc%=KillTimer(tid%)
' IF sc%<0 THEN ERROR "Failed to kill timer" 
' ON TIMER tid% thandler DETACH
' IF MM.errno < 0 THEN ERROR "Failed to detach handler"
 goto start

' Timer handler called every 5 seconds
' id% timer identifier
FUNCTION thandler(id%)  
  numt%=numt%+1
END FUNCTION


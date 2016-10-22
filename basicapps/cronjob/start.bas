' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2015 - 2016 swissEmbedded GmbH, All rights reserved.
' This example uses the internal cron mechanism to schedule an internal function
' cron is simplified unix cron alike scheduler, we support minutes, hours, day of month, month, day of week and year
' day of week: sun, mon, tue, wed, thu, fri, sat
' months: jan, feb, mar, apr, may, jun, jul, aug, sep, oct, nov, dec
' format min, hour, day of month, month, day of week
' * * * * * is every minute
' 17 * * * * hourly at xx:17
' 17 6 * * * daily at 6:17
' 17 18 * * 5 is every friday at 18:17
' 0 0 1 * *  is monthly on the 1st

' start cron job every minute
clid%=CrontabAdd("* * * * *")
IF clid% < 0 THEN ERROR "Failed to add CRON entry"
ON CRON clid% crhandler
n%=0
start: 
 ' wait for cron for 5 seconds
 Dispatch 5000
 print "do something else " n%
 n%=n%+1
 'detach cron
 'sc%=CrontabRemove(clid%)
 'IF sc% < 0 THEN ERROR "Failed to remove CRON entry"
 goto start


' Cron handler called every minute
' id% cron identifier
' elapsed% time in ms elapsed since last schedule
FUNCTION crhandler(id%,elapsed%)  
 PRINT "cron1 id=" id% " el=" elapsed% " date=" Date$()
END FUNCTION


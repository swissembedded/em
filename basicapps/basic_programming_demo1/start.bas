' This script is an example of the EMDO101 energy manager
' Please visit us at www.swissembedded.com
' Copyright (c) 2016 swissEmbedded GmbH, All rights reserved.
' This is a simple introduction to MMBASIC 
' Read EMDO onboard temperature sensor (which returns an integer)
T=Temperature
' This is a float and string variable
hot=33.0
C$="temperature "

' Display text on console
print C$ " is " T "degree Celsius"
F=T*9/5 + 32
print "Which is " F " degree Fahrenheit"

' this is a conditional statement
if T>=hot then
    print "hot weather today"
else
    print "not that hot today"
endif

' this is a loop count to 10 (wait one second on each count) and backward to 0
for a = 1 to 3
 pause 1000
next a
do while a>0
 a=a-1
loop
print "a is now =" a
100 REM TEST 8
101 REM From http://www.cpcwiki.eu/index.php/BASIC_Benchmark
102 REM Executes in about 65s on SBC9995MAX with 12MHz crystal (3MHz CPU)
103 REM Executed in about 840s on 1802 Membership Card with 3.8MHz crystal
104 REM Executed in about 195s on CDP180X FPGA implementation at 25MHz clock
105 ENINT 200
110 PRINT "START (Press INT button to see variable values)"
120 K=0
130 K=K+1
140 A=K^2
150 B=LOG(K)
160 C=SIN(K)
170 IF K<1000 THEN  GOTO 130
180 PRINT "STOP"
190 END
200 PRINT K,A,B,C
205 RETURN 

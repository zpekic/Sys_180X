@echo off
@echo See https://github.com/zpekic/MicroCodeCompiler
copy ..\..\sys9900\mcc\microcode\tty_screen.mcc
..\..\Sys9900\mcc\mcc\bin\Debug\mcc.exe tty_screen.mcc
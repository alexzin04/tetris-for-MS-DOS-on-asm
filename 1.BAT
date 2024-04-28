@echo off

cls

C:\TASM\tasm a3.asm,a.object
if errorlevel 1 goto error

C:\TASM\tlink /x/t a.object,a.com

a
:eror

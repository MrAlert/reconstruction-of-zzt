@echo off
if not exist BIN mkdir BIN
del BIN\*.*

if not exist DIST mkdir DIST
del DIST\*.*

echo.
echo [ Building ZZT.EXE ]
echo.
TPC /B /EBIN /GD /ISRC /USRC SRC\ZZT.PAS
if errorlevel 1 goto error

echo.
echo [ Creating DIST/ ]
echo.

copy BIN\ZZT.EXE DIST\ZZT.EXE
copy DOC\*.HLP DIST\
copy RES\REGISTER DIST\REGISTER
copy RES\DEMO.ZZT DIST\DEMO.ZZT
copy LICENSE.TXT DIST\LICENSE.TXT
goto done
:error
echo.
echo [ Error detected! Stopping. ]
:done

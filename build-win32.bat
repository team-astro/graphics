@echo off
if not defined DevEnvDir (
  call "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat" x64
)

IF NOT EXIST build mkdir build
pushd build

rem MSVC Switches - http://msdn.microsoft.com/en-us/library/fwkeyyhe.aspx
rem -nologo Disable MS header on output
rem -Gm- Disables minimal rebuild (always build everything)
rem -GR- Disables run-time type information
rem -EHa- Disables exception handling
rem -Oi Enable compiler intrinsic in place of C runtime calls
rem -WX Treats all compiler warnings as errors.
rem -W4 Warning level 4
rem -FC Display full path of source code files passed to cl.exe in diagnostic text
rem -Z7 Generates C 7.0–compatible debugging information (no PDB)
rem -Fm Creates a map file of the executable
rem -MT Static link to C runtime 
rem
rem Warnings:
rem 4201: nonstandard extension used : nameless struct/union
rem 4100: unreferenced formal parameter
rem 4611: interaction between 'function' and C++ object destruction is non-portable (setjmp used in greatest)
rem 4127: conditional expression is constant
rem

set CommonCompilerDefines=-D_CRT_SECURE_NO_WARNINGS -D_HAS_EXCEPTIONS=0
set CommonCompilerFlags=-nologo -wd4201 -wd4100 -wd4611 -wd4127 -Gm- -GR- -EHa- -Oi -WX -W4 -FC -Z7 -MTd
set LibsPath=C:\Libs

cl ^
 %CommonCompilerDefines% ^
 %CommonCompilerFlags% ^
 -FmAstroGraphicsTests.exe.map ^
 ..\test\main.cpp ^
 -FeAstroGraphicsTests.exe ^
 -I ..\include ^
 -I ..\deps ^
 -I ..\..\astro\include ^
 /link -subsystem:windows,5.2 user32.lib


popd


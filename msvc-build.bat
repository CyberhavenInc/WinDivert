:: msvc-build.bat
:: (C) 2019, all rights reserved,
::
:: This file is part of WinDivert.
::
:: WinDivert is free software: you can redistribute it and/or modify it under
:: the terms of the GNU Lesser General Public License as published by the
:: Free Software Foundation, either version 3 of the License, or (at your
:: option) any later version.
::
:: This program is distributed in the hope that it will be useful, but
:: WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
:: or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
:: License for more details.
::
:: You should have received a copy of the GNU Lesser General Public License
:: along with this program.  If not, see <http://www.gnu.org/licenses/>.
::
:: WinDivert is free software; you can redistribute it and/or modify it under
:: the terms of the GNU General Public License as published by the Free
:: Software Foundation; either version 2 of the License, or (at your option)
:: any later version.
:: 
:: This program is distributed in the hope that it will be useful, but
:: WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
:: or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
:: for more details.
:: 
:: You should have received a copy of the GNU General Public License along
:: with this program; if not, write to the Free Software Foundation, Inc., 51
:: Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

@echo off

set WindowsSdkDir=C:\Program Files (x86)\Windows Kits\10\

REM Create a self-signed certificate for driver signing (only if it doesn't exist)
if not exist WinDivert.pfx (
    echo Creating WinDivert certificate...
    if exist WinDivert.cer del WinDivert.cer
    if exist WinDivert.pvk del WinDivert.pvk
    makecert -r -pe -ss PrivateCertStore -n "CN=WinDivert" -eku 1.3.6.1.5.5.7.3.3 WinDivert.cer -sv WinDivert.pvk
    pvk2pfx -pvk WinDivert.pvk -spc WinDivert.cer -pfx WinDivert.pfx
    echo Certificate created successfully.
) else (
    echo Using existing WinDivert certificate.
)

REM Compile message catalog to generate windivert_log.h
pushd sys
mc.exe -z "windivert_log" -h "." -r "." windivert_log.mc
popd

msbuild sys\windivert.vcxproj ^
    /p:Configuration=Release ^
    /p:platform=ARM64 ^
    /p:WindowsTargetPlatformVersion=10.0.22621.0 ^
    /p:SignMode=Off ^
    /p:OutDir=..\install\MSVC\arm64\ ^
    /p:AssemblyName=WinDivert64
REM signtool sign /f WinDivert.pfx /fd sha256 install\MSVC\arm64\WinDivert64.sys

msbuild sys\windivert.vcxproj ^
    /p:Configuration=Release ^
    /p:platform=x64 ^
    /p:WindowsTargetPlatformVersion=10.0.22621.0 ^
    /p:SignMode=Off ^
    /p:OutDir=..\install\MSVC\amd64\ ^
    /p:AssemblyName=WinDivert64
REM signtool sign /f WinDivert.pfx /fd sha256 install\MSVC\amd64\WinDivert64.sys

msbuild dll\windivert.vcxproj ^
    /p:Configuration=Release ^
    /p:platform=ARM64 ^
    /p:OutDir=..\install\MSVC\arm64\
move dll\WinDivert.lib install\MSVC\arm64\.

msbuild dll\windivert.vcxproj ^
    /p:Configuration=Release ^
    /p:platform=x64 ^
    /p:OutDir=..\install\MSVC\amd64\
move dll\WinDivert.lib install\MSVC\amd64\.



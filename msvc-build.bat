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

msbuild sys\windivert.vcxproj ^
    /p:Configuration=Release ^
    /p:platform=ARM64 ^
    /p:SignMode=Off ^
    /p:OutDir=..\install\MSVC\arm64\ ^
    /p:AssemblyName=WinDivert64

msbuild sys\windivert.vcxproj ^
    /p:Configuration=Release ^
    /p:platform=x64 ^
    /p:SignMode=Off ^
    /p:OutDir=..\install\MSVC\amd64\ ^
    /p:AssemblyName=WinDivert64

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



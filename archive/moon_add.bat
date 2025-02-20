@echo off
%1 mshta vbscript:CreateObject("Shell.Application").ShellExecute("%~fs0","::","","runas",1)(window.close)&&exit /b
zerotier-cli orbit 02fff9f2c8 02fff9f2c8
zerotier-cli listpeers
pause
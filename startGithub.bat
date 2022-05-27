@echo off&setlocal EnableDelayedExpansion
rem start C:\Program" "Files\Git\git-bash.exe --cd=.
set path=%path%;"C:\Program Files\Git\cmd"

rem 切换到工程目录
set /p adir=project folder (in the same parent folder of this document):
pushd %adir%

if "%adir:~0,6%"=="github" (
	set bdir=%adir:~6%
) else (
	set bdir=%adir%
)

if not exist ".git" (
    git init
    git config --global user.name "gjkevin2"
    git config --global user.email "gjkevin2@163.com"
    git config --local http.proxy socks5://127.0.0.1:10808
    git config --local https.proxy socks5://127.0.0.1:10808
    git config --global credential.helper store
    git config --global init.defaultBranch master
    git remote add origin https://github.com/gjkevin2/!bdir!.git
    rem add token to repos
    git remote set-url origin https://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@github.com/gjkevin2/!bdir!.git/
)

call :git
pause & exit

:git
git add .
git commit -m "update"
git pull origin master --allow-unrelated-histories
git push origin master
goto :eof
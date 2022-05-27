@echo off&setlocal EnableDelayedExpansion
rem start C:\Program" "Files\Git\git-bash.exe --cd=.
set path=%path%;"C:\Program Files\Git\cmd"

rem 切换到工程目录
set /p adir=project folder (in the same parent folder of this document):
pushd %adir%

if not exist ".git" (
    git init
    git config --global user.name "gjkevin"
    git config --global user.email "gjkevin2@163.com"
    git config --global pull.rebase false
    git config --global credential.helper store
    git config --global init.defaultBranch master
    git remote add origin "https://gitee.com/gjkevin/!adir!.git"
)

call :git
pause & exit

:git
git add .
git commit -m "update"
git pull origin master --allow-unrelated-histories
git push origin master
goto :eof
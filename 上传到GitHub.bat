@echo off
chcp 936 >nul
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

set "BRANCH=main"
set "REMOTE=origin"
set "GHURL=https://github.com/hsz123511/aaa"

echo ==========================================================
echo   一键上传到 GitHub :  %GHURL%
echo ----------------------------------------------------------
echo   用法一: 把一个或多个文件/文件夹 拖到本 bat 图标上
echo   用法二: 先把文件复制进本目录, 再双击本 bat
echo   说明  : 会自动 add / commit / push, 出错会提示
echo ==========================================================
echo.

rem ---------- 0. 仓库自检 ----------
if not exist ".git\" (
    echo [初始化] 当前目录还不是 git 仓库, 正在初始化 ...
    git init -b %BRANCH%
    echo.
)
git remote get-url %REMOTE% >nul 2>&1
if errorlevel 1 (
    echo [配置] 添加远端 %REMOTE% -^> %GHURL%.git
    git remote add %REMOTE% "%GHURL%.git"
    echo.
)
rem 让中文文件名正常显示
git config core.quotepath false >nul 2>&1

rem ---------- 1. 把拖进来的东西复制到仓库目录 ----------
if not "%~1"=="" (
    for %%F in (%*) do (
        if exist "%%~fF\" (
            echo [复制] 文件夹  %%~nxF
            xcopy "%%~fF" "%%~nxF\" /E /I /Y >nul
        ) else (
            echo [复制] 文件    %%~nxF
            copy /Y "%%~fF" "%%~nxF" >nul
        )
    )
    echo.
)

rem ---------- 2. 是否有变化 ----------
git add -A
git diff --cached --quiet
if not errorlevel 1 (
    echo [跳过] 没有检测到新变化, 无需提交.
    goto :done
)

rem ---------- 3. 提交说明 ----------
set "MSG="
if "%~1"=="" set /p "MSG=请输入提交说明 (直接回车用默认): "
if not defined MSG set "MSG=上传文件 %DATE% %TIME%"
echo.
echo [提交] %MSG%
git commit -m "%MSG%"
if errorlevel 1 goto :fail

rem ---------- 4. 推送 ----------
echo.
echo [推送] git push %REMOTE% %BRANCH% ...
git push %REMOTE% %BRANCH%
if errorlevel 1 (
    echo.
    echo [同步] 远端有新的提交, 先拉取合并再重试 ...
    git pull --rebase %REMOTE% %BRANCH%
    if errorlevel 1 goto :fail
    git push %REMOTE% %BRANCH%
    if errorlevel 1 goto :fail
)

:done
echo.
echo [完成] 已上传到 %GHURL%
git log --oneline -1
echo.
echo 提示: 单个文件超过 100 MB 会被 GitHub 拒绝, 大文件请改用 Release 或 Git LFS.
goto :end

:fail
echo.
echo [失败] 上面有报错信息. 常见原因:
echo    - 网络不通 / 代理问题
echo    - 凭据失效: 在 Windows 凭据管理器里删除 git:https://github.com 后重试
echo    - 冲突: 手动执行 git status 查看
goto :end

:end
if not defined NO_PAUSE pause
exit /b 0

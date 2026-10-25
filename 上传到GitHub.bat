@echo off
chcp 936 >nul
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

set "BRANCH=main"
set "REMOTE=origin"
set "GHURL=https://github.com/hsz123511/aaa"
set "MAXSIZE=95000000"

echo ==========================================================
echo   一键上传 ZIP 到 GitHub :  %GHURL%
echo ----------------------------------------------------------
echo   只接受 .zip 文件, 其他类型一律跳过
echo   用法一: 把一个或多个 .zip 拖到本 bat 图标上
echo   用法二: 把 .zip 复制进本目录后, 双击本 bat
echo ==========================================================
echo.

rem ---------- 0. 仓库自检 ----------
if not exist ".git\" (
    echo [初始化] 当前目录还不是 git 仓库, 正在初始化 ...
    git init -b main
    echo.
)
git remote get-url %REMOTE% >nul 2>&1
if errorlevel 1 (
    echo [配置] 添加远端 %REMOTE% -^> %GHURL%.git
    git remote add %REMOTE% "%GHURL%.git"
    echo.
)
git config core.quotepath false >nul 2>&1

rem ---------- 1. 只复制拖进来的 zip ----------
if not "%~1"=="" (
    for %%F in (%*) do (
        if /i not "%%~xF"==".zip" (
            echo [跳过] %%~nxF  -- 只接受 .zip 文件
        ) else (
            if %%~zF GTR %MAXSIZE% (
                echo [警告] %%~nxF 超过 95 MB, GitHub 可能拒绝接收
            )
            echo [复制] %%~nxF
            copy /Y "%%~fF" "%%~nxF" >nul
        )
    )
    echo.
)

rem ---------- 2. 只暂存 zip 文件 ----------
git add -A -- "*.zip"
git diff --cached --quiet
if not errorlevel 1 (
    echo [跳过] 没有新的 zip 文件需要提交.
    goto :done
)

rem ---------- 3. 提交说明 ----------
set "MSG="
if "%~1"=="" set /p "MSG=请输入提交说明 (直接回车用默认): "
if not defined MSG set "MSG=上传 zip 文件 %DATE% %TIME%"
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
echo 提示: 单个 zip 超过 100 MB 会被 GitHub 拒绝, 可改用 Release 或 Git LFS.
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

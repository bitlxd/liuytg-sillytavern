@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
cd /d "%~dp0"

echo ========================================
echo    流瞳预设  一键发布
echo ========================================
echo.

rem ---------- 1. 读取版本号 ----------
set "ver="
set /p "ver=请输入版本号 (只填数字, 例如 3.1): "
if "%ver%"=="" (
    echo [错误] 版本号不能为空
    pause & exit /b 1
)
set "tag=v%ver%"
echo.

rem ---------- 2. 检查 tag 是否已存在 ----------
git rev-parse -q --verify "refs/tags/%tag%" >nul 2>nul
if not errorlevel 1 (
    echo [错误] 本地已存在 tag %tag%
    echo        换个版本号, 或先执行: git tag -d %tag%
    pause & exit /b 1
)
git ls-remote --tags origin "%tag%" 2>nul | findstr /c:"%tag%" >nul
if not errorlevel 1 (
    echo [错误] 远程已存在 tag %tag%
    pause & exit /b 1
)

rem ---------- 3. 暂存 + 提交 ----------
git add -A
git diff --cached --quiet
if errorlevel 1 (
    git commit -m "update v%ver%"
    if errorlevel 1 (
        echo [错误] commit 失败
        pause & exit /b 1
    )
) else (
    echo [提示] 没有文件改动, 跳过 commit
)

rem ---------- 4. 打 tag ----------
git tag -a "%tag%" -m "流瞳预设 %tag%"
if errorlevel 1 (
    echo [错误] 打 tag 失败
    pause & exit /b 1
)

rem ---------- 5. 推送 ----------
git push origin main
if errorlevel 1 goto fail
git push origin "%tag%"
if errorlevel 1 goto fail

echo.
echo [成功] 已发布 %tag%
set "tagurl=%tag%"
start "" "https://github.com/bitlxd/liuytg-sillytavern/releases/new?tag=%tagurl%"
pause & exit /b 0

:fail
echo.
echo [错误] 推送失败. 常见原因: 网络 / 远程有新提交需先 pull
echo        可执行: git pull --rebase origin main  然后重跑本脚本
pause & exit /b 1

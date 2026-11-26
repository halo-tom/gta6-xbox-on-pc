@echo off
setlocal
title GTA VI on PC - best measured configuration (1080p, series-s)

rem ------------------------------------------------------------------
rem  Point this at your own dump. Nothing is downloaded or provided here.
rem ------------------------------------------------------------------
if not defined VICTORY_GAME_DIR set "VICTORY_GAME_DIR=D:\your\own\dump"

rem ------------------------------------------------------------------
rem  The layer build: any VIctory-based fork with the land subsystem.
rem  The one measured here is the cool_fox archive at commit f4b48ad.
rem ------------------------------------------------------------------
set "V=%~dp0target\release\victory.exe"
if not exist "%V%" set "V=victory.exe"

if not exist "%VICTORY_GAME_DIR%\game_scarlett_master.exe" (
  echo Set VICTORY_GAME_DIR to the folder that holds game_scarlett_master.exe.
  exit /b 2
)

rem --- switches measured together on one machine ---
set "VICTORY_ASYNC_SUBMIT=1"
set "VICTORY_QUEUE2=1"
set "VICTORY_INDIRECT_WINDOW=1"
set "VICTORY_TEXTURE_NO_WAIT=1"
set "VICTORY_LATE_WAIT=3"
set "VICTORY_WIDE_BACK=1"
set "VICTORY_CARD_BUFFERS_MIN_MB=1"
set "VICTORY_CARD_BUFFERS_MB=1024"
set "VICTORY_CARD_REHASH_RUNS=1"
set "VICTORY_JOIN_COPIES=1"
set "VICTORY_COPY_PLAIN=1"
set "VICTORY_JOIN_PARTS=1"
set "VICTORY_BACK_OWN_VIEW=1"
set "VICTORY_INDIRECT_GATHER=1"

rem --- not an optimisation: newer builds default this off and lose about 12 percent ---
set "VICTORY_REAPER=1"

rem --- deliberately unset ---
set "VICTORY_MERGE_GAP="
set "VICTORY_MERGE_RUNS="
set "VICTORY_WAVE_WIDE="
set "VICTORY_CARD_FETCH_INFLIGHT="
set "VICTORY_D3D12_WARP="
set "VICTORY_D3D12_DIR="

echo ============================================================
echo  GTA VI (Xbox Series build) on PC
echo.
echo  console profile : series-s  -^> the title renders 1920x1080
echo  measured here   : 110 ms/frame median (9.1 fps), 551 samples
echo  same build on series-x: 172-220 ms/frame (4.8-5.9 fps)
echo.
echo  The first launch translates shaders and builds pipelines; it
echo  is slow and the window may stay black for a while. The frame
echo  rate is drawn in the corner of the picture.
echo ============================================================
echo.

"%V%" run "%VICTORY_GAME_DIR%\game_scarlett_master.exe" --console series-s --execute

echo.
echo ============================================================
echo  finished, exit %ERRORLEVEL%
echo ============================================================
pause

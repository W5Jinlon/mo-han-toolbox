@echo off
goto :bof
ytdl.worker
mo-han <zmhungrown@gmail.com>
Dependencies:
    python3
        youtube-dl
        ytdl.iwara.na2uploader.py
            lxml
Reverse dependencies:   
    ytdl
:bof
setlocal
title "%url%"

set split=5
set pause_range=5

if %url:~0,3%==[av ( if %url:~-1%==] ( set url=https://b23.tv/%url:~1,-1% && goto :end_url_completion))
if %url:~0,3%==[BV ( if %url:~-1%==] ( set url=https://b23.tv/%url:~1,-1% && goto :end_url_completion))
if %url:~0,3%==[ph ( if %url:~-1%==] ( set url=https://www.pornhub.com/view_video.php?viewkey=%url:~1,-1% && goto :end_url_completion))
if %url:~0,3%==[sm ( if %url:~-1%==] ( set url=https://www.nicovideo.jp/watch/%url:~1,-1% && goto :end_url_completion))
if %url:~0,1%==[ ( if %url:~-1%==] ( set url=https://www.youtube.com/watch?v=%url:~1,-1% && goto :end_url_completion))

:end_url_completion
set e=0
echo "%url%" | findstr bilibili > nul
set /a e=%e%+%errorlevel%
echo "%url%" | findstr b23.tv > nul
set /a e=%e%+%errorlevel%
if %e% lss 2 (set bilibili=1) else set bilibili=0

echo "%url%" | findstr /c:"/av" > nul
if %errorlevel%==0 set id_prefix=av
echo "%url%" | findstr /c:"/BV" > nul
if %errorlevel%==0 set id_prefix=BV

if %bilibili%==1 set output_fmt=%%(title)s [%id_prefix%%%(id)s][%%(uploader)s].%%(ext)s
if %bilibili%==0 set output_fmt=%%(title)s [%%(id)s][%%(uploader)s].%%(ext)s
set base_args_uploader=-o "%output_fmt%" --yes-playlist --fragment-retries infinite -icw "%url%"
set base_args_iwara=-o "%%(title)s [%%(id)s][%%(uploader)s].%%(ext)s" --yes-playlist "%url%"
set aria2_args=--external-downloader aria2c --external-downloader-args "-x%split% -s%split% -k 1M --file-allocation=trunc"
if defined noaria2 set aria2_args=
set args=--proxy=%proxy% --youtube-skip-dash-manifest %aria2_args% %base_args_uploader%
rem set args=--proxy %proxy% %base_args_uploader%

echo "%url%" | findstr "sankakucomplex" > nul
if %errorlevel%==0 set args=--proxy=%proxy% %aria2_args% -o "%%(id)s.%%(ext)s" "%url%"
echo "%url%" | findstr "javdove.com" > nul
if %errorlevel%==0 set args=--proxy=%proxy% %aria2_args% -o "%%(title)s [javdove].%%(ext)s" "%url%"
echo "%url%" | findstr "iwara" > nul
if %errorlevel%==0 (
set args=--proxy=%proxy% %aria2_args% %base_args_iwara% --no-check-certificate
set postprocess=iwara
) else set postprocess=null
if %bilibili%==1 set args=--cookies %locallib_usretc%\cookies.bilibili.txt --exec "conv.copy2mp4 {} -map_metadata -1 -y -loglevel warning && del {}" %aria2_args% %base_args_uploader%
rem Append `--no-check-certificate` for YouTube. Have no idea but it works. And since it's just video data downloaded, there should be no security/privacy issue.
rem echo "%url%" | findstr "youtube youtu.be" > nul
rem if %errorlevel%==0 set args=--no-check-certificate %args%

:end_per_site_adjustment
call ytdl.custom.cmd

if not [%default%]==[false] (
set fmt=%default%
goto :afterprompt
)
:prompt
echo %args%
echo --------------------------------
set fmt=
echo [Q]uit, [B]est, [F]ormat list (Default), File[N]ame, [J]SON, [Enter]=Default
echo [M] try mp4 1080p 60fps
echo [W] try webm 1080p 60fps
set /p "fmt=> "
echo --------------------------------
if not defined fmt set fmt=f
:afterprompt
if "%fmt%"=="q" exit
if "%fmt%"=="f" (
youtube-dl -F %args%
echo --------------------------------
goto :prompt
)
if "%fmt%"=="md" (
set fmt=m
set args=%args:--youtube-skip-dash-manifest=%
)
if "%fmt%"=="wd" (
set fmt=w
set args=%args:--youtube-skip-dash-manifest=%
)
if "%fmt%"=="n" youtube-dl --get-filename %args% && goto :eof
if "%fmt%"=="j" goto :json
if "%fmt%"=="b" set "fmt=bestvideo+bestaudio/best"
if "%fmt%"=="m" (
set "fmt=(mp4)[height<=1080][fps<=60]+(m4a/aac)/bestvideo+bestaudio/best"
set args=--embed-thumbnail %args%
)
if "%fmt%"=="w" set "fmt=(webm)[height<=1080][fps<=60]+bestaudio[ext=webm]/bestvideo+bestaudio/best"
set args=-f "%fmt%" %args%
if %bilibili%==1 set args=%args:--embed-thumbnail =%
goto :download

:download
echo %args%
set /a pause=(%random%*%pause_range%/32768)+%pause_range%
youtube-dl %args%
rem echo %errorlevel%
rem pause
if errorlevel 1 (
rem set /a retry+=1
rem if %retry% lss %retry_max% goto :download
rem set /p "_fin=Try again or [q]uit ? "
rem if not defined _fin (
rem   set /a retry=0
rem   goto :download
rem )
rem if not "%_fin%"=="q" (
rem   set /a retry=0
rem   goto :download
rem )
rem if "%_fin%"=="q" goto :end
timeout %pause%
goto :download
)
echo --------------------------------
echo DOWNLOAD SUCCESS
if %postprocess%==iwara call ytdl_iwara_na2uploader.py "%url%"
timeout 3
goto :eof

:json
youtube-dl -j %args%
echo --------------------------------
pause
goto eof

:: Changelog
:: [0.7.2] -2020-03-25
:: + bilibili with postprocess (flv -> mp4).
:: [0.7.2] - 2020-03-23
:: + ytdl.iwara.na2uploader.py to rename downloaded videos from iwara, replacing [NA] with [%(uploader)s].
:: [0.7.1] - 2020-02-11
:: + option `--no-check-certificate` for iwara site.
:: [0.7] - 2020-02-11
:: - options `--socket-timeout 30 --youtube-skip-dash-manifest`;
:: * webm 1440p -> 1080p, audio using opus/vorbis (remove webm).
:: [0.6] - 2020-01-24
:: + new option `j` for [J]SON (dumping only).
:: [0.5.3] - 2019-12-07
:: + embed thumbnail.
:: [0.5.2] - 2019-12-07
:: - embed thumbnail & subs;
:: * aria2 use trunc.
:: [0.5.1] - 2019-12-07
:: + embed thumbnail & subs; aria2 use falloc.
:: [0.5.0] - 2019-11-01
:: + call a new script `yt-dl.custom.bat` after per_site_adjustment procedure.
:: [0.4.2] - 2019-09-29
:: * retry interval range changed from 30s~60s to 60s~120s.
:: [0.4.1] - 2019-09-23
:: * when failed downloading, wait a random time between 30~60 sec before retrying.
:: [0.4.0] - 2019-09-10
:: * when encouting error, wait for 60s then retry, rather than pause and prompt.
:: [0.3.4] - 2019-09-01
:: + --youtube-skip-dash-manifest
:: [0.3.3] - 2019-07-28
:: + youtube video id inside "[]" being detected and auto-completed.
:: [0.3.2] - 2019-07-20
:: * "[W] try webm 1080p 60fps" now trying 1440p instead of 1080p.
:: [0.3.1] - 2019-07-13
:: + sankakucomplex.com support.
:: * when error occurs, prompt "Try again or [q]uit?".
:: [0.3.0] - 2019-06-28
:: * a lot of minor changes been forgotten
:: [0.2.2] 2018-02-14
:: Append `--no-check-certificate` for YouTube. Reasons unknown, but the CRL url `http://pki.google.com/GIAG2.crl` in YouTube's SSL cert is blocked by GFW, which might be the cause.
:: [0.2.1] - 2018-02-08
:: add: `--external-downloader-args "--http-proxy=%proxy% -x10 -s10"` for aria2.
:: [0.2] - 2017-12-12
:: * Now default to [F]ormat list, pressing [Enter] will list all formats.
:: 171120
:: * Default to [W] webm/mp4 1080p 60fps bestaudio (Default)
:: 170620
:: + New param `d` for "automatically select default" (will not prompt for format).
:: 170517
:: * Format list is optional now. It would only be showed chosen.
:: 170514
:: * `aria2_args` & `aria2_args`
:: 170501
:: + Auto retry downloading for 3 times, then prompt for retrying.
:: 170414
::  [*] MP4 seems better (although bigger) than WebM on YouTube
::  [*] [1] mp4/webm 1080p 60fps bestaudio (default)
::  [*] [2] webm/mp4 1080p 60fps bestaudio
:: 170331
::  [+] Use aria2c to download bilibili videos (to avoid speed limitation)
::  [+] New download choice: webm/mp4 [1]920 60fps bestaudio (default)
::  [+] New download choice: webm/mp4 [2]560 60fps bestaudio
::  [+] Wait 5 sec to exit after download
:: 170316
::  [+] Always get filename
::  [-] Remove `fn`
::  [+] Input `q` to quit
::  [+] After an error occurs, input `r` to re-download
:: 161113
::  [+] Input `fn` to get output file name
::  [+] Exam 'bilibili' in URL to disable proxy
::  [*] Use proxy by default
::  [*] Quote URL for stablity against special characters such as ampersand
:: 160916
::  [-] Remove `IF` block of proxy switching
::  [*] Always use proxy
:: 160906
::  [*] NOT useing proxy by default
::  [-] Remove `--no-playlist` option
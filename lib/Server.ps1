# ============================================================
#  WSM2 - Server.ps1
#  Starten (in een apart consolevenster), stoppen, status en
#  het volgen van het serverlogbestand.
# ============================================================

$script:WF2AppId = '1203190'

function Get-ServerExePath {
    param([Parameter(Mandatory)][string]$InstallPath)
    return (Join-Path $InstallPath 'Wreckfest2.exe')
}

# 8.3 korte pad (voor paden met spaties, omdat --save-dir niet gequoteerd mag worden).
function Get-ShortPath {
    param([Parameter(Mandatory)][string]$Path)
    try {
        $fso = New-Object -ComObject Scripting.FileSystemObject
        return $fso.GetFolder($Path).ShortPath
    } catch {
        return $Path
    }
}

function Ensure-SteamAppId {
    param([Parameter(Mandatory)][string]$InstallPath)
    $f = Join-Path $InstallPath 'steam_appid.txt'
    if (-not (Test-Path -LiteralPath $f)) {
        [System.IO.File]::WriteAllText($f, $script:WF2AppId, (New-Object System.Text.UTF8Encoding($false)))
    }
}

function Get-RunningServerProcess {
    param([Parameter(Mandatory)][string]$InstallPath)
    $exe = (Get-ServerExePath -InstallPath $InstallPath)
    $procs = @(Get-Process -Name 'Wreckfest2' -ErrorAction SilentlyContinue)
    $found = @()
    foreach ($p in $procs) {
        try {
            if ($p.Path -and ($p.Path -ieq $exe)) { $found += $p }
        } catch { }
    }
    return $found
}

function Test-ServerRunning {
    param([Parameter(Mandatory)][string]$InstallPath)
    return ((Get-RunningServerProcess -InstallPath $InstallPath).Count -gt 0)
}

function Start-WF2Server {
    param(
        [Parameter(Mandatory)][string]$InstallPath,
        [Parameter(Mandatory)][string]$SaveDir,
        [ValidateSet('community', 'local')][string]$Mode = 'community'
    )
    $exe = Get-ServerExePath -InstallPath $InstallPath
    if (-not (Test-Path -LiteralPath $exe)) {
        throw ((T 'Server-executable niet gevonden: {0}') -f $exe)
    }
    if (-not (Test-Path -LiteralPath $SaveDir)) {
        New-Item -ItemType Directory -Path $SaveDir -Force | Out-Null
    }
    Ensure-SteamAppId -InstallPath $InstallPath

    $modeArg = if ($Mode -eq 'local') { '--local-server' } else { '--server' }

    # De engine verwacht --save-dir=<pad> ONgequoteerd; quotes geven een
    # "Fatal Error" (pad bestaat niet). Bij spaties in het pad gebruiken we
    # het 8.3 korte pad als workaround.
    $saveArg = $SaveDir
    if ($SaveDir -match '\s') { $saveArg = Get-ShortPath $SaveDir }

    # Een klein launcher-script voorkomt lastige quoting en houdt het venster
    # open (pause) zodat de serveruitvoer/log leesbaar blijft.
    $launcher = Join-Path ([System.IO.Path]::GetTempPath()) 'WSM2_start_server.cmd'
    $lines = @(
        '@echo off'
        'title Wreckfest 2 Server'
        "cd /d `"$InstallPath`""
        "`"$exe`" $modeArg --save-dir=$saveArg"
        'echo.'
        "echo === $(T 'Server gestopt (exitcode %errorlevel%)') ==="
        "echo $(T 'Druk op een toets om dit venster te sluiten.')"
        'pause >nul'
    )
    [System.IO.File]::WriteAllText($launcher, ($lines -join "`r`n"), (New-Object System.Text.UTF8Encoding($false)))

    # Via 'cmd /c start' forceren we een nieuw, zichtbaar consolevenster
    # (Start-Process alleen erft de verborgen vensterstatus van de launcher).
    $p = Start-Process -FilePath 'cmd.exe' `
        -ArgumentList '/c', 'start', '"Wreckfest 2 Server"', "`"$launcher`"" `
        -WorkingDirectory $InstallPath -PassThru
    return $p
}

function Stop-WF2Server {
    param([Parameter(Mandatory)][string]$InstallPath)
    $procs = Get-RunningServerProcess -InstallPath $InstallPath
    foreach ($p in $procs) {
        try { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue } catch { }
    }
    return $procs.Count
}

function Get-LogFileTail {
    param(
        [Parameter(Mandatory)][string]$LogPath,
        [int]$Lines = 200
    )
    if (-not (Test-Path -LiteralPath $LogPath)) { return '' }
    try {
        $content = Get-Content -LiteralPath $LogPath -Tail $Lines -ErrorAction Stop
        return ($content -join "`r`n")
    } catch {
        return ''
    }
}

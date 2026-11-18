# ============================================================
#  WSM2 - Config.ps1
#  Inlezen / valideren / wegschrijven van de Wreckfest 2
#  serverconfiguratiebestanden (JSON).
# ============================================================

# --- Bestandsnamen binnen de save-dir -----------------------
$script:FileNameServerConfig = 'server_config.scnf'
$script:FileNameCupConfig    = 'server_cup_config.ccnl'
$script:FileNamePrivilege    = 'server_privilege.sprv'
$script:TelemetrySubDir      = 'telemetry'
$script:TelemetryFile        = 'config.json'

function Get-SaveDirPaths {
    param([Parameter(Mandatory)][string]$SaveDir)
    return [ordered]@{
        SaveDir       = $SaveDir
        ServerConfig  = Join-Path $SaveDir $script:FileNameServerConfig
        CupConfig     = Join-Path $SaveDir $script:FileNameCupConfig
        Privilege     = Join-Path $SaveDir $script:FileNamePrivilege
        TelemetryDir  = Join-Path $SaveDir $script:TelemetrySubDir
        Telemetry     = Join-Path (Join-Path $SaveDir $script:TelemetrySubDir) $script:TelemetryFile
    }
}

# --- JSON lezen/schrijven -----------------------------------
function Read-JsonFile {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    try {
        $raw = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
        if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
        return ($raw | ConvertFrom-Json)
    } catch {
        throw ((T 'Kan JSON niet lezen uit {0}: {1}') -f @($Path, $_.Exception.Message))
    }
}

function Backup-ConfigFile {
    param([Parameter(Mandatory)][string]$Path)
    if (Test-Path -LiteralPath $Path) {
        $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        Copy-Item -LiteralPath $Path -Destination "$Path.$stamp.bak" -Force -ErrorAction SilentlyContinue
    }
}

function Write-JsonFile {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)]$Object,
        [switch]$NoBackup
    )
    if (-not $NoBackup) { Backup-ConfigFile -Path $Path }
    $json = $Object | ConvertTo-Json -Depth 100
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    [System.IO.File]::WriteAllText($Path, $json, (New-Object System.Text.UTF8Encoding($false)))
}

# --- Property helpers ---------------------------------------
function Get-Prop {
    param($Obj, [string]$Name)
    if ($null -eq $Obj) { return $null }
    if ($Obj -is [System.Collections.IDictionary]) {
        if ($Obj.Contains($Name)) { return $Obj[$Name] }
        return $null
    }
    $p = $Obj.PSObject.Properties[$Name]
    if ($p) { return $p.Value }
    return $null
}

function Set-Prop {
    param($Obj, [string]$Name, $Value)
    if ($null -eq $Obj) { return }
    if ($Obj -is [System.Collections.IDictionary]) {
        $Obj[$Name] = $Value
        return
    }
    if ($Obj.PSObject.Properties[$Name]) {
        $Obj.$Name = $Value
    } else {
        $Obj | Add-Member -NotePropertyName $Name -NotePropertyValue $Value -Force
    }
}

# Geeft het eerste element van een (mogelijk door PowerShell uitgepakte)
# array terug, of $null. Nodig omdat functies arrays uitpakken.
function Get-FirstItem {
    param($Value)
    if ($null -eq $Value) { return $null }
    $arr = @($Value)
    if ($arr.Count -eq 0) { return $null }
    return $arr[0]
}

# Geeft altijd een array terug (of lege array), ongeacht uitpakken.
function Get-Array {
    param($Value)
    if ($null -eq $Value) { return @() }
    return @($Value)
}

function Get-Bbmeta {
    param($Obj)
    if ($null -eq $Obj) { return $null }
    if ($Obj -is [System.Collections.IDictionary]) {
        if ($Obj.Contains('bbmeta')) { return $Obj['bbmeta'] }
        return $null
    }
    $p = $Obj.PSObject.Properties['bbmeta']
    if ($p) { return $p.Value }
    return $null
}

function Set-Bbmeta {
    param($Obj, $Value)
    if ([string]::IsNullOrEmpty($Value)) { return }
    if ($Obj -is [System.Collections.IDictionary]) { $Obj['bbmeta'] = $Value; return }
    $Obj | Add-Member -NotePropertyName 'bbmeta' -NotePropertyValue $Value -Force
}

# --- Standaardstructuren ------------------------------------
function New-DefaultServerConfig {
    return [ordered]@{
        'net server config' = @(
            [ordered]@{
                'name'           = 'Wreckfest 2 Server'
                'description'    = 'Welkom op mijn server!'
                'password'       = ''
                'log file name'  = ''
                'game port'      = 30100
            }
        )
        'game server config' = @(
            [ordered]@{
                'cup list'               = ''
                'event loop name'        = 'default_loop'
                'countdown time'         = 100000
                'voting time'            = 20000
                'flags'                  = ''
                'auto ban report limits' = @(
                    [ordered]@{ 'censor report limit' = 4; 'silence report limit' = 8; 'suspend report limit' = 12 }
                )
                'server ban durations'   = @(
                    [ordered]@{ 'censor duration' = 1440; 'silence duration' = 1440; 'suspend duration' = 525600 }
                )
                'admin ban durations'    = @(
                    [ordered]@{ 'censor duration' = 1440; 'silence duration' = 1440; 'suspend duration' = 525600 }
                )
                'default ban durations'  = @(
                    [ordered]@{ 'censor duration' = 1440; 'silence duration' = 1440; 'suspend duration' = 525600 }
                )
            }
        )
    }
}

function New-EventRule {
    return [ordered]@{
        'laps'                        = 3
        'time limit'                  = 5
        'number of teams'             = 1
        'max number of participants'  = 24
        'flags'                       = ''
        'collecting order'            = 'Collecting Sequential'
        'car reset delay (seconds)'   = 2
        'team split (%)'              = 0
        'vehicle damage id'           = ''
    }
}

function New-EventLevel {
    return [ordered]@{
        'level id'            = ''
        'weather path'        = ''
        'weather intent path' = ''
        'ai set path'         = 'runtime/career/ai-class-all.aist'
        'game mode id'        = 'bangerrace'
    }
}

function New-Event {
    return [ordered]@{
        'level'           = @( (New-EventLevel) )
        'rules'           = @( (New-EventRule) )
        'car restriction' = @()
        'bot count'       = 8
    }
}

function New-CupRaceSettings {
    return [ordered]@{
        'point distribution'       = '30;27;25;20;19;18;17;16;15;14;13;12;11;10;9;8;7;6;5;4;3;2;1;0'
        'flags'                    = ''
        'start order'              = 'random'
        'points for best lap time' = 0
        'points for highest score' = 0
        'last race multiplier'     = 1
    }
}

function New-Cup {
    return [ordered]@{
        'race settings'     = @( (New-CupRaceSettings) )
        'event loop'        = 'data/property/settings/cup/waypoint_tracks.becl'
        'cup name'          = 'Nieuwe cup'
        'cup description'   = ''
        'icon'              = ''
        'car restriction'   = @()
    }
}

function New-DefaultEventLoop {
    $ev = New-Event
    $ev['level'][0]['level id']     = 'track01_1'
    $ev['level'][0]['weather path'] = 'data/property/weather/track01_1.weat'
    $ev['rules'][0]['laps']         = 4
    return [ordered]@{ 'events' = @( $ev ) }
}

function New-DefaultCupConfig {
    return [ordered]@{ 'cups' = @( (New-Cup) ) }
}

function New-DefaultPrivilege {
    return [ordered]@{
        'bbmeta' = 'sprv v0 n1'
        'roles'  = @()
        'bans'   = @()
    }
}

function New-DefaultTelemetry {
    return [ordered]@{
        'udp'     = @( [ordered]@{ 'enabled' = 0; 'ip' = '127.0.0.1'; 'port' = '23123' } )
        'logging' = @( [ordered]@{ 'format' = 'none' } )
        'server'  = @( [ordered]@{ 'enabled' = 0; 'automaticMainCar' = 0 } )
    }
}

# --- Save-dir voorbereiden ----------------------------------
function Initialize-SaveDir {
    param([Parameter(Mandatory)][string]$SaveDir)
    if (-not (Test-Path -LiteralPath $SaveDir)) {
        New-Item -ItemType Directory -Path $SaveDir -Force | Out-Null
    }
    $p = Get-SaveDirPaths -SaveDir $SaveDir
    if (-not (Test-Path -LiteralPath $p.TelemetryDir)) {
        New-Item -ItemType Directory -Path $p.TelemetryDir -Force | Out-Null
    }
    if (-not (Test-Path -LiteralPath $p.ServerConfig)) {
        Write-JsonFile -Path $p.ServerConfig -Object (New-DefaultServerConfig) -NoBackup
    }
    if (-not (Test-Path -LiteralPath $p.CupConfig)) {
        Write-JsonFile -Path $p.CupConfig -Object (New-DefaultCupConfig) -NoBackup
    }
    if (-not (Test-Path -LiteralPath $p.Privilege)) {
        Write-JsonFile -Path $p.Privilege -Object (New-DefaultPrivilege) -NoBackup
    }
    if (-not (Test-Path -LiteralPath $p.Telemetry)) {
        Write-JsonFile -Path $p.Telemetry -Object (New-DefaultTelemetry) -NoBackup
    }
}

# --- Validatie ----------------------------------------------
function Test-Port {
    param($Value)
    $n = 0
    if (-not [int]::TryParse([string]$Value, [ref]$n)) { return $false }
    return ($n -ge 1 -and $n -le 65535)
}

function Test-Range {
    param($Value, [int]$Min, [int]$Max)
    $n = 0
    if (-not [int]::TryParse([string]$Value, [ref]$n)) { return $false }
    return ($n -ge $Min -and $n -le $Max)
}

# --- Server config: uitlezen naar vlakke waarden ------------
function Read-ServerConfigValues {
    param($Obj)
    $net = @{}
    $net.name = 'Server'
    $net.description = ''
    $net.password = ''
    $net.logFileName = ''
    $net.gamePort = 30100

    $game = @{}
    $game.cupList = ''
    $game.eventLoopName = 'default_loop'
    $game.countdownTime = 100000
    $game.votingTime = 20000
    $game.flags = ''
    $game.censorReport = 4
    $game.silenceReport = 8
    $game.suspendReport = 12
    $game.serverCensor = 1440; $game.serverSilence = 1440; $game.serverSuspend = 525600
    $game.adminCensor = 1440;  $game.adminSilence = 1440;  $game.adminSuspend = 525600
    $game.defaultCensor = 1440; $game.defaultSilence = 1440; $game.defaultSuspend = 525600

    if ($null -ne $Obj) {
        $n = Get-FirstItem (Get-Prop $Obj 'net server config')
        if ($null -ne $n) {
            if (Get-Prop $n 'name')          { $net.name = Get-Prop $n 'name' }
            if ($null -ne (Get-Prop $n 'description')) { $net.description = Get-Prop $n 'description' }
            if ($null -ne (Get-Prop $n 'password'))    { $net.password = Get-Prop $n 'password' }
            if ($null -ne (Get-Prop $n 'log file name')) { $net.logFileName = Get-Prop $n 'log file name' }
            if ($null -ne (Get-Prop $n 'game port'))   { $net.gamePort = Get-Prop $n 'game port' }
        }
        $g = Get-FirstItem (Get-Prop $Obj 'game server config')
        if ($null -ne $g) {
            if ($null -ne (Get-Prop $g 'cup list'))         { $game.cupList = Get-Prop $g 'cup list' }
            if (Get-Prop $g 'event loop name')              { $game.eventLoopName = Get-Prop $g 'event loop name' }
            if ($null -ne (Get-Prop $g 'countdown time'))   { $game.countdownTime = Get-Prop $g 'countdown time' }
            if ($null -ne (Get-Prop $g 'voting time'))      { $game.votingTime = Get-Prop $g 'voting time' }
            if ($null -ne (Get-Prop $g 'flags'))            { $game.flags = Get-Prop $g 'flags' }
            $abl = Get-FirstItem (Get-Prop $g 'auto ban report limits')
            if ($null -ne $abl) {
                $game.censorReport  = Get-Prop $abl 'censor report limit'
                $game.silenceReport = Get-Prop $abl 'silence report limit'
                $game.suspendReport = Get-Prop $abl 'suspend report limit'
            }
            $sbd = Get-FirstItem (Get-Prop $g 'server ban durations')
            if ($null -ne $sbd) {
                $game.serverCensor  = Get-Prop $sbd 'censor duration'
                $game.serverSilence = Get-Prop $sbd 'silence duration'
                $game.serverSuspend = Get-Prop $sbd 'suspend duration'
            }
            $abd = Get-FirstItem (Get-Prop $g 'admin ban durations')
            if ($null -ne $abd) {
                $game.adminCensor  = Get-Prop $abd 'censor duration'
                $game.adminSilence = Get-Prop $abd 'silence duration'
                $game.adminSuspend = Get-Prop $abd 'suspend duration'
            }
            $dbd = Get-FirstItem (Get-Prop $g 'default ban durations')
            if ($null -ne $dbd) {
                $game.defaultCensor  = Get-Prop $dbd 'censor duration'
                $game.defaultSilence = Get-Prop $dbd 'silence duration'
                $game.defaultSuspend = Get-Prop $dbd 'suspend duration'
            }
        }
    }
    return [ordered]@{ net = $net; game = $game }
}

# --- Server config: wegschrijven (behoudt bbmeta) -----------
function Save-ServerConfig {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)]$Values
    )
    $existing = $null
    try { $existing = Read-JsonFile -Path $Path } catch { $existing = $null }

    $net = $Values.net
    $game = $Values.game

    $netObj = [ordered]@{}
    Set-Bbmeta $netObj (Get-Bbmeta (Get-Prop $net 'bbmeta'))
    $netObj['name']          = $net.name
    $netObj['description']   = $net.description
    $netObj['password']      = $net.password
    $netObj['log file name'] = $net.logFileName
    $netObj['game port']     = [int]$net.gamePort

    $gameObj = [ordered]@{}
    $gameObj['cup list']        = $game.cupList
    $gameObj['event loop name'] = $game.eventLoopName
    $gameObj['countdown time']  = [int]$game.countdownTime
    $gameObj['voting time']     = [int]$game.votingTime
    $gameObj['flags']           = $game.flags
    $gameObj['auto ban report limits'] = @(
        [ordered]@{
            'censor report limit'  = [int]$game.censorReport
            'silence report limit' = [int]$game.silenceReport
            'suspend report limit' = [int]$game.suspendReport
        }
    )
    $gameObj['server ban durations'] = @(
        [ordered]@{ 'censor duration' = [int]$game.serverCensor; 'silence duration' = [int]$game.serverSilence; 'suspend duration' = [int]$game.serverSuspend }
    )
    $gameObj['admin ban durations'] = @(
        [ordered]@{ 'censor duration' = [int]$game.adminCensor; 'silence duration' = [int]$game.adminSilence; 'suspend duration' = [int]$game.adminSuspend }
    )
    $gameObj['default ban durations'] = @(
        [ordered]@{ 'censor duration' = [int]$game.defaultCensor; 'silence duration' = [int]$game.defaultSilence; 'suspend duration' = [int]$game.defaultSuspend }
    )

    $root = [ordered]@{}
    Set-Bbmeta $root (Get-Bbmeta $existing)
    $root['net server config']  = @( $netObj )
    $root['game server config'] = @( $gameObj )

    Write-JsonFile -Path $Path -Object $root
}

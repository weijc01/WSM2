# ============================================================
#  WSM2 - GameData.ps1
#  Detectie van Steam-bibliotheken en uitlezen van speldata
#  voor de dropdowns (levels, weer, AI-sets, game modes).
# ============================================================

function Get-SteamRootCandidates {
    $c = @()
    $c += (Join-Path ${env:ProgramFiles(x86)} 'Steam')
    $c += (Join-Path $env:ProgramFiles 'Steam')
    # Uit het register
    try {
        $reg = Get-ItemProperty -Path 'HKCU:\Software\Valve\Steam' -ErrorAction SilentlyContinue
        if ($reg.SteamPath) { $c += $reg.SteamPath }
        $reg2 = Get-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam' -ErrorAction SilentlyContinue
        if ($reg2.InstallPath) { $c += $reg2.InstallPath }
    } catch { }
    return ($c | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -Unique)
}

function Get-SteamLibraries {
    $libs = @()
    foreach ($root in Get-SteamRootCandidates) {
        $libs += (Join-Path $root 'steamapps\common')
        $vdf = Join-Path $root 'steamapps\libraryfolders.vdf'
        if (Test-Path -LiteralPath $vdf) {
            try {
                $content = Get-Content -LiteralPath $vdf -Raw
                foreach ($m in [regex]::Matches($content, '"path"\s*"([^"]+)"')) {
                    $p = $m.Groups[1].Value -replace '\\\\', '\'
                    $libs += (Join-Path $p 'steamapps\common')
                }
            } catch { }
        }
    }
    return ($libs | Where-Object { $_ } | Select-Object -Unique)
}

function Find-WF2ServerInstall {
    foreach ($lib in Get-SteamLibraries) {
        $p = Join-Path $lib 'Wreckfest 2 Dedicated Server'
        if (Test-Path -LiteralPath (Join-Path $p 'Wreckfest2.exe')) { return $p }
    }
    # Vaste standaardlocatie als laatste redmiddel
    $def = 'C:\Program Files (x86)\Steam\steamapps\common\Wreckfest 2 Dedicated Server'
    if (Test-Path -LiteralPath (Join-Path $def 'Wreckfest2.exe')) { return $def }
    return $null
}

function Find-SteamExe {
    foreach ($root in Get-SteamRootCandidates) {
        $exe = Join-Path $root 'steam.exe'
        if (Test-Path -LiteralPath $exe) { return $exe }
    }
    return $null
}

function Get-WF2GameData {
    param([string]$InstallPath)

    $data = [ordered]@{
        Levels        = @()
        Weather       = @()
        AiSets        = @()
        GameModes     = @('bangerrace', 'waypointrace', 'suiciderace', 'demolitionderby')
        DamageIds     = @('', 'normal', 'realistic', 'wrecker')
        StartOrders   = @('random', 'points', 'points reversed', 'last race reversed')
        Collecting    = @('Collecting Sequential', 'Collecting Random')
        CarTypes      = @()
        CupLoops      = @()
    }

    if (-not $InstallPath -or -not (Test-Path -LiteralPath $InstallPath)) { return $data }

    # Levels (uit .evse bestandsnamen)
    $eventDir = Join-Path $InstallPath 'data\property\event'
    if (Test-Path -LiteralPath $eventDir) {
        $lvl = @()
        Get-ChildItem -LiteralPath $eventDir -Recurse -Filter *.evse -ErrorAction SilentlyContinue | ForEach-Object {
            $lvl += [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
        }
        $data.Levels = ($lvl | Sort-Object -Unique)
    }

    # Weer (relatief pad)
    $weatherDir = Join-Path $InstallPath 'data\property\weather'
    if (Test-Path -LiteralPath $weatherDir) {
        $w = @()
        Get-ChildItem -LiteralPath $weatherDir -Filter *.weat -ErrorAction SilentlyContinue | ForEach-Object {
            $w += ('data/property/weather/' + $_.Name)
        }
        $data.Weather = ($w | Sort-Object -Unique)
    }

    # AI-sets (relatief pad)
    $careerDir = Join-Path $InstallPath 'data\property\career'
    if (Test-Path -LiteralPath $careerDir) {
        $a = @()
        $rootLen = $InstallPath.Length
        Get-ChildItem -LiteralPath $careerDir -Recurse -Filter *.aist -ErrorAction SilentlyContinue | ForEach-Object {
            $rel = $_.FullName.Substring($rootLen).TrimStart('\') -replace '\\', '/'
            $a += $rel
        }
        # Bekende virtuele paden uit de save-config
        $a += 'runtime/career/ai-class-all.aist'
        $data.AiSets = ($a | Sort-Object -Unique)
    }

    # Car types (vehicle mappen)
    $vehDir = Join-Path $InstallPath 'data\vehicle'
    if (Test-Path -LiteralPath $vehDir) {
        $ct = @()
        Get-ChildItem -LiteralPath $vehDir -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            $ct += $_.Name
        }
        $data.CarTypes = ($ct | Sort-Object -Unique)
    }

    # Cup event loops (relatief pad)
    $cupDir = Join-Path $InstallPath 'data\property\settings\cup'
    if (Test-Path -LiteralPath $cupDir) {
        $cl = @()
        Get-ChildItem -LiteralPath $cupDir -Filter *.becl -ErrorAction SilentlyContinue | ForEach-Object {
            $cl += ('data/property/settings/cup/' + $_.Name)
        }
        $data.CupLoops = ($cl | Sort-Object -Unique)
    }

    return $data
}

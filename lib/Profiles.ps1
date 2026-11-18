# ============================================================
#  WSM2 - Profiles.ps1
#  App-instellingen en serverprofielen (WSM2.settings.json).
# ============================================================

function Get-SettingsPath {
    $root = $script:AppRoot
    if ([string]::IsNullOrWhiteSpace($root)) { $root = (Split-Path -Parent $PSScriptRoot) }
    return (Join-Path $root 'WSM2.settings.json')
}

function New-DefaultSettings {
    $saveDir = 'C:\WreckFest2server'
    return [ordered]@{
        ServerInstallPath = (Find-WF2ServerInstall)
        SteamExe          = (Find-SteamExe)
        LastProfile       = 'Standaard'
        FollowLog         = $true
        Profiles          = @(
            [ordered]@{ Name = 'Standaard'; SaveDir = $saveDir; Mode = 'community' }
        )
    }
}

function Load-Settings {
    $path = Get-SettingsPath
    $s = $null
    if (Test-Path -LiteralPath $path) {
        try { $s = Read-JsonFile -Path $path } catch { $s = $null }
    }
    if ($null -eq $s) { return (New-DefaultSettings) }

    # Ontbrekende velden aanvullen
    if ($null -eq (Get-FirstItem (Get-Prop $s 'Profiles'))) {
        Set-Prop $s 'Profiles' @( [ordered]@{ Name = 'Standaard'; SaveDir = 'C:\WreckFest2server'; Mode = 'community' } )
    }
    if (-not (Get-Prop $s 'LastProfile')) { Set-Prop $s 'LastProfile' 'Standaard' }
    if ($null -eq (Get-Prop $s 'ServerInstallPath')) { Set-Prop $s 'ServerInstallPath' (Find-WF2ServerInstall) }
    if ($null -eq (Get-Prop $s 'SteamExe')) { Set-Prop $s 'SteamExe' (Find-SteamExe) }
    if ($null -eq (Get-Prop $s 'FollowLog')) { Set-Prop $s 'FollowLog' $true }
    return $s
}

function Save-Settings {
    param([Parameter(Mandatory)]$Settings)
    Write-JsonFile -Path (Get-SettingsPath) -Object $Settings -NoBackup
}

function Get-ProfileByName {
    param($Settings, [string]$Name)
    foreach ($p in (Get-Prop $Settings 'Profiles')) {
        if ((Get-Prop $p 'Name') -eq $Name) { return $p }
    }
    return $null
}

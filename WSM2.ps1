# ============================================================
#  WSM2 - Wreckfest 2 Server Manager
#  Hoofdvenster (WinForms). Nederlandse interface.
# ============================================================
#requires -version 5.1

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$script:AppRoot = $PSScriptRoot
. (Join-Path $script:AppRoot 'lib\Config.ps1')
. (Join-Path $script:AppRoot 'lib\GameData.ps1')
. (Join-Path $script:AppRoot 'lib\Profiles.ps1')
. (Join-Path $script:AppRoot 'lib\Server.ps1')

# --- Globale status -----------------------------------------
$script:Settings      = Load-Settings
$script:GameData      = $null
$script:Events        = @()
$script:EventLoopBbmeta = $null
$script:Cups          = @()
$script:CupBbmeta     = $null
$script:PrivBbmeta    = $null
$script:CurEventIndex = -1
$script:CurCupIndex   = -1
$script:UI            = @{}

# --- Kleine helpers -----------------------------------------
function Show-Err { param($m) [System.Windows.Forms.MessageBox]::Show($m, 'WSM2 - Fout', 'OK', 'Error') | Out-Null }
function Show-Info { param($m) [System.Windows.Forms.MessageBox]::Show($m, 'WSM2', 'OK', 'Information') | Out-Null }

function Get-CurrentProfile {
    $name = Get-Prop $script:Settings 'LastProfile'
    $p = Get-ProfileByName $script:Settings $name
    if ($null -eq $p) { $list = @(Get-Prop $script:Settings 'Profiles'); if ($list.Count -gt 0) { $p = $list[0] } }
    return $p
}

function Get-CurrentSaveDir { return [string](Get-Prop (Get-CurrentProfile) 'SaveDir') }
function Get-CurrentMode { return [string](Get-Prop (Get-CurrentProfile) 'Mode') }

function Test-ServerStoppedOrWarn {
    $install = [string](Get-Prop $script:Settings 'ServerInstallPath')
    if ($install -and (Test-ServerRunning -InstallPath $install)) {
        Show-Err "De server draait nog. Stop de server eerst voordat je de configuratie opslaat (de server overschrijft de bestanden bij het afsluiten)."
        return $false
    }
    return $true
}

# --- WinForms fabrieksfuncties ------------------------------
function New-Label { param($parent,$text,$x,$y,$w=150,$h=20,[switch]$PassThru)
    $c = New-Object System.Windows.Forms.Label
    $c.Text = $text; $c.Location = New-Object System.Drawing.Point($x,$y)
    $c.AutoSize = $true
    $c.BackColor = [System.Drawing.Color]::Transparent
    $parent.Controls.Add($c)
    if ($PassThru) { return $c } }

function New-Text { param($parent,$x,$y,$w,$h=23,$text='')
    $c = New-Object System.Windows.Forms.TextBox
    $c.Location = New-Object System.Drawing.Point($x,$y)
    $c.Size = New-Object System.Drawing.Size($w,$h); $c.Text = $text
    $parent.Controls.Add($c); return $c }

function New-Num { param($parent,$x,$y,$w,$min,$max,$val)
    $c = New-Object System.Windows.Forms.NumericUpDown
    $c.Location = New-Object System.Drawing.Point($x,$y)
    $c.Size = New-Object System.Drawing.Size($w,23)
    $c.Minimum = $min; $c.Maximum = $max; $c.Value = $val
    $parent.Controls.Add($c); return $c }

function New-Check { param($parent,$text,$x,$y,$w=240,$h=22,$checked=$false)
    $c = New-Object System.Windows.Forms.CheckBox
    $c.Text = $text; $c.Location = New-Object System.Drawing.Point($x,$y)
    $c.Size = New-Object System.Drawing.Size($w,$h); $c.Checked = $checked
    $parent.Controls.Add($c); return $c }

function New-Combo { param($parent,$x,$y,$w,$editable=$true)
    $c = New-Object System.Windows.Forms.ComboBox
    $c.Location = New-Object System.Drawing.Point($x,$y)
    $c.Size = New-Object System.Drawing.Size($w,23)
    if ($editable) { $c.DropDownStyle = 'DropDown' } else { $c.DropDownStyle = 'DropDownList' }
    $parent.Controls.Add($c); return $c }

function New-Btn { param($parent,$text,$x,$y,$w,$h=26)
    $c = New-Object System.Windows.Forms.Button
    $c.Text = $text; $c.Location = New-Object System.Drawing.Point($x,$y)
    $c.Size = New-Object System.Drawing.Size($w,$h)
    $parent.Controls.Add($c); return $c }

function New-Group { param($parent,$text,$x,$y,$w,$h)
    $c = New-Object System.Windows.Forms.GroupBox
    $c.Text = $text; $c.Location = New-Object System.Drawing.Point($x,$y)
    $c.Size = New-Object System.Drawing.Size($w,$h)
    $parent.Controls.Add($c); return $c }

function New-ListBox { param($parent,$x,$y,$w,$h)
    $c = New-Object System.Windows.Forms.ListBox
    $c.Location = New-Object System.Drawing.Point($x,$y)
    $c.Size = New-Object System.Drawing.Size($w,$h)
    $parent.Controls.Add($c); return $c }

function New-Grid { param($parent,$x,$y,$w,$h,$columns)
    $c = New-Object System.Windows.Forms.DataGridView
    $c.Location = New-Object System.Drawing.Point($x,$y)
    $c.Size = New-Object System.Drawing.Size($w,$h)
    $c.AllowUserToAddRows = $false
    $c.AllowUserToDeleteRows = $false
    $c.RowHeadersVisible = $false
    $c.AutoSizeColumnsMode = 'Fill'
    $c.SelectionMode = 'FullRowSelect'
    $c.MultiSelect = $false
    foreach ($col in $columns) {
        $gc = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
        $gc.HeaderText = $col; $gc.Name = $col
        [void]$c.Columns.Add($gc)
    }
    $parent.Controls.Add($c); return $c }

function Parse-JsonTextbox {
    param($Text, $Default)
    if ([string]::IsNullOrWhiteSpace($Text)) { return $Default }
    try { return ($Text | ConvertFrom-Json) } catch { throw "Ongeldige JSON: $($_.Exception.Message)" }
}

function Format-Json { param($Obj) if ($null -eq $Obj) { return '' } return ($Obj | ConvertTo-Json -Depth 100) }

function Insert-At {
    param($Array, [int]$Index, $Item)
    $list = New-Object System.Collections.ArrayList
    $arr = @($Array)
    for ($i = 0; $i -lt $arr.Count; $i++) {
        if ($i -eq $Index) { [void]$list.Add($Item) }
        [void]$list.Add($arr[$i])
    }
    if ($Index -ge $arr.Count) { [void]$list.Add($Item) }
    return @($list.ToArray())
}

function Remove-At {
    param($Array, [int]$Index)
    $arr = @($Array)
    $list = @()
    for ($i = 0; $i -lt $arr.Count; $i++) { if ($i -ne $Index) { $list += $arr[$i] } }
    return @($list)
}

function Swap-At {
    param($Array, [int]$A, [int]$B)
    $arr = @($Array)
    $tmp = $arr[$A]; $arr[$A] = $arr[$B]; $arr[$B] = $tmp
    return @($arr)
}

# ============================================================
#  Hoofdformulier
# ============================================================
$form = New-Object System.Windows.Forms.Form
$form.Text = 'WSM2 - Wreckfest 2 Server Manager'
$form.Size = New-Object System.Drawing.Size(1030, 780)
$form.StartPosition = 'CenterScreen'
$form.MinimumSize = New-Object System.Drawing.Size(1000, 720)

$tabs = New-Object System.Windows.Forms.TabControl
$tabs.Location = New-Object System.Drawing.Point(8, 8)
$tabs.Size = New-Object System.Drawing.Size(996, 690)
$form.Controls.Add($tabs)

$tabServer = New-Object System.Windows.Forms.TabPage; $tabServer.Text = 'Server'
$tabEvents = New-Object System.Windows.Forms.TabPage; $tabEvents.Text = 'Evenementen'
$tabCups   = New-Object System.Windows.Forms.TabPage; $tabCups.Text   = 'Cups'
$tabPriv   = New-Object System.Windows.Forms.TabPage; $tabPriv.Text   = 'Rollen & Bans'
$tabTele   = New-Object System.Windows.Forms.TabPage; $tabTele.Text   = 'Telemetrie'
$tabStart  = New-Object System.Windows.Forms.TabPage; $tabStart.Text  = 'Starten'
$tabSet    = New-Object System.Windows.Forms.TabPage; $tabSet.Text    = 'Instellingen'
$tabs.TabPages.AddRange(@($tabServer,$tabEvents,$tabCups,$tabPriv,$tabTele,$tabStart,$tabSet))

# Statusbalk
$status = New-Object System.Windows.Forms.StatusStrip
$script:UI['statusLabel'] = New-Object System.Windows.Forms.ToolStripStatusLabel
$script:UI['statusLabel'].Text = 'Gereed'
$status.Items.Add($script:UI['statusLabel']) | Out-Null
$form.Controls.Add($status)

# ============================================================
#  TAB: Server
# ============================================================
$gNet = New-Group $tabServer 'Netwerk (server_config.scnf)' 10 10 470 235
New-Label $gNet 'Naam:' 15 28
$script:UI['txtName'] = New-Text $gNet 130 25 320
New-Label $gNet 'Beschrijving:' 15 58
$script:UI['txtDesc'] = New-Text $gNet 130 55 320 60
$script:UI['txtDesc'].Multiline = $true
New-Label $gNet 'Wachtwoord:' 15 125
$script:UI['txtPass'] = New-Text $gNet 130 122 320
New-Label $gNet 'Logbestand:' 15 155
$script:UI['txtLog'] = New-Text $gNet 130 152 320
New-Label $gNet 'Game poort:' 15 185
$script:UI['numPort'] = New-Num $gNet 130 182 100 1 65535 30100

$gSpel = New-Group $tabServer 'Spel' 490 10 480 235
New-Label $gSpel 'Event loop:' 15 28
$script:UI['cmbEventLoop'] = New-Combo $gSpel 130 25 320 $true
New-Label $gSpel 'Cup list:' 15 58
$script:UI['txtCupList'] = New-Text $gSpel 130 55 320
New-Label $gSpel 'Countdown (ms):' 15 88
$script:UI['numCountdown'] = New-Num $gSpel 130 85 130 30000 500000 100000
New-Label $gSpel 'Voting (ms):' 15 118
$script:UI['numVoting'] = New-Num $gSpel 130 115 130 10000 30000 20000
$lblHint = New-Label $gSpel 'Countdown: 30000-500000 ms  |  Voting: 10000-30000 ms' 15 150 440 40 -PassThru
$lblHint.ForeColor = [System.Drawing.Color]::DimGray

$gFlags = New-Group $tabServer 'Servervlaggen' 10 250 470 175
$script:UI['chkLeader']     = New-Check $gFlags 'leader enabled (race-director)' 15 25 400
$script:UI['chkIdle']       = New-Check $gFlags 'idle kicker disabled' 15 48 400
$script:UI['chkRaceTimer']  = New-Check $gFlags 'race timer disabled' 15 71 400
$script:UI['chkEventLoop']  = New-Check $gFlags 'event loop disabled' 15 94 400
$script:UI['chkLiveries']   = New-Check $gFlags 'hide default user liveries' 15 117 400
$script:UI['chkNoAdmin']    = New-Check $gFlags 'disable auto-admin' 15 140 400

$gAutoBan = New-Group $tabServer 'Auto-ban meldingen' 490 250 480 110
New-Label $gAutoBan 'Censor:' 15 28
$script:UI['numCensorRep'] = New-Num $gAutoBan 120 25 80 0 1000 4
New-Label $gAutoBan 'Silence:' 220 28
$script:UI['numSilenceRep'] = New-Num $gAutoBan 310 25 80 0 1000 8
New-Label $gAutoBan 'Suspend:' 15 58
$script:UI['numSuspendRep'] = New-Num $gAutoBan 120 55 80 0 1000 12
New-Label $gAutoBan '0 = uitgeschakeld' 220 58 200

$gBanDur = New-Group $tabServer 'Ban-duren (minuten)' 10 365 960 200
New-Label $gBanDur 'Type' 15 30 150
New-Label $gBanDur 'Censor' 200 30 90
New-Label $gBanDur 'Silence' 330 30 90
New-Label $gBanDur 'Suspend' 460 30 90
New-Label $gBanDur 'Server bans:' 15 65
$script:UI['numSrvCensor']  = New-Num $gBanDur 200 62 90 1 525600 1440
$script:UI['numSrvSilence'] = New-Num $gBanDur 330 62 90 1 525600 1440
$script:UI['numSrvSuspend'] = New-Num $gBanDur 460 62 110 1 525600 525600
New-Label $gBanDur 'Admin bans:' 15 100
$script:UI['numAdmCensor']  = New-Num $gBanDur 200 97 90 1 525600 1440
$script:UI['numAdmSilence'] = New-Num $gBanDur 330 97 90 1 525600 1440
$script:UI['numAdmSuspend'] = New-Num $gBanDur 460 97 110 1 525600 525600
New-Label $gBanDur 'Default bans:' 15 135
$script:UI['numDefCensor']  = New-Num $gBanDur 200 132 90 1 525600 1440
$script:UI['numDefSilence'] = New-Num $gBanDur 330 132 90 1 525600 1440
$script:UI['numDefSuspend'] = New-Num $gBanDur 460 132 110 1 525600 525600

$btnSaveServer = New-Btn $tabServer 'Serverconfig opslaan' 10 580 200
$btnReloadServer = New-Btn $tabServer 'Herladen' 220 580 120

# ============================================================
#  TAB: Evenementen (event loop .becl)
# ============================================================
New-Label $tabEvents 'Event loop-bestand:' 10 15
$script:UI['cmbLoopFile'] = New-Combo $tabEvents 150 12 260 $true
$script:UI['cmbLoopFile'].DropDownStyle = 'DropDownList'
$btnLoopLoad = New-Btn $tabEvents 'Laden' 420 11 80
$btnLoopNew  = New-Btn $tabEvents 'Nieuw' 505 11 80
$btnLoopSave = New-Btn $tabEvents 'Opslaan als' 590 11 110

$script:UI['lstEvents'] = New-ListBox $tabEvents 10 50 300 500
$btnEvNew  = New-Btn $tabEvents 'Nieuw' 10 558 70 26
$btnEvDup  = New-Btn $tabEvents 'Dupliceer' 85 558 80 26
$btnEvDel  = New-Btn $tabEvents 'Verwijder' 170 558 80 26
$btnEvUp   = New-Btn $tabEvents 'Omhoog' 255 558 55 26
$btnEvDown = New-Btn $tabEvents 'Omlaag' 315 558 55 26

$gLvl = New-Group $tabEvents 'Level' 325 45 650 150
New-Label $gLvl 'Level id:' 15 28
$script:UI['cmbLevel'] = New-Combo $gLvl 150 25 300 $true
New-Label $gLvl 'Weer:' 15 58
$script:UI['cmbWeather'] = New-Combo $gLvl 150 55 300 $true
New-Label $gLvl 'AI-set:' 15 88
$script:UI['cmbAiSet'] = New-Combo $gLvl 150 85 300 $true
New-Label $gLvl 'Game mode:' 15 118
$script:UI['cmbMode'] = New-Combo $gLvl 150 115 300 $true

$gRules = New-Group $tabEvents 'Regels' 325 200 650 235
New-Label $gRules 'Rondes:' 15 28
$script:UI['numLaps'] = New-Num $gRules 150 25 80 0 100 3
New-Label $gRules 'Tijdslimiet:' 260 28
$script:UI['numTimeLimit'] = New-Num $gRules 380 25 80 0 1000 5
New-Label $gRules 'Teams:' 15 58
$script:UI['numTeams'] = New-Num $gRules 150 55 80 1 10 1
New-Label $gRules 'Max deelnemers:' 260 58
$script:UI['numMaxPart'] = New-Num $gRules 380 55 80 1 24 24
New-Label $gRules 'Vlaggen:' 15 88
$script:UI['txtRuleFlags'] = New-Text $gRules 150 85 300
New-Label $gRules 'Collecting:' 15 118
$script:UI['cmbCollecting'] = New-Combo $gRules 150 115 300 $true
New-Label $gRules 'Car reset (s):' 15 148
$script:UI['numCarReset'] = New-Num $gRules 150 145 80 0 60 2
New-Label $gRules 'Team split (%):' 260 148
$script:UI['numTeamSplit'] = New-Num $gRules 380 145 80 0 100 0
New-Label $gRules 'Schade-id:' 15 178
$script:UI['cmbDamage'] = New-Combo $gRules 150 175 200 $true
New-Label $gRules 'Bots:' 380 178
$script:UI['numBots'] = New-Num $gRules 450 175 80 0 24 8

$gCarResEv = New-Group $tabEvents 'Car restrictions (JSON-array)' 325 440 650 145
$script:UI['txtEvCarRes'] = New-Text $gCarResEv 10 22 630 115
$script:UI['txtEvCarRes'].Multiline = $true
$script:UI['txtEvCarRes'].ScrollBars = 'Vertical'

# ============================================================
#  TAB: Cups
# ============================================================
$script:UI['lstCups'] = New-ListBox $tabCups 10 15 280 570
$btnCupNew = New-Btn $tabCups 'Nieuw' 10 592 65 26
$btnCupDup = New-Btn $tabCups 'Dupliceer' 80 592 75 26
$btnCupDel = New-Btn $tabCups 'Verwijder' 160 592 75 26
$btnCupUp  = New-Btn $tabCups 'Omhoog' 240 592 45 26
$btnCupDown = New-Btn $tabCups 'Omlaag' 290 592 45 26

$gCupInfo = New-Group $tabCups 'Cup' 300 10 675 180
New-Label $gCupInfo 'Naam:' 15 28
$script:UI['txtCupName'] = New-Text $gCupInfo 150 25 500
New-Label $gCupInfo 'Beschrijving:' 15 58
$script:UI['txtCupDesc'] = New-Text $gCupInfo 150 55 500 45
$script:UI['txtCupDesc'].Multiline = $true
New-Label $gCupInfo 'Event loop:' 15 108
$script:UI['cmbCupLoop'] = New-Combo $gCupInfo 150 105 500 $true
New-Label $gCupInfo 'Icon:' 15 138
$script:UI['txtCupIcon'] = New-Text $gCupInfo 150 135 500

$gCupRace = New-Group $tabCups 'Race-instellingen' 300 195 675 180
New-Label $gCupRace 'Point distribution:' 15 28
$script:UI['txtPointDist'] = New-Text $gCupRace 170 25 480
New-Label $gCupRace 'Vlaggen:' 15 58
$script:UI['txtCupFlags'] = New-Text $gCupRace 170 55 480
New-Label $gCupRace 'Start order:' 15 88
$script:UI['cmbStartOrder'] = New-Combo $gCupRace 170 85 220 $true
New-Label $gCupRace 'Punten beste ronde:' 15 118
$script:UI['numBestLap'] = New-Num $gCupRace 170 115 80 0 1000 0
New-Label $gCupRace 'Punten hoogste score:' 270 118
$script:UI['numHighScore'] = New-Num $gCupRace 460 115 80 0 1000 0
New-Label $gCupRace 'Laatste race multiplier:' 15 148
$script:UI['numLastMult'] = New-Num $gCupRace 200 145 80 0 100 1

$gCupCarRes = New-Group $tabCups 'Car restrictions (JSON-array)' 300 380 675 205
$script:UI['txtCupCarRes'] = New-Text $gCupCarRes 10 22 655 175
$script:UI['txtCupCarRes'].Multiline = $true
$script:UI['txtCupCarRes'].ScrollBars = 'Vertical'

$btnSaveCups = New-Btn $tabCups 'Cups opslaan' 300 592 160

# ============================================================
#  TAB: Rollen & Bans
# ============================================================
$gRoles = New-Group $tabPriv 'Rollen (server_privilege.sprv)' 10 10 960 300
$script:UI['gridRoles'] = New-Grid $gRoles 10 22 940 230 @('Platform ID (SteamID64)', 'Rol (admin/mod)')
$btnRoleAdd = New-Btn $gRoles 'Rij toevoegen' 10 258 130
$btnRoleDel = New-Btn $gRoles 'Rij verwijderen' 150 258 130

$gBans = New-Group $tabPriv 'Bans (JSON-array)' 10 320 960 300
$script:UI['txtBans'] = New-Text $gBans 10 22 940 235
$script:UI['txtBans'].Multiline = $true
$script:UI['txtBans'].ScrollBars = 'Vertical'
$btnSavePriv = New-Btn $tabPriv 'Rollen & bans opslaan' 10 628 200

# ============================================================
#  TAB: Telemetrie
# ============================================================
$gUdp = New-Group $tabTele 'UDP (telemetry/config.json)' 10 10 470 200
$script:UI['chkUdpEnabled'] = New-Check $gUdp 'UDP ingeschakeld' 15 28 300
New-Label $gUdp 'IP-adres:' 15 60
$script:UI['txtUdpIp'] = New-Text $gUdp 130 57 300 23 '127.0.0.1'
New-Label $gUdp 'Poort:' 15 92
$script:UI['txtUdpPort'] = New-Text $gUdp 130 89 150 23 '23123'

$gLogging = New-Group $tabTele 'Logging' 490 10 480 200
New-Label $gLogging 'Formaat:' 15 30
$script:UI['cmbLogFormat'] = New-Combo $gLogging 130 27 200 $true

$gTeleSrv = New-Group $tabTele 'Server-telemetrie' 10 220 960 160
$script:UI['chkSrvEnabled'] = New-Check $gTeleSrv 'Server-telemetrie ingeschakeld' 15 30 400
$script:UI['chkAutoMainCar'] = New-Check $gTeleSrv 'automaticMainCar' 15 60 400
$btnSaveTele = New-Btn $tabTele 'Telemetrie opslaan' 10 400 180

# ============================================================
#  TAB: Starten
# ============================================================
$gStart = New-Group $tabStart 'Server bedienen' 10 10 960 250
New-Label $gStart 'Profiel:' 15 30
$script:UI['cmbProfile'] = New-Combo $gStart 130 27 260 $false
New-Label $gStart 'Save-dir:' 15 62
$script:UI['txtSaveDir'] = New-Text $gStart 130 59 600
$btnSaveDir = New-Btn $gStart 'Map openen' 740 58 130
New-Label $gStart 'Modus:' 15 94
$script:UI['cmbMode'] = New-Combo $gStart 130 91 260 $false
$script:UI['cmbMode'].Items.AddRange(@('community (--server)', 'lokaal (--local-server)')) | Out-Null
$script:UI['cmbMode'].SelectedIndex = 0

$btnStart = New-Btn $gStart 'START server' 130 130 180 34
$btnStart.BackColor = [System.Drawing.Color]::FromArgb(198,239,206)
$btnStop = New-Btn $gStart 'STOP server' 320 130 180 34
$btnStop.BackColor = [System.Drawing.Color]::FromArgb(255,199,206)
$btnRefresh = New-Btn $gStart 'Status vernieuwen' 510 130 150 34
$script:UI['lblStatus'] = New-Label $gStart 'Status: onbekend' 130 180 700 30 -PassThru
$script:UI['lblStatus'].Font = New-Object System.Drawing.Font('Segoe UI',10,[System.Drawing.FontStyle]::Bold)

$gLogView = New-Group $tabStart 'Serverlog' 10 270 960 400
$script:UI['chkFollowLog'] = New-Check $gLogView 'Automatisch verversen' 15 25 200
$btnRefreshLog = New-Btn $gLogView 'Vernieuwen' 220 23 110
$btnOpenLog = New-Btn $gLogView 'Logbestand openen' 340 23 150
$script:UI['txtLogView'] = New-Text $gLogView 15 55 930 335
$script:UI['txtLogView'].Multiline = $true
$script:UI['txtLogView'].ReadOnly = $true
$script:UI['txtLogView'].ScrollBars = 'Both'
$script:UI['txtLogView'].WordWrap = $false
$script:UI['txtLogView'].Font = New-Object System.Drawing.Font('Consolas',9)

# ============================================================
#  TAB: Instellingen
# ============================================================
$gInstall = New-Group $tabSet 'Installatiepaden' 10 10 960 170
New-Label $gInstall 'Server-installatiemap:' 15 30
$script:UI['txtInstallPath'] = New-Text $gInstall 200 27 620
$btnBrowseInstall = New-Btn $gInstall 'Bladeren...' 830 26 110
New-Label $gInstall 'Steam.exe:' 15 65
$script:UI['txtSteamExe'] = New-Text $gInstall 200 62 620
$btnBrowseSteam = New-Btn $gInstall 'Bladeren...' 830 61 110
$btnDetect = New-Btn $gInstall 'Automatisch detecteren' 200 100 180
$btnSaveSettings = New-Btn $gInstall 'Instellingen opslaan' 390 100 180

$gProfiles = New-Group $tabSet 'Profielen (naam, save-dir, modus)' 10 190 960 380
$script:UI['gridProfiles'] = New-Grid $gProfiles 10 22 940 300 @('Naam', 'Save-dir', 'Modus (community/local)')
$btnProfAdd = New-Btn $gProfiles 'Rij toevoegen' 10 330 130
$btnProfDel = New-Btn $gProfiles 'Rij verwijderen' 150 330 130
$btnProfSave = New-Btn $gProfiles 'Profielen opslaan' 290 330 160
$lblProfHint = New-Label $gProfiles 'Na het opslaan de app herstarten of op "Profielen vernieuwen" klikken.' 470 335 480 -PassThru
$lblProfHint.ForeColor = [System.Drawing.Color]::DimGray

# ============================================================
#  Data laden
# ============================================================
function Refresh-SaveDirLists {
    $saveDir = Get-CurrentSaveDir
    $loops = @()
    if ($saveDir -and (Test-Path -LiteralPath $saveDir)) {
        $loops = @(Get-ChildItem -LiteralPath $saveDir -Filter *.becl -ErrorAction SilentlyContinue |
                   ForEach-Object { [System.IO.Path]::GetFileNameWithoutExtension($_.Name) } | Sort-Object -Unique)
    }
    $script:UI['cmbEventLoop'].Items.Clear()
    $script:UI['cmbLoopFile'].Items.Clear()
    foreach ($l in $loops) {
        [void]$script:UI['cmbEventLoop'].Items.Add($l)
        [void]$script:UI['cmbLoopFile'].Items.Add($l)
    }
}

function Refresh-GameDataLists {
    $install = [string](Get-Prop $script:Settings 'ServerInstallPath')
    $script:GameData = Get-WF2GameData -InstallPath $install
    $gd = $script:GameData

    foreach ($pair in @(
        @('cmbLevel', $gd.Levels),
        @('cmbWeather', $gd.Weather),
        @('cmbAiSet', $gd.AiSets),
        @('cmbMode', $gd.GameModes),
        @('cmbCollecting', $gd.Collecting),
        @('cmbDamage', $gd.DamageIds),
        @('cmbStartOrder', $gd.StartOrders)
    )) {
        $ctrl = $script:UI[$pair[0]]
        $ctrl.Items.Clear()
        foreach ($v in $pair[1]) { [void]$ctrl.Items.Add($v) }
    }

    $script:UI['cmbCupLoop'].Items.Clear()
    foreach ($v in $gd.CupLoops) { [void]$script:UI['cmbCupLoop'].Items.Add($v) }

    $script:UI['cmbLogFormat'].Items.Clear()
    foreach ($v in @('none','json','csv')) { [void]$script:UI['cmbLogFormat'].Items.Add($v) }
}

# --- Server-tab laden/opslaan -------------------------------
function Load-ServerConfigToUI {
    $paths = Get-SaveDirPaths -SaveDir (Get-CurrentSaveDir)
    $obj = $null
    try { $obj = Read-JsonFile -Path $paths.ServerConfig } catch { $obj = $null }
    if ($null -eq $obj) { $obj = New-DefaultServerConfig }
    $v = Read-ServerConfigValues -Obj $obj
    $n = $v.net; $g = $v.game
    $script:UI['txtName'].Text = [string]$n.name
    $script:UI['txtDesc'].Text = [string]$n.description
    $script:UI['txtPass'].Text = [string]$n.password
    $script:UI['txtLog'].Text  = [string]$n.logFileName
    $script:UI['numPort'].Value = [decimal][int]$n.gamePort

    $script:UI['cmbEventLoop'].Text = [string]$g.eventLoopName
    $script:UI['txtCupList'].Text = [string]$g.cupList
    $script:UI['numCountdown'].Value = [decimal][int]$g.countdownTime
    $script:UI['numVoting'].Value = [decimal][int]$g.votingTime

    $flags = [string]$g.flags
    $has = { param($t) return ($flags -split '\s+' -contains $t) }
    $script:UI['chkLeader'].Checked    = & $has 'leader'
    $script:UI['chkIdle'].Checked      = ($flags -match 'idle kicker disabled')
    $script:UI['chkRaceTimer'].Checked = ($flags -match 'race timer disabled')
    $script:UI['chkEventLoop'].Checked = ($flags -match 'event loop disabled')
    $script:UI['chkLiveries'].Checked  = ($flags -match 'hide default user liveries')
    $script:UI['chkNoAdmin'].Checked   = ($flags -match 'disable auto-admin')

    $script:UI['numCensorRep'].Value  = [decimal][int]$g.censorReport
    $script:UI['numSilenceRep'].Value = [decimal][int]$g.silenceReport
    $script:UI['numSuspendRep'].Value = [decimal][int]$g.suspendReport
    $script:UI['numSrvCensor'].Value  = [decimal][int]$g.serverCensor
    $script:UI['numSrvSilence'].Value = [decimal][int]$g.serverSilence
    $script:UI['numSrvSuspend'].Value = [decimal][int]$g.serverSuspend
    $script:UI['numAdmCensor'].Value  = [decimal][int]$g.adminCensor
    $script:UI['numAdmSilence'].Value = [decimal][int]$g.adminSilence
    $script:UI['numAdmSuspend'].Value = [decimal][int]$g.adminSuspend
    $script:UI['numDefCensor'].Value  = [decimal][int]$g.defaultCensor
    $script:UI['numDefSilence'].Value = [decimal][int]$g.defaultSilence
    $script:UI['numDefSuspend'].Value = [decimal][int]$g.defaultSuspend
}

function Save-ServerConfigFromUI {
    if (-not (Test-ServerStoppedOrWarn)) { return }
    $flags = @()
    if ($script:UI['chkLeader'].Checked)    { $flags += 'leader enabled' }
    if ($script:UI['chkIdle'].Checked)      { $flags += 'idle kicker disabled' }
    if ($script:UI['chkRaceTimer'].Checked) { $flags += 'race timer disabled' }
    if ($script:UI['chkEventLoop'].Checked) { $flags += 'event loop disabled' }
    if ($script:UI['chkLiveries'].Checked)  { $flags += 'hide default user liveries' }
    if ($script:UI['chkNoAdmin'].Checked)   { $flags += 'disable auto-admin' }

    $vals = [ordered]@{
        net = @{
            name = $script:UI['txtName'].Text
            description = $script:UI['txtDesc'].Text
            password = $script:UI['txtPass'].Text
            logFileName = $script:UI['txtLog'].Text
            gamePort = [int]$script:UI['numPort'].Value
        }
        game = @{
            cupList = $script:UI['txtCupList'].Text
            eventLoopName = $script:UI['cmbEventLoop'].Text
            countdownTime = [int]$script:UI['numCountdown'].Value
            votingTime = [int]$script:UI['numVoting'].Value
            flags = ($flags -join ' ')
            censorReport = [int]$script:UI['numCensorRep'].Value
            silenceReport = [int]$script:UI['numSilenceRep'].Value
            suspendReport = [int]$script:UI['numSuspendRep'].Value
            serverCensor = [int]$script:UI['numSrvCensor'].Value
            serverSilence = [int]$script:UI['numSrvSilence'].Value
            serverSuspend = [int]$script:UI['numSrvSuspend'].Value
            adminCensor = [int]$script:UI['numAdmCensor'].Value
            adminSilence = [int]$script:UI['numAdmSilence'].Value
            adminSuspend = [int]$script:UI['numAdmSuspend'].Value
            defaultCensor = [int]$script:UI['numDefCensor'].Value
            defaultSilence = [int]$script:UI['numDefSilence'].Value
            defaultSuspend = [int]$script:UI['numDefSuspend'].Value
        }
    }
    $paths = Get-SaveDirPaths -SaveDir (Get-CurrentSaveDir)
    Save-ServerConfig -Path $paths.ServerConfig -Values $vals
    $script:UI['statusLabel'].Text = "Serverconfig opgeslagen: $($paths.ServerConfig)"
    Show-Info 'Serverconfiguratie opgeslagen.'
}

# --- Evenementen: model --------------------------------------
function ConvertTo-EventModel {
    param($raw)
    $ev = [ordered]@{}
    $bm = Get-Bbmeta $raw; if ($bm) { $ev['bbmeta'] = $bm }
    $lvlRaw = Get-FirstItem (Get-Prop $raw 'level')
    $lvl = [ordered]@{}
    if ($lvlRaw) { $bm2 = Get-Bbmeta $lvlRaw; if ($bm2) { $lvl['bbmeta'] = $bm2 } }
    foreach ($k in @('level id','weather path','weather intent path','ai set path','game mode id')) {
        $v = if ($lvlRaw) { Get-Prop $lvlRaw $k } else { $null }
        if ($null -eq $v) { $v = (New-EventLevel)[$k] }
        $lvl[$k] = $v
    }
    $rulesRaw = Get-FirstItem (Get-Prop $raw 'rules')
    $rules = [ordered]@{}
    if ($rulesRaw) { $bm3 = Get-Bbmeta $rulesRaw; if ($bm3) { $rules['bbmeta'] = $bm3 } }
    $defRules = New-EventRule
    foreach ($k in @('laps','time limit','number of teams','max number of participants','flags','collecting order','car reset delay (seconds)','team split (%)','vehicle damage id')) {
        $v = if ($rulesRaw) { Get-Prop $rulesRaw $k } else { $null }
        if ($null -eq $v) { $v = $defRules[$k] }
        $rules[$k] = $v
    }
    $ev['level'] = @($lvl)
    $ev['rules'] = @($rules)
    $cr = Get-Prop $raw 'car restriction'; if ($null -eq $cr) { $cr = @() }
    $ev['car restriction'] = @($cr)
    $bc = Get-Prop $raw 'bot count'; if ($null -eq $bc) { $bc = 0 }
    $ev['bot count'] = $bc
    return $ev
}

function Refresh-EventList {
    $script:UI['lstEvents'].Items.Clear()
    $i = 1
    foreach ($ev in $script:Events) {
        $lvl = $ev['level'][0]
        $script:UI['lstEvents'].Items.Add(("{0}. {1}  [{2}]" -f $i, $lvl['level id'], $lvl['game mode id'])) | Out-Null
        $i++
    }
}

function Load-EventIntoFields {
    param([int]$index)
    $script:CurEventIndex = $index
    if ($index -lt 0 -or $index -ge $script:Events.Count) { return }
    $ev = $script:Events[$index]
    $lvl = $ev['level'][0]; $r = $ev['rules'][0]
    $script:UI['cmbLevel'].Text = [string]$lvl['level id']
    $script:UI['cmbWeather'].Text = [string]$lvl['weather path']
    $script:UI['cmbAiSet'].Text = [string]$lvl['ai set path']
    $script:UI['cmbMode'].Text = [string]$lvl['game mode id']
    $script:UI['numLaps'].Value = [decimal][int]$r['laps']
    $script:UI['numTimeLimit'].Value = [decimal][int]$r['time limit']
    $script:UI['numTeams'].Value = [decimal][int]$r['number of teams']
    $script:UI['numMaxPart'].Value = [decimal][int]$r['max number of participants']
    $script:UI['txtRuleFlags'].Text = [string]$r['flags']
    $script:UI['cmbCollecting'].Text = [string]$r['collecting order']
    $script:UI['numCarReset'].Value = [decimal][int]$r['car reset delay (seconds)']
    $script:UI['numTeamSplit'].Value = [decimal][int]$r['team split (%)']
    $script:UI['cmbDamage'].Text = [string]$r['vehicle damage id']
    $script:UI['numBots'].Value = [decimal][int]$ev['bot count']
    $script:UI['txtEvCarRes'].Text = Format-Json $ev['car restriction']
}

function Save-FieldsIntoEvent {
    param([int]$index)
    if ($index -lt 0 -or $index -ge $script:Events.Count) { return }
    $ev = $script:Events[$index]
    $lvl = $ev['level'][0]; $r = $ev['rules'][0]
    $lvl['level id'] = $script:UI['cmbLevel'].Text
    $lvl['weather path'] = $script:UI['cmbWeather'].Text
    $lvl['ai set path'] = $script:UI['cmbAiSet'].Text
    $lvl['game mode id'] = $script:UI['cmbMode'].Text
    $r['laps'] = [int]$script:UI['numLaps'].Value
    $r['time limit'] = [int]$script:UI['numTimeLimit'].Value
    $r['number of teams'] = [int]$script:UI['numTeams'].Value
    $r['max number of participants'] = [int]$script:UI['numMaxPart'].Value
    $r['flags'] = $script:UI['txtRuleFlags'].Text
    $r['collecting order'] = $script:UI['cmbCollecting'].Text
    $r['car reset delay (seconds)'] = [int]$script:UI['numCarReset'].Value
    $r['team split (%)'] = [int]$script:UI['numTeamSplit'].Value
    $r['vehicle damage id'] = $script:UI['cmbDamage'].Text
    $ev['bot count'] = [int]$script:UI['numBots'].Value
    try { $ev['car restriction'] = @(Parse-JsonTextbox $script:UI['txtEvCarRes'].Text @()) }
    catch { throw $_ }
}

function Load-EventLoopFromFile {
    param([string]$Name)
    $saveDir = Get-CurrentSaveDir
    $path = Join-Path $saveDir "$Name.becl"
    $obj = $null
    try { $obj = Read-JsonFile -Path $path } catch { $obj = $null }
    if ($null -eq $obj) { $obj = New-DefaultEventLoop }
    $script:EventLoopBbmeta = Get-Bbmeta $obj
    $script:Events = @()
    $evs = Get-Prop $obj 'events'
    if ($evs) { foreach ($e in $evs) { $script:Events += (ConvertTo-EventModel $e) } }
    if ($script:Events.Count -eq 0) { $script:Events = @( (New-Event) ) }
    Select-EventItem 0
}

function Save-EventLoopToFile {
    param([string]$Name)
    if (-not (Test-ServerStoppedOrWarn)) { return }
    # Huidige velden wegschrijven
    if ($script:CurEventIndex -ge 0) { Save-FieldsIntoEvent $script:CurEventIndex }
    $eventsOut = @()
    foreach ($ev in $script:Events) {
        $lvl = $ev['level'][0]; $r = $ev['rules'][0]
        $lvlOut = [ordered]@{}
        if ($lvl.Contains('bbmeta')) { $lvlOut['bbmeta'] = $lvl['bbmeta'] }
        foreach ($k in @('level id','weather path','weather intent path','ai set path','game mode id')) { $lvlOut[$k] = $lvl[$k] }
        $rOut = [ordered]@{}
        if ($r.Contains('bbmeta')) { $rOut['bbmeta'] = $r['bbmeta'] }
        foreach ($k in @('laps','time limit','number of teams','max number of participants','flags','collecting order','car reset delay (seconds)','team split (%)','vehicle damage id')) { $rOut[$k] = $r[$k] }
        $evOut = [ordered]@{}
        if ($ev.Contains('bbmeta')) { $evOut['bbmeta'] = $ev['bbmeta'] }
        $evOut['level'] = @($lvlOut)
        $evOut['rules'] = @($rOut)
        $evOut['car restriction'] = @($ev['car restriction'])
        $evOut['bot count'] = $ev['bot count']
        $eventsOut += $evOut
    }
    $root = [ordered]@{}
    if ($script:EventLoopBbmeta) { $root['bbmeta'] = $script:EventLoopBbmeta }
    $root['events'] = $eventsOut
    $path = Join-Path (Get-CurrentSaveDir) "$Name.becl"
    Write-JsonFile -Path $path -Object $root
    Refresh-SaveDirLists
    $script:UI['statusLabel'].Text = "Event loop opgeslagen: $path"
    Show-Info "Event loop '$Name' opgeslagen."
}

# --- Cups: model ---------------------------------------------
function ConvertTo-CupModel {
    param($raw)
    $cup = [ordered]@{}
    $bm = Get-Bbmeta $raw; if ($bm) { $cup['bbmeta'] = $bm }
    $rsRaw = Get-FirstItem (Get-Prop $raw 'race settings')
    $rs = [ordered]@{}
    if ($rsRaw) { $bm2 = Get-Bbmeta $rsRaw; if ($bm2) { $rs['bbmeta'] = $bm2 } }
    $defRs = New-CupRaceSettings
    foreach ($k in @('point distribution','flags','start order','points for best lap time','points for highest score','last race multiplier')) {
        $v = if ($rsRaw) { Get-Prop $rsRaw $k } else { $null }
        if ($null -eq $v) { $v = $defRs[$k] }
        $rs[$k] = $v
    }
    $cup['race settings'] = @($rs)
    $cup['event loop'] = [string](Get-Prop $raw 'event loop')
    $cup['cup name'] = [string](Get-Prop $raw 'cup name')
    $cup['cup description'] = [string](Get-Prop $raw 'cup description')
    $cup['icon'] = [string](Get-Prop $raw 'icon')
    $cr = Get-Prop $raw 'car restriction'; if ($null -eq $cr) { $cr = @() }
    $cup['car restriction'] = @($cr)
    return $cup
}

function Refresh-CupList {
    $script:UI['lstCups'].Items.Clear()
    $i = 1
    foreach ($c in $script:Cups) {
        $script:UI['lstCups'].Items.Add(("{0}. {1}" -f $i, $c['cup name'])) | Out-Null
        $i++
    }
}

function Load-CupIntoFields {
    param([int]$index)
    $script:CurCupIndex = $index
    if ($index -lt 0 -or $index -ge $script:Cups.Count) { return }
    $c = $script:Cups[$index]
    $rs = $c['race settings'][0]
    $script:UI['txtCupName'].Text = [string]$c['cup name']
    $script:UI['txtCupDesc'].Text = [string]$c['cup description']
    $script:UI['cmbCupLoop'].Text = [string]$c['event loop']
    $script:UI['txtCupIcon'].Text = [string]$c['icon']
    $script:UI['txtPointDist'].Text = [string]$rs['point distribution']
    $script:UI['txtCupFlags'].Text = [string]$rs['flags']
    $script:UI['cmbStartOrder'].Text = [string]$rs['start order']
    $script:UI['numBestLap'].Value = [decimal][int]$rs['points for best lap time']
    $script:UI['numHighScore'].Value = [decimal][int]$rs['points for highest score']
    $script:UI['numLastMult'].Value = [decimal][int]$rs['last race multiplier']
    $script:UI['txtCupCarRes'].Text = Format-Json $c['car restriction']
}

function Save-FieldsIntoCup {
    param([int]$index)
    if ($index -lt 0 -or $index -ge $script:Cups.Count) { return }
    $c = $script:Cups[$index]
    $rs = $c['race settings'][0]
    $c['cup name'] = $script:UI['txtCupName'].Text
    $c['cup description'] = $script:UI['txtCupDesc'].Text
    $c['event loop'] = $script:UI['cmbCupLoop'].Text
    $c['icon'] = $script:UI['txtCupIcon'].Text
    $rs['point distribution'] = $script:UI['txtPointDist'].Text
    $rs['flags'] = $script:UI['txtCupFlags'].Text
    $rs['start order'] = $script:UI['cmbStartOrder'].Text
    $rs['points for best lap time'] = [int]$script:UI['numBestLap'].Value
    $rs['points for highest score'] = [int]$script:UI['numHighScore'].Value
    $rs['last race multiplier'] = [int]$script:UI['numLastMult'].Value
    try { $c['car restriction'] = @(Parse-JsonTextbox $script:UI['txtCupCarRes'].Text @()) }
    catch { throw $_ }
}

function Load-CupConfigFromFile {
    $paths = Get-SaveDirPaths -SaveDir (Get-CurrentSaveDir)
    $obj = $null
    try { $obj = Read-JsonFile -Path $paths.CupConfig } catch { $obj = $null }
    if ($null -eq $obj) { $obj = New-DefaultCupConfig }
    $script:CupBbmeta = Get-Bbmeta $obj
    $script:Cups = @()
    $cups = Get-Prop $obj 'cups'
    if ($cups) { foreach ($c in $cups) { $script:Cups += (ConvertTo-CupModel $c) } }
    if ($script:Cups.Count -eq 0) { $script:Cups = @( (New-Cup) ) }
    Select-CupItem 0
}

function Save-CupConfigToFile {
    if (-not (Test-ServerStoppedOrWarn)) { return }
    if ($script:CurCupIndex -ge 0) { Save-FieldsIntoCup $script:CurCupIndex }
    $cupsOut = @()
    foreach ($c in $script:Cups) {
        $rs = $c['race settings'][0]
        $rsOut = [ordered]@{}
        if ($rs.Contains('bbmeta')) { $rsOut['bbmeta'] = $rs['bbmeta'] }
        foreach ($k in @('point distribution','flags','start order','points for best lap time','points for highest score','last race multiplier')) { $rsOut[$k] = $rs[$k] }
        $cOut = [ordered]@{}
        if ($c.Contains('bbmeta')) { $cOut['bbmeta'] = $c['bbmeta'] }
        $cOut['race settings'] = @($rsOut)
        $cOut['event loop'] = $c['event loop']
        $cOut['cup name'] = $c['cup name']
        $cOut['cup description'] = $c['cup description']
        $cOut['icon'] = $c['icon']
        $cOut['car restriction'] = @($c['car restriction'])
        $cupsOut += $cOut
    }
    $root = [ordered]@{}
    if ($script:CupBbmeta) { $root['bbmeta'] = $script:CupBbmeta }
    $root['cups'] = $cupsOut
    $paths = Get-SaveDirPaths -SaveDir (Get-CurrentSaveDir)
    Write-JsonFile -Path $paths.CupConfig -Object $root
    $script:UI['statusLabel'].Text = "Cups opgeslagen: $($paths.CupConfig)"
    Show-Info 'Cup-configuratie opgeslagen.'
}

# --- Rollen & bans -------------------------------------------
function Load-PrivilegeToUI {
    $paths = Get-SaveDirPaths -SaveDir (Get-CurrentSaveDir)
    $obj = $null
    try { $obj = Read-JsonFile -Path $paths.Privilege } catch { $obj = $null }
    if ($null -eq $obj) { $obj = New-DefaultPrivilege }
    $script:PrivBbmeta = Get-Bbmeta $obj
    $grid = $script:UI['gridRoles']
    $grid.Rows.Clear()
    $roles = Get-Prop $obj 'roles'
    if ($roles) {
        foreach ($r in $roles) {
            $grid.Rows.Add([string](Get-Prop $r 'platform id'), [string](Get-Prop $r 'role')) | Out-Null
        }
    }
    $bans = Get-Prop $obj 'bans'
    $script:UI['txtBans'].Text = Format-Json $bans
}

function Save-PrivilegeFromUI {
    if (-not (Test-ServerStoppedOrWarn)) { return }
    $roles = @()
    foreach ($row in $script:UI['gridRoles'].Rows) {
        $platformId = $row.Cells[0].Value; $role = $row.Cells[1].Value
        if ([string]::IsNullOrWhiteSpace([string]$platformId)) { continue }
        $obj = [ordered]@{}
        $obj['bbmeta'] = 'ssrl v0 n1'
        $idNum = 0
        if ([int64]::TryParse([string]$platformId, [ref]$idNum)) { $obj['platform id'] = $idNum } else { $obj['platform id'] = [string]$platformId }
        $obj['role'] = if ([string]::IsNullOrWhiteSpace([string]$role)) { 'admin' } else { [string]$role }
        $roles += $obj
    }
    $bans = @()
    try { $bans = @(Parse-JsonTextbox $script:UI['txtBans'].Text @()) }
    catch { Show-Err "Bans bevatten ongeldige JSON: $($_.Exception.Message)"; return }

    $root = [ordered]@{}
    if ($script:PrivBbmeta) { $root['bbmeta'] = $script:PrivBbmeta } else { $root['bbmeta'] = 'sprv v0 n1' }
    $root['roles'] = $roles
    $root['bans'] = $bans
    $paths = Get-SaveDirPaths -SaveDir (Get-CurrentSaveDir)
    Write-JsonFile -Path $paths.Privilege -Object $root
    $script:UI['statusLabel'].Text = "Rollen & bans opgeslagen: $($paths.Privilege)"
    Show-Info 'Rollen & bans opgeslagen.'
}

# --- Telemetrie ----------------------------------------------
function Load-TelemetryToUI {
    $paths = Get-SaveDirPaths -SaveDir (Get-CurrentSaveDir)
    $obj = $null
    try { $obj = Read-JsonFile -Path $paths.Telemetry } catch { $obj = $null }
    if ($null -eq $obj) { $obj = New-DefaultTelemetry }
    $udp = Get-FirstItem (Get-Prop $obj 'udp')
    if ($udp) {
        $script:UI['chkUdpEnabled'].Checked = ([int](Get-Prop $udp 'enabled') -ne 0)
        $script:UI['txtUdpIp'].Text = [string](Get-Prop $udp 'ip')
        $script:UI['txtUdpPort'].Text = [string](Get-Prop $udp 'port')
    }
    $log = Get-FirstItem (Get-Prop $obj 'logging')
    if ($log) { $script:UI['cmbLogFormat'].Text = [string](Get-Prop $log 'format') }
    $srv = Get-FirstItem (Get-Prop $obj 'server')
    if ($srv) {
        $script:UI['chkSrvEnabled'].Checked = ([int](Get-Prop $srv 'enabled') -ne 0)
        $script:UI['chkAutoMainCar'].Checked = ([int](Get-Prop $srv 'automaticMainCar') -ne 0)
    }
}

function Save-TelemetryFromUI {
    if (-not (Test-ServerStoppedOrWarn)) { return }
    $root = [ordered]@{
        'udp' = @( [ordered]@{
            'enabled' = if ($script:UI['chkUdpEnabled'].Checked) { 1 } else { 0 }
            'ip' = $script:UI['txtUdpIp'].Text
            'port' = $script:UI['txtUdpPort'].Text
        })
        'logging' = @( [ordered]@{ 'format' = $script:UI['cmbLogFormat'].Text } )
        'server' = @( [ordered]@{
            'enabled' = if ($script:UI['chkSrvEnabled'].Checked) { 1 } else { 0 }
            'automaticMainCar' = if ($script:UI['chkAutoMainCar'].Checked) { 1 } else { 0 }
        })
    }
    $paths = Get-SaveDirPaths -SaveDir (Get-CurrentSaveDir)
    Write-JsonFile -Path $paths.Telemetry -Object $root
    $script:UI['statusLabel'].Text = "Telemetrie opgeslagen: $($paths.Telemetry)"
    Show-Info 'Telemetrie opgeslagen.'
}

# --- Profielen & instellingen --------------------------------
function Refresh-ProfilesUI {
    $grid = $script:UI['gridProfiles']
    $grid.Rows.Clear()
    foreach ($p in (Get-Prop $script:Settings 'Profiles')) {
        $grid.Rows.Add([string](Get-Prop $p 'Name'), [string](Get-Prop $p 'SaveDir'), [string](Get-Prop $p 'Mode')) | Out-Null
    }
    $cmb = $script:UI['cmbProfile']
    $cmb.Items.Clear()
    foreach ($p in (Get-Prop $script:Settings 'Profiles')) { [void]$cmb.Items.Add([string](Get-Prop $p 'Name')) }
    $last = [string](Get-Prop $script:Settings 'LastProfile')
    if ($cmb.Items.Contains($last)) { $cmb.SelectedItem = $last } elseif ($cmb.Items.Count -gt 0) { $cmb.SelectedIndex = 0 }
    $script:UI['txtSaveDir'].Text = Get-CurrentSaveDir
}

function Save-ProfilesFromUI {
    $list = @()
    foreach ($row in $script:UI['gridProfiles'].Rows) {
        $n = [string]$row.Cells[0].Value
        if ([string]::IsNullOrWhiteSpace($n)) { continue }
        $m = [string]$row.Cells[2].Value
        if ($m -notin @('community','local')) { $m = 'community' }
        $list += [ordered]@{ Name = $n; SaveDir = [string]$row.Cells[1].Value; Mode = $m }
    }
    if ($list.Count -eq 0) { Show-Err 'Er moet minstens één profiel zijn.'; return }
    Set-Prop $script:Settings 'Profiles' $list
    Set-Prop $script:Settings 'ServerInstallPath' $script:UI['txtInstallPath'].Text
    Set-Prop $script:Settings 'SteamExe' $script:UI['txtSteamExe'].Text
    Save-Settings $script:Settings
    Refresh-ProfilesUI
    Show-Info 'Instellingen en profielen opgeslagen.'
}

# --- Log / status --------------------------------------------
function Get-ConfiguredLogPath {
    $saveDir = Get-CurrentSaveDir
    $log = $script:UI['txtLog'].Text
    if ([string]::IsNullOrWhiteSpace($log)) { return $null }
    if ([System.IO.Path]::IsPathRooted($log)) { return $log }
    return (Join-Path $saveDir $log)
}

function Refresh-Status {
    $install = [string](Get-Prop $script:Settings 'ServerInstallPath')
    $running = $false
    if ($install) { $running = Test-ServerRunning -InstallPath $install }
    if ($running) {
        $script:UI['lblStatus'].Text = 'Status: SERVER DRAAIT'
        $script:UI['lblStatus'].ForeColor = [System.Drawing.Color]::Green
    } else {
        $script:UI['lblStatus'].Text = 'Status: gestopt'
        $script:UI['lblStatus'].ForeColor = [System.Drawing.Color]::Firebrick
    }
}

function Refresh-LogView {
    $p = Get-ConfiguredLogPath
    if (-not $p) { $script:UI['txtLogView'].Text = '(Geen logbestand ingesteld in de serverconfig.)'; return }
    if (-not (Test-Path -LiteralPath $p)) { $script:UI['txtLogView'].Text = "Logbestand nog niet gevonden: $p"; return }
    $script:UI['txtLogView'].Text = Get-LogFileTail -LogPath $p -Lines 300
    $script:UI['txtLogView'].SelectionStart = $script:UI['txtLogView'].Text.Length
    $script:UI['txtLogView'].ScrollToCaret()
}

function Load-AllConfigs {
    Initialize-SaveDir -SaveDir (Get-CurrentSaveDir)
    Refresh-SaveDirLists
    Load-ServerConfigToUI
    Load-EventLoopFromFile ([string]$script:UI['cmbEventLoop'].Text)
    Load-CupConfigFromFile
    Load-PrivilegeToUI
    Load-TelemetryToUI
    Refresh-Status
}

# ============================================================
#  Event wiring
# ============================================================
$btnSaveServer.Add_Click({ try { Save-ServerConfigFromUI } catch { Show-Err $_.Exception.Message } })
$btnReloadServer.Add_Click({ try { Load-ServerConfigToUI } catch { Show-Err $_.Exception.Message } })

$script:SuppressList = $false

function Select-EventItem {
    param([int]$index)
    $script:SuppressList = $true
    Refresh-EventList
    if ($index -ge 0 -and $index -lt $script:Events.Count) {
        $script:UI['lstEvents'].SelectedIndex = $index
        Load-EventIntoFields $index
    }
    $script:SuppressList = $false
}

function Select-CupItem {
    param([int]$index)
    $script:SuppressList = $true
    Refresh-CupList
    if ($index -ge 0 -and $index -lt $script:Cups.Count) {
        $script:UI['lstCups'].SelectedIndex = $index
        Load-CupIntoFields $index
    }
    $script:SuppressList = $false
}

$btnLoopLoad.Add_Click({
    try { Load-EventLoopFromFile ([string]$script:UI['cmbLoopFile'].Text) } catch { Show-Err $_.Exception.Message }
})
$btnLoopNew.Add_Click({
    $script:Events = @( (New-Event) ); $script:EventLoopBbmeta = $null
    Select-EventItem 0
})
$btnLoopSave.Add_Click({
    try {
        $name = [string]$script:UI['cmbLoopFile'].Text
        if ([string]::IsNullOrWhiteSpace($name)) { $name = [string]$script:UI['cmbEventLoop'].Text }
        if ([string]::IsNullOrWhiteSpace($name)) { Show-Err 'Geef een naam voor het event loop-bestand.'; return }
        Save-EventLoopToFile $name
        $script:UI['cmbLoopFile'].Text = $name
        $script:UI['cmbEventLoop'].Text = $name
    } catch { Show-Err $_.Exception.Message }
})

$script:UI['lstEvents'].Add_SelectedIndexChanged({
    if ($script:SuppressList) { return }
    $new = $script:UI['lstEvents'].SelectedIndex
    if ($new -lt 0 -or $new -eq $script:CurEventIndex) { return }
    if ($script:CurEventIndex -ge 0 -and $script:CurEventIndex -lt $script:Events.Count) {
        try { Save-FieldsIntoEvent $script:CurEventIndex } catch { Show-Err $_.Exception.Message; return }
    }
    Load-EventIntoFields $new
    $script:SuppressList = $true
    Refresh-EventList
    $script:UI['lstEvents'].SelectedIndex = $new
    $script:SuppressList = $false
})
$btnEvNew.Add_Click({
    if ($script:CurEventIndex -ge 0) { Save-FieldsIntoEvent $script:CurEventIndex }
    $script:Events = @($script:Events) + @( (New-Event) )
    Select-EventItem ($script:Events.Count - 1)
})
$btnEvDup.Add_Click({
    if ($script:CurEventIndex -lt 0) { return }
    Save-FieldsIntoEvent $script:CurEventIndex
    $src = $script:Events[$script:CurEventIndex]
    $copy = $src.Clone()
    $copy['level'] = @( $src['level'][0].Clone() )
    $copy['rules'] = @( $src['rules'][0].Clone() )
    $script:Events = Insert-At $script:Events ($script:CurEventIndex + 1) $copy
    Select-EventItem ($script:CurEventIndex + 1)
})
$btnEvDel.Add_Click({
    if ($script:CurEventIndex -lt 0 -or $script:Events.Count -le 1) { return }
    $i = $script:CurEventIndex
    $script:Events = Remove-At $script:Events $i
    Select-EventItem ([Math]::Max(0, $i - 1))
})
$btnEvUp.Add_Click({
    if ($script:CurEventIndex -le 0) { return }
    Save-FieldsIntoEvent $script:CurEventIndex
    $i = $script:CurEventIndex
    $script:Events = Swap-At $script:Events $i ($i - 1)
    Select-EventItem ($i - 1)
})
$btnEvDown.Add_Click({
    if ($script:CurEventIndex -lt 0 -or $script:CurEventIndex -ge ($script:Events.Count - 1)) { return }
    Save-FieldsIntoEvent $script:CurEventIndex
    $i = $script:CurEventIndex
    $script:Events = Swap-At $script:Events $i ($i + 1)
    Select-EventItem ($i + 1)
})


$script:UI['lstCups'].Add_SelectedIndexChanged({
    if ($script:SuppressList) { return }
    $new = $script:UI['lstCups'].SelectedIndex
    if ($new -lt 0 -or $new -eq $script:CurCupIndex) { return }
    if ($script:CurCupIndex -ge 0 -and $script:CurCupIndex -lt $script:Cups.Count) {
        try { Save-FieldsIntoCup $script:CurCupIndex } catch { Show-Err $_.Exception.Message; return }
    }
    Load-CupIntoFields $new
    $script:SuppressList = $true
    Refresh-CupList
    $script:UI['lstCups'].SelectedIndex = $new
    $script:SuppressList = $false
})
$btnCupNew.Add_Click({
    if ($script:CurCupIndex -ge 0) { Save-FieldsIntoCup $script:CurCupIndex }
    $script:Cups = @($script:Cups) + @( (New-Cup) )
    Select-CupItem ($script:Cups.Count - 1)
})
$btnCupDup.Add_Click({
    if ($script:CurCupIndex -lt 0) { return }
    Save-FieldsIntoCup $script:CurCupIndex
    $src = $script:Cups[$script:CurCupIndex]
    $copy = $src.Clone()
    $copy['race settings'] = @( $src['race settings'][0].Clone() )
    $script:Cups = Insert-At $script:Cups ($script:CurCupIndex + 1) $copy
    Select-CupItem ($script:CurCupIndex + 1)
})
$btnCupDel.Add_Click({
    if ($script:CurCupIndex -lt 0 -or $script:Cups.Count -le 1) { return }
    $i = $script:CurCupIndex
    $script:Cups = Remove-At $script:Cups $i
    Select-CupItem ([Math]::Max(0, $i - 1))
})
$btnCupUp.Add_Click({
    if ($script:CurCupIndex -le 0) { return }
    Save-FieldsIntoCup $script:CurCupIndex
    $i = $script:CurCupIndex
    $script:Cups = Swap-At $script:Cups $i ($i - 1)
    Select-CupItem ($i - 1)
})
$btnCupDown.Add_Click({
    if ($script:CurCupIndex -lt 0 -or $script:CurCupIndex -ge ($script:Cups.Count - 1)) { return }
    Save-FieldsIntoCup $script:CurCupIndex
    $i = $script:CurCupIndex
    $script:Cups = Swap-At $script:Cups $i ($i + 1)
    Select-CupItem ($i + 1)
})
$btnSaveCups.Add_Click({ try { Save-CupConfigToFile } catch { Show-Err $_.Exception.Message } })

$btnRoleAdd.Add_Click({ $script:UI['gridRoles'].Rows.Add('', 'admin') | Out-Null })
$btnRoleDel.Add_Click({
    $i = $script:UI['gridRoles'].CurrentRowIndex
    if ($i -ge 0) { $script:UI['gridRoles'].Rows.RemoveAt($i) }
})
$btnSavePriv.Add_Click({ try { Save-PrivilegeFromUI } catch { Show-Err $_.Exception.Message } })

$btnSaveTele.Add_Click({ try { Save-TelemetryFromUI } catch { Show-Err $_.Exception.Message } })

$btnSaveDir.Add_Click({
    $dir = $script:UI['txtSaveDir'].Text
    if (Test-Path -LiteralPath $dir) { Start-Process explorer.exe $dir } else { Show-Err "Map bestaat niet: $dir" }
})
$btnStart.Add_Click({
    try {
        if (-not (Test-ServerStoppedOrWarn)) { return }
        # Eerst alle configuraties wegschrijven
        Save-ServerConfigFromUI
        $name = [string]$script:UI['cmbEventLoop'].Text
        if ($name) { Save-EventLoopToFile $name }
        Save-CupConfigToFile
        Save-PrivilegeFromUI
        Save-TelemetryFromUI
        $install = [string](Get-Prop $script:Settings 'ServerInstallPath')
        if (-not (Test-Path -LiteralPath (Join-Path $install 'Wreckfest2.exe'))) { Show-Err "Server niet gevonden in: $install"; return }
        $mode = if ($script:UI['cmbMode'].SelectedIndex -eq 1) { 'local' } else { 'community' }
        $dir = $script:UI['txtSaveDir'].Text
        Start-WF2Server -InstallPath $install -SaveDir $dir -Mode $mode | Out-Null
        $script:UI['statusLabel'].Text = 'Server gestart in een apart venster.'
        Start-Sleep -Milliseconds 800
        Refresh-Status
        if ($script:UI['chkFollowLog'].Checked) { Refresh-LogView }
    } catch { Show-Err $_.Exception.Message }
})
$btnStop.Add_Click({
    try {
        $install = [string](Get-Prop $script:Settings 'ServerInstallPath')
        $n = Stop-WF2Server -InstallPath $install
        $script:UI['statusLabel'].Text = "Server gestopt ($n proces(sen))."
        Refresh-Status
    } catch { Show-Err $_.Exception.Message }
})
$btnRefresh.Add_Click({ Refresh-Status })
$btnRefreshLog.Add_Click({ Refresh-LogView })
$btnOpenLog.Add_Click({
    $p = Get-ConfiguredLogPath
    if ($p -and (Test-Path -LiteralPath $p)) { Start-Process notepad.exe $p } else { Show-Err 'Logbestand niet gevonden.' }
})

$script:UI['cmbProfile'].Add_SelectedIndexChanged({
    $name = [string]$script:UI['cmbProfile'].SelectedItem
    $p = Get-ProfileByName $script:Settings $name
    if ($p) {
        Set-Prop $script:Settings 'LastProfile' $name
        $script:UI['txtSaveDir'].Text = [string](Get-Prop $p 'SaveDir')
        $idx = if ((Get-Prop $p 'Mode') -eq 'local') { 1 } else { 0 }
        $script:UI['cmbMode'].SelectedIndex = $idx
        try { Load-AllConfigs } catch { Show-Err $_.Exception.Message }
    }
})

$btnDetect.Add_Click({
    $install = Find-WF2ServerInstall
    if ($install) { $script:UI['txtInstallPath'].Text = $install } else { Show-Err 'Server-installatie niet gevonden.' }
    $steam = Find-SteamExe
    if ($steam) { $script:UI['txtSteamExe'].Text = $steam }
})
$btnBrowseInstall.Add_Click({
    $f = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($f.ShowDialog() -eq 'OK') { $script:UI['txtInstallPath'].Text = $f.SelectedPath }
})
$btnBrowseSteam.Add_Click({
    $f = New-Object System.Windows.Forms.OpenFileDialog
    $f.Filter = 'steam.exe|steam.exe'
    if ($f.ShowDialog() -eq 'OK') { $script:UI['txtSteamExe'].Text = $f.FileName }
})
$btnSaveSettings.Add_Click({
    try {
        Save-ProfilesFromUI
        Refresh-GameDataLists
    } catch { Show-Err $_.Exception.Message }
})
$btnProfAdd.Add_Click({ $script:UI['gridProfiles'].Rows.Add('Nieuw', (Get-CurrentSaveDir), 'community') | Out-Null })
$btnProfDel.Add_Click({
    $i = $script:UI['gridProfiles'].CurrentRowIndex
    if ($i -ge 0) { $script:UI['gridProfiles'].Rows.RemoveAt($i) }
})
$btnProfSave.Add_Click({ try { Save-ProfilesFromUI } catch { Show-Err $_.Exception.Message } })

# Log-timer
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 2500
$timer.Add_Tick({
    if ($script:UI['chkFollowLog'].Checked) { Refresh-LogView }
    Refresh-Status
})
$timer.Start()

# ============================================================
#  Initieel laden
# ============================================================
try {
    $script:UI['txtInstallPath'].Text = [string](Get-Prop $script:Settings 'ServerInstallPath')
    $script:UI['txtSteamExe'].Text = [string](Get-Prop $script:Settings 'SteamExe')
    Refresh-GameDataLists
    Refresh-ProfilesUI
    $script:UI['chkFollowLog'].Checked = [bool](Get-Prop $script:Settings 'FollowLog')
    $mode = Get-CurrentMode
    $script:UI['cmbMode'].SelectedIndex = if ($mode -eq 'local') { 1 } else { 0 }
    Load-AllConfigs
} catch {
    Show-Err "Fout bij laden: $($_.Exception.Message)"
}

if ($env:WSM2_SELFTEST -eq '1') {
    $timer.Stop()
    Write-Output ("SELFTEST OK | events={0} cups={1} levels={2} weather={3} loops={4} profile='{5}' savedir='{6}'" -f `
        $script:Events.Count, $script:Cups.Count, $script:GameData.Levels.Count, $script:GameData.Weather.Count, `
        $script:UI['cmbLoopFile'].Items.Count, (Get-Prop (Get-CurrentProfile) 'Name'), (Get-CurrentSaveDir))
    $form.Dispose()
    return
}

[void]$form.ShowDialog()
$timer.Stop()

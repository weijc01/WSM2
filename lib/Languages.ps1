# ============================================================
#  WSM2 - Languages.ps1
#  Meertalige interface: NL (standaard), EN, FR en DE.
#  De Nederlandse tekst dient als sleutel; ontbrekende
#  vertalingen vallen terug op het Nederlands.
# ============================================================

$script:Language = 'nl'
$script:Languages = @{}

function Register-Language {
    param([Parameter(Mandatory)][string]$Code, [Parameter(Mandatory)][hashtable]$Strings)
    $script:Languages[$Code] = $Strings
}

function Get-LanguageCodes {
    return @('nl', 'en', 'fr', 'de')
}

function Get-LanguageName {
    param([string]$Code)
    switch ($Code) {
        'nl' { return 'Nederlands' }
        'en' { return 'English' }
        'fr' { return 'Français' }
        'de' { return 'Deutsch' }
        default { return [string]$Code }
    }
}

function Set-Language {
    param([string]$Code)
    if ($Code -and $script:Languages.ContainsKey($Code)) { $script:Language = $Code }
    else { $script:Language = 'nl' }
}

function T {
    param([AllowEmptyString()][Parameter(Mandatory)][string]$Key)
    if ([string]::IsNullOrEmpty($Key)) { return '' }
    $text = $Key
    $dict = $script:Languages[$script:Language]
    if ($dict -and $dict.ContainsKey($Key)) { $text = [string]$dict[$Key] }
    if ($args.Count -gt 0) { return ($text -f $args) }
    return $text
}

$langDir = $PSScriptRoot
foreach ($file in (Get-ChildItem -LiteralPath $langDir -Filter 'Languages.*.ps1' -ErrorAction SilentlyContinue)) {
    try { . $file.FullName } catch { }
}

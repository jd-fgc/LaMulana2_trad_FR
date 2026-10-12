# Génère patch\LaMulana2FR\fr.txt à partir de traduction\source\*.json, et compile le plugin si BepInEx est disponible.
# Les lignes pas encore traduites (fr vide) reprennent l'anglais.
param(
  [string]$Jeu = (& "$PSScriptRoot\chemin_jeu.ps1"),
  [string]$Source = "$PSScriptRoot\..\traduction\source",
  [string]$Sortie = "$PSScriptRoot\..\patch\LaMulana2FR",
  # À utiliser quand le jeu tourne : construit le patch sans le copier dans le dossier du jeu.
  [switch]$SansInstallation
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force $Sortie | Out-Null
# Les polices du jeu n'ont ni œ/Œ ni guillemets français : on les remplace ici pour pouvoir écrire un français correct dans les JSON.
function Echapper([string]$s) {
  $s = $s.Replace('œ', 'oe').Replace('Œ', 'Oe').Replace('« ', '"').Replace(' »', '"').Replace('«', '"').Replace('»', '"').Replace([string][char]0x202F, ' ').Replace([string][char]0xA0, ' ')
  $s.Replace('\', '\\').Replace("`r", '').Replace("`n", '\n').Replace("`t", ' ')
}

$lignes = [Collections.Generic.List[string]]::new()
$total = 0; $traduites = 0
foreach ($f in Get-ChildItem $Source -Filter *.json) {
  $db = Get-Content $f.FullName -Raw | ConvertFrom-Json -AsHashtable
  foreach ($feuille in $db.Keys) {
    foreach ($l in $db[$feuille]) {
      $total++
      $texte = if ($l.fr) { $traduites++; $l.fr } else { $l.eng }
      $lignes.Add(($f.BaseName, $feuille, $l.ligne, 'chi', (Echapper $texte)) -join "`t")
      # Le nom de la langue doit se lire "Français" quelle que soit la langue en cours
      if ($l.id -eq 'conLang3') {
        foreach ($col in 'jpn', 'eng', 'chi') { $lignes.Add(($f.BaseName, $feuille, $l.ligne, $col, 'Français') -join "`t") }
      }
    }
  }
}
[IO.File]::WriteAllLines((Join-Path $Sortie 'fr.txt'), $lignes, [Text.UTF8Encoding]::new($false))
"fr.txt : {0} lignes, {1} traduites ({2:P1})" -f $total, $traduites, ($traduites / $total)

$bep = Join-Path $Jeu 'BepInEx\core'
if (-not (Test-Path "$bep\BepInEx.dll")) { 'BepInEx absent du dossier du jeu : plugin non compilé.'; return }
$gere = Join-Path $Jeu 'LaMulana2_Data\Managed'
$csc = Get-ChildItem "$env:ProgramFiles\dotnet\sdk\*\Roslyn\bincore\csc.dll" | Sort-Object FullName | Select-Object -Last 1
$refs = @("$gere\mscorlib.dll", "$gere\System.dll", "$gere\System.Core.dll", "$gere\UnityEngine.dll", "$gere\UnityEngine.CoreModule.dll", "$gere\UnityEngine.TextRenderingModule.dll", "$gere\Assembly-CSharp.dll", "$bep\BepInEx.dll", "$bep\0Harmony.dll") | ForEach-Object { "-r:$_" }
dotnet $csc.FullName -nologo -nostdlib -noconfig -target:library -optimize -langversion:7.3 "-out:$Sortie\LaMulana2FR.dll" @refs "$PSScriptRoot\..\plugin\LaMulana2FR.cs"
if ($LASTEXITCODE) { throw 'Compilation du plugin échouée.' }
"Plugin compilé : $Sortie\LaMulana2FR.dll"
if ($SansInstallation) { 'Patch construit, non installé.'; return }
$plugins = Join-Path $Jeu 'BepInEx\plugins\LaMulana2FR'
New-Item -ItemType Directory -Force $plugins | Out-Null
Copy-Item "$Sortie\*" $plugins -Force
"Installé dans $plugins"

# Construit le patch puis assemble les archives de distribution dans distribution\.
# - LaMulana2FR-<version>.zip         : BepInEx + plugin, à décompresser dans le dossier du jeu
# - LaMulana2FR-<version>-plugin.zip  : plugin seul, pour qui a déjà BepInEx 5
param(
  [Parameter(Mandatory)][string]$Version,
  [string]$BepInEx = "$PSScriptRoot\..\telechargements\BepInEx_5.4.23.5\contenu"
)
$ErrorActionPreference = 'Stop'
& "$PSScriptRoot\construire_patch.ps1" -SansInstallation
$racine = Resolve-Path "$PSScriptRoot\.."
$sortie = Join-Path $racine 'distribution'
$tmp = Join-Path ([IO.Path]::GetTempPath()) ("LaMulana2FR_" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force $sortie, "$tmp\complet\BepInEx\plugins\LaMulana2FR", "$tmp\plugin\LaMulana2FR" | Out-Null

Copy-Item -Path "$BepInEx\*" -Destination "$tmp\complet" -Recurse -Force
Copy-Item -Path "$racine\patch\LaMulana2FR\*" -Destination "$tmp\complet\BepInEx\plugins\LaMulana2FR"
Copy-Item -Path "$racine\LISEZMOI.txt" -Destination "$tmp\complet\LISEZMOI-LaMulana2FR.txt"
Copy-Item -Path "$racine\patch\LaMulana2FR\*" -Destination "$tmp\plugin\LaMulana2FR"
Copy-Item -Path "$racine\LISEZMOI.txt" -Destination "$tmp\plugin\LISEZMOI-LaMulana2FR.txt"

Compress-Archive -Path "$tmp\complet\*" -DestinationPath "$sortie\LaMulana2FR-$Version.zip" -Force
Compress-Archive -Path "$tmp\plugin\*" -DestinationPath "$sortie\LaMulana2FR-$Version-plugin.zip" -Force
Get-ChildItem $sortie -Filter "LaMulana2FR-$Version*.zip" | Select-Object Name, Length

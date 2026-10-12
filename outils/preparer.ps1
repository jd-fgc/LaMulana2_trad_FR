# Reconstitue traduction\source\*.json à partir du jeu installé et des lots de traduction.
# À lancer une fois après avoir cloné le dépôt : les textes originaux du jeu ne sont pas versionnés.
$ErrorActionPreference = 'Stop'
$source = Join-Path $PSScriptRoot '..\traduction\source'
if (-not (Test-Path "$source\*.json")) { & "$PSScriptRoot\extraire_textes.ps1" }
foreach ($lot in Get-ChildItem (Join-Path $PSScriptRoot '..\traduction\lots') -Filter *.txt) {
  & "$PSScriptRoot\importer_lot.ps1" -Base $lot.BaseName
}
& "$PSScriptRoot\glossaire.ps1" | Out-Null
& "$PSScriptRoot\appliquer_propositions.ps1"

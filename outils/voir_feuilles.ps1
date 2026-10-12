# Affiche des feuilles d'une base pour préparer un lot : anglais, plus le japonais quand la ligne contient un terme coloré.
# Usage : pwsh outils\voir_feuilles.ps1 -Base L2TalkDataBase -Feuilles xelpud,neburu [-Japonais]
param(
  [Parameter(Mandatory)][string]$Base,
  [Parameter(Mandatory)][string[]]$Feuilles,
  [switch]$Japonais,
  [string]$Source = "$PSScriptRoot\..\traduction\source"
)
$db = Get-Content (Join-Path $Source "$Base.json") -Raw | ConvertFrom-Json -AsHashtable
foreach ($f in ($Feuilles -split ',')) {
  "### $f"
  foreach ($l in $db[$f]) {
    "{0} [{1}] {2}" -f $l.ligne, $l.id, $l.eng.Replace("`n", '\n')
    if ($Japonais -or $l.eng -match '<color') { "    JP: " + $l.jpn.Replace("`n", '\n') }
  }
}

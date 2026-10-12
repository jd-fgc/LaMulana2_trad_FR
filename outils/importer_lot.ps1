# Reporte un lot de traduction (traduction\lots\<Base>.txt) dans le champ fr de traduction\source\<Base>.json,
# puis contrôle que chaque ligne traduite garde les mêmes balises (<color>, <sprite>) que l'anglais.
param(
  [Parameter(Mandatory)][string]$Base,
  [string]$Lots = "$PSScriptRoot\..\traduction\lots",
  [string]$Source = "$PSScriptRoot\..\traduction\source"
)
$ErrorActionPreference = 'Stop'
$json = Join-Path $Source "$Base.json"
$db = Get-Content $json -Raw | ConvertFrom-Json -AsHashtable
$feuille = $null; $n = 0; $pb = 0
foreach ($l in Get-Content (Join-Path $Lots "$Base.txt") -Encoding utf8) {
  if ($l -match '^### (.+)$') { $feuille = $Matches[1].Trim(); continue }
  if ($l -match '^\s*(#|$)') { continue }
  if ($l -notmatch '^(\d+): (.*)$' -or -not $feuille) { Write-Warning "Ligne illisible : $l"; $pb++; continue }
  $no = [int]$Matches[1]; $texte = $Matches[2].Replace('\n', "`n")
  $cible = $db[$feuille] | Where-Object { $_.ligne -eq $no }
  if (-not $cible) { Write-Warning "Introuvable : $feuille/$no"; $pb++; continue }
  $cible.fr = $texte; $n++
}
$rx = [regex]'<color=#[0-9A-Fa-f]{8}>|</color>|<sprite name=\w+>'
foreach ($f in $db.Keys) {
  foreach ($l in $db[$f]) {
    if (-not $l.fr) { continue }
    $a = ($rx.Matches($l.eng) | ForEach-Object Value | Sort-Object) -join ' '
    $b = ($rx.Matches($l.fr) | ForEach-Object Value | Sort-Object) -join ' '
    if ($a -cne $b) { Write-Warning "Balises différentes : $f/$($l.ligne) [$($l.id)]"; $pb++ }
  }
}
[IO.File]::WriteAllText($json, ($db | ConvertTo-Json -Depth 6), [Text.UTF8Encoding]::new($false))
"{0} : {1} lignes importées, {2} problème(s)." -f $Base, $n, $pb

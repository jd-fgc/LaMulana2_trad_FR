# Reporte traduction\glossaire_propositions.txt dans la colonne fr de traduction\glossaire.csv.
# Une valeur déjà saisie dans le CSV est conservée, sauf avec -Ecraser.
param(
  [string]$Propositions = "$PSScriptRoot\..\traduction\glossaire_propositions.txt",
  [string]$Glossaire = "$PSScriptRoot\..\traduction\glossaire.csv",
  [switch]$Ecraser
)
$ErrorActionPreference = 'Stop'
$map = [Collections.Generic.Dictionary[string, string]]::new([StringComparer]::Ordinal)
foreach ($l in Get-Content $Propositions -Encoding utf8) {
  if ($l -match '^\s*(#|$)') { continue }
  $p = $l.Split(' = ', 2)
  if ($p.Count -ne 2) { Write-Warning "Ligne illisible : $l"; continue }
  $map[$p[0].Trim()] = $p[1].Trim()
}
$lignes = Import-Csv $Glossaire -Delimiter ';' -Encoding utf8
$vus = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach ($l in $lignes) {
  if ($map.ContainsKey($l.eng)) {
    [void]$vus.Add($l.eng)
    if ($Ecraser -or -not $l.fr) { $l.fr = $map[$l.eng] }
  }
}
$lignes | Export-Csv $Glossaire -Delimiter ';' -Encoding utf8BOM -NoTypeInformation
$inutiles = @($map.Keys | Where-Object { -not $vus.Contains($_) })
"{0} termes renseignés sur {1} ; {2} restent à traduire en contexte." -f @($lignes | Where-Object fr).Count, $lignes.Count, @($lignes | Where-Object { -not $_.fr }).Count
if ($inutiles) { "Propositions sans terme correspondant : " + ($inutiles -join ', ') }

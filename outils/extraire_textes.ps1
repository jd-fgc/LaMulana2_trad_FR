# Extrait les textes de La-Mulana 2 (classes L2Word.* de Assembly-CSharp.dll) vers traduction\source\*.json
# Usage : pwsh outils\extraire_textes.ps1 [-Dll <chemin vers Assembly-CSharp.dll>]
param(
  [string]$Dll = (Join-Path (& "$PSScriptRoot\chemin_jeu.ps1") 'LaMulana2_Data\Managed\Assembly-CSharp.dll'),
  [string]$Sortie = "$PSScriptRoot\..\traduction\source"
)
$ErrorActionPreference = 'Stop'
# Garde-fou : une réextraction écraserait les champs "fr" déjà remplis.
if (Test-Path "$Sortie\*.json") { throw "Des fichiers existent déjà dans $Sortie : réextraire écraserait la traduction en cours." }
$asm = [Reflection.Assembly]::LoadFile((Resolve-Path $Dll).Path)
$bases = 'L2TalkDataBase','L2TalkSystemDataBase','L2TalkMapname','L2TalkMonsterLib','L2WordDataBase','L2ShopDataBase','L2ItemDataBase','L2XlepdDataBase'
New-Item -ItemType Directory -Force $Sortie | Out-Null

# Une cellule = segments [balise couleur, texte, </color>] répétés. Le blanc par défaut est omis pour la lisibilité.
function Join-Cell([string[]]$seg) {
  if ($null -eq $seg) { return '' }
  if ($seg.Length % 3 -ne 0) { return ($seg -join '') }
  $sb = [Text.StringBuilder]::new()
  for ($i = 0; $i -lt $seg.Length; $i += 3) {
    if ($seg[$i] -eq '<color=#FFFFFFFF>') { [void]$sb.Append($seg[$i + 1]) }
    else { [void]$sb.Append($seg[$i]).Append($seg[$i + 1]).Append($seg[$i + 2]) }
  }
  $sb.ToString()
}

$bilan = foreach ($nom in $bases) {
  $db = [Activator]::CreateInstance($asm.GetType("L2Word.$nom"))
  $feuilles = [ordered]@{}
  $nb = 0; $car = 0
  for ($s = 0; $s -lt $db.seetNum; $s++) {
    $rows = $db.cellData[$s]
    if ($null -eq $rows -or $rows.Length -eq 0) { continue }
    $cols = @($rows[0] | ForEach-Object { Join-Cell $_ })
    $iEng = [Array]::IndexOf($cols, 'eng'); $iJpn = [Array]::IndexOf($cols, 'jpn')
    if ($iEng -lt 0) { continue }
    $lignes = [Collections.Generic.List[object]]::new()
    for ($r = 1; $r -lt $rows.Length; $r++) {
      $row = $rows[$r]
      if ($null -eq $row -or $row.Length -le $iEng) { continue }
      $eng = Join-Cell $row[$iEng]
      if ($eng -eq '' -or $eng -eq '*') { continue }
      $lignes.Add([ordered]@{
        ligne = $r
        id    = Join-Cell $row[0]
        jpn   = if ($iJpn -ge 0) { Join-Cell $row[$iJpn] } else { '' }
        eng   = $eng
        fr    = ''
      })
      $nb++; $car += $eng.Length
    }
    if ($lignes.Count) { $feuilles[$db.seetName[$s]] = $lignes }
  }
  $json = $feuilles | ConvertTo-Json -Depth 6
  [IO.File]::WriteAllText((Join-Path $Sortie "$nom.json"), $json, [Text.UTF8Encoding]::new($false))
  [pscustomobject]@{ Base = $nom; Feuilles = $feuilles.Count; Lignes = $nb; Caracteres = $car }
}
$bilan | Format-Table -AutoSize
"TOTAL : {0} lignes, {1} caractères anglais" -f ($bilan | Measure-Object Lignes -Sum).Sum, ($bilan | Measure-Object Caracteres -Sum).Sum

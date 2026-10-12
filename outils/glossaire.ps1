# Construit traduction\glossaire.csv : tous les termes colorés (mots-clés d'énigmes) avec leur équivalent japonais quand il est déductible.
# Les lignes déjà renseignées (colonne fr) d'un glossaire existant sont conservées.
param(
  [string]$Source = "$PSScriptRoot\..\traduction\source",
  [string]$Sortie = "$PSScriptRoot\..\traduction\glossaire.csv"
)
$ErrorActionPreference = 'Stop'
$rx = [regex]'<color=#([0-9A-Fa-f]{6})[0-9A-Fa-f]{2}>(.*?)</color>'
$termes = @{}
foreach ($f in Get-ChildItem $Source -Filter *.json) {
  $base = $f.BaseName
  $db = Get-Content $f.FullName -Raw | ConvertFrom-Json -AsHashtable
  foreach ($feuille in $db.Keys) {
    foreach ($l in $db[$feuille]) {
      $e = @($rx.Matches($l.eng)); $j = @($rx.Matches($l.jpn))
      foreach ($m in $e) {
        $coul = $m.Groups[1].Value.ToUpper(); $t = $m.Groups[2].Value.Trim()
        if ($t -eq '') { continue }
        $cle = "$coul|$t"
        if (-not $termes.ContainsKey($cle)) {
          $termes[$cle] = [ordered]@{ couleur = $coul; eng = $t; jpn = [Collections.Generic.HashSet[string]]::new(); occurrences = 0; exemple = "$base/$feuille/$($l.id)"; fr = '' }
        }
        $termes[$cle].occurrences++
        # Appariement sûr uniquement si la ligne contient un seul terme de cette couleur dans les deux langues
        $ec = @($e | Where-Object { $_.Groups[1].Value -eq $m.Groups[1].Value })
        $jc = @($j | Where-Object { $_.Groups[1].Value.ToUpper() -eq $coul })
        if ($ec.Count -eq 1 -and $jc.Count -eq 1) { [void]$termes[$cle].jpn.Add($jc[0].Groups[2].Value.Trim()) }
      }
    }
  }
}
if (Test-Path $Sortie) {
  foreach ($a in Import-Csv $Sortie -Delimiter ';' -Encoding utf8) {
    $cle = "$($a.couleur)|$($a.eng)"
    if ($a.fr -and $termes.ContainsKey($cle)) { $termes[$cle].fr = $a.fr }
  }
}
$termes.Values | Sort-Object { $_.couleur }, { -$_.occurrences }, { $_.eng } | ForEach-Object {
  [pscustomobject]@{ couleur = $_.couleur; eng = $_.eng; jpn = ($_.jpn -join ' / '); occurrences = $_.occurrences; exemple = $_.exemple; fr = $_.fr }
} | Export-Csv $Sortie -Delimiter ';' -Encoding utf8BOM -NoTypeInformation
$termes.Values | Group-Object { $_.couleur } | ForEach-Object {
  "{0} : {1,4} termes, {2,5} occurrences  ex. {3}" -f $_.Name, $_.Count, ($_.Group | ForEach-Object { $_.occurrences } | Measure-Object -Sum).Sum, (($_.Group | Sort-Object { -$_.occurrences } | Select-Object -First 8 | ForEach-Object { $_.eng }) -join ' | ')
}

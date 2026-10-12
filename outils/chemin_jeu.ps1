# Renvoie le dossier d'installation de La-Mulana 2.
# Ordre : fichier chemin_jeu.txt à la racine du dépôt, variable LAMULANA2_PATH, puis emplacement Steam par défaut.
$fichier = Join-Path $PSScriptRoot '..\chemin_jeu.txt'
if (Test-Path $fichier) { return (Get-Content $fichier -TotalCount 1).Trim() }
if ($env:LAMULANA2_PATH) { return $env:LAMULANA2_PATH }
return 'C:\Program Files (x86)\Steam\steamapps\common\La-Mulana 2'

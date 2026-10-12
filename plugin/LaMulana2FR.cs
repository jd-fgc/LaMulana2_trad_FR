using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using System.Text;
using System.Text.RegularExpressions;
using BepInEx;
using BepInEx.Logging;
using HarmonyLib;
using L2Base;
using L2Menu;
using L2Word;

namespace LaMulana2FR
{
	// Remplace la langue "chi" du jeu par le français : textes lus dans fr.txt, polices reprises du slot anglais.
	[BepInPlugin("fr.lamulana2.traduction", "La-Mulana 2 FR", "0.9.0")]
	public class Plugin : BaseUnityPlugin
	{
		private const int SlotAnglais = 1;

		private const int SlotFrancais = 2;

		private static readonly Regex Couleur = new Regex("<color=#[0-9A-Fa-f]{8}>(.*?)</color>", RegexOptions.Singleline);

		private static ManualLogSource log;

		private static string fichierTextes;

		private void Awake()
		{
			log = Logger;
			fichierTextes = Path.Combine(Path.GetDirectoryName(Info.Location), "fr.txt");
			Harmony harmony = new Harmony("fr.lamulana2.traduction");
			HarmonyMethod polices = new HarmonyMethod(typeof(Plugin).GetMethod("PolicesPostfix", BindingFlags.Static | BindingFlags.NonPublic));
			harmony.Patch(AccessTools.Method(typeof(FontSetContr), "Start"), null, polices);
			harmony.Patch(AccessTools.Method(typeof(FontSetContrTMP), "Start"), null, polices);
			// setL2System est appelé une fois les bases de textes construites, avant tout affichage.
			harmony.Patch(AccessTools.Method(typeof(FontSetContr), "setL2System"), null, new HarmonyMethod(typeof(Plugin).GetMethod("TextesPostfix", BindingFlags.Static | BindingFlags.NonPublic)));
		}

		private static void PolicesPostfix(object __instance)
		{
			Array jeux = AccessTools.Field(__instance.GetType(), "fonts").GetValue(__instance) as Array;
			if (jeux == null)
			{
				return;
			}
			foreach (Array jeu in jeux)
			{
				if (jeu != null && jeu.Length > SlotFrancais)
				{
					jeu.SetValue(jeu.GetValue(SlotAnglais), SlotFrancais);
				}
			}
		}

		private static void TextesPostfix(L2System l2sys)
		{
			try
			{
				AppliquerTextes(l2sys);
			}
			catch (Exception e)
			{
				log.LogError("Echec du chargement de la traduction : " + e);
			}
		}

		private static void AppliquerTextes(L2System sys)
		{
			if (!File.Exists(fichierTextes))
			{
				log.LogError("Fichier introuvable : " + fichierTextes);
				return;
			}
			Dictionary<string, L2WordBaseClass> bases = new Dictionary<string, L2WordBaseClass>();
			foreach (FieldInfo champ in typeof(L2System).GetFields(BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic))
			{
				if (typeof(L2WordBaseClass).IsAssignableFrom(champ.FieldType))
				{
					L2WordBaseClass db = champ.GetValue(sys) as L2WordBaseClass;
					if (db != null)
					{
						bases[db.GetType().Name] = db;
					}
				}
			}
			int ok = 0;
			int erreurs = 0;
			// Format d'une ligne : base, feuille, n° de ligne, colonne, texte (séparés par des tabulations)
			foreach (string ligne in File.ReadAllLines(fichierTextes, Encoding.UTF8))
			{
				if (ligne.Length == 0 || ligne[0] == '#')
				{
					continue;
				}
				string[] p = ligne.Split(new char[1] { '\t' }, 5);
				L2WordBaseClass db;
				if (p.Length == 5 && bases.TryGetValue(p[0], out db) && Remplacer(db, p[1], int.Parse(p[2]), p[3], Desechapper(p[4])))
				{
					ok++;
				}
				else if (erreurs++ < 10)
				{
					log.LogWarning("Ligne ignorée : " + (ligne.Length > 80 ? ligne.Substring(0, 80) : ligne));
				}
			}
			log.LogInfo(ok + " textes remplacés, " + erreurs + " lignes ignorées.");
		}

		private static bool Remplacer(L2WordBaseClass db, string feuille, int ligne, string colonne, string texte)
		{
			int s = Array.IndexOf(db.seetName, feuille);
			if (s < 0 || ligne < 1 || ligne >= db.cellData[s].Length)
			{
				return false;
			}
			string[][] entete = db.cellData[s][0];
			for (int c = 0; c < entete.Length; c++)
			{
				string nom = entete[c].Length >= 2 ? entete[c][1] : entete[c][0];
				if (nom == colonne && c < db.cellData[s][ligne].Length)
				{
					db.cellData[s][ligne][c] = EnSegments(texte);
					return true;
				}
			}
			return false;
		}

		// Le jeu attend des triplets [balise couleur, texte, </color>] ; le texte hors balise est blanc.
		private static string[] EnSegments(string texte)
		{
			List<string> seg = new List<string>();
			int pos = 0;
			foreach (Match m in Couleur.Matches(texte))
			{
				if (m.Index > pos)
				{
					AjouterBlanc(seg, texte.Substring(pos, m.Index - pos));
				}
				seg.Add(m.Value.Substring(0, 17));
				seg.Add(m.Groups[1].Value);
				seg.Add("</color>");
				pos = m.Index + m.Length;
			}
			if (pos < texte.Length || seg.Count == 0)
			{
				AjouterBlanc(seg, texte.Substring(pos));
			}
			return seg.ToArray();
		}

		private static void AjouterBlanc(List<string> seg, string texte)
		{
			seg.Add("<color=#FFFFFFFF>");
			seg.Add(texte);
			seg.Add("</color>");
		}

		private static string Desechapper(string s)
		{
			StringBuilder sb = new StringBuilder(s.Length);
			for (int i = 0; i < s.Length; i++)
			{
				if (s[i] == '\\' && i + 1 < s.Length)
				{
					i++;
					sb.Append(s[i] == 'n' ? '\n' : s[i]);
				}
				else
				{
					sb.Append(s[i]);
				}
			}
			return sb.ToString();
		}
	}
}

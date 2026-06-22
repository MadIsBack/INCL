using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Windows.Forms;

namespace Komponenten_V63_CSharp
{
    public static class Sprache_V63
    {
        // Language constants
        public const int DEBUGSpracheFILE = 0;
        
        public const int SP_DEUTSCH = 0;
        public const int SP_SPANISCH = 5000;
        public const int SP_DAENISCH = 10000;
        public const int SP_USENGLISCH = 15000;
        public const int SP_TSCHECHISCH = 20000;
        public const int SP_SCHWEDISCH = 25000;
        public const int SP_POLNISCH = 30000;
        
        public const int SP_Anzahl = 7;
        
        public const int SP_FORMAT_EUROPE = 0;
        public const int SP_FORMAT_USA = 1;
        
        public const int REPORT_DEUTSCH = 0;
        public const int REPORT_ENGLISCH = 1;
        
        public const int MaxString = 255;
        public const int Offset = 1000;

        // Language structures
        public class TSpracheWort
        {
            public string DE { get; set; } = "";
            public string Andere { get; set; } = "";
        }

        // Global variables
        public static int SprachWortAnzahl { get; set; } = 0;
        public static List<TSpracheWort> SpracheWort { get; set; } = new List<TSpracheWort>();
        public static List<TSpracheWort> CustomWort { get; set; } = new List<TSpracheWort>();
        
        public static int SpracheNr { get; set; } = SP_DEUTSCH;
        public static int Sprache2 { get; set; } = SP_USENGLISCH;
        public static int Sprache_Format { get; set; } = SP_FORMAT_EUROPE;
        public static char DBSeparator { get; set; } = ',';

        private static Dictionary<string, string> languageDictionary = new Dictionary<string, string>();
        
        // Character set for language processing
        private static readonly HashSet<char> SetSym = new HashSet<char>
        {
            '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
            '=', ':', ';', '!', '.', ' ', '&', '?', ',', '-', '>', '<',
            '^', '_', '"', '\'', '#', '(', ')', '[', ']', '*', '+', '/', '\\', '%'
        };

        static Sprache_V63()
        {
            // Initialize with default language
            LoadLanguageArray();
        }

        public static string GetL(string T)
        {
            if (string.IsNullOrEmpty(T))
                return T;

            // Check if we have a translation
            if (languageDictionary.TryGetValue(T, out string translation))
                return translation;

            // Return original if no translation found
            return T;
        }

        public static void MakeFormLanguage(Control form)
        {
            if (form == null)
                return;

            Application.DoEvents();
            
            // Process form caption and hint
            if (form.Tag == 0 || form.Tag == null)
            {
                form.Text = GetL(form.Text);
                // Note: In WinForms, ToolTip is handled differently
            }

            // Recursively process all controls
            ProcessControls(form);
        }

        private static void ProcessControls(Control control)
        {
            if (control == null)
                return;

            // Process this control
            ProcessControl(control);

            // Process all child controls
            foreach (Control child in control.Controls)
            {
                ProcessControls(child);
            }
        }

        private static void ProcessControl(Control control)
        {
            if (control.Tag != null && (int)control.Tag != 0)
                return; // Skip if Tag is not 0

            switch (control)
            {
                case Label label:
                    label.Text = GetL(label.Text);
                    // ToolTip would be handled separately in WinForms
                    break;
                    
                case TextBox textBox:
                    textBox.Text = GetL(textBox.Text);
                    break;
                    
                case Button button:
                    button.Text = GetL(button.Text);
                    break;
                    
                case CheckBox checkBox:
                    checkBox.Text = GetL(checkBox.Text);
                    break;
                    
                case RadioButton radioButton:
                    radioButton.Text = GetL(radioButton.Text);
                    break;
                    
                case ComboBox comboBox:
                    comboBox.Text = GetL(comboBox.Text);
                    // Process items
                    for (int i = 0; i < comboBox.Items.Count; i++)
                    {
                        comboBox.Items[i] = GetL(comboBox.Items[i].ToString());
                    }
                    break;
                    
                case ListBox listBox:
                    for (int i = 0; i < listBox.Items.Count; i++)
                    {
                        listBox.Items[i] = GetL(listBox.Items[i].ToString());
                    }
                    break;
                    
                case CheckedListBox checkedListBox:
                    for (int i = 0; i < checkedListBox.Items.Count; i++)
                    {
                        checkedListBox.Items[i] = GetL(checkedListBox.Items[i].ToString());
                    }
                    break;
                    
                case TabPage tabPage:
                    tabPage.Text = GetL(tabPage.Text);
                    break;
                    
                case GroupBox groupBox:
                    groupBox.Text = GetL(groupBox.Text);
                    break;
                    
                case RichTextBox richTextBox:
                    richTextBox.Text = GetL(richTextBox.Text);
                    break;
            }
        }

        public static void MakeReportLanguage(Form form)
        {
            // For Windows Forms
            MakeFormLanguage(form);
        }

        public static void MakeReportLanguage(object quickRep)
        {
            // For QuickReport - placeholder for now
            // In a real implementation, this would process QuickReport components
        }

        public static void MakeEnviroment(CO_Query Q)
        {
            // Set up environment based on language settings
            if (Sprache_Format == SP_FORMAT_USA)
            {
                CultureInfo.CurrentCulture = new CultureInfo("en-US");
                DBSeparator = '.';
            }
            else
            {
                CultureInfo.CurrentCulture = new CultureInfo("de-DE");
                DBSeparator = ',';
            }
        }

        public static int MessageDialog(string Msg, MessageBoxIcon DlgType, MessageBoxButtons Buttons)
        {
            string Cap = "";
            
            switch (DlgType)
            {
                case MessageBoxIcon.Warning:
                    Cap = GetL("Warnung");
                    break;
                case MessageBoxIcon.Error:
                    Cap = GetL("Fehler");
                    break;
                case MessageBoxIcon.Information:
                    Cap = GetL("Information");
                    break;
                case MessageBoxIcon.Question:
                    Cap = GetL("Bestätigung");
                    break;
            }

            return (int)MessageBox.Show(Msg, Cap, Buttons, DlgType);
        }

        public static int LoadLanguageArray()
        {
            try
            {
                // Try to load language file based on current language
                string languageFile = GetLanguageFileName();
                
                if (File.Exists(languageFile))
                {
                    LoadLanguageFromFile(languageFile);
                    return SpracheWort.Count;
                }
                else
                {
                    // Load default language (German)
                    LoadDefaultLanguage();
                    return SpracheWort.Count;
                }
            }
            catch
            {
                LoadDefaultLanguage();
                return SpracheWort.Count;
            }
        }

        private static string GetLanguageFileName()
        {
            // Determine language file based on current language setting
            switch (SpracheNr)
            {
                case SP_DEUTSCH: return "lang_de.dat";
                case SP_SPANISCH: return "lang_es.dat";
                case SP_DAENISCH: return "lang_da.dat";
                case SP_USENGLISCH: return "lang_en.dat";
                case SP_TSCHECHISCH: return "lang_cz.dat";
                case SP_SCHWEDISCH: return "lang_se.dat";
                case SP_POLNISCH: return "lang_pl.dat";
                default: return "lang_de.dat";
            }
        }

        private static void LoadDefaultLanguage()
        {
            // Load basic translations for testing
            SpracheWort.Clear();
            languageDictionary.Clear();
            
            // Add some basic translations
            AddTranslation("Warnung", "Warning");
            AddTranslation("Fehler", "Error");
            AddTranslation("Information", "Information");
            AddTranslation("Bestätigung", "Confirmation");
            AddTranslation("OK", "OK");
            AddTranslation("Abbrechen", "Cancel");
            AddTranslation("Ja", "Yes");
            AddTranslation("Nein", "No");
        }

        private static void LoadLanguageFromFile(string fileName)
        {
            try
            {
                // Read language file and parse translations
                string[] lines = File.ReadAllLines(fileName);
                
                SpracheWort.Clear();
                languageDictionary.Clear();
                
                foreach (string line in lines)
                {
                    if (string.IsNullOrWhiteSpace(line) || line.StartsWith("#"))
                        continue;
                    
                    // Parse line: "GermanText=TranslatedText"
                    int equalsPos = line.IndexOf('=');
                    if (equalsPos > 0)
                    {
                        string german = line.Substring(0, equalsPos).Trim();
                        string translation = line.Substring(equalsPos + 1).Trim();
                        AddTranslation(german, translation);
                    }
                }
            }
            catch
            {
                LoadDefaultLanguage();
            }
        }

        private static void AddTranslation(string german, string translation)
        {
            if (!string.IsNullOrEmpty(german))
            {
                SpracheWort.Add(new TSpracheWort { DE = german, Andere = translation });
                languageDictionary[german] = translation;
            }
        }

        public static string GetNext(ref string D)
        {
            if (string.IsNullOrEmpty(D))
                return "";

            // Find next token separated by SetSym characters
            int pos = 0;
            while (pos < D.Length && SetSym.Contains(D[pos]))
            {
                pos++;
            }

            if (pos >= D.Length)
            {
                string result = D;
                D = "";
                return result;
            }

            int start = pos;
            while (pos < D.Length && !SetSym.Contains(D[pos]))
            {
                pos++;
            }

            string result = D.Substring(start, pos - start);
            D = pos < D.Length ? D.Substring(pos) : "";
            return result;
        }
    }
}

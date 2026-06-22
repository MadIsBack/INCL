// <summary>
// Sprache_V63.cs - C# translation of Sprache_V63.pas
// Language handling functions
// </summary>

using System;
using System.Collections.Generic;

namespace INCLService_CSharp
{
    /// <summary>
    /// Language class
    /// </summary>
    public static class Sprache_V63
    {
        private static Dictionary<string, Dictionary<string, string>> languageStrings = new Dictionary<string, Dictionary<string, string>>();
        private static string currentLanguage = "de";

        /// <summary>
        /// Initialize language
        /// </summary>
        public static void InitLanguage(string lang = "de")
        {
            try
            {
                currentLanguage = lang;
                // Load language strings from database or files
                // This is a simplified implementation
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in InitLanguage: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Get language string
        /// </summary>
        public static string GetL(string key, string defaultValue = "")
        {
            try
            {
                if (languageStrings.ContainsKey(currentLanguage) && 
                    languageStrings[currentLanguage].ContainsKey(key))
                {
                    return languageStrings[currentLanguage][key];
                }
                return defaultValue;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in GetL: " + ex.Message, 0);
                return defaultValue;
            }
        }

        /// <summary>
        /// Set language string
        /// </summary>
        public static void SetL(string key, string value, string lang = "")
        {
            try
            {
                if (string.IsNullOrEmpty(lang))
                    lang = currentLanguage;
                
                if (!languageStrings.ContainsKey(lang))
                    languageStrings[lang] = new Dictionary<string, string>();
                
                languageStrings[lang][key] = value;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in SetL: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Load language from database
        /// </summary>
        public static void LoadLanguageFromDB(CO_Query query, string lang)
        {
            try
            {
                string sql = "SELECT * FROM LANGUAGE_STRINGS WHERE Language = '" + lang + "'";
                SQL_fuc.SQL_Get(query, sql);
                
                if (!languageStrings.ContainsKey(lang))
                    languageStrings[lang] = new Dictionary<string, string>();
                
                while (!query.EOF)
                {
                    string key = query.FieldByName("StringKey").AsString;
                    string value = query.FieldByName("StringValue").AsString;
                    languageStrings[lang][key] = value;
                    query.Next();
                }
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in LoadLanguageFromDB: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Get current language
        /// </summary>
        public static string GetCurrentLanguage()
        {
            return currentLanguage;
        }

        /// <summary>
        /// Set current language
        /// </summary>
        public static void SetCurrentLanguage(string lang)
        {
            currentLanguage = lang;
        }

        /// <summary>
        /// Get available languages
        /// </summary>
        public static string[] GetAvailableLanguages()
        {
            try
            {
                string[] languages = new string[languageStrings.Count];
                languageStrings.Keys.CopyTo(languages, 0);
                return languages;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in GetAvailableLanguages: " + ex.Message, 0);
                return new string[0];
            }
        }
    }
}

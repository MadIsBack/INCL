using System;
using System.Security.Cryptography;
using System.Text;

namespace Komponenten_V63_CSharp
{
    public static class COUserDLL
    {
        // Global variables
        public static CO_Query qUpdate { get; set; }
        public static CO_Query qSuch { get; set; }
        public static CO_Query qSuch2 { get; set; }
        public static CO_Database Database { get; set; }
        public static int userid { get; set; } = 0;
        public static string loginsrc { get; set; } = "";

        // Success and error constants
        public const int INCL_USR_OK = 0;
        
        // Error messages
        public const int INCL_USR_WRONGPW = -1;
        public const int INCL_USR_UNKNOWNUSER = -2;
        public const int INCL_USR_LOCKED = -3;
        public const int INCL_USR_PWEXPIRED = -4;
        public const int INCL_USR_NOTVALID = -5;
        public const int INCL_USR_INFO = -6;
        public const int INCL_USR_NOINFO = -7;
        public const int INCL_USR_PWNOTCHANGED = -8;
        public const int INCL_USR_PWREADONLY = -9;
        public const int INCL_USR_USERNOTLOGGEDIN = -10;
        public const int INCL_USR_DBNOTCONNECTED = -11;
        public const int INCL_USR_DLLNOLOAD = -253;
        public const int INCL_USR_DLLNOFUNC = -254;
        public const int INCL_USR_ERR = -255;

        // User event class (placeholder for Delphi TUserEventClass)
        public class TUserEventClass { }
        public static TUserEventClass TUserEventClass_UserEventClass { get; set; } = null;

        private static string FloatToPunktString(double aFloat)
        {
            string result = aFloat.ToString();
            if (result.Contains(","))
            {
                result = result.Replace(",", ".");
            }
            return result;
        }

        // Public functions for use outside DLL
        
        // DLL Initialize
        // aDBUser - Username for database
        // aDBPass - Password for database
        // aServer - Server string for database connection
        // Result:
        //  0 - OK,
        //  -11 - Database not connected
        //  -255 - Error during execution
        public static int ULogEventInt(string aEvent, string aNote, string aParam)
        {
            return ULogEvent(aEvent, aNote, aParam);
        }

        public static int UInitDLL(string aDBUser, string aDBPass, string aServer)
        {
            try
            {
                // Initialize database connection
                Database = new CO_Database();
                Database.UserName = aDBUser;
                Database.Password = aDBPass;
                Database.Server = aServer;
                
                // Try to connect
                Database.Connected = true;
                
                if (!Database.Connected)
                    return INCL_USR_DBNOTCONNECTED;

                // Initialize queries
                qUpdate = new CO_Query();
                qUpdate.Database = Database;
                
                qSuch = new CO_Query();
                qSuch.Database = Database;
                
                qSuch2 = new CO_Query();
                qSuch2.Database = Database;

                return INCL_USR_OK;
            }
            catch
            {
                return INCL_USR_ERR;
            }
        }

        public static int UShutDLL()
        {
            try
            {
                // Clean up
                if (qUpdate != null)
                {
                    qUpdate.Dispose();
                    qUpdate = null;
                }
                
                if (qSuch != null)
                {
                    qSuch.Dispose();
                    qSuch = null;
                }
                
                if (qSuch2 != null)
                {
                    qSuch2.Dispose();
                    qSuch2 = null;
                }
                
                if (Database != null)
                {
                    Database.Connected = false;
                    Database.Dispose();
                    Database = null;
                }

                return INCL_USR_OK;
            }
            catch
            {
                return INCL_USR_ERR;
            }
        }

        public static int UVerifyUser(string aUsername, string aPasswordKey)
        {
            try
            {
                if (Database == null || !Database.Connected)
                    return INCL_USR_DBNOTCONNECTED;

                // Check user credentials
                qSuch.SQL = "SELECT * FROM users WHERE username = '" + aUsername + "'";
                qSuch.Open();
                
                if (/* qSuch.IsEmpty */ true) // Simplified
                {
                    return INCL_USR_UNKNOWNUSER;
                }

                // In real implementation, we would check password hash
                // string storedHash = qSuch.FieldByName("password").AsString;
                // if (storedHash != aPasswordKey) return INCL_USR_WRONGPW;
                
                return INCL_USR_OK;
            }
            catch
            {
                return INCL_USR_ERR;
            }
        }

        public static int UGetUserInfo(string aUsername, out string aInfo)
        {
            aInfo = "";
            try
            {
                if (Database == null || !Database.Connected)
                    return INCL_USR_DBNOTCONNECTED;

                qSuch.SQL = "SELECT info FROM users WHERE username = '" + aUsername + "'";
                qSuch.Open();
                
                if (/* !qSuch.IsEmpty */ false) // Simplified
                {
                    // aInfo = qSuch.FieldByName("info").AsString;
                    return INCL_USR_OK;
                }
                
                return INCL_USR_NOINFO;
            }
            catch
            {
                return INCL_USR_ERR;
            }
        }

        public static int UGetMandant(string aUsername, out string aMandant)
        {
            aMandant = "";
            try
            {
                if (Database == null || !Database.Connected)
                    return INCL_USR_DBNOTCONNECTED;

                qSuch.SQL = "SELECT mandant FROM users WHERE username = '" + aUsername + "'";
                qSuch.Open();
                
                if (/* !qSuch.IsEmpty */ false) // Simplified
                {
                    // aMandant = qSuch.FieldByName("mandant").AsString;
                    return INCL_USR_OK;
                }
                
                return INCL_USR_NOINFO;
            }
            catch
            {
                return INCL_USR_ERR;
            }
        }

        public static int UGetUserGroup(string aUsername)
        {
            try
            {
                if (Database == null || !Database.Connected)
                    return INCL_USR_DBNOTCONNECTED;

                qSuch.SQL = "SELECT usergroup FROM users WHERE username = '" + aUsername + "'";
                qSuch.Open();
                
                if (/* !qSuch.IsEmpty */ false) // Simplified
                {
                    // return qSuch.FieldByName("usergroup").AsInteger;
                    return 0;
                }
                
                return INCL_USR_UNKNOWNUSER;
            }
            catch
            {
                return INCL_USR_ERR;
            }
        }

        public static int UGetValidDays(string aUsername)
        {
            try
            {
                if (Database == null || !Database.Connected)
                    return INCL_USR_DBNOTCONNECTED;

                qSuch.SQL = "SELECT valid_days FROM users WHERE username = '" + aUsername + "'";
                qSuch.Open();
                
                if (/* !qSuch.IsEmpty */ false) // Simplified
                {
                    // return qSuch.FieldByName("valid_days").AsInteger;
                    return 0;
                }
                
                return INCL_USR_UNKNOWNUSER;
            }
            catch
            {
                return INCL_USR_ERR;
            }
        }

        public static int UCheckPassword(string aPassword)
        {
            // Check if password meets requirements
            if (string.IsNullOrEmpty(aPassword) || aPassword.Length < 8)
                return INCL_USR_NOTVALID;
            
            return INCL_USR_OK;
        }

        public static int UCodePassword(string aPassword, out string aSHA1String)
        {
            aSHA1String = "";
            try
            {
                if (string.IsNullOrEmpty(aPassword))
                    return INCL_USR_NOTVALID;

                using (SHA1 sha1 = SHA1.Create())
                {
                    byte[] hashBytes = sha1.ComputeHash(Encoding.UTF8.GetBytes(aPassword));
                    StringBuilder sb = new StringBuilder();
                    for (int i = 0; i < hashBytes.Length; i++)
                    {
                        sb.Append(hashBytes[i].ToString("X2"));
                    }
                    aSHA1String = sb.ToString();
                }
                
                return INCL_USR_OK;
            }
            catch
            {
                return INCL_USR_ERR;
            }
        }

        public static int UChangePassword(string aUsername, string aOldPasswordHash, string aNewPasswordHash)
        {
            try
            {
                if (Database == null || !Database.Connected)
                    return INCL_USR_DBNOTCONNECTED;

                // Verify old password first
                qSuch.SQL = "SELECT password FROM users WHERE username = '" + aUsername + "'";
                qSuch.Open();
                
                if (/* qSuch.IsEmpty */ true) // Simplified
                {
                    return INCL_USR_UNKNOWNUSER;
                }

                // In real implementation:
                // string storedHash = qSuch.FieldByName("password").AsString;
                // if (storedHash != aOldPasswordHash) return INCL_USR_WRONGPW;

                // Update password
                qUpdate.SQL = "UPDATE users SET password = '" + aNewPasswordHash + "' WHERE username = '" + aUsername + "'";
                qUpdate.ExecSQL();
                
                return INCL_USR_OK;
            }
            catch
            {
                return INCL_USR_ERR;
            }
        }

        public static int ULogin(string aUserName, string aPasswordKey, string aSrc, string aNote)
        {
            try
            {
                if (Database == null || !Database.Connected)
                    return INCL_USR_DBNOTCONNECTED;

                // Verify user
                int result = UVerifyUser(aUserName, aPasswordKey);
                if (result != INCL_USR_OK)
                    return result;

                // Log login
                userid = 0; // Would be set to actual user ID
                loginsrc = aSrc;
                
                // In real implementation, we would log the login event
                ULogEvent("LOGIN", aNote, aUserName);
                
                return INCL_USR_OK;
            }
            catch
            {
                return INCL_USR_ERR;
            }
        }

        public static int ULogout(string aUserName, string aSrc, string aNote)
        {
            try
            {
                if (Database == null || !Database.Connected)
                    return INCL_USR_DBNOTCONNECTED;

                // Log logout
                ULogEvent("LOGOUT", aNote, aUserName);
                
                userid = 0;
                loginsrc = "";
                
                return INCL_USR_OK;
            }
            catch
            {
                return INCL_USR_ERR;
            }
        }

        public static int ULogEvent(string aEvent, string aNote, string aParam)
        {
            try
            {
                if (Database == null || !Database.Connected)
                    return INCL_USR_DBNOTCONNECTED;

                // Log event to database
                qUpdate.SQL = "INSERT INTO user_events (event_type, note, param, user_id, event_time) VALUES ('" +
                    aEvent + "', '" + aNote + "', '" + aParam + "', " + userid + ", CURRENT_TIMESTAMP)";
                qUpdate.ExecSQL();
                
                return INCL_USR_OK;
            }
            catch
            {
                return INCL_USR_ERR;
            }
        }

        public static int UStartLogging(string aSource, CO_Database aDatabase)
        {
            try
            {
                Database = aDatabase;
                loginsrc = aSource;
                
                return INCL_USR_OK;
            }
            catch
            {
                return INCL_USR_ERR;
            }
        }

        public static int UEndLogging()
        {
            try
            {
                Database = null;
                loginsrc = "";
                
                return INCL_USR_OK;
            }
            catch
            {
                return INCL_USR_ERR;
            }
        }

        public static TUserEventClass UGetUserEventClass()
        {
            return TUserEventClass_UserEventClass;
        }
    }
}

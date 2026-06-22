// <summary>
// CO_User.cs - C# translation of CO_User.pas
// User management classes
// </summary>

using System;
using System.Collections.Generic;

namespace INCLService_CSharp
{
    /// <summary>
    /// User class
    /// </summary>
    public class CO_User
    {
        public string UserName { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public int UserID { get; set; } = 0;
        public int GroupID { get; set; } = 0;
        public bool Active { get; set; } = true;
        
        public CO_User()
        {
        }
        
        public CO_User(string userName, string password)
        {
            UserName = userName;
            Password = password;
        }
        
        /// <summary>
        /// Authenticate user
        /// </summary>
        public bool Authenticate(CO_Query query)
        {
            try
            {
                string sql = "SELECT COUNT(*) as cnt FROM USERS WHERE UserName = '" + UserName + 
                    "' AND Password = '" + Password + "'";
                SQL_fuc.SQL_Get(query, sql);
                return query.FieldByName("cnt").AsInteger > 0;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in CO_User.Authenticate: " + ex.Message, 0);
                return false;
            }
        }
        
        /// <summary>
        /// Load user data from database
        /// </summary>
        public bool Load(CO_Query query, string userName)
        {
            try
            {
                string sql = "SELECT * FROM USERS WHERE UserName = '" + userName + "'";
                SQL_fuc.SQL_Get(query, sql);
                if (!query.EOF)
                {
                    UserName = query.FieldByName("UserName").AsString;
                    FullName = query.FieldByName("FullName").AsString;
                    UserID = query.FieldByName("UserID").AsInteger;
                    GroupID = query.FieldByName("GroupID").AsInteger;
                    Active = query.FieldByName("Active").AsInteger == 1;
                    return true;
                }
                return false;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in CO_User.Load: " + ex.Message, 0);
                return false;
            }
        }
    }
    
    /// <summary>
    /// User list class
    /// </summary>
    public class CO_UserList : List<CO_User>
    {
        /// <summary>
        /// Load all users from database
        /// </summary>
        public void LoadAll(CO_Query query)
        {
            try
            {
                Clear();
                string sql = "SELECT * FROM USERS ORDER BY UserName";
                SQL_fuc.SQL_Get(query, sql);
                while (!query.EOF)
                {
                    CO_User user = new CO_User();
                    user.UserName = query.FieldByName("UserName").AsString;
                    user.FullName = query.FieldByName("FullName").AsString;
                    user.UserID = query.FieldByName("UserID").AsInteger;
                    user.GroupID = query.FieldByName("GroupID").AsInteger;
                    user.Active = query.FieldByName("Active").AsInteger == 1;
                    Add(user);
                    query.Next();
                }
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in CO_UserList.LoadAll: " + ex.Message, 0);
            }
        }
    }
}

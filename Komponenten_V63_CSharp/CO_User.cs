using System;
using System.Security.Cryptography;
using System.Text;

namespace Komponenten_V63_CSharp
{
    public class CO_User : IDisposable
    {
        private string fHash = "";
        private MD5 fCoderMD5;

        public string Hash => fHash;

        public string Password
        {
            set => SetPassword(value);
        }

        public CO_User()
        {
            fCoderMD5 = MD5.Create();
        }

        public bool CheckPassword(string aPassword)
        {
            string hashedPassword = ComputeMD5Hash(aPassword);
            return fHash == hashedPassword;
        }

        private void SetPassword(string Value)
        {
            fHash = ComputeMD5Hash(Value);
        }

        private string ComputeMD5Hash(string input)
        {
            if (fCoderMD5 == null)
                fCoderMD5 = MD5.Create();

            byte[] inputBytes = Encoding.UTF8.GetBytes(input);
            byte[] hashBytes = fCoderMD5.ComputeHash(inputBytes);
            
            StringBuilder sb = new StringBuilder();
            for (int i = 0; i < hashBytes.Length; i++)
            {
                sb.Append(hashBytes[i].ToString("X2"));
            }
            return sb.ToString();
        }

        public void Dispose()
        {
            if (fCoderMD5 != null)
            {
                fCoderMD5.Dispose();
                fCoderMD5 = null;
            }
        }

        ~CO_User()
        {
            Dispose();
        }
    }

    public class CO_UserGroup
    {
        // Empty class as in Delphi original
    }

    public class CO_View
    {
        // Empty class as in Delphi original
    }
}

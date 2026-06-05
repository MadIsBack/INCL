using System;
using System.Windows.Forms;
using INCLUDIS.Utils.CommonDB.Properties;

namespace INCLUDIS.Utils.CommonDB
{
    public partial class CommonDbControl : UserControl
    {
        public delegate void ConnectedDelegate();
        public event ConnectedDelegate OnConnect;

        public CommonDB Cdb { get; private set; }

        public CommonDbControl()
        {
            InitializeComponent();
            tbUser.Text = Settings.Default.DBUser;
            tbPassword.Text = Settings.Default.DBPassword;
            tbServer.Text = Settings.Default.DBServer;

            cbType.DataSource = Enum.GetValues(typeof(CommonDB.DatabaseType));
            cbType.SelectedItem = (CommonDB.DatabaseType)Settings.Default.DBType;
            tbCatalog.Text = Settings.Default.DBCatalog;
            cbUnicode.Checked = Settings.Default.DBUnicode;
        }

        private void btnConnect_Click(object sender, EventArgs e)
        {
            if (Cdb != null /*&& Cdb.IsOpen*/)
            {
                //Cdb.Close(true);
                Cdb = null;
                tbUser.Enabled = true;
                tbPassword.Enabled = true;
                tbServer.Enabled = true;
                cbType.Enabled = true;
                tbCatalog.Enabled = true;
                cbUnicode.Enabled = true;
                btnConnect.Text = "Connect";
                lState.Text = "State: Closed";
            }
            else
            {
                var dbType = (CommonDB.DatabaseType) cbType.SelectedValue;

                Settings.Default.DBUser = tbUser.Text;
                Settings.Default.DBPassword = tbPassword.Text;
                Settings.Default.DBServer = tbServer.Text;
                Settings.Default.DBType = (int) cbType.SelectedValue;
                Settings.Default.DBCatalog = tbCatalog.Text;
                Settings.Default.DBUnicode = cbUnicode.Checked;
                Settings.Default.Save();

                Cdb = new CommonDB(dbType, tbUser.Text, tbPassword.Text, tbServer.Text, tbCatalog.Text,
                                   cbUnicode.Checked);
                var open = Cdb.CheckDbState();
                lState.Text = "State: " + (open ? "Open" : "Closed");
                if (open)
                {
                    tbUser.Enabled = false;
                    tbPassword.Enabled = false;
                    tbServer.Enabled = false;
                    cbType.Enabled = false;
                    tbCatalog.Enabled = false;
                    cbUnicode.Enabled = false;
                    btnConnect.Text = "Disconnect";
                    if (OnConnect != null)
                        OnConnect();
                }
            }

        }
    }
}

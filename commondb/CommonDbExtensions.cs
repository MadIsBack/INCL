using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace INCLUDIS.Utils.CommonDB
{
    public static class CommonDbExtensions
    {
        /// <summary>
        /// Konvertierung von DateTime nach Invariant Culture OA Date
        /// </summary>
        /// <param name="dateTime"></param>
        /// <returns></returns>
        public static string ToSqlOa(this DateTime dateTime)
        {
            return dateTime.ToOADate().ToString(System.Globalization.CultureInfo.InvariantCulture);
        }

        /// <summary>
        /// Erzeugt einen CommonReader für das übergebene SQL-Statement.
        /// Erweiterungsmethode auf CommonDB (wird im Dienst als _database.ExecuteReader(sql) genutzt).
        /// </summary>
        public static CommonReader ExecuteReader(this CommonDB db, string sql)
        {
            if (db == null)
                return null;
            return db.GetReader(sql);
        }

        /// <summary>
        /// Erzeugt einen neuen CommonCommand für das übergebene SQL-Statement.
        /// Erweiterungsmethode auf CommonDB.
        /// </summary>
        public static CommonCommand CreateCommand(this CommonDB db, string sql)
        {
            if (db == null)
                return null;
            var cmd = db.NewCommonCommand();
            if (cmd != null && sql != null)
                cmd.CommandText = sql;
            return cmd;
        }

        /// <summary>
        /// Führt ein Nicht-Query-SQL-Statement asynchron aus.
        /// Erweiterungsmethode auf CommonDB.
        /// </summary>
        public static Task<int> ExecuteNonQueryAsync(this CommonDB db, string sql, CancellationToken cancellationToken)
        {
            if (db == null)
                return Task.FromResult(0);
            return Task.Run(() => db.ExecuteNonQuery(sql), cancellationToken);
        }

        /// <summary>
        /// Führt ein Nicht-Query-SQL-Statement asynchron aus.
        /// Erweiterungsmethode auf CommonDB (ohne CancellationToken).
        /// </summary>
        public static Task<int> ExecuteNonQueryAsync(this CommonDB db, string sql)
        {
            return ExecuteNonQueryAsync(db, sql, CancellationToken.None);
        }

        /// <summary>
        /// Liest den naechsten Datensatz asynchron. Erweiterungsmethode auf CommonReader,
        /// da der zugrundeliegende DbDataReader.ReadAsync(CancellationToken) nur in net8
        /// verfuegbar ist, CommonReader diesen aber nicht direkt nach aussen gibt.
        /// </summary>
        public static Task<bool> ReadAsync(this CommonReader reader, CancellationToken cancellationToken)
        {
            if (reader?.Reader == null)
                return Task.FromResult(false);
            return reader.Reader.ReadAsync(cancellationToken);
        }


        /// <summary>
        /// Fuehrt ein Nicht-Query asynchron aus. Erweiterungsmethode auf CommonCommand.
        /// </summary>
        public static Task<int> ExecuteNonQueryAsync(this CommonCommand command, CancellationToken cancellationToken)
        {
            if (command == null)
                return Task.FromResult(0);
            return Task.Run(() => command.ExecuteNonQuery(), cancellationToken);
        }
    }
}

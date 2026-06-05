Neue Konstrukte und Funktionen für die Datenbank Persistenz:

AttributedClass
AttributedClassList

Klassen die Datenbank Persistenz verwenden sollen, müssen von dieser Klasse ableiten. Die Tabelle von AttributedClassList und die Klasse, 
also ein einzelner Datensatz von AttributedClass


DbFieldAttribute
Die Felder die Persistenz verwenden werde mit dem Attribut wie folgt beschrieben:
[DbField(DbFieldType = DbType.Double, DbFieldName = "DBFIELDNAME"), DefaultValue(0)]

Der DefaultValue dient der Vereinfachung. Sollte ein Wert 'null' per Insert übergeben werden, kommtes zu Exceptions. 
FieldAttribute bietet außerdem die Möglichkeit eine Länge zu integrieren. Dies kann künftig abgefragt werden.
        

DbListAttribute
Klassen die Persistenz verwenden werden mit folgendem Attribut beschrieben:
[DbList(TableName = "TABLENAME")]
Hier wird der Liste ein Tabellenname zugeordnet der für Insert und Update notwendig ist. 
Select ist derzeit noch nicht implementiert.
    

DbCondition
DbConditionList

Beide Klassen liefern die Möglichkeit bei Update und Select eine Bedingung einzufügen. Die Verwendung sollte sich aus dem Quellcode ergeben.

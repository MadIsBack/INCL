unit CO_Util_V63;



interface

uses
    Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls,
    Dialogs, db, dbtables;

function BeginDatabaseConnection: Boolean;
function EndDatabaseConnection: Boolean;

(********************************************************************************************

    Funktionen GetSetupOption(aQuery, aFieldname, aDefault)

    Die Funktionen dienen zur Abfrage der Setup Optionen. Sollte eine Option noch
    nicht durch TableCreate in der Datenbank verfügbar ein, wird entweder false/0/'' oder
    der übergebene Defaultwert zurück gegeben. Sollte es keine Datenbankverbindung geben,
    kann aQuery als nil übergeben werden und es wird eine Verbindung aufgebaut.

    über die Variablen fBDUSER und fDBPASS kann der Mandant ausgewählt werden

*********************************************************************************************)

function GetSetupOption(aQuery: TQuery; aFieldName: string; aDefault: boolean = false): Boolean; overload;
function GetSetupOption(aQuery: TQuery; aFieldName: string; aDefault: string = ''): string; overload;
function GetSetupOption(aQuery: TQuery; aFieldName: string; aDefault: Integer = 0): Integer; overload;

var
    fDBUSER: string;
    fDBPASS: string;

implementation

var
    fQuery: TQuery;
    fDatabase: TDatabase;

function BeginDatabaseConnection: Boolean;
begin
    try
        fDatabase := TDatabase.Create(nil); // Datenbank wird kreiert und angemeldet.
        fDatabase.AliasName := 'ora1';
        fDatabase.DatabaseName := 'AINCSSS';
        fDatabase.LoginPrompt := False;
        if fDBUSER = '' then
            fDBUSER := 'includis';
        if fDBPASS = '' then
            fDBPASS := 'comtas';
        fDatabase.Params.Add('USER NAME=' + fDBUSER);
        fDatabase.Params.Add('PASSWORD=' + fDBPASS);
        fDatabase.SessionName := 'Default';
        fQuery := TQuery.Create(nil); // Abfrage wird kreiert.
        fQuery.DatabaseName := 'AINCSSS';
        fQuery.SQL.Text := 'SELECT dbuser FROM setup';
        fQuery.Open;
        result := fQuery.Active;
        fQuery.Close;
    except
        result := false;
    end;

end;

function EndDatabaseConnection: Boolean;
begin
    result := false;
    try
    fQuery.Close;
    fDatabase.Close;
    FreeAndNil(fQuery);
    FreeAndNil(fDatabase);
    result := true;
    except
    end;
end;

function GetSetupOption(aQuery: TQuery; aFieldName: string; aDefault: boolean = false): Boolean; overload;
var s: string;
    fieldname: string;
    connectDatabase, connected: boolean;
begin
    result := false;
    connectDatabase := (aQuery = nil);
    if connectDatabase then
        connected := BeginDatabaseConnection
    else
        connected := true;
    if connected then
    begin
        fieldname := UpperCase(aFieldName);
        s := 'SELECT * FROM SYS.ALL_TAB_COLUMNS WHERE tablename = ''SETUP'' AND column_name = ''' + fieldname + '''';
        fQuery.Close;
        fQuery.SQL.Text := s;
        fQuery.Open;
        if fQuery.IsEmpty then
            result := false

        else
        begin
            s := 'SELECT ''' + fieldname + ''' FROM setup WHERE nr = 1';
            fQuery.Close;
            fQuery.SQL.Text := s;
            fQuery.Open;
            result := (fQuery.FieldByName(fieldname).AsInteger <> 0);
        end;
    end;
    if connectDatabase then
        EndDatabaseConnection;

end;

function GetSetupOption(aQuery: TQuery; aFieldName: string; aDefault: Integer = 0): Integer; overload;
var s: string;
    fieldname: string;
    connectDatabase, connected: boolean;
begin
    result := 0;
    connectDatabase := (aQuery = nil);
    if connectDatabase then
        connected := BeginDatabaseConnection
    else
        connected := true;
    if connected then
    begin
        fieldname := UpperCase(aFieldName);
        s := 'SELECT * FROM SYS.ALL_TAB_COLUMNS WHERE tablename = ''SETUP'' AND column_name = ''' + fieldname + '''';
        fQuery.Close;
        fQuery.SQL.Text := s;
        fQuery.Open;
        if fQuery.IsEmpty then
            result := 0
        else
        begin
            s := 'SELECT ''' + fieldname + ''' FROM setup WHERE nr = 1';
            fQuery.Close;
            fQuery.SQL.Text := s;
            fQuery.Open;
            result := fQuery.FieldByName(fieldname).AsInteger;
        end;
        if connectDatabase then
            EndDatabaseConnection;

    end;
end;

function GetSetupOption(aQuery: TQuery; aFieldName: string; aDefault: string = ''): string; overload;
var s: string;
    fieldname: string;
    connectDatabase, connected: boolean;
begin
    result := '';
    connectDatabase := (aQuery = nil);
    if connectDatabase then
        connected := BeginDatabaseConnection
    else
        connected := true;

    if connected then
    begin
        fieldname := UpperCase(aFieldName);
        s := 'SELECT * FROM SYS.ALL_TAB_COLUMNS WHERE tablename = ''SETUP'' AND column_name = ''' + fieldname + '''';
        fQuery.Close;
        fQuery.SQL.Text := s;
        fQuery.Open;
        if fQuery.IsEmpty then
            result := ''
        else
        begin
            s := 'SELECT ''' + fieldname + ''' FROM setup WHERE nr = 1';
            fQuery.Close;
            fQuery.SQL.Text := s;
            fQuery.Open;
            result := fQuery.FieldByName(fieldname).AsString;
        end;
        if connectDatabase then
            EndDatabaseConnection;

    end;
end;
end.



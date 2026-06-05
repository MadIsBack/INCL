unit CO_User;

interface

uses IdBaseComponent, IdCoder, IdCoderMessageDigest, StdCtrls;

type
  TCO_User = class
  private
    fHash: string;
    fCoderMD5: TIdCoderMD5;
    procedure SetPassord(const Value: string);

  public
    function checkPassword(aPassword : String):boolean;

    property password: string write SetPassord;
    property hash: string read fHash;
    constructor create;
    destructor destroy; override;
  end;

  TCO_UserGroup = class

  end;

  TCO_View = class

  end;

implementation

{ TCO_User }

function TCO_User.checkPassword(aPassword: String): boolean;
begin
  fCoderMD5.AutoCompleteInput := True;
  result := (fHash = fCoderMD5.CodeString(aPassword));
end;

constructor TCO_User.create;
begin
  inherited;
  fCoderMD5 := TIdCoderMD5.Create(nil);

end;

destructor TCO_User.destroy;
begin
  fCoderMD5.Free;
  inherited;
end;

procedure TCO_User.SetPassord(const Value: string);
begin
  fCoderMD5.AutoCompleteInput := True;
  fHash := fCoderMD5.CodeString(Value);
end;

end.


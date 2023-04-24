unit data;

interface

uses
  System.SysUtils, System.Classes, Data.DB, Data.Win.ADODB, System.TypInfo;

const CNX_STRING  = 'Provider=MSDASQL.1;Persist Security Info=False;Extended Properties="Driver={SQLite3 ODBC Driver};' +
                    'Database=[filename];UTF8Encoding=1;StepAPI=0;SyncPragma=NORMAL;NoTXN=0;Timeout=;ShortNames=0;LongNames=0;NoCreat=0;NoWCHAR=0;FKSupport=0;JournalMode=;LoadExt=;"';

      TOKEN_VALIDE     = 200;
      TOKEN_INVALIDE   = 400;
      TOKEN_EXPIRED    = 401;
      USER_UNKNOWN     = 402;
      USER_NOTACTIVATE = 403;
      INVALID_PASSWORD = 404;
      INTERNAL_ERROR   = 500;

type
  Tmodule = class(TDataModule)
    cnxDataBase: TADOConnection;
    procedure DataModuleCreate(Sender: TObject);
  private
    function NewToken(const userid: Integer): string;
    procedure CheckDataBase;
    { Déclarations privées }
  public
    { Déclarations publiques }
    function AddQuery: TADOQuery;
    function tokenValid(const token: string): Integer;
    function getToken(const userid: integer): string;
  end;

var
  module: Tmodule;

implementation

  uses exo1_intrf, Louis.json.objects;

{%CLASSGROUP 'Vcl.Controls.TControl'}

function GetColumnType(APropInfo: PPropInfo): string;
begin
  case APropInfo^.PropType^.Kind of
    tkInteger, tkInt64: Result := 'INTEGER';
    tkFloat: Result := 'REAL';
    tkString, tkLString, tkWString, tkUString: Result := 'TEXT';
    tkEnumeration: Result := 'INTEGER';
    tkVariant: Result := 'BLOB';
    tkClass: Result := 'INTEGER';
    tkInterface: Result := 'INTEGER';
    tkDynArray: Result := 'BLOB';
    tkRecord: Result := 'BLOB';
    tkArray: Result := 'BLOB';
    else
      Result := 'TEXT';
  end;
end;

function GenerateCreateTableSQL(AClass: TClass; ATableName: string): string;
var
  TypeInfo: PTypeInfo;
  TypeData: PTypeData;
  PropList: PPropList;
  PropInfo: PPropInfo;
  PropCount, I: Integer;
  SQLColumns, SQLPrimaryKeys: string;
begin
  Result := '';
  TypeInfo := AClass.ClassInfo;
  TypeData := GetTypeData(TypeInfo);
  PropCount := TypeData^.PropCount;
  if PropCount = 0 then
    Exit;

  SQLColumns := '';
  SQLPrimaryKeys := '';

  GetMem(PropList, PropCount * SizeOf(Pointer));
  try
    GetPropInfos(TypeInfo, PropList);
    for I := 0 to PropCount - 1 do
    begin
      PropInfo := PropList^[I];
      if PropInfo^.PropType^.Kind in [tkArray, tkRecord, tkInterface] then
        Continue;
      if PropInfo^.PropType^.Kind = tkClass then
        Continue;
      if PropInfo.Name = 'id' then
      begin
        SQLColumns := SQLColumns + 'id INTEGER PRIMARY KEY AUTOINCREMENT, ';
        SQLPrimaryKeys := SQLPrimaryKeys + 'id, ';
      end
      else
        SQLColumns := SQLColumns + PropInfo.Name + ' ' + GetColumnType(PropInfo) + ', ';
    end;
    SQLColumns := Copy(SQLColumns, 1, Length(SQLColumns) - 2);
    //if SQLPrimaryKeys <> '' then
    //  SQLPrimaryKeys := 'PRIMARY KEY(' + Copy(SQLPrimaryKeys, 1, Length(SQLPrimaryKeys) - 2) + ')';

    Result := 'CREATE TABLE IF NOT EXISTS ' + ATableName + ' (' + SQLColumns;
//    if SQLPrimaryKeys <> '' then
//      Result := Result + ', ' + SQLPrimaryKeys;
    Result := Result + ');';
  finally
    FreeMem(PropList, PropCount * SizeOf(Pointer));
  end;
end;


{$R *.dfm}

function GenerateToken: string;
const
  TokenChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
var
  I: Integer;
begin
  Result := '';
  for I := 1 to 32 do // 32 character token
    Result := Result + TokenChars[Random(Length(TokenChars)) + 1];
end;

function Tmodule.AddQuery: TADOQuery;
begin
  result:= TADOQuery.Create(nil);
  Result.Connection:= cnxDataBase;
  Result.SQL.Clear;
end;

procedure Tmodule.DataModuleCreate(Sender: TObject);
begin
  cnxDataBase.ConnectionString := StringReplace(CNX_STRING, '[filename]', ExtractFilePath(ParamStr(0)) + '\data\mabase.db', [rfReplaceAll]);
  try
    cnxDataBase.open;
    CheckDataBase;
  except
    on e: exception do
      ODS('error', 'datamodule.creatre', 'impossible de trouver la base de données : ' + e.Message);
  end;
end;

procedure Tmodule.CheckDataBase;
begin
  with AddQuery do
  try
    SQL.Text:= GenerateCreateTableSQL(TDevice, 'device');
    try ExecSQL; except on e : Exception do ODS('error', 'checkDataBase.device ' + SQL.Text, e.Message); end;
    SQL.Text:= GenerateCreateTableSQL(TBlood, 'bloodgroup');
    try ExecSQL; except on e : Exception do ODS('error', 'checkDataBase.bloodgroup ' + SQL.Text, e.Message);  end;
    SQL.Text:= GenerateCreateTableSQL(TPatient, 'patient');
    try ExecSQL; except on e : Exception do ODS('error', 'checkDataBase.patient ' + SQL.Text, e.Message);  end;
    SQL.Text:= GenerateCreateTableSQL(TParameter, 'parameter');
    try ExecSQL; except on e : Exception do ODS('error', 'checkDataBase.parameter ' + SQL.Text, e.Message);  end;
    SQL.Text:= GenerateCreateTableSQL(TBed, 'bed');
    try ExecSQL; except on e : Exception do ODS('error', 'checkDataBase.bed ' + SQL.Text, e.Message); end;
    SQL.Text:= GenerateCreateTableSQL(TUnit, 'unit');
    try ExecSQL; except on e : Exception do ODS('error', 'checkDataBase.unit ' + SQL.Text, e.Message);  end;
    SQL.Text:= GenerateCreateTableSQL(TCentral, 'central');
    try ExecSQL; except on e : Exception do ODS('error', 'checkDataBase.central ' + SQL.Text, e.Message);  end;
    SQL.Text:= GenerateCreateTableSQL(TCentralLink, 'central_link');
    try ExecSQL; except on e : Exception do ODS('error', 'checkDataBase.central_link ' + SQL.Text, e.Message);  end;
    SQL.Text:= GenerateCreateTableSQL(TDpiLink, 'dpi_link');
    try ExecSQL; except on e : Exception do ODS('error', 'checkDataBase.dpi_link ' + SQL.Text, e.Message);  end;
    SQL.Text:= GenerateCreateTableSQL(TDpiLink, 'bed_status');
    try ExecSQL; except on e : Exception do ODS('error', 'checkDataBase.bed_status ' + SQL.Text, e.Message);  end;
    SQL.Text:= GenerateCreateTableSQL(TDpiLink, 'param_values');
    try ExecSQL; except on e : Exception do ODS('error', 'checkDataBase.param_values ' + SQL.Text, e.Message);  end;
  finally
    Free;
  end;
end;

function IsDateWithinOneHour(const ADate: TDateTime): Boolean;
begin
  Result := ADate > (Now - EncodeTime(1, 0, 0, 0));
end;

function Tmodule.NewToken(const userid: Integer): string;
begin
  result:= GenerateToken;
  with AddQuery do
  try
    SQL.Add('insert into tokens');
    SQL.Add('(iduser, token, startdate)');
    SQL.Add('values');
    SQL.Add('(:iduser, :token, :startdate)');

    Parameters.ParamByName('iduser').Value:= userid;
    Parameters.ParamByName('token').Value := result;
    Parameters.ParamByName('startdate').Value:= FormatDateTime('yyyy-mm-dd hh:nn:ss', now);

    try
      ExecSQL;
    except
      on e: Exception do
        ODS('error', 'datamodule.NowToken', e.Message);
    end;
  finally
    Free;
  end;
end;

function Tmodule.getToken(const userid: integer): string;
begin
  with AddQuery do
  try
     SQL.Add('select * from tokens where iduser=:userid order by startdate desc LIMIT 1');
     Parameters.ParamByName('userid').Value:= userid;
     open;
     if Eof<>Bof then
     begin
       if IsDateWithinOneHour(FieldByName('startdate').AsDateTime) then
            result:= FieldByName('token').AsString
       else Result:= NewToken(userid);
     end
     else Result:= NewToken(userid);
     Close;
  finally
    Free;
  end;
end;

function Tmodule.tokenValid(const token: string): Integer;
begin
  with AddQuery do
  try
    try
      SQL.Add('select * from tokens where token=:token');
      Parameters.ParamByName('token').Value:= token;
      Open;
      if Eof<>Bof then
      begin
        if IsDateWithinOneHour(FieldByName('startdate').AsDateTime) then
             result:= TOKEN_VALIDE
        else result:= TOKEN_EXPIRED;
      end
      else result:= TOKEN_INVALIDE;
    except
      on e : Exception do
      begin
        ODS('error', 'tokenValid', e.Message);
        result:= TOKEN_INVALIDE;
      end;
    end;
  finally
    Free;
  end;
end;

end.

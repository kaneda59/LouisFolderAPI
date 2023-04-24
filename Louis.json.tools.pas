unit Louis.json.tools;

interface

  uses System.SysUtils, Classes, Variants, SynCommons, mORMot, mORMotHttpClient,  mORMotDDD,
  SynLog, mORMotService, mORMotHttpServer, mormot.net.server, Louis.json.objects,
  System.Rtti, System.TypInfo, Data.DBXJSON, System.Generics.Defaults,
  System.Generics.Collections;

  function BoolToStr(const cond: boolean; const strue, sfalse: string): string;
  function classToJSon(aClasse: TPersistentWithCustomCreate): RawJSON;
  function JSonToObject(AJsonString: AnsiString; AObjectType: TClass): TObject;

  function JSonToUserLogin(AJsonString: RawJSON): TUserLogin;
  function JSonToDevice(AJsonString: RawJSON): TDevice;
  function JSonToBloodGroup(AJsonString: RawJSON): TBlood;
  function JSonToPatient(AJsonString: RawJSON): TPatient;
  function JSonToParameter(AJsonString: RawJSON): TParameter;
  function JSonToUnit(AJSonString: RawJSON): TUnit;
  function JSonToCentral(AJsonString: RawJSON): TCentral;
  function JSonToCentralLink(AJsonString: RawJSON): TCentralLink;
  function JSonToDPILink(AJsonString: RawJSon): TDPILink;
  function JSonToBed(AJSonString: RawJSON): TBed;
  function JSontToBedSatus(AJsonString: RawJSON): TBedStatus;
  function JSontToRequestParam(AJsonString: RawJSON): TRequestParam;


implementation

function BoolToStr(const cond: boolean; const strue, sfalse: string): string;
begin
  if cond then result:= sTrue
          else result:= sFalse;
end;

function classToJSon(aClasse: TPersistentWithCustomCreate): RawJSON;
var vaClasse: Variant;
begin
  vaClasse:= ObjectToVariant(aClasse);
  result:= variantSaveJSon(vaClasse);
end;

function PurgeJSon(value: AnsiString): AnsiString;
var buffer: array of char;
    i: Integer;
begin
  result:= '';
  repeat
    if value[i]<>#0 then
      result:= Result + value[i];
    i:= i+1;
  until i>Length(value);
end;

function JSonToObject(AJsonString: AnsiString; AObjectType: TClass): TObject;
var
  obj: TObject;
  ctx: TRttiContext;
  objType: TRttiType;
  prop: TRttiProperty;
  jsonObj: TJSONObject;
  jsonPair: TJSONPair;
  fieldName: string;
begin
  obj := AObjectType.Create;
  try
    jsonObj := TJSONObject.ParseJSONValue(AJsonString) as TJSONObject;
    objType := ctx.GetType(AObjectType);
    if not objType.IsInstance then
      raise Exception.Create('Type parameter must be a class');

    for prop in objType.GetProperties do
    begin
      fieldName := LowerCase(prop.Name); // convertit le nom de la propriété en minuscules
      jsonPair := jsonObj.Get(fieldName);
      if Assigned(jsonPair) and (not (jsonPair.JsonValue.Value='')) then
      begin
        SetPropValue(obj, fieldname, jsonPair.JsonValue.Value); //TValue.FromVariant(
      end;
    end;
  except
    obj.Free;
    raise;
  end;
  Result := obj;
end;

function JSonToUserLogin(AJsonString: RawJSON): TUserLogin;
//var v: variant;
begin
  result:= TUserLogin(JSonToObject(AJsonString, TUserLogin));
//  result:= TUserLogin.Create;
//  v:= _JSon(AJsonString);
//  result.login   := v.login;
//  result.password:= v.password;
end;

function JSontToRequestParam(AJsonString: RawJSON): TRequestParam;
var v: Variant;
begin
  result:= TRequestParam(JSonToObject(AJsonString, TRequestParam));
end;

function JSonToDevice(AJsonString: RawJSON): TDevice;
var v: variant;
begin
//  result:= TDevice.Create;
//  v:= _JSon(AJsonString);

  result:= TDevice(JSonToObject(AJsonString, TDevice));

//  try
//    result.id         := v.id;
//    result.name       := v.name;
//    Result.description:= v.description;
//    Result.brands     := v.brands;
//    Result.device_type:= v.device_type;
//  except
//    on e: Exception do
//      ODS('error', 'JsonToDevice invalid', AJsonString);
//  end;
end;

function JSonToBloodGroup(AJsonString: RawJSON): TBlood;
var v: variant;
begin
  result:= TBlood.Create;
  v:= _JSon(AJsonString);

  Result.id        := v.id;
  Result.bloodgroup:= v.bloodgroup;
end;

function JSonToPatient(AJsonString: RawJSON): TPatient;
var v: variant;
begin
  result:= TPatient.Create;
  v:= _JSon(AJsonString);

  Result.id       := v.id;
  Result.firstname:= v.firstname;
  Result.lastname := v.lastname;
  Result.birthdate:= v.birthdate;
  Result.pid      := v.pid;
  Result.bloodid  := v.bloodid;
  Result.Height   := v.height;
  Result.Width    := v.Width;
end;

function JSonToParameter(AJsonString: RawJSON): TParameter;
var v: variant;
begin
  result:= TParameter.Create;
  v:= _JSon(AJsonString);

  Result.id         := v.id;
  Result.xpressoid  := v.xpressoid;
  Result.name       := v.name;
  Result.description:= v.description;
  Result.sending    := v.sending;
  Result.active     := v.active;
end;

function JSonToUnit(AJSonString: RawJSON): TUnit;
var v: variant;
begin
  result:= TUnit.Create;
  v:= _JSon(AJsonString);

  Result.id         := v.id;
  Result.name       := v.name;
  Result.unitid     := v.unitid;
end;

function JSonToCentral(AJsonString: RawJSON): TCentral;
var v: variant;
begin
  result:= TCentral.Create;
  v:= _JSon(AJsonString);

  Result.id         := v.id;
  Result.name       := v.name;
  Result.host       := v.host;
  Result.port       := v.port;
  Result.description:= v.description;
end;

function JSonToCentralLink(AJsonString: RawJSON): TCentralLink;
var v: variant;
begin
  result:= TCentralLink.Create;
  v:= _JSon(AJsonString);

  Result.id         := v.id;
  Result.centralid  := v.centralid;
  Result.centralcode:= v.centralcode;
  Result.centraltype:= v.centraltype;
  Result.centrallink:= v.centrallink;
end;

function JSonToDPILink(AJsonString: RawJSon): TDPILink;
var v: variant;
begin
  result:= TDPILink.Create;
  v:= _JSon(AJsonString);

  Result.id         := v.id;
  Result.dpiid      := v.dpiid;
  Result.dpicode    := v.dpicode;
  Result.dpitype    := v.dpitype;
end;

function JSonToBed(AJsonString: RawJSON): TBed;
var v: variant;
begin
  result:= TBed.Create;
  v:= _JSon(AJsonString);

  result.id         := v.id;
  result.name       := v.name;
end;

function JSontToBedSatus(AJsonString: RawJSON): TBedStatus;
var v: variant;
begin
  result:= TBedStatus.Create;
  v:= _Json(AJsonString);

  Result.id        := v.id;
  Result.idbed     := v.idBed;
  Result.state     := v.state;
  Result.interval  := v.interval;
  Result.intervalDefault:= v.intervalDefault;
end;

end.

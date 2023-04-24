unit Louis.service;

interface

uses
  System.SysUtils, System.Classes,
  SynCommons, mORMot, mORMotHttpClient,  mORMotDDD,
  SynLog, mORMotService, mORMotHttpServer,
  exo1_intrf, mormot.rest.http.server, DateUtils,
  Louis.json.objects,
  Louis.json.tools,
  mormot.net.server;

type
  TMessageService = class(TInterfacedObject,IMessageService)
  protected
    fConnected: array of IMessageCallback;
  public
    procedure Join(const login: string; const callback: IMessageCallback);
    procedure Message(const login,msg: string);
    procedure CallbackReleased(const callback: IInvokable; const interfaceName: RawUTF8);
  end;

  TLouisServices = class(TInterfacedObject, ILouisServices)
  private
    fAccessControlAllowOrigin: string;
    fuseHttpApiRegisteringURI: string;
    function DeviceExists(const id: integer): Boolean;
  public
    constructor Create; reintroduce;
    function Login(JSonValue: RawUTF8): TResponse;

    function getDevices(const id: integer = 0): TResponse;
    function postDevices(JSonValue: RawUTF8):TResponse;
    function deleteDevices(const id: integer):TResponse;

    function getBloodGroup(const id: integer = 0): TResponse;
    function postBloodGroup(JSonValue: RawUTF8): TResponse;
    function deleteBloodGroup(const id: integer): TResponse;

    function getPatient(const id: integer = 0): TResponse;
    function postPatient(JSonValue: RawUTF8): TResponse;
    function deletePatient(const id: integer): TResponse;

    function getParameters(const id: integer = 0): TResponse;
    function postParameters(JSonValue: RawUTF8): TResponse;
    function deleteParameters(const id: integer): TResponse;

    function getParamValues(const AJsonValue: RawUTF8): TResponse;

    function getUnits(const id: integer = 0): TResponse;
    function postUnits(JSonValue: RawUTF8): TResponse;
    function deleteUnits(const id: integer): TResponse;

    function getCentral(const id: integer = 0): TResponse;
    function postCentral(JSonValue: RawUTF8): TResponse;
    function deleteCentral(const id: integer): TResponse;

    function getCentralLinks(const id: integer = 0): TResponse;
    function postCentralLinks(JSonValue: RawUTF8): TResponse;
    function deleteCentralLinks(const id: integer): TResponse;

    function getDPILinks(const id: integer = 0): TResponse;
    function postDPILinks(JSonValue: RawUTF8): TResponse;
    function deleteDPILinks(const id: integer): TResponse;

    function getBed(const id: Integer = 0): TResponse;
    function postBed(JSonValue: RawUTF8): TResponse;
    function deleteBed(const id: Integer): TResponse;

    function getBedStatus(const id: integer = 0): TResponse;
    function postBedStatus(JSonValue: RawUTF8): TResponse;
    function deleteBedStatus(const id: integer): TResponse;

    property AccessControlAllowOrigin: string read fAccessControlAllowOrigin write fAccessControlAllowOrigin;
    property useHttpApiRegisteringURI: string read fuseHttpApiRegisteringURI write fuseHttpApiRegisteringURI;
  end;
implementation

  uses data, variants, Louis.orm.tools;

{ TLouisServices }



function JSonToDevice(AJsonString: RawJSON): TDevice;
var v: variant;
    vd: variant;
begin
  result:= TDevice.Create;
  v:= _JSon(AJsonString);
  result.name:= v.name;
  result.description:= v.description;
  result.brands     := v.brands;
  Result.device_type:= v.device_type;
end;

constructor TLouisServices.Create;
begin
  inherited create;
end;

function TLouisServices.DeviceExists(const id: integer): Boolean;
begin
  with module.AddQuery do
  try
    SQL.Add('select id from devices where id=:id');
    Parameters.paramByName('id').value:= id;
    open;
    result:= Eof<>Bof;
    Close;
  finally
    Free;
  end;
end;


function TLouisServices.deleteBed(const id: Integer): TResponse;
begin
  result:= deleteDataObject('bed', id);
end;

function TLouisServices.deleteBedStatus(const id: integer): TResponse;
begin
  result:= deleteDataObject('bed_status', id);
end;

function TLouisServices.deleteBloodGroup(const id: integer): TResponse;
begin
  result:= deleteDataObject('bloodgroup', id);
end;

function TLouisServices.deleteCentral(const id: integer): TResponse;
begin
  result:= deleteDataObject('central', id);
end;

function TLouisServices.deleteCentralLinks(const id: integer): TResponse;
begin
  result:= deleteDataObject('central_link', id);
end;

function TLouisServices.deleteDevices(const id: integer): TResponse;
begin
  result:= deleteDataObject('device', id);
end;

function TLouisServices.deleteDPILinks(const id: integer): TResponse;
begin
  result:= deleteDataObject('dpi_link', id);
end;

function TLouisServices.deleteParameters(const id: integer): TResponse;
begin
  result:= deleteDataObject('parameter', id);
end;

function TLouisServices.deletePatient(const id: integer): TResponse;
begin
  result:= deleteDataObject('patient', id);
end;

function TLouisServices.deleteUnits(const id: integer): TResponse;
begin
  result:= deleteDataObject('unit', id);
end;

function TLouisServices.getBed(const id: Integer): TResponse;
begin
  result:= getDataBed(id);
end;

function TLouisServices.getBedStatus(const id: integer): TResponse;
begin
  result:= getDataBedStatus(id);
end;

function TLouisServices.getBloodGroup(const id: integer = 0): TResponse;
begin
  result:= getDataBlood(id);
end;

function TLouisServices.getCentral(const id: integer = 0): TResponse;
begin
  result:= getDataCentral(id);
end;

function TLouisServices.getCentralLinks(const id: integer = 0): TResponse;
begin
  result:= getDataCentralLink(id);
end;

function TLouisServices.getDevices(const id: integer = 0): TResponse;
begin
  result:= getDataDevice(id);
end;

function TLouisServices.getDPILinks(const id: integer = 0): TResponse;
begin
  result:= getDataDPILink(id);
end;

function TLouisServices.getParameters(const id: integer = 0): TResponse;
begin
  result:= getDataParameter(id);
end;

function TLouisServices.getParamValues(const AJsonValue: RawUTF8): TResponse;
var datestart, datefin: TDateTime;
    request_param: TRequestParam;
    jsonvalues: RawJSON;
begin
  randomize;
  try
    request_param := JSontToRequestParam(AJsonValue);
    jsonvalues:= '';
    dateStart:= request_param.datestart;
    repeat
      if request_param.xpressoid=5   then begin
                   jsonvalues:= jsonvalues + '{"xpressoid":5,"values":' + FormatFloat('0', 50+Random(100)) + ',"unit":"/min","timestamp":"' + FormatDateTime('yyyy-mm-ddThhnnss', datestart) + '"},';
                 end;
      if request_param.xpressoid=162   then begin
                   jsonvalues:= jsonvalues + '{"xpressoid":162,"values":' + FormatFloat('0', 80+Random(20)) + ',"unit":"%n","timestamp":"' + FormatDateTime('yyyy-mm-ddThhnnss', datestart) + '"},';
                 end;
      if request_param.xpressoid=163   then begin
                   jsonvalues:= jsonvalues + '{"xpressoid":163,"values":' + FormatFloat('0', 50+Random(100)) + ',"unit":"/min","timestamp":"' + FormatDateTime('yyyy-mm-ddThhnnss', datestart) + '"},';
                 end;
      if request_param.xpressoid=110   then begin
                   jsonvalues:= jsonvalues + '{"xpressoid":110,"values":' + FormatFloat('0', 95+Random(100)) + ',"unit":"mmHg","timestamp":"' + FormatDateTime('yyyy-mm-ddThhnnss', datestart) + '"},';
                 end;
      if request_param.xpressoid=111   then begin
                   jsonvalues:= jsonvalues + '{"xpressoid":111,"values":' + FormatFloat('0', 50+Random(100)) + ',"unit":"mmHg","timestamp":"' + FormatDateTime('yyyy-mm-ddThhnnss', datestart) + '"},';
                 end;
      if request_param.xpressoid=112   then begin
                   jsonvalues:= jsonvalues + '{"xpressoid":112,"values":' + FormatFloat('0', 50+Random(49)) + ',"unit":"mmHg","timestamp":"' + FormatDateTime('yyyy-mm-ddThhnnss', datestart) + '"},';
                 end;
      if request_param.xpressoid=131   then begin
                   jsonvalues:= jsonvalues + '{"xpressoid":131,"values":' + FormatFloat('0', 30+Random(12)) + ',"unit":"°C","timestamp":"' + FormatDateTime('yyyy-mm-ddThhnnss', datestart) + '"},';
                 end;
        datestart := IncMinute(datestart, 5);
    until dateStart>=request_param.dateend;
    Delete(jsonvalues, Length(jsonvalues), 1);
    if jsonvalues<>'' then
    begin
      Result.state:= 200;
      Result.response:= '[' + jsonvalues + ']';
    end
    else
    begin
      result.state := 400;
      Result.response:= '{"error":"xpressoid or data not found"}';
    end;
  except
    on e: Exception do
    begin
      result.state := 400;
      Result.response:= '{"error":"' + e.Message + '"}';
    end;
  end;
end;

function TLouisServices.getPatient(const id: integer = 0): TResponse;
begin
  result:= getDataPatient(id);
end;

function TLouisServices.getUnits(const id: integer = 0): TResponse;
begin
  result:= getDataUnit(id);
end;

function TLouisServices.Login(JSonValue: RawUTF8): TResponse;
var user: TUserLogin;
begin
  if JSonValue='' then exit;
  user:= JSonToUserLogin(JSonValue);
  if Assigned(user) then
  begin
    with module.AddQuery do
    try
      SQL.Add('select * from users where login=:login');
      Parameters.ParamByName('login').Value:= user.login;
      Open;
      if Eof<>Bof then
      begin
        if FieldByName('password').AsString=user.password then
        begin
          Result.response:= '{"token":"'+module.getToken(FieldByName('id').AsInteger)+'"}';
          Result.State:= HTTP_SUCCESS;
        end
        else
        begin
          Result.state:= 401;
          Result.response:= '{"error":"identification incorrecte"}';
        end;
      end
      else
      begin
        Result.state:= 400;
        Result.response:= '{"error":"utilisateur inconnue"}';
      end;
    finally
      Free;
    end;
  end;
end;

function TLouisServices.postBed(JSonValue: RawUTF8): TResponse;
begin
  result:= postDataBed(JsonValue);
end;

function TLouisServices.postBedStatus(JSonValue: RawUTF8): TResponse;
begin
  result:= postDataBedStatus(JsonValue);
end;

function TLouisServices.postBloodGroup(JSonValue: RawUTF8): TResponse;
begin
  result:= postDataBloodGroup(JsonValue);
end;

function TLouisServices.postCentral(JSonValue: RawUTF8): TResponse;
begin
  result:= postDataCentral(JsonValue);
end;

function TLouisServices.postCentralLinks(JSonValue: RawUTF8): TResponse;
begin
  result:= postDataCentralLink(JsonValue);
end;

function TLouisServices.postDevices(JSonValue: RawUTF8): TResponse;
//var device: TDevice;
begin
  result:= postDataDevices(JsonValue);
//  device:= JSonToDevice(JsonValue);
//  if assigned(device) then
//  begin
//    with module.AddQuery do
//    try
//    if DeviceExists(device.id) then
//    begin
//      SQL.Add('update device');
//      SQL.Add('set name=:name,');
//      SQL.Add('    description=:description,');
//      SQL.Add('    brands=:brands,');
//      SQL.Add('    device_type=:device_type');
//      SQL.Add('where id=:id');
//
//      Parameters.ParamByName('id').Value:= device.id;
//    end
//    else
//    begin
//      SQL.Add('insert into device');
//      SQL.Add('(name, description, brands, device_type)');
//      SQL.Add('values');
//      SQL.Add('(:name, :description, :brands, :device_type)');
//    end;
//
//    Parameters.ParamByName('name').Value       := device.name;
//    Parameters.ParamByName('description').Value:= device.description;
//    Parameters.ParamByName('brands').Value     := device.brands;
//    Parameters.ParamByName('device_type').Value:= device.device_type;
//
//    try
//      ExecSQL;
//      Result.state:= 200;
//      Result.response:= '{"info":"device mise à jour"}';
//    except
//      on e: Exception do
//      begin
//        Result.state:= 500;
//        Result.response:= '{"error":"erreur lors de l''insertion : ' + e.Message + '"}';
//      end;
//    end;
//
//    finally
//      Free;
//    end;
//  end
//  else
//  begin
//    result.state:= 400;
//    result.response:= '{"error":"device non trouvé"}';
//  end;
end;

function TLouisServices.postDPILinks(JSonValue: RawUTF8): TResponse;
begin
  result:= postDataDPILink(JsonValue);
end;

function TLouisServices.postParameters(JSonValue: RawUTF8): TResponse;
begin
  result:= postDataParameter(JsonValue);
end;

function TLouisServices.postPatient(JSonValue: RawUTF8): TResponse;
begin
  result:= postDataPatient(JsonValue);
end;

function TLouisServices.postUnits(JSonValue: RawUTF8): TResponse;
begin
  result:= postDataUnit(JsonValue);
end;

{ TMessageService }

procedure TMessageService.CallbackReleased(const callback: IInvokable;
  const interfaceName: RawUTF8);
begin
  if interfaceName='IMessageCallback' then
     InterfaceArrayDelete(fConnected,callback);
end;

procedure TMessageService.Join(const login: string;
  const callback: IMessageCallback);
begin
  InterfaceArrayAdd(fConnected,callback);
end;

procedure TMessageService.Message(const login, msg: string);
var i: integer;
begin
  for i := high(fConnected) downto 0 do
  try
    fConnected[i].NotifyMessage(login,msg);
  except
    InterfaceArrayDelete(fConnected,i);
  end;
end;

end.


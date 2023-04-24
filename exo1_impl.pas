unit exo1_impl;

interface

uses
     System.SysUtils, System.Classes, Winapi.Windows, TypInfo, Winapi.ActiveX,
     Data.DBXJSON, ADODB, variants, Ora, OraClasses, System.RegularExpressions,
     exo1_intrf,
     soap.EncdDecd,
     Louis.service,
     Louis.json.objects,
     {$IFNDEF mormot2}
     SynCommons,
     SynLog,
     mORMot,
     SynCrtSock,
     mORMotHttpServer;
     {$ELSE}
     mormot.rest.core,
     mormot.rest.server,
     mormot.rest.memserver,
     mormot.core.json,
     mormot.core.base,
     mormot.core.os,
     mormot.core.rtti,
     mormot.core.log,
     mormot.core.text,
     mormot.rest.http.server,
     mormot.net.http,
     mormot.net.server,
     mormot.net.async;
     {$ENDIF}

type

  TServer = class
  private
    LouisServices: TLouisServices;
    {$IFDEF mormot2}
    fHttpServer: TRestHttpServer;//THttpAsyncServer;
    function DoOnRequest(Ctxt: TRestServerUriContext{THttpServerRequestAbstract}): Boolean; //: cardinal;
    function doOnBeforeRequest(Ctxt: THttpServerRequestAbstract): cardinal ;
    {$ELSE}
    L: ISynLog;
    aDB: TSQLRestServerFullMemory;
    aModel: TSQLModel;
    aServer: TSQLHttpServer;

    HttpWebSock: TSQLHttpServer;
    WebSocket  : TSQLRestServerFullMemory;

    function doOnRequest(Ctxt: THttpServerRequest): cardinal;
    function dobeforeRequest(Ctxt: THttpServerRequest): cardinal;
    {$ENDIF}
  public
    constructor Create;
    destructor Destroy; override;
    function ActiveServer(const act: Boolean): Boolean;
  end;



var global_server: TServer;

implementation

  uses data;

const
  ROOT_NAME   = 'api';
  ROOT_PORT   = '9501';
  ROOT_PORT_2 = '9502';

{ TServer }
{$ifdef mormot2}
function TServer.doOnBeforeRequest(Ctxt: THttpServerRequestAbstract): cardinal ;
begin
  Ctxt.InHeaders := Ctxt.InHeaders + #13#10 + 'Access-Control-Allow-Origin: *'#13#10 +
                                              'Access-Control-Allow-Methods: GET,POST,PUT,DELETE'#13#10 +
                                              'Access-Control-Allow-Headers: Content-Type, Authorization';

end;
{$ENDIF}

function TServer.ActiveServer(const act: Boolean): Boolean;
{$IFDEF  mormot2}var restServer: TRestServer; {$ENDIF}
begin
  result:= False;
  {$IFDEF  mormot2}
  try
    if act then
    begin
//      fHttpServer := TRestHttpServer.Create(ROOT_PORT, [restServer], '+',
//        HTTP_DEFAULT_MODE, SystemInfo.dwNumberOfProcessors + 1, secNone, '', '',
//        HTTPSERVER_DEFAULT_OPTIONS, nil);
//      fHttpServer.AccessControlAllowOrigin := '*';// autoriser toutes les origines
//      restServer.OnBeforeUri := doOnRequest;
//      restServer.Run;
//      result := True;
      fHttpServer := THttpAsyncServer.Create(
        ROOT_PORT, nil, nil, '', SystemInfo.dwNumberOfProcessors + 1, 30000,
        [hsoNoXPoweredHeader,
         hsoNoStats,
//         hsoHeadersInterning,
         hsoThreadSmooting,
         hsoHeadersUnfiltered,
         hsoIncludeDateHeader
        //, hsoLogVerbose
        ]);
      //writeln('DropPriviledges=', DropPriviledges('abouchez'));
      fHttpServer.HttpQueueLength := 100000; // needed e.g. from wrk/ab benchmarks
      //fHttpServer.OnBeforeRequest := DoOnBeforeRequest;
      fHttpServer.OnRequest := DoOnRequest;
      fHttpServer.WaitStarted; // raise exception e.g. on binding issue
      result := True;
    end
    else
    begin
      fHttpServer.Free;
      result:= True;
    end;
  except

  end;
  {$ELSE}
  Result:= False;
  if act then
  begin
    try
      TSQLLog.Family.Level := LOG_STACKTRACE+[sllInfo,sllServer];
      TSQLLog.Family.EchoToConsole := LOG_VERBOSE;

      L:=  TSQLLog.Enter;
      aModel := TSQLModel.Create([], ROOT_NAME);

      aDB := TSQLRestServerFullMemory.Create(aModel,false);
      aDB.ServiceRegister(TLouisServices,[TypeInfo(ILouisServices)], sicShared).
      SetOptions([], [optExecLockedPerInterface]).
      ByPassAuthentication:= True;
      aServer := TSQLHttpServer.Create(ROOT_PORT,[aDB],'+',useHttpApiRegisteringURI);
      aServer.AccessControlAllowOrigin := '*';
      aServer.HttpServer.OnAfterRequest:= doOnRequest;

      WebSocket := TSQLRestServerFullMemory.CreateWithOwnModel([]);
      WebSocket.CreateMissingTables;
      WebSocket.ServiceDefine(TMessageService,[IMessageService],sicShared).
      SetOptions([],[optExecLockedPerInterface]).
      ByPassAuthentication := true;
      HttpWebSock := TSQLHttpServer.Create(ROOT_PORT_2,[WebSocket],'+',useBidirSocket);
      HttpWebSock.WebSocketsEnable(WebSocket,TRANSMISSION_KEY).
        Settings.SetFullLog;

      ODS('info', 'serverTools.StartmORMot', 'activation du serveur distant : succès');
      ODS('info', 'serverConeect', 'information :' + aServer.DomainName);
      Result:= True;
    except
      on e : exception do
        ODS('erreur', 'serverTools.StartmORMot', 'activation du serveur distant : ' + e.Message);
    end;
  end
  else
  begin
    if Assigned(aServer) then
      aServer.Free;
    ODS('info', 'serverTools.StartmORMot', 'désactivation');

    if Assigned(WebSocket) then
      WebSocket.Free;
  end;
  {$ENDIF}
end;

function TServer.dobeforeRequest(Ctxt: THttpServerRequest): cardinal;
begin
  Ctxt.OutCustomHeaders := 'Access-Control-Allow-Origin: *'#13#10 +
                           'Access-Control-Allow-Methods: GET,PUT,POST,DELETE,OPTIONS'#13#10 +
                           'Access-Control-Allow-Headers: Content-Type,Authorization'#13#10 +
                           'Access-Control-Allow-Credentials: true'#13#10 +
                           'Access-Control-Max-Age: 86400'#13#10
end;

constructor TServer.Create;
begin

end;

destructor TServer.Destroy;
begin

  inherited;
end;


function ContainsText(const AText, ASubText: string): Boolean;
begin
  Result := Pos(UpperCase(ASubText), UpperCase(AText)) > 0;
end;

function ExtractBearerTokenFromHeader(const header: string): string;
var
  re: TRegEx;
  match: TMatch;
begin
  re := TRegEx.Create('Bearer\s+([^\s]+)');
  match := re.Match(header);
  if match.Success then
    Result := match.Groups[1].Value
  else
    Result := '';
end;

{$IFDEF mormot2}
function TServer.DoOnRequest(Ctxt: THttpServerRequestAbstract): cardinal;
var resp    : RawJSON;
    state   : TResponse;
    inJSon  : RawUTF8;
    stateTok: Cardinal;
    token   : string;
    iddevice: integer;
    err: integer;
begin
.
   if (Ctxt.Url <> '') and (Pos('/api/', Ctxt.Url) = 1) then
  begin
    LouisServices:= TLouisServices.Create();
    try
      inJSon := Ctxt.InContent;

      token := ExtractBearerTokenFromHeader(UTF8ToString(Ctxt.InHeaders));

      stateTok := module.tokenValid(token);

      if ContainsText(Ctxt.Url, '/login') or (stateTok=TOKEN_VALIDE) then
      begin
        // appeler la méthode appropriée en fonction de la requête HTTP
        if CompareText(Ctxt.Method, 'GET')=0 then
        begin
          if ContainsText(Ctxt.Url, '/device') then
            state:= LouisServices.getDevices
          else
            state.state:= HTTP_NOTFOUND;
        end
        else
        if CompareText(Ctxt.Method, 'PUT')=0 then
        begin
          if ContainsText(Ctxt.Url, '/login') then
             state:= LouisServices.login(inJSon)
          else
             state.state:= HTTP_NOTFOUND;
        end
        else
        if CompareText(Ctxt.Method, 'POST')=0 then
        begin
          if ContainsText(Ctxt.Url, '/device') then
            state:= LouisServices.postDevices(Ctxt.InContent)
          else
            state.state:= HTTP_NOTFOUND;
        end
        else
        if CompareText(Ctxt.Method, 'DELETE')=0 then
        begin
          if ContainsText(Ctxt.Url, '/device/') then
          begin
            Val(copy(Ctxt.Url, pos('/device/', lowercase(Ctxt.url))+Length('/device/'), Length(Ctxt.url)), iddevice, err);
            if err=0 then
               state:= LouisServices.deleteDevices(iddevice)
            else
            begin
              state.state:= 405;
              state.response:= '{"error":"impossible de déterminer l''identifiant du device"}';
            end;
          end
          else
            state.state:= HTTP_NOTFOUND;
        end
        else
            state.state:= HTTP_BADREQUEST;
      end
      else
      begin
        state.state:= stateTok;
        state.response:= '{"error":"invalid token"}';
      end;

      // définir la réponse HTTP
      Ctxt.OutContentType := 'application/json';
      Ctxt.OutContent:= state.response;
      Result := state.state;
    except
    end;
    FreeAndNil(LouisServices);
  end
  else
  begin
    Ctxt.OutContentType:= 'URL INVALIDE';
    result:= 500;
  end;
end;
{$ELSE}
function TServer.doOnRequest(Ctxt: THttpServerRequest): cardinal;
var resp    : RawJSON;
    state   : TResponse;
    inJSon  : RawUTF8;
    stateTok: Cardinal;
    token   : string;
    iddevice: integer;
    err: integer;

    origin: RawUTF8;

    function ExtractId(const fct: string): Integer;
    begin
      Val(copy(Ctxt.Url, pos('/'+fct+'/', lowercase(Ctxt.url))+Length('/'+fct+'/'), Length(Ctxt.url)), result, err);
    end;
begin
  if Ctxt.Method <> 'OPTIONS' then
  if (Ctxt.Url <> '') and (Pos('/api/', Ctxt.Url) = 1) then
  begin
    LouisServices:= TLouisServices.Create();
    try
      inJSon := Ctxt.InContent;

      token := ExtractBearerTokenFromHeader(UTF8ToString(Ctxt.InHeaders));
      if token<>'' then
         stateTok := module.tokenValid(token);

      if ContainsText(Ctxt.Url, '/login') or (stateTok=TOKEN_VALIDE) then
      begin
        // appeler la méthode appropriée en fonction de la requête HTTP
        if CompareText(Ctxt.Method, 'GET')=0 then
        begin
          if ContainsText(Ctxt.Url, '/device') then
            state:= LouisServices.getDevices(ExtractId('device'))
          else
          if ContainsText(Ctxt.URL, '/blood') then
            state:= LouisServices.getBloodGroup(ExtractId('blood'))
          else
          if ContainsText(Ctxt.URL, '/patient') then
            state:= LouisServices.getPatient(ExtractId('patient'))
          else
          if ContainsText(Ctxt.URL, '/parameter') then
            state:= LouisServices.getParameters(ExtractId('parameter'))
          else
          if ContainsText(Ctxt.URL, '/unit') then
            state:= LouisServices.getUnits(ExtractId('unit'))
          else
          if ContainsText(Ctxt.URL, '/central') then
            state:= LouisServices.getcentral(ExtractId('central'))
          else
          if ContainsText(Ctxt.URL, '/bed') then
            state:= LouisServices.getBed(ExtractId('bed'))
          else
          if ContainsText(Ctxt.URL, '/centrallink') then
            state:= LouisServices.getCentralLinks(ExtractId('centrallink'))
          else
          if ContainsText(Ctxt.URL, '/dpilink') then
            state:= LouisServices.getDPILinks(ExtractId('dpilink'))
          else
          if ContainsText(Ctxt.URL, '/paramvalues') then
               state:= LouisServices.getParamValues(inJson)
          else state.state:= HTTP_NOTFOUND;
        end
        else
        if CompareText(Ctxt.Method, 'PUT')=0 then
        begin
          if ContainsText(Ctxt.Url, '/login') and (InJson<>'') then
             state:= LouisServices.login(inJSon)
          else
             state.state:= HTTP_NOTFOUND;
        end
        else
        if CompareText(Ctxt.Method, 'POST')=0 then
        begin
          if ContainsText(Ctxt.Url, '/device') then
            state:= LouisServices.postDevices(Ctxt.InContent)
          else
          if ContainsText(Ctxt.Url, '/blood') then
            state:= LouisServices.postBloodGroup(Ctxt.InContent)
          else
          if ContainsText(Ctxt.Url, '/patient') then
            state:= LouisServices.postPatient(Ctxt.InContent)
          else
          if ContainsText(Ctxt.Url, '/parameter') then
            state:= LouisServices.postParameters(Ctxt.InContent)
          else
          if ContainsText(Ctxt.Url, '/unit') then
            state:= LouisServices.postUnits(Ctxt.InContent)
          else
          if ContainsText(Ctxt.Url, '/central') then
            state:= LouisServices.postCentral(Ctxt.InContent)
          else
          if ContainsText(Ctxt.Url, '/bed') then
            state:= LouisServices.postBed(Ctxt.InContent)
          else
          if ContainsText(Ctxt.Url, '/centrallink') then
            state:= LouisServices.postCentralLinks(Ctxt.InContent)
          else
          if ContainsText(Ctxt.Url, '/depilink') then
            state:= LouisServices.postDPILinks(Ctxt.InContent)
          else
            state.state:= HTTP_NOTFOUND;
        end
        else
        if CompareText(Ctxt.Method, 'DELETE')=0 then
        begin
          if ContainsText(Ctxt.Url, '/device') then
            state:= LouisServices.deleteDevices(ExtractId('device'))
          else
          if ContainsText(Ctxt.Url, '/blood') then
            state:= LouisServices.deleteBloodGroup(ExtractId('blood'))
          else
          if ContainsText(Ctxt.Url, '/patient') then
            state:= LouisServices.deletePatient(ExtractId('patient'))
          else
          if ContainsText(Ctxt.Url, '/parameter') then
            state:= LouisServices.deleteParameters(ExtractId('parameter'))
          else
          if ContainsText(Ctxt.Url, '/unit') then
            state:= LouisServices.deleteUnits(ExtractId('unit'))
          else
          if ContainsText(Ctxt.Url, '/central') then
            state:= LouisServices.deleteCentral(ExtractId('central'))
          else
          if ContainsText(Ctxt.Url, '/bed') then
            state:= LouisServices.deleteBed(ExtractId('bed'))
          else
          if ContainsText(Ctxt.Url, '/centrallink') then
            state:= LouisServices.deleteCentralLinks(ExtractId('centrallink'))
          else
          if ContainsText(Ctxt.Url, '/depilink') then
            state:= LouisServices.deleteDPILinks(ExtractId('depilink'))
          else
            state.state:= HTTP_NOTFOUND;
        end
        else
            state.state:= HTTP_BADREQUEST;
      end
      else
      begin
        state.state:= stateTok;
        state.response:= '{"error":"invalid token"}';
      end;

      // définir la réponse HTTP
      Ctxt.OutContentType := 'application/json';
      Ctxt.OutContent:= state.response;
      Result := state.state;
    except
    end;
    FreeAndNil(LouisServices);
  end
  else
  begin
    Ctxt.OutContentType:= 'URL INVALIDE';
    result:= 500;
  end;
end;
{$ENDIF}

end.

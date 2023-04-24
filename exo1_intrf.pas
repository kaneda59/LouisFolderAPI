unit exo1_intrf;

interface

  uses
       windows,
       system.SysUtils,
       data.DBXJSON,
       Louis.json.objects,
       synlog,
       syncommons,
       mORMot,
       mORmotHTTPServer;

type
  IMessageCallback = interface(IInvokable)
    ['{F088C57F-BF9F-4D6C-B46D-CC7F606AF080}']
    procedure NotifyMessage(const login, msg: string);
  end;

  IMessageService = interface(IServiceWithCallbackReleased)
    ['{164CEFCD-86CC-4644-8003-0B6152AEA4EC}']
    procedure Join(const login: string; const callback: IMessageCallback);
    procedure Message(const login, msg: string);
  end;

  ILouisServices = interface(IInvokable)
  ['{E7D03A61-2F97-465F-8D10-566E6563C86C}']
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
  end;

  procedure ODS(const strType: string; const position: string; const msg: string);

const TRANSMISSION_KEY = '5A3A4E96-4352-4B7F-BF17-BF5E3D77CC6A';


implementation

procedure ODS(const strType: string; const position: string; const msg: string);
begin
  outputdebugstring(pchar(format('[%s] - %s (%s) : %s', [FormatDateTime('dd/mm/yyyy hh:nn:ss', now), strType, Position, Msg])));
end;

initialization

  TInterfaceFactory.RegisterInterfaces([TypeInfo(IMessageService),TypeInfo(IMessageCallback)]);

end.

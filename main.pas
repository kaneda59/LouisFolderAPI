unit main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.SvcMgr, Vcl.Dialogs, System.Win.Registry;

type
  TLouisSVC = class(TService)
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure ServiceStop(Sender: TService; var Stopped: Boolean);
    procedure ServicePause(Sender: TService; var Paused: Boolean);
    procedure ServiceShutdown(Sender: TService);
    procedure ServiceCreate(Sender: TObject);
    procedure ServiceDestroy(Sender: TObject);
  private
    { D�clarations priv�es }
  public
    function GetServiceController: TServiceController; override;
    { D�clarations publiques }
  end;

var
  LouisSVC: TLouisSVC;

implementation

  uses exo1_impl;

{$R *.dfm}

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  LouisSVC.Controller(CtrlCode);
end;

function TLouisSVC.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TLouisSVC.ServiceCreate(Sender: TObject);
begin
  global_server := TServer.Create;
end;

procedure TLouisSVC.ServiceDestroy(Sender: TObject);
begin
  FreeAndNil(global_server);
end;

procedure TLouisSVC.ServicePause(Sender: TService; var Paused: Boolean);
begin
  global_server.ActiveServer(Paused);
end;

procedure TLouisSVC.ServiceShutdown(Sender: TService);
begin
  global_server.ActiveServer(False);
end;

procedure TLouisSVC.ServiceStart(Sender: TService; var Started: Boolean);
begin
  global_server.ActiveServer(Started);
end;

procedure TLouisSVC.ServiceStop(Sender: TService; var Stopped: Boolean);
begin
  global_server.ActiveServer(Stopped);
end;

end.

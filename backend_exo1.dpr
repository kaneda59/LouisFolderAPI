program backend_exo1;

uses
  Vcl.SvcMgr,
  main in 'main.pas' {LouisSVC: TService},
  exo1_intrf in 'exo1_intrf.pas',
  exo1_impl in 'exo1_impl.pas',
  data in 'data.pas' {module: TDataModule},
  Louis.service in 'Louis.service.pas',
  Louis.json.objects in 'Louis.json.objects.pas',
  Louis.json.tools in 'Louis.json.tools.pas',
  Louis.orm.tools in 'Louis.orm.tools.pas';

{$R *.RES}

begin
  // Windows 2003 Server nécessite que StartServiceCtrlDispatcher soit
  // appelé avant CoRegisterClassObject, qui peut être appelé indirectement
  // par Application.Initialize. TServiceApplication.DelayInitialize permet
  // l'appel de Application.Initialize depuis TService.Main (après
  // l'appel de StartServiceCtrlDispatcher).
  //
  // L'initialisation différée de l'objet Application peut affecter
  // les événements qui surviennent alors avant l'initialisation, tels que
  // TService.OnCreate. Elle est seulement recommandée si le ServiceApplication
  // enregistre un objet de classe avec OLE et est destinée à une utilisation
  // avec Windows 2003 Server.
  //
  // Application.DelayInitialize := True;
  //
  if not Application.DelayInitialize or Application.Installing then
    Application.Initialize;
  Application.CreateForm(TLouisSVC, LouisSVC);
  Application.CreateForm(Tmodule, module);
  Application.Run;
end.

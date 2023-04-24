object LouisSVC: TLouisSVC
  OldCreateOrder = True
  OnCreate = ServiceCreate
  OnDestroy = ServiceDestroy
  DisplayName = 'louis service'
  OnPause = ServicePause
  OnShutdown = ServiceShutdown
  OnStart = ServiceStart
  OnStop = ServiceStop
  Height = 1080
  Width = 1440
end

unit Louis.json.objects;

interface

uses System.SysUtils,
     System.Classes,
     SynCommons,
     mORMot;

type

  TResponse = record
    response: RawJSON;
    state   : cardinal;
  end;

  TRequestParam = class
  private
    fdateend: TDateTime;
    fdatestart: TDateTime;
    fxpressoid: integer;
  published
    property xpressoid: integer   read fxpressoid write fxpressoid;
    property datestart: TDateTime read fdatestart write fdatestart;
    property dateend  : TDateTime read fdateend   write fdateend;
  end;

  TUserLogin = class(TPersistentWithCustomCreate)
  private
    Flogin: RawUTF8;
    Fpassword: RawUTF8;
  published
    property login: RawUTF8 read Flogin write FLogin;
    property password: RawUTF8 read Fpassword write FPassword;
  end;

  TDevice = class(TPersistentWithCustomCreate)
  private
    fName: RawUTF8;
    fbrands: RawUTF8;
    fDescription: RawUTF8;
    fdevice_type: RawUTF8;
    fid: integer;
  published
    property id         : integer read fid          write fid;
    property name       : RawUTF8 read fName        write fName;
    property description: RawUTF8 read fDescription write fDescription;
    property brands     : RawUTF8 read fbrands      write fBrands;
    property device_type: RawUTF8 read fdevice_type write fdevice_type;
  end;

  TBlood = class(TPersistentWithCustomCreate)
  private
    fid: integer;
    fbloodgroup: RawUTF8;
  published
    property id         : integer   read fid          write fid;
    property bloodgroup : RawUTF8   read fbloodgroup  write fbloodgroup;
  end;

  TBed = class(TPersistentWithCustomCreate)
  private
    fid: integer;
    fname: RawUTF8;
  published
    property id         : integer   read fid          write fid;
    property name       : RawUTF8   read fname        write fname;
  end;

  TPatient = class(TPersistentWithCustomCreate)
  private
    fbirthdate: TDateTime;
    flastname: RawUTF8;
    fpid: RawUTF8;
    fWidth: integer;
    fid: integer;
    fbloodid: integer;
    ffirstname: RawUTF8;
    fHeight: Integer;
  published
    property id         : integer   read fid          write fid;
    property firstname  : RawUTF8   read ffirstname   write ffirstname;
    property lastname   : RawUTF8   read flastname    write flastname;
    property birthdate  : TDateTime read fbirthdate   write fbirthdate;
    property pid        : RawUTF8   read fpid         write fpid;
    property bloodid    : integer   read fbloodid     write fbloodid;
    property Height     : Integer   read fHeight      write fHeight;
    property Width      : integer   read fWidth       write fWidth;
  end;

  TParameter  = class(TPersistentWithCustomCreate)
  private
    fname       : RawUTF8;
    fSending    : Boolean;
    fid         : integer;
    fxpressoid  : integer;
    fdescription: RawUTF8;
    factive     : Boolean;
  published
    property id         : integer    read fid          write fid;
    property xpressoid  : integer    read fxpressoid   write fxpressoid;
    property name       : RawUTF8    read fname        write fname;
    property description: RawUTF8    read fdescription write fdescription;
    property sending    : Boolean    read fSending     write fSending;
    property active     : Boolean    read factive      write factive;
  end;

  TUnit = class(TPersistentWithCustomCreate)
  private
    fname  : RawUTF8;
    funitid: integer;
    fid    : integer;
  published
    property id         : integer    read fid          write fid;
    property name       : RawUTF8    read fname        write fname;
    property unitid     : integer    read funitid      write funitid;
  end;

  TCentral = class(TPersistentWithCustomCreate)
  private
    fname: RawUTF8;
    fid: Integer;
    fport: RawUTF8;
    fdescription: RawUTF8;
    fhost: RawUTF8;
  published
    property id         : Integer    read fid          write fid;
    property name       : RawUTF8    read fname        write fname;
    property host       : RawUTF8    read fhost        write fhost;
    property port       : RawUTF8    read fport        write fport;
    property description: RawUTF8    read fdescription write fdescription;
  end;

  // 0 = parameters, 1 = units, 2 = beds
  TCentralLink = class(TPersistentWithCustomCreate)
  private
    fcentralcode: RawUTF8;
    fcentrallink: integer;
    fcentralid  : integer;
    fid         : integer;
    fcentraltype: integer;
  published
    property id         : integer    read fid          write fid;
    property centralid  : integer    read fcentralid   write fcentralid;
    property centralcode: RawUTF8    read fcentralcode write fcentralcode;
    property centraltype: integer    read fcentraltype write fcentraltype;
    property centrallink: integer    read fcentrallink write fcentrallink;
  end;

  // 0 = parameters, 1 = units, 2 = beds
  TDpiLink = class(TPersistentWithCustomCreate)
  private
    fdpicode: RawUTF8;
    fid: integer;
    fdpiid: integer;
    fdpitype: integer;
  published
    property id         : integer    read fid          write fid;
    property dpiid      : integer    read fdpiid       write fdpiid;
    property dpicode    : RawUTF8    read fdpicode     write fdpicode;
    property dpitype    : integer    read fdpitype     write fdpitype;
  end;

  TBedStatus = class(TPersistentWithCustomCreate)
  private
    fstate: Boolean;
    fid: integer;
    finterval: integer;
    fidbed: integer;
    fintervaldefault: integer;
  published
    property id         : integer    read fid          write fid;
    property idbed      : integer    read fidbed       write fidbed;
    property state      : Boolean    read fstate       write fstate;
    property interval   : integer    read finterval    write finterval;
    property intervalDefault: integer read fintervaldefault write fintervaldefault;
  end;

  TParamValue = class(TPersistentWithCustomCreate)
  private
    fdate_param: TDateTime;
    fidunit    : integer;
    fid        : integer;
    fxpressoid : integer;
    fvalue     : RawUTF8;
    fobx       : RawUTF8;
    fidpat     : integer;
    fidbed     : integer;
    fMsgID     : RawUTF8;
    property id        : integer     read fid          write fid;
    property xpressoid : integer     read fxpressoid   write fxpressoid;
    property date_param: TDateTime   read fdate_param  write fdate_param;
    property idunit    : integer     read fidunit      write fidunit;
    property value     : RawUTF8     read fvalue       write fvalue;
    property obx       : RawUTF8     read fobx         write fobx;
    property MsgID     : RawUTF8     read fMsgID       write fMSGID;
    property idbed     : integer     read fidbed       write fidbed;
    property idpat     : integer     read fidpat       write fidpat;
  end;


  { exemple :

       centrale

          id       name
          1        centrale philips

       parameters

          xpressoid   name
          162         SPO2

       units

          unitid      name
          2065        %

      centralLink

          centralid   centralcode   centraltype  centrallink
             1         0004-u20u    0            162             // parameters
             1         0004-p02p    1            2065            // units

      dpiLinks

          dpiid       dpicode       dpitype
          162         F-20265          0
          2065        pct              1

  }


implementation

initialization

  RegisterClasses([
                     TDevice, TBlood, TBed, TParameter, TUnit, TCentral, TCentralLink, TDpiLink, TPatient
                  ]);

finalization

  UnRegisterClasses([
                      TDevice, TBlood, TBed, TParameter, TUnit, TCentral, TCentralLink, TDpiLink, TPatient
                    ])

end.

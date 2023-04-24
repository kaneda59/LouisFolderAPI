unit Louis.orm.tools;

interface

  uses System.SysUtils, System.Classes, Louis.json.objects, mORMot, exo1_intrf
       , SynCommons
       , SynLog
       , System.TypInfo
       , Louis.json.tools;

  function getDataDevice     (const id: integer = 0): TResponse;
  function getDataBlood      (const id: integer = 0): TResponse;
  function getDataPatient    (const id: integer = 0): TResponse;
  function getDataParameter  (const id: integer = 0): TResponse;
  function getDataUnit       (const id: integer = 0): TResponse;
  function getDataCentral    (const id: integer = 0): TResponse;
  function getDataBed        (const id: integer = 0): TResponse;
  function getDataCentralLink(const id: integer = 0): TResponse;
  function getDataDPILink    (const id: integer = 0): TResponse;
  function getDataBedStatus  (const id: Integer = 0): TResponse;

  function objectExists      (const object_name: string; const id: integer): Boolean;

  function deleteDataObject  (const object_name: string; const id: integer): TResponse;

  function postDataDevices    (JSonValue: RawUTF8): TResponse;
  function postDataBloodGroup (JSonValue: RawUTF8): TResponse;
  function postDataPatient    (JSonValue: RawUTF8): TResponse;
  function postDataParameter  (JSonValue: RawUTF8): TResponse;
  function postDataUnit       (JSonValue: RawUTF8): TResponse;
  function postDataCentral    (JSonValue: RawUTF8): TResponse;
  function postDataBed        (JSonValue: RawUTF8): TResponse;
  function postDataCentralLink(JSonValue: RawUTF8): TResponse;
  function postDataDPILink    (JSonValue: RawUTF8): TResponse;
  function postDataBedStatus  (JSonValue: RawUTF8): TResponse;




implementation

uses data;

function GenerateInsertSQL(const AObject: TObject; const object_name: string): string;
var
  PropList: PPropList;
  PropCount, I: integer;
  PropName, PropValue: string;
begin
  PropCount := GetPropList(AObject.ClassInfo, PropList);
  try
    Result := 'INSERT INTO ' + object_name + ' (';
    for I := 0 to PropCount - 1 do
    if LowerCase(PropList[I]^.Name)<>'id' then
    begin
      PropName := PropList[I]^.Name;
      PropValue := GetPropValue(AObject, PropName, True);
      if PropValue = '' then Continue; // skip empty properties
      //if I > 0 then Result := Result + ', ';
      Result := Result + PropName + ',';
    end;
    Delete(Result, Length(Result), 1);
    Result := Result + ') VALUES (';
    for I := 0 to PropCount - 1 do
    if LowerCase(PropList[I]^.Name)<>'id' then
    begin
      PropValue := GetPropValue(AObject, PropList[I]^.Name, True);
      if PropValue = '' then Continue; // skip empty properties
      //if I > 0 then Result := Result + ', ';
      Result := Result + QuotedStr(PropValue) + ',';
    end;
    delete(Result, Length(result), 1);
    Result := Result + ');';
  finally
    FreeMem(PropList); // always free memory allocated by GetPropList
  end;
end;

function GenerateUpdateSQL(AObject: TObject; object_name: string): string;
var
  TypeInfo: PTypeInfo;
  TypeData: PTypeData;
  PropList: PPropList;
  PropInfo: PPropInfo;
  PropCount, I: Integer;
  PropName, PropValue: string;
  FormatSettings: TFormatSettings;
begin
  Result := '';
  TypeInfo := AObject.ClassInfo;
  TypeData := GetTypeData(TypeInfo);
  PropCount := TypeData^.PropCount;
  if PropCount = 0 then
    Exit;

  // Utilisation de TFormatSettings pour formater les dates
  FormatSettings := TFormatSettings.Create;
  FormatSettings.DateSeparator := '-';
  FormatSettings.ShortDateFormat := 'yyyy-mm-dd';

  Result := 'UPDATE ' + object_name + ' SET ';
  GetMem(PropList, PropCount * SizeOf(Pointer));
  try
    GetPropInfos(TypeInfo, PropList);
    for I := 0 to PropCount - 1 do
    begin
      PropInfo := PropList^[I];
      PropName := PropInfo.Name;
      if PropInfo^.PropType^.Kind in [tkArray, tkRecord, tkInterface] then
        Continue;
      if PropInfo^.PropType^.Kind = tkClass then
        Continue;
      PropValue := GetPropValue(AObject, PropName, True);
      // Utilisation de IsType pour détecter les dates
      if PropInfo^.PropType^.Name = 'TDateTime' then
        PropValue := FormatDateTime('yyyy-mm-dd hh:nn:ss', StrToDateTime(PropValue), FormatSettings)
      else if (PropInfo^.PropType^.Name = 'Extended') or (PropInfo^.PropType^.Name = 'double') then
        PropValue := FloatToStr(StrToFloat(PropValue), FormatSettings)
      else
      if not (PropInfo^.PropType^.Kind in [tkInteger, tkInt64]) then
        PropValue := QuotedStr(PropValue);
      if PropValue <> '' then
      begin
        if Result <> 'UPDATE ' + object_name + ' SET ' then
          Result := Result + ', ';
        Result := Result + PropName + ' = ' + PropValue;
      end;
    end;
    Result := Result + ' WHERE id = ' + IntToStr(GetPropValue(AObject, 'id', True));
  finally
    FreeMem(PropList, PropCount * SizeOf(Pointer));
  end;
end;


//function GenerateUpdateSQL(AObject: TObject; object_name: string): string;
//var
//  TypeInfo: PTypeInfo;
//  TypeData: PTypeData;
//  PropList: PPropList;
//  PropInfo: PPropInfo;
//  PropCount, I: Integer;
//  PropName, PropValue: string;
//begin
//  Result := '';
//  TypeInfo := AObject.ClassInfo;
//  TypeData := GetTypeData(TypeInfo);
//  PropCount := TypeData^.PropCount;
//  if PropCount = 0 then
//    Exit;
//
//  Result := 'UPDATE ' + object_name + ' SET ';
//  GetMem(PropList, PropCount * SizeOf(Pointer));
//  try
//    GetPropInfos(TypeInfo, PropList);
//    for I := 0 to PropCount - 1 do
//    begin
//      PropInfo := PropList^[I];
//      PropName := PropInfo.Name;
//      if PropInfo^.PropType^.Kind in [tkArray, tkRecord, tkInterface] then
//        Continue;
//      if PropInfo^.PropType^.Kind = tkClass then
//        Continue;
//      PropValue := GetPropValue(AObject, PropName, True);
//      if PropValue <> '' then
//      begin
//        if PropInfo^.PropType^.Kind = tkFloat then
//           PropValue := FormatFloat('#,##0.##', StrToFloat(PropValue), TFormatSettings.Create('en-US'));
//          //PropValue := FloatToStr(StrToFloat(PropValue, FormatSettings.DecimalSeparator, FormatSettings.ThousandSeparator, '1234567.89'));
//        if Result <> 'UPDATE ' + object_name + ' SET ' then
//          Result := Result + ', ';
//        if PropInfo^.PropType^.Kind in [tkInteger, tkInt64] then
//             Result := Result + PropName + ' = ' + PropValue
//        else Result := Result + PropName + ' = ' + QuotedStr(PropValue);
//      end;
//    end;
//    Result := Result + ' WHERE id = ' + IntToStr(GetPropValue(AObject, 'id', True));
//  finally
//    FreeMem(PropList, PropCount * SizeOf(Pointer));
//  end;
//end;



//function GenerateUpdateSQL(AObject: TObject; object_name: string): string;
//var
//  TypeInfo: PTypeInfo;
//  TypeData: PTypeData;
//  PropList: PPropList;
//  PropInfo: PPropInfo;
//  PropCount, I: Integer;
//  PropName, PropValue: string;
//begin
//  Result := '';
//  TypeInfo := AObject.ClassInfo;
//  TypeData := GetTypeData(TypeInfo);
//  PropCount := TypeData^.PropCount;
//  if PropCount = 0 then
//    Exit;
//
//  Result := 'UPDATE ' + object_name + ' SET ';
//  GetMem(PropList, PropCount * SizeOf(Pointer));
//  try
//    GetPropInfos(TypeInfo, PropList);
//    for I := 0 to PropCount - 1 do
//    begin
//      PropInfo := PropList^[I];
//      PropName := PropInfo.Name;
//      if PropInfo^.PropType^.Kind in [tkArray, tkRecord, tkInterface] then
//        Continue;
//      if PropInfo^.PropType^.Kind = tkClass then
//        Continue;
//      PropValue := GetPropValue(AObject, PropName, True);
//      if PropValue <> '' then
//      begin
//        if Result <> 'UPDATE ' + object_name + ' SET ' then
//          Result := Result + ', ';
//        Result := Result + PropName + ' = ' + PropValue;
//      end;
//    end;
//    Result := Result + ' WHERE id = ' + IntToStr(GetPropValue(AObject, 'id', True));
//  finally
//    FreeMem(PropList, PropCount * SizeOf(Pointer));
//  end;
//end;


function objectExists      (const object_name: string; const id: integer): Boolean;
begin
  result:= False;
  if id>0 then
  with module.AddQuery do
  try
    SQL.Add('select * from ' + object_name);
    SQL.Add('where id=:id');
    Parameters.ParamByName('id').Value:= id;
    try
      Open;
      result:= FieldByName('id').AsInteger=id;
      Close;
    except
      on e: Exception do
        ODS('error', 'objectExists(' + object_name + ', ' + intToStr(id) + ')', e.message);
    end;
  finally
    Free;
  end;
end;

function deleteDataObject (const object_name: string; const id: integer): TResponse;
begin
  if objectExists(object_name, id) then
  with module.AddQuery do
  try
    SQL.Add('delete from ' + object_name);
    SQL.Add('where id=:id');
    Parameters.ParamByName('id').Value:= id;
    try
      ExecSQL;
      result.State:= 200;
      result.response:= '{"info":"'+ object_name+' supprimé"}';
    except
      on e: Exception do
      begin
        result.state:= 500;
        result.response:= '{"error":"' + e.Message+'"}';
      end;
    end;
  finally
    Free;
  end
  else
  begin
    result.state:= 400;
    result.response:= '{"error":"'+ object_name+' non trouvé"}';
  end;
end;

function getDataDevice(const id: integer = 0): TResponse;
var s  : string;
    i  : integer;
    obj: TDevice;
begin
  obj:= TDevice.Create;
  with module.AddQuery do
  try
    try
      SQL.Add('select * from device');
      if id>0 then
        SQL.Add('where id=' + intToStr(id));
      Open;

      if (Eof=Bof) then
      begin
        Result.state:= HTTP_NOTFOUND;
        Result.response:= '{"error":"not record found"}';
        exit;
      end;

      s:= '';
      while not Eof do
      begin
        obj.id         := FieldByName('id').AsInteger;
        obj.name       := FieldByName('name').AsString;
        obj.description:= FieldByName('description').AsString;
        obj.brands     := FieldByName('brands').AsString;
        obj.device_type:= FieldByName('device_type').AsString;
        s := s + classToJSon(obj) + ',';
        Next;
      end;
      System.delete(s, length(s), 1);
      Close;
      result.state:= HTTP_SUCCESS;
      if id<=0 then
           result.response := '[' + s + ']'
      else result.response  := s;
    except
      on e: exception do
      begin
        Result.state := HTTP_NOTFOUND;
        Result.response:= '{"error":"'+ e.message+'"}';
      end;
    end;
  finally
    Free;
    FreeAndNil(obj);
  end;
end;

function getDataBlood(const id: integer = 0): TResponse;
var s  : string;
    i  : integer;
    obj: TBlood;
begin
  obj:= TBlood.Create;
  with module.AddQuery do
  try
    try
      SQL.Add('select * from bloodgroup');
      if id>0 then
        SQL.Add('where id=' + intToStr(id));
      Open;

      if (Eof=Bof) then
      begin
        Result.state:= HTTP_NOTFOUND;
        Result.response:= '{"error":"not record found"}';
        exit;
      end;

      s:= '';
      while not Eof do
      begin
        obj.id         := FieldByName('id').AsInteger;
        obj.bloodgroup := FieldByName('bloodgroup').AsString;
        s := s + classToJSon(obj) + ',';
        Next;
      end;
      System.delete(s, length(s), 1);
      Close;
      result.state:= HTTP_SUCCESS;
      if id<=0 then
           result.response := '[' + s + ']'
      else result.response  := s;
    except
      on e: exception do
      begin
        Result.state := HTTP_NOTFOUND;
        Result.response:= '{"error":"'+ e.message+'"}';
      end;
    end;
  finally
    Free;
    FreeAndNil(obj);
  end;
end;

function getDataPatient(const id: integer = 0): TResponse;
var s  : string;
    i  : integer;
    obj: TPatient;
begin
  obj:= TPatient.Create;
  with module.AddQuery do
  try
    try
      SQL.Add('select * from patient');
      if id>0 then
        SQL.Add('where id=' + intToStr(id));
      Open;

      if (Eof=Bof) then
      begin
        Result.state:= HTTP_NOTFOUND;
        Result.response:= '{"error":"not record found"}';
        exit;
      end;

      s:= '';
      while not Eof do
      begin
        obj.id         := FieldByName('id').AsInteger;
        obj.firstname  := FieldByName('firstname').AsString;
        obj.lastname   := FieldByName('lastname').AsString;
        obj.birthdate  := FieldByName('birthdate').AsDateTime;
        obj.pid        := FieldByName('pid').AsString;
        obj.bloodid    := FieldByName('bloodid').AsInteger;
        obj.Height     := FieldByName('height').AsInteger;
        obj.Width      := FieldByName('width').AsInteger;
        s := s + classToJSon(obj) + ',';
        Next;
      end;
      System.delete(s, length(s), 1);
      Close;
      result.state:= HTTP_SUCCESS;
      if id<=0 then
           result.response := '[' + s + ']'
      else result.response  := s;
    except
      on e: exception do
      begin
        Result.state := HTTP_NOTFOUND;
        Result.response:= '{"error":"'+ e.message+'"}';
      end;
    end;
  finally
    Free;
    FreeAndNil(obj);
  end;
end;

function getDataParameter(const id: integer = 0): TResponse;
var s  : string;
    i  : integer;
    obj: TParameter;
begin
  obj:= TParameter.Create;
  with module.AddQuery do
  try
    try
      SQL.Add('select * from parameter');
      if id>0 then
        SQL.Add('where id=' + intToStr(id));
      Open;

      if (Eof=Bof) then
      begin
        Result.state:= HTTP_NOTFOUND;
        Result.response:= '{"error":"not record found"}';
        exit;
      end;

      s:= '';
      while not Eof do
      begin
        obj.id         := FieldByName('id').AsInteger;
        obj.xpressoid  := FieldByName('xpressoid').AsInteger;
        obj.name       := FieldByName('name').AsString;
        obj.description:= FieldByName('description').AsString;
        obj.sending    := FieldByName('sending').AsBoolean;
        obj.active     := FieldByName('active').AsBoolean;
        s := s + classToJSon(obj) + ',';
        Next;
      end;
      System.delete(s, length(s), 1);
      Close;
      result.state:= HTTP_SUCCESS;
      if id<=0 then
           result.response := '[' + s + ']'
      else result.response  := s;
    except
      on e: exception do
      begin
        Result.state := HTTP_NOTFOUND;
        Result.response:= '{"error":"'+ e.message+'"}';
      end;
    end;
  finally
    Free;
    FreeAndNil(obj);
  end;
end;

function getDataUnit     (const id: Integer = 0): TResponse;
var s  : string;
    i  : integer;
    obj: TUnit;
begin
  obj:= TUnit.Create;
  with module.AddQuery do
  try
    try
      SQL.Add('select * from unit');
      if id>0 then
        SQL.Add('where id=' + intToStr(id));
      Open;

      if (Eof=Bof) then
      begin
        Result.state:= HTTP_NOTFOUND;
        Result.response:= '{"error":"not record found"}';
        exit;
      end;

      s:= '';
      while not Eof do
      begin
        obj.id         := FieldByName('id').AsInteger;
        obj.name       := FieldByName('name').AsString;
        obj.unitid     := FieldByName('unitid').AsInteger;
        s := s + classToJSon(obj) + ',';
        Next;
      end;
      System.delete(s, length(s), 1);
      Close;
      result.state:= HTTP_SUCCESS;
      if id<=0 then
           result.response := '[' + s + ']'
      else result.response  := s;
    except
      on e: exception do
      begin
        Result.state := HTTP_NOTFOUND;
        Result.response:= '{"error":"'+ e.message+'"}';
      end;
    end;
  finally
    Free;
    FreeAndNil(obj);
  end;
end;

function getDataCentral  (const id: integer = 0): TResponse;
var s  : string;
    i  : integer;
    obj: TCentral;
begin
  obj:= TCentral.Create;
  with module.AddQuery do
  try
    try
      SQL.Add('select * from central');
      if id>0 then
        SQL.Add('where id=' + intToStr(id));
      Open;

      if (Eof=Bof) then
      begin
        Result.state:= HTTP_NOTFOUND;
        Result.response:= '{"error":"not record found"}';
        exit;
      end;

      s:= '';
      while not Eof do
      begin
        obj.id         := FieldByName('id').AsInteger;
        obj.name       := FieldByName('name').AsString;
        obj.host       := FieldByName('host').AsString;
        obj.port       := FieldByName('port').AsString;
        obj.description:= FieldByName('description').AsString;
        s := s + classToJSon(obj) + ',';
        Next;
      end;
      System.delete(s, length(s), 1);
      Close;
      result.state:= HTTP_SUCCESS;
      if id<=0 then
           result.response := '[' + s + ']'
      else result.response  := s;
    except
      on e: exception do
      begin
        Result.state := HTTP_NOTFOUND;
        Result.response:= '{"error":"'+ e.message+'"}';
      end;
    end;
  finally
    Free;
    FreeAndNil(obj);
  end;
end;

function getDataBed      (const id: integer = 0): TResponse;
var s  : string;
    i  : integer;
    obj: TBed;
begin
  obj:= TBed.Create;
  with module.AddQuery do
  try
    try
      SQL.Add('select * from bed');
      if id>0 then
        SQL.Add('where id=' + intToStr(id));
      Open;

      if (Eof=Bof) then
      begin
        Result.state:= HTTP_NOTFOUND;
        Result.response:= '{"error":"not record found"}';
        exit;
      end;

      s:= '';
      while not Eof do
      begin
        obj.id         := FieldByName('id').AsInteger;
        obj.name       := FieldByName('name').AsString;
        s := s + classToJSon(obj) + ',';
        Next;
      end;
      System.delete(s, length(s), 1);
      Close;
      result.state:= HTTP_SUCCESS;
      if id<=0 then
           result.response := '[' + s + ']'
      else result.response  := s;
    except
      on e: exception do
      begin
        Result.state := HTTP_NOTFOUND;
        Result.response:= '{"error":"'+ e.message+'"}';
      end;
    end;
  finally
    Free;
    FreeAndNil(obj);
  end;
end;

function getDataCentralLink(const id: integer = 0): TResponse;
var s  : string;
    i  : integer;
    obj: TCentralLink;
begin
  obj:= TCentralLink.Create;
  with module.AddQuery do
  try
    try
      SQL.Add('select * from central_link');
      if id>0 then
        SQL.Add('where id=' + intToStr(id));
      Open;

      if (Eof=Bof) then
      begin
        Result.state:= HTTP_NOTFOUND;
        Result.response:= '{"error":"not record found"}';
        exit;
      end;

      s:= '';
      while not Eof do
      begin
        obj.id         := FieldByName('id').AsInteger;
        obj.centralid  := FieldByName('centralid').AsInteger;
        obj.centralcode:= FieldByName('centralcode').AsString;
        obj.centraltype:= FieldByName('centraltype').AsInteger;
        obj.centrallink:= FieldByName('centrallink').AsInteger;
        s := s + classToJSon(obj) + ',';
        Next;
      end;
      System.delete(s, length(s), 1);
      Close;
      result.state:= HTTP_SUCCESS;
      if id<=0 then
           result.response := '[' + s + ']'
      else result.response  := s;
    except
      on e: exception do
      begin
        Result.state := HTTP_NOTFOUND;
        Result.response:= '{"error":"'+ e.message+'"}';
      end;
    end;
  finally
    Free;
    FreeAndNil(obj);
  end;
end;

function getDataDPILink    (const id: integer = 0): TResponse;
var s  : string;
    i  : integer;
    obj: TDPILink;
begin
  obj:= TDPILink.Create;
  with module.AddQuery do
  try
    try
      SQL.Add('select * from dpi_link');
      if id>0 then
        SQL.Add('where id=' + intToStr(id));
      Open;

      if (Eof=Bof) then
      begin
        Result.state:= HTTP_NOTFOUND;
        Result.response:= '{"error":"not record found"}';
        exit;
      end;

      s:= '';
      while not Eof do
      begin
        obj.id         := FieldByName('id').AsInteger;
        obj.dpiid      := FieldByName('dpiid').AsInteger;
        obj.dpicode    := FieldByName('dpicode').AsString;
        obj.dpitype    := FieldByName('dpitype').AsInteger;
        s := s + classToJSon(obj) + ',';
        Next;
      end;
      System.delete(s, length(s), 1);
      Close;
      result.state:= HTTP_SUCCESS;
      if id<=0 then
           result.response := '[' + s + ']'
      else result.response  := s;
    except
      on e: exception do
      begin
        Result.state := HTTP_NOTFOUND;
        Result.response:= '{"error":"'+ e.message+'"}';
      end;
    end;
  finally
    Free;
    FreeAndNil(obj);
  end;
end;

function getDataBedStatus  (const id: Integer = 0): TResponse;
var s  : string;
    i  : integer;
    obj: TBedStatus;
begin
  obj:= TBedStatus.Create;
  with module.AddQuery do
  try
    try
      SQL.Add('select * from bed_status');
      if id>0 then
        SQL.Add('where id=' + intToStr(id));
      Open;

      if (Eof=Bof) then
      begin
        Result.state:= HTTP_NOTFOUND;
        Result.response:= '{"error":"not record found"}';
        exit;
      end;

      s:= '';
      while not Eof do
      begin
        obj.id         := FieldByName('id').AsInteger;
        obj.idbed      := FieldByName('idbed').AsInteger;
        obj.state      := FieldByName('state').AsBoolean;
        obj.interval   := FieldByName('interval').AsInteger;
        obj.intervalDefault := FieldByName('intervalDefault').AsInteger;
        s := s + classToJSon(obj) + ',';
        Next;
      end;
      System.delete(s, length(s), 1);
      Close;
      result.state:= HTTP_SUCCESS;
      if id<=0 then
           result.response := '[' + s + ']'
      else result.response  := s;
    except
      on e: exception do
      begin
        Result.state := HTTP_NOTFOUND;
        Result.response:= '{"error":"'+ e.message+'"}';
      end;
    end;
  finally
    Free;
    FreeAndNil(obj);
  end;
end;

function executePostScript(obj: TObject; const obj_name: string; const id: integer): TResponse;
begin
  with module.AddQuery do
  try
    if objectExists(obj_name, id) then
         SQL.Text:= GenerateUpdateSQL(obj, obj_name)
    else SQL.Text:= GenerateInsertSQL(obj, obj_name);

  try
    ExecSQL;
    Result.state:= 200;
    Result.response:= '{"info":"'+obj_name+' mis à jour"}';
  except
    on e: Exception do
    begin
      Result.state:= 500;
      Result.response:= '{"error":"erreur lors de l''insertion : ' + e.Message + '"}';
    end;
  end;

  finally
    Free;
  end;
end;


function postDataDevices(JSonValue: RawUTF8): TResponse;
var obj: TDevice;
begin
  obj:= JSonToDevice(JsonValue);
  try
    if assigned(obj) then
    begin
      result:= executePostScript(obj, 'device', obj.id);
    end
    else
    begin
      result.state:= 400;
      result.response:= '{"error":"device non trouvé"}';
    end;
  finally
    FreeAndNil(obj);
  end;
end;

function postDataBloodGroup(JSonValue: RawUTF8): TResponse;
var obj: TBlood;
begin
  obj:= JSonToBloodGroup(JsonValue);
  try
    if assigned(obj) then
    begin
      result:= executePostScript(obj, 'bloodgroup', obj.id);
    end
    else
    begin
      result.state:= 400;
      result.response:= '{"error":"bloodgroup non trouvé"}';
    end;
  finally
    FreeAndNil(obj);
  end;
end;

function postDataPatient(JSonValue: RawUTF8): TResponse;
var obj: TPatient;
begin
  obj:= JSonToPatient(JsonValue);
  try
    if assigned(obj) then
    begin
      result:= executePostScript(obj, 'patient', obj.id);
    end
    else
    begin
      result.state:= 400;
      result.response:= '{"error":"patient non trouvé"}';
    end;
  finally
    FreeAndNil(obj);
  end;
end;

function postDataParameter(JSonValue: RawUTF8): TResponse;
var obj: TParameter;
begin
  obj:= JSonToParameter(JsonValue);
  try
    if assigned(obj) then
    begin
      result:= executePostScript(obj, 'parameter', obj.id);
    end
    else
    begin
      result.state:= 400;
      result.response:= '{"error":"parameter non trouvé"}';
    end;
  finally
    FreeAndNil(obj);
  end;
end;

function postDataUnit(JSonValue: RawUTF8): TResponse;
var obj: TUnit;
begin
  obj:= JSonToUnit(JSonValue);
  try
    if assigned(obj) then
    begin
      result:= executePostScript(obj, 'unit', obj.id);
    end
    else
    begin
      result.state:= 400;
      result.response:= '{"error":"unit non trouvée"}';
    end;
  finally
    FreeAndNil(obj);
  end;
end;

function postDataCentral(JSonValue: RawUTF8): TResponse;
var obj: TCentral;
begin
  obj:= JSonToCentral(JSonValue);
  try
    if assigned(obj) then
    begin
      result:= executePostScript(obj, 'central', obj.id);
    end
    else
    begin
      result.state:= 400;
      result.response:= '{"error":"central non trouvée"}';
    end;
  finally
    FreeAndNil(obj);
  end;
end;

function postDataBed(JSonValue: RawUTF8): TResponse;
var obj: TBed;
begin
  obj:= JSonToBed(JSonValue);
  try
    if assigned(obj) then
    begin
      result:= executePostScript(obj, 'bed', obj.id);
    end
    else
    begin
      result.state:= 400;
      result.response:= '{"error":"lit non trouvé"}';
    end;
  finally
    FreeAndNil(obj);
  end;
end;

function postDataCentralLink(JSonValue: RawUTF8): TResponse;
var obj: TCentralLink;
begin
  obj:= JSonToCentralLink(JSonValue);
  try
    if assigned(obj) then
    begin
      result:= executePostScript(obj, 'central_link', obj.id);
    end
    else
    begin
      result.state:= 400;
      result.response:= '{"error":"lien central non trouvé"}';
    end;
  finally
    FreeAndNil(obj);
  end;
end;

function postDataDPILink(JSonValue: RawUTF8): TResponse;
var obj: TDPILink;
begin
  obj:= JSonToDPILink(JSonValue);
  try
    if assigned(obj) then
    begin
      result:= executePostScript(obj, 'dpi_link', obj.id);
    end
    else
    begin
      result.state:= 400;
      result.response:= '{"error":"lien dpi non trouvé"}';
    end;
  finally
    FreeAndNil(obj);
  end;
end;

function postDataBedStatus  (JSonValue: RawUTF8): TResponse;
var obj: TBedStatus;
begin
  obj:= JSontToBedSatus(JSonValue);
  try
    if assigned(obj) then
    begin
      result:= executePostScript(obj, 'bed_status', obj.id);
    end
    else
    begin
      result.state:= 400;
      result.response:= '{"error":"bed status non trouvé"}';
    end;
  finally
    FreeAndNil(obj);
  end;
end;

end.

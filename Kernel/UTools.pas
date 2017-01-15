{**************************************************************}
{                                                              }
{    (c) Eric Langedijk                                        }
{                                                              }
{    classes, lists en tools                                   }
{                                                              }
{**************************************************************}
unit UTools;

interface

uses
  Classes, Types, Contnrs, Sysutils, Math, UMisc, TypInfo;

type
  TOwnedPersistent = class(TPersistent)
  private
    fOwner: TPersistent;
  protected
    function GetOwner: TPersistent; override;
    function FindOwner(aClass: TClass): TPersistent;
  public
    constructor Create(aOwner: TPersistent);
    property Owner: TPersistent read fOwner;
  end;

  {-------------------------------------------------------------------------------
    TCollectionEx en TOwnedCollectionEx hebben een direct pointer naar fItems.
    Natuurlijk kun je de gehele collection dan vernachelen. maar daar zijn we
    zelf bij :)
    Direct access naar de property List is veel sneller dan access via de gewone
    Items.
  -------------------------------------------------------------------------------}
type
  TCollectionEx = class(TCollection)
  private
  protected
  public
    constructor Create(aItemClass: TCollectionItemClass);
  published
  end;

type
  TOwnedCollectionEx = class(TOwnedCollection)
  private
    fHackedList: TList;
    fItemChanges: Integer;
  protected
  public
    constructor Create(Owner: TPersistent; aItemClass: TCollectionItemClass);
    property HackedList: TList read fHackedList;
    procedure BeginUpdate; override;
    procedure EndUpdate; override;
    procedure ItemChanged(Item: TCollectionItem);
    procedure SetCount(Value: Integer);
    property ItemChanges: Integer read fItemChanges;
  published
  end;

type
  TListEx = class(TList)
  private
    fKeepCapacity: Boolean;
  public
    destructor Destroy; override;
    procedure Clear; override;
    property KeepCapacity: Boolean read fKeepCapacity write fKeepCapacity;
  end;

  TObjectListEx = class(TObjectList)
  private
    fKeepCapacity: Boolean;
  public
    destructor Destroy; override;
    procedure Clear; override;
    property KeepCapacity: Boolean read fKeepCapacity write fKeepCapacity;
  end;

type
  TClassFactory = class(TComponent)
  private
  protected
    fBaseClass: TClass;
    fClassList: TStringList;
    function GetClassCount: integer;
    function GetClass(const aName: string): TClass;
  public
    constructor Create(const aBaseClass: TClass); reintroduce;
    destructor Destroy; override;
    function DoRegisterClass(const aClass: TClass; const aName: string = ''): Integer; virtual;
    function ClassRegistered(const aName: string): boolean;
    function SafeGetClass(const aName: string): TClass;
    property BaseClass: TClass read fBaseClass;
    property ClassList: TStringList read fClassList;
    property ClassCount: integer read GetClassCount;
  end;

  TComponentFactory = class(TClassFactory)
  protected
    function CreateComponent(const aName: string; const aOwner: TComponent): TComponent; virtual;
  end;

  TTranslateEvent = procedure(Sender: TObject;
                              MainComponent, CurrentComponent: TComponent;
                              const PropName: string;
                              const InString: string; var OutString: string) of object;

procedure IniToObject(const AFilename, ASection: String; const AObject: TObject; Sorted: Boolean = True);
procedure ObjectToIni(const AFilename, ASection: String; const AObject: TObject; Sorted: Boolean = True);

type
  TScanObjectPropertiesMethod = procedure(aObject: TObject;
    const aPropName: string; aPropType: TTypeKind) of object;

  TScanClassPropertiesMethod = procedure(aClass: TClass; const aPropName: string; aPropType: TTypeKind) of object;

procedure ForEachProperty(aObject: TObject; aMethod: TScanObjectPropertiesMethod); overload;
procedure ForEachProperty(aClass: TClass; aMethod: TScanClassPropertiesMethod); overload;

procedure ForEachPublishedProperty(aObject: TObject; const aTypeKinds: TTypeKinds; aMethod: TScanObjectPropertiesMethod); overload;

procedure FreeStringsWithObjects(aList: TStrings);
procedure ClearStringsWithObjects(aList: TStrings);


{$IFNDEF EXEVERSION}
procedure FindAllClasses(const aList: Tlist);
procedure FindAllClassesStr(const aList: TStringlist);
{$ENDIF}

implementation

uses
  Windows, IniFiles;

{ TOwnedPersistent }

constructor TOwnedPersistent.Create(aOwner: TPersistent);
begin
  fOwner := aOwner;
end;

function TOwnedPersistent.GetOwner: TPersistent;
begin
  Result := fOwner;
end;

type
  THackedPersistent = class(TPersistent);

function TOwnedPersistent.FindOwner(aClass: TClass): TPersistent;
var
  O: TPersistent;
begin
  O := Self;
  Result := nil;
  while O <> nil do
  begin
    O := THackedPersistent(O).GetOwner;
    if O = nil then
      Exit;
    if O is aClass then
    begin
      Result := O;
      Exit;
    end;
  end;
end;

{ TClassFactory }

constructor TClassFactory.Create(const aBaseClass: TClass);
begin
  inherited Create(nil);
  fBaseClass := aBaseClass;
  fClassList := TStringList.Create;
  fClassList.Duplicates := dupIgnore;
  fClassList.Sorted := True;
end;

destructor TClassFactory.Destroy;
begin
  FClassList.Free;
  inherited;
end;

function TClassFactory.DoRegisterClass(const AClass: TClass; const aName: string = ''): Integer;
var
  TheName: string;
begin
//  Result := -1;
  if aClass = nil then
    AppError('Een geregistreerde klasse mag niet nil zijn', Self);
  if (fBaseClass <> nil) and not (aClass.InheritsFrom(fBaseClass)) then
    AppErrorFmt('Gerigistreerde klasse %s moet afstammen van %s', [aClass.ClassName, fBaseClass.ClassName]);

  TheName := aName;
  if TheName = '' then
    TheName := aClass.ClassName;
  Result := fClassList.AddObject(TheName, TObject(AClass));
end;

function TClassFactory.GetClass(const AName: string): TClass;
var
  i: integer;
begin
//  Result := nil;
  i := FClassList.IndexOf(AName);
  if i = -1 then AppErrorFmt('Klassenaam "%s" niet gevonden', [AName], Self);
  if FClassList.Objects[i] = nil then AppErrorFmt('Klasse "%s" is ongedefinieerd', [AName], Self);
  Result := TClass(fClassList.Objects[i]);
end;

function TClassFactory.ClassRegistered(const AName: string): boolean;
begin
  Result := FClassList.IndexOf(AName) >= 0;
end;

function TClassFactory.SafeGetClass(const AName: string): TClass;
var
  i: integer;
begin
  i := FClassList.IndexOf(AName);
  if i = -1 then
    Result := nil
  else
    Result := TClass(FClassList.Objects[i]);
end;

function TClassFactory.GetClassCount: integer;
begin
  Result := fClassList.Count;
end;

{ TComponentFactory }

function TComponentFactory.CreateComponent(const aName: string; const aOwner: TComponent): TComponent;
var
  MyClass: TComponentClass;
begin
  MyClass := TComponentClass(GetClass(aName)); //classes

//    if aOwner <> nil then
  //    aOwner.ValidateRename(Self, FName, NewName) else
    //  ValidateRename(nil, FName, NewName);

  Result := MyClass.Create(aOwner);
end;

procedure FreeStringsWithObjects(aList: TStrings);
var
  i: integer;
  O: TObject;
begin
  if AList = nil then Exit;
  with AList do
  begin
    for i := 0 to Count - 1 do
    begin
      O := Objects[i];
      if O <> nil then FreeAndNil(O);
    end;
  end;
  FreeAndNil(AList);
  aList := nil;
end;

procedure ClearStringsWithObjects(aList: TStrings);
var
  i: integer;
  O: TObject;
begin
  if aList = nil then Exit;
  with aList do
  begin
    for i := 0 to Count - 1 do
    begin
      O := Objects[i];
      if O <> nil then FreeAndNil(O);
    end;
    Clear;
  end;
end;

{$IFNDEF EXEVERSION}
var
  MinAddress: pointer;
  MaxAddress: pointer;

function GetMemoryRange(out aMinAddress, aMaxAddress: pointer): boolean;
var
  MemoryBasicInfo: TMemoryBasicInformation;
begin
  Result := VirtualQuery(Pointer(TObject),
                         MemoryBasicInfo,
                         SizeOf(MemoryBasicInfo)) = SizeOf(MemoryBasicInfo);
  if not Result then Exit;
  aMinAddress := MemoryBasicInfo.BaseAddress;
  aMaxAddress := pointer(Cardinal(MemoryBasicInfo.BaseAddress)
                        + MemoryBasicInfo.RegionSize);
end;

function ReadVMT(const aClass: TClass; const aOffset: integer): pointer;
begin
  Result := AClass;
  Inc(Integer(Result), AOffset);
  Result := PPointer(Result)^;
end;

function IsValidPointer(const aPtr: Pointer): boolean;
begin
  Result := ((Cardinal(aPtr) and 3) = 0) and
            (Cardinal(aPtr) >= Cardinal(MinAddress)) and
            (Cardinal(aPtr) < Cardinal(MaxAddress));
end;

function IsValidClassName(const aClassName: PShortString): boolean;
var
  Len: Byte;
  EndPtr: pShortString;
begin
  Result := IsValidPointer(aClassName);
  if not Result then Exit;
  Len := pByte(aClassName)^;
  EndPtr := aClassName;
  Inc(EndPtr, Len);
  Result := (Len > 0) and
            IsValidPointer(EndPtr) and
            IsValidIdent(aClassName^);
end;

function TestClassOnAddress(const aClassToCheck: TClass): boolean;
var
  List: TList;
//  Recur: integer;

    function DoTestClass(const aClass: TClass): boolean;
    begin
  //    Inc(Recur);
    //  try
        Result := (ReadVMT(aClass, vmtSelfPtr) = aClass) and
                  IsValidClassName(ReadVMT(aClass, vmtClassName)) and
                  IsValidPointer(ReadVMT(aClass, vmtParent)) and
                  IsValidPointer(aClass.ClassParent) and
                  (List.Add(aClass) >= 0);
(*
        if Result then
        begin
          if not DoTestClass(aClass.ClassParent) then
            Log([stringofchar(' ', recur), 'parenttest mislukt', aclass.classname, aclass.classparent])
          else
            Log([stringofchar(' ', recur), 'parenttest gelukt', aclass.classname, aclass.classparent])
        end *)
      //finally
        //Dec(Recur);
//      end;
    end;
//var
  //i: integer;
begin
//  Recur := 0;
  List := TList.Create;
  try
    Result := DoTestClass(aClassToCheck);
  finally
    List.Free;
  end;
end;

procedure FindAllClasses(const aList: TList);
var
  Ptr: TClass;
//  C: Cardinal;
begin
  if not GetMemoryRange(MinAddress, MaxAddress) then
    Exit;
  {$WARNINGS OFF}
  Cardinal(Ptr) := Cardinal(MinAddress) - vmtSelfPtr;
  {$WARNINGS ON}
  while Cardinal(Ptr) < Cardinal(MaxAddress) do
  begin
    if TestClassOnAddress(Ptr) then
      AList.Add(Ptr);
    Inc(Cardinal(Ptr), 4);
  end;
end;

procedure FindAllClassesStr(const aList: TStringList);
var
  Ptr: TClass;
begin
  if not GetMemoryRange(MinAddress, MaxAddress) then
    Exit;
  {$WARNINGS OFF}
  Cardinal(Ptr) := Cardinal(MinAddress) - vmtSelfPtr;
  {$WARNINGS ON}
  while Cardinal(Ptr) < Cardinal(MaxAddress) do
  begin
    if TestClassOnAddress(Ptr) then
      AList.Add(Ptr.ClassName);
    Inc(Cardinal(Ptr), 4);
  end;
end;

{$ENDIF}


procedure IniToObject(const AFilename, ASection: String;
                      const AObject: TObject; Sorted: Boolean = True);
var
  iCount:       Integer;
  iSize:        Integer;
  iProp:        Integer;
  pProps:       PPropList;

  iDefault:     Integer;
  fDefault:     Extended;
  sDefault:     String;

begin
  // Open het INI bestand
  with TIniFile.Create(AFilename) do
    try
      // Vraag het aantal properties op en reken het benodigde geheugen uit...
      iCount  := GetPropList(AObject.ClassInfo, tkProperties, nil);
      iSize   := iCount * SizeOf(TPropInfo);

      // Reserveer het geheugen...
      GetMem(pProps, iSize);

      try
        // Vraag de properties lijst op...
        GetPropList(AObject.ClassInfo, tkProperties, pProps, Sorted);

        for iProp := 0 to iCount - 1 do begin
          // Werking:
          //
          //    Vraag eerst de huidige waarde op, dit om later te gebruiken als
          //    default waarde voor het geval de property niet bestaat in het
          //    INI bestand. Lees hierna de waarde uit en wijs het toe aan
          //    het object.
          //
          //    Aangezien we voor elk property-type een andere Read-functie aan
          //    moeten roepen:
          case pProps^[iProp]^.PropType^.Kind of
            // Alle integer properties...
            tkInteger, tkChar, tkEnumeration, tkSet, tkWChar:
              begin
                iDefault  := GetOrdProp(AObject, pProps^[iProp]);
                SetOrdProp(AObject, pProps^[iProp], ReadInteger(ASection,
                           pProps^[iProp]^.Name, iDefault));
              end;
            // Floating point properties...
            tkFloat:
              begin
                fDefault  := GetFloatProp(AObject, pProps^[iProp]);
                SetFloatProP(AObject, pProps^[iProp], ReadFloat(ASection,
                             pProps^[iProp]^.Name, fDefault));
              end;
            // String properties...
            tkLString, tkString:
              begin
                // Fix: voorkom dat de Name property wordt geschreven,
                // deze moet uniek zijn...
                if CompareText(pProps^[iProp]^.Name, 'Name') <> 0 then begin
                  sDefault  := GetStrProp(AObject, pProps^[iProp]);
                  SetStrProp(AObject, pProps^[iProp], ReadString(ASection,
                             pProps^[iProp].Name, sDefault));
                end;
              end;
          end;
        end;
      finally
        FreeMem(pProps, iSize);
      end;
    finally
      Free();
    end;
end;

procedure ObjectToINI(const AFilename, ASection: String;
                      const AObject: TObject; Sorted: Boolean = True);
var
  iCount:       Integer;
  iSize:        Integer;
  iProp:        Integer;
  pProps:       PPropList;

  iValue:       Integer;
  fValue:       Extended;
  sValue:       String;

begin
  // Open het INI bestand
  with TIniFile.Create(AFilename) do
    try
      // Vraag het aantal properties op en reken het benodigde geheugen uit...
      iCount  := GetPropList(AObject.ClassInfo, tkProperties, nil);
      iSize   := iCount * SizeOf(TPropInfo);

      // Reserveer het geheugen...
      GetMem(pProps, iSize);

      try
        // Vraag de properties lijst op...
        GetPropList(AObject.ClassInfo, tkProperties, pProps, Sorted);

        for iProp := 0 to iCount - 1 do begin
          // Aangezien we voor elk property-type een andere Write-functie aan
          // moeten roepen:
(*                 //windlg([pProps^[iProp]^.Name, Ord(pProps^[iProp]^.PropType^.Kind)]);
          if Ord(pProps^[iProp]^.PropType^.Kind) = 3 then
          begin
            Log(['asdf']);
          end; *)

          case pProps^[iProp]^.PropType^.Kind of
            // Alle integer properties...
            tkInteger, tkChar, tkEnumeration, tkSet, tkWChar:
              begin
                iValue  := GetOrdProp(AObject, pProps^[iProp]);
                WriteInteger(ASection, pProps^[iProp]^.Name, iValue);
              end;
            // Floating point properties...
            tkFloat:
              begin
                fValue  := GetFloatProp(AObject, pProps^[iProp]);
                WriteFloat(ASection, pProps^[iProp]^.Name, fValue);
              end;
            // String properties...
            tkLString, tkString:
              begin
                // Fix: voorkom dat de Name property wordt geschreven,
                // deze moet uniek zijn...
                if CompareText(pProps^[iProp]^.Name, 'Name') <> 0 then begin
                  sValue  := GetStrProp(AObject, pProps^[iProp]);
                  WriteString(ASection, pProps^[iProp].Name, sValue);
                end;
              end;
          end;
        end;
      finally
        FreeMem(pProps, iSize);
      end;
    finally
//      UpdateFile;
      Free();
    end;
end;

procedure ForEachProperty(aObject: TObject; aMethod: TScanObjectPropertiesMethod);
var
  iCount:       Integer;
  iSize:        Integer;
  iProp:        Integer;
  pProps:       PPropList;

  //iValue:       Integer;
  //fValue:       Extended;
  //sValue:       String;

begin
    // Vraag het aantal properties op en reken het benodigde geheugen uit...
    iCount  := GetPropList(AObject.ClassInfo, tkProperties, nil);
    iSize   := iCount * SizeOf(TPropInfo);

    // Reserveer het geheugen...
    GetMem(pProps, iSize);

    try
      // Vraag de properties lijst op...
      GetPropList(AObject.ClassInfo, tkProperties, pProps);
      for iProp := 0 to iCount - 1 do
      begin
        aMethod(aObject, pProps^[iProp]^.Name, pProps^[iProp]^.PropType^.Kind);
      end;
    finally
      FreeMem(pProps, iSize);
    end;
end;

procedure ForEachPublishedProperty(aObject: TObject; const aTypeKinds: TTypeKinds; aMethod: TScanObjectPropertiesMethod); overload;
var
  iCount:       Integer;
  iSize:        Integer;
  iProp:        Integer;
  pProps:       PPropList;
begin
    // Vraag het aantal properties op en reken het benodigde geheugen uit...
    iCount  := GetPropList(AObject.ClassInfo, tkAny, nil);
    iSize   := iCount * SizeOf(TPropInfo);
    // Reserveer het geheugen...
    GetMem(pProps, iSize);
    try
      // Vraag de properties lijst op...
      GetPropList(AObject.ClassInfo, tkAny, pProps);
      for iProp := 0 to iCount - 1 do
//        if pProps^[iProp]^.PropType^.Kind in aTypeKinds then
      begin
        aMethod(aObject, pProps^[iProp]^.Name, pProps^[iProp]^.PropType^.Kind);
      end;
    finally
      FreeMem(pProps, iSize);
    end;
end;

procedure ForEachProperty(aClass: TClass; aMethod: TScanClassPropertiesMethod); overload;
var
  iCount:       Integer;
  iSize:        Integer;
  iProp:        Integer;
  pProps:       PPropList;
//  iValue:       Integer;
//  fValue:       Extended;
//  sValue:       String;
begin
    // Vraag het aantal properties op en reken het benodigde geheugen uit...
    iCount  := GetPropList(aClass.ClassInfo, tkProperties, nil);
    iSize   := iCount * SizeOf(TPropInfo);

    // Reserveer het geheugen...
    GetMem(pProps, iSize);

    try
      // Vraag de properties lijst op...
      GetPropList(aClass.ClassInfo, tkProperties, pProps);
      for iProp := 0 to iCount - 1 do
      begin
        aMethod(aClass, pProps^[iProp]^.Name, pProps^[iProp]^.PropType^.Kind);
      end;
    finally
      FreeMem(pProps, iSize);
    end;
end;

{ TCollectionEx }

constructor TCollectionEx.Create(aItemClass: TCollectionItemClass);
begin
  inherited;
end;


{ TOwnedCollectionEx }

constructor TOwnedCollectionEx.Create(Owner: TPersistent; aItemClass: TCollectionItemClass);
begin
  inherited;
  fHackedList := TList(PDWORD(DWORD(Self) + $4 + SizeOf(TPersistent))^);
end;

procedure TOwnedCollectionEx.BeginUpdate;
begin
  if UpdateCount = 0 then
  begin
    fItemChanges := 0;
  end;
  inherited BeginUpdate;
end;

procedure TOwnedCollectionEx.EndUpdate;
begin
  inherited EndUpdate;
end;


procedure TOwnedCollectionEx.ItemChanged(Item: TCollectionItem);
begin
  Inc(fItemChanges);
end;


procedure TOwnedCollectionEx.SetCount(Value: Integer);
var
  i: Integer;
begin
  if Value = Count then
    Exit;
  if Value > Count then
    for i := 1 to (Value - Count) do
      Add
  else while (Count > Value) and (Count > 0) do
    Items[Count - 1].Free;
end;

{ TListEx }

procedure TListEx.Clear;
begin
  if fKeepCapacity then
    SetCount(0)
  else inherited;
end;

destructor TListEx.Destroy;
begin
  fKeepCapacity := False;
  Clear;
  inherited;
end;
{ TObjectListEx }

procedure TObjectListEx.Clear;
begin
  if fKeepCapacity then
    SetCount(0)
  else inherited;
end;

destructor TObjectListEx.Destroy;
begin
  fKeepCapacity := False; // force clearing memory
  inherited;
end;


end.


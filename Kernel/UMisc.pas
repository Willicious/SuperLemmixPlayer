(*    dagberekening

jaar, bv 1935. neem 35
deel 35 door 4 en rond af naar beneden (dus 8)
dag, bv de 28e
maandgetal,  voor november4 (zie beneden)
tel op: 35+8+28 (dag) +4(maand) deze 4 getallen optellen
uitkomst delen door 7. het restgetal geldt en geeft de dag aan.
 voor jan t/m dec achtereenvolgens 1-4-4-0-2-5-0-3-6-1-4-6 (dus elke maand een ander getal
[20:51:21] elsjedewolf zegt: data na 2000.....
[20:51:43] elsjedewolf zegt: teller van de breuk in de formule met 1 verminderen
*)

{**************************************************************}
{                                                              }
{    Eric Langedijk                                            }
{                                                              }
{    Algemene types en functies                                }
{                                                              }
{**************************************************************}

{$WARN SYMBOL_PLATFORM OFF} // Disable "___ is specific to a platform" warnings, since NeoLemmix is only for Windows anyway

unit UMisc;

interface

uses
  Windows, Classes, Sysutils, TypInfo, Math,
  UFastStrings;

{ Algemene constanten en types }

const
  { getallen }
  CrLf        = Chr(13) + Chr(10);

{ pointers naar basische types }
type
  pWord          = ^word;
  pPointer       = ^Pointer;

type
  PBytes = ^TBytes;
  TBytes = array[0..MaxListSize * 4 - 1] of Byte;  // Warning: MaxListSize is deprecated!!!

{ sets }
type
  TCharSet = set of char;
  PCharSet = ^TCharSet;
  TByteSet = set of byte;
  PByteSet = ^TByteSet;

type
  TIntArray = array[0..MaxListSize - 1] of integer;
  PIntArray = ^TIntArray;
  TPointArray = array[0..MaxListSize div 2 - 1] of TPoint;
  PPointArray = ^TPointArray;
  TOpenBooleanArray = array of boolean;
  TOpenByteArray = array of Byte;
  TOpenStringArray = array of string;
  TOpenIntegerArray = array of integer;
  TOpenVarRecArray = array of TVarRec;
  TOpenExtendedArray = array of Extended;
  TOpenVariantArray = array of Variant;
  TOpenVariantPointerArray = array of PVariant;
  TOpenRectArray = array of TRect;

{ Chars en Strings }

function BoolStr(B: boolean): string;
    { converteert een boolean naar een string }
function CountChars(C: Char; const S: string): integer;
    { telt aantal chars in string }
function CutLeft(const S: string; aLen: integer): string;
    { haal aan begin van string chars weg }
function CutRight(const S: string; aLen: integer): string;
    { haal aan eind van string chars weg }
function HexStr(I: integer): string;
    { geeft hexadecimale notatie van integer }
function i2s(i: integer): string;
    { str }
function LeadZeroStr(Int, Len: integer): string;
    { lijdende nullen voor getal }
function PadL(const S: string; aLen: integer; PadChar: char = ' '): string;
    { = RStr met een te kiezen karakter }
function PadR(const S: string; aLen: integer; PadChar: char = ' '): string;
    { = Lstr met een te kiezen karakter }
function ReplaceChar(const S: string; aFrom, aTo: Char): string;
    { vervangt karakters in string }
function ReplaceFileExt(const aFileName, aNewExt: string): string;
    { vervangt fileext door nieuwe ext, als niet gevonden dan geen verandering }
function s2i(const S: string): integer;
    { als StrToInt }

function SplitString(const S: string; Index: integer; Seperator: Char; DoTrim: Boolean = True): string;
    { haal string uit Seperated string }
function SplitStringCount(const S: string; Seperator: Char): integer;
    { geeft aan hoeveel splitstrings er in S zitten }
function SplitString_To_StringList(const S: string; Seperator: Char;
  DoTrim: boolean = False): TStringList; overload;
    { sloopt <S>, gescheiden door een <Seperator> uit elkaar in meerdere strings }
procedure SplitString_To_StringList(const S: string; AList: TStringList; Seperator: Char;
  DoTrim: boolean = False); overload;
    { sloopt <S>, gescheiden door een <Seperator> uit elkaar in meerdere strings }

procedure StringToFile(const aString, aFileName: string);
    { bewaar string als file }

function Transform(const AVarRec: TVarRec): string;
    { transformeert een varrec naar string }
function StrToFloatDef(const S: string; const DefValue: Extended = 0): Extended; overload;
    { = StrToFloat, maar geeft DefValue terug bij exception. NB StrToIntDef staat in sysutils }
function StringToCharSet(const S: string; const Keep: TCharSet = []): TCharSet;
    { geeft alle letters uit set }

{ Getallen }

function Percentage(Max, N: integer): integer; overload;

{ Datum en Tijd }

function MilliSeconds: integer;
    { geeft milliseconden sinds middernacht }
function DtoS(const aDate: TDateTime): ShortString;
    { output: 20011231 }
function TtoS(const ATime: TDateTime; const aSeparator: string = ''): ShortString;
    { output: 20011231 + aSeparator + 124559 }

{ Memory }

procedure FillDWord(var Dest; Count, Value: Integer);
    { vult een stuk geheugen met DWords }

{ TRect TPoint }

function RectHeight(const aRect: TRect): integer;
function RectWidth(const aRect: TRect): integer;
procedure RectMove(var R: TRect; X, Y: integer); {windows.offsetrect}
function ZeroTopLeftRect(const aRect: TRect): TRect;

{ Range }

function Between(X, A, B: integer): boolean; overload;
procedure Restrict(var aValue: integer; aMin, aMax: integer);

{ IIFS }

function IIF(aExpr: boolean; const aTrue, aFalse: pointer): pointer; overload;
function IIF(aExpr, aTrue, aFalse: boolean): boolean; overload;
function IIF(aExpr: boolean; const aTrue, aFalse: integer): integer; overload;
function IIF(aExpr: boolean; const aTrue, aFalse: string): string; overload;
function IIF(aExpr: boolean; const aTrue, aFalse: Char): Char; overload;
function IIF(aExpr: boolean; const aTrue, aFalse: Currency): Currency; overload;

{ Swaps }

procedure Swap(var A, B; Size: integer);
procedure SwapInts(var A, B: integer);

{ nibble swap }
function SwapWord(W: Word): Word;

{ Components }

function ComponentToString(Component: TComponent): string;
procedure ComponentToTextFile(C: TComponent; const AFileName: string);

type
  TComponentMethod = procedure(Com: TComponent) of object;


{ Exception handling algemeen }

type
  EAppError = class(Exception);

procedure AppError(const Msg: string; Sender: TObject = nil);
procedure AppErrorFmt(const Msg: string;  const Args: array of const; Sender: TObject = nil);

procedure WinDlg(const S: string); overload;
procedure WinDlg(const AValues: array of const); overload;

{ diversen }

function GetApplicationPath: string;


const
  EmptyRect: TRect = (Left: 0; Top: 0; Right: 0; Bottom: 0);


type
  TDebProc = procedure(const aValues: array of const);

procedure Deb(const aValues: array of const);
procedure Log(const aValues: array of const);

resourcestring
  SMyException = 'Fout: %s in module %s.' + Chr(13) +
                 'Adres: %p.' + Chr(13) + Chr(13) +
                 '%s%s';


implementation


var
  _DebProc: TDebProc = nil;


procedure Deb(const aValues: array of const);
begin
  if Assigned(_DebProc) then
    _DebProc(aValues);    //ulog
end;

procedure Log(const aValues: array of const);
begin
  Deb(aValues);
end;

function BoolStr(B: boolean): string;
begin
 if B then Result := 'TRUE' else Result := 'FALSE';
end;

function CountChars(C: Char; const S: string): integer;
var
  i: integer;
begin
  Result := 0;
  for i := 1 to Length(S) do
    if S[i] = C then inc(Result);
end;

function CutLeft(const S: string; aLen: integer): string;
begin
  Result := Copy(S, aLen + 1, Length(S));
end;

function CutRight(const S: string; aLen: integer): string;
begin
  Result := Copy(S, 1, Length(S) - aLen);
end;

function HexStr(I: integer): string;
begin
  Result := '$' + Format('%x', [i]);
end;

function i2s(i: integer): string;
begin
  Str(i, Result);
end;

function PadL(const S: string; aLen: integer; PadChar: char = ' '): string;
begin
  Result := StringOfChar(PadChar, aLen - Length(S)) + Copy(S, Length(S) - aLen + 1, aLen);
end;

function PadR(const S: string; aLen: integer; PadChar: char = ' '): string;
begin
  { de compiler checkt intern al op negatieve waarden, daar maken we gebruik van }
  Result := Copy(S, 1, aLen) + StringOfChar(PadChar, aLen - Length(S));
end;

function ReplaceChar(const S: string; aFrom, aTo: Char): string;
var
  i: Integer;
begin
  Result := S;
  for i := 1 to length(Result) do
    if Result[i] = aFrom then
      Result[i] := aTo;
end;

function ReplaceFileExt(const aFileName, aNewExt: string): string;
var
  Ext: string;
begin
  Ext := ExtractFileExt(aFileName);
  if Ext <> '' then
  begin
    Result := CutRight(aFileName, Length(Ext)) + aNewExt;
  end;
end;

function s2i(const S: string): integer;
var
  Code: integer;
begin
  {$I-}
  Val(S, Result, Code);
  {$I+}
  if Code <> 0 then
    Result := 0;
end;

function LeadZeroStr(Int, Len: integer): string;
var
  i: byte;
begin
  Str(Int:Len, Result);
  i := 1;
  while Result[i] = ' ' do
  begin
    Result[i] := '0';
    Inc(i);
  end;
end;


function Transform(const AVarRec: TVarRec): string;
begin
  with AVarRec do
    case VType of
      vtInteger     : Result := IntToStr(VInteger);
      vtBoolean     : Result := BoolStr(VBoolean);
      vtChar        : if VChar = #0 then Result := ' ' else Result := VChar;
      vtExtended    : Result := FloatToStrF(VExtended^, ffFixed, 15, 4);
      vtString      : Result := VString^;
      vtPChar       : Result := VPChar;
      vtObject      :  if VObject = nil then Result := 'NIL' else VObject.ClassName;
      vtClass       : Result := VClass.ClassName;
      vtAnsiString  : Result := string(VAnsiString);
      vtCurrency    : Result := CurrToStr(VCurrency^);
      vtVariant     : Result := string(VVariant^);
      vtInt64       : Result := IntToStr(VInt64^);
      else Result := '';
    end;
end;

function StrToFloatDef(const S: string; const DefValue: Extended): Extended;
begin
  if not TextToFloat(PChar(S), Result, fvExtended) then
    Result := DefValue;
end;

function StringToCharSet(const S: string; const Keep: TCharSet = []): TCharSet;
var
  i: Integer;
begin
  Result := [];
  for i := 1 to Length(S) do
    if (Keep = []) or (S[i] in Keep) then
      Include(Result, S[i]);
end;



function SplitString(const S: string; Index: integer; Seperator: Char; DoTrim: Boolean = True): string;
var
  L: TStringList;
begin
  Result := '';
  L := SplitString_To_StringList(S, Seperator, DoTrim);
  try
    if Index < L.Count then
      Result := L[Index];
  finally
    L.Free;
  end;
end;

function SplitStringCount(const S: string; Seperator: Char): integer;
var
  Start, P: integer;
begin
  Result := 0;
  Start := 1;
  repeat
    P := FastCharPos(S, Seperator, Start);
    if P = 0 then Break;
    Inc(Result);
    Start := P + 1;
  until P = 0;
  { evt laatste }
  if (Result > 0) and (Start <= Length(S)) then
    inc(Result);
end;


function SplitString_To_StringList(const S: string; Seperator: Char; DoTrim: boolean = False): TStringList;
var
  Cnt, Start, P: integer;
begin
  Result := TStringList.Create;
  Start := 1;
  Cnt := 0;
  repeat
    P := FastCharPos(S, Seperator, Start);
    if P = 0 then Break;
    case DoTrim of
      False: Result.Add(Copy(S, Start, P - Start));
      True: Result.Add(Trim(Copy(S, Start, P - Start)));
    end;
    Inc(Cnt);
    Start := P + 1;
  until P = 0;
  { evt laatste }
  if (Cnt = 0) and (P = 0) and (S <> '') then
    case DoTrim of
      False: Result.Add(S);
      True: Result.Add(Trim(S));
    end
  else if (Cnt > 0) and (Start <= Length(S)) then
    case DoTrim of
      False: Result.Add(Copy(S, Start, Length(S) - Start + 1));
      True: Result.Add(Trim(Copy(S, Start, Length(S) - Start + 1)));
    end;
end;

procedure SplitString_To_StringList(const S: string; AList: TStringList; Seperator: Char;
  DoTrim: boolean = False);
var
  Cnt, Start, P: integer;
begin
  if not Assigned(AList) then Exit;
  AList.Clear;
  Start := 1;
  Cnt := 0;
  repeat
    P := FastCharPos(S, Seperator, Start);
    if P = 0 then Break;
    case DoTrim of
      False:
         AList.Add(Copy(S, Start, P - Start));
      True:
         AList.Add(Trim(Copy(S, Start, P - Start)));
    end;
    Inc(Cnt);
    Start := P + 1;
  until P = 0;
  { evt laatste }
  if (Cnt = 0) and (P = 0) and (S <> '') then
    case DoTrim of
      False:
         AList.Add(S);
      True:
         AList.Add(Trim(S));
    end
  else if (Cnt > 0) and (Start <= Length(S)) then
    case DoTrim of
      False:
        AList.Add(Copy(S, Start, Length(S) - Start + 1));
      True:
         AList.Add(Trim(Copy(S, Start, Length(S) - Start + 1)));
    end;
end;


procedure StringToFile(const aString, aFileName: string);
var
  L: TStringList;
begin
  L := TStringList.Create;
  try
    L.Add(aString);
    L.SaveToFile(aFileName);
  finally
    L.Free;
  end;
end;



function Between(X, A, B: integer): boolean;
begin
  Result := (X >= A) and (X <= B);
end;


function Percentage(Max, N: integer): integer;
begin
  if Max = 0 then
    Result := 0
  else
    Result := Trunc((N/Max) * 100);
end;

procedure Restrict(var aValue: integer; aMin, aMax: integer);
begin
  if aMin > aMax then SwapInts(aMin, aMax);
  if aValue < aMin then
    aValue := aMin else
  if aValue > aMax then
    aValue := aMax
end;



{ retourneert aantal milliseconden sinds middernacht }
function MilliSeconds: integer;
var
  SysTime: TSystemTime;
begin
  DateTimeToSystemTime(Now, SysTime);
  with SysTime do
    Result := (wHour * 60 * 60 + wMinute * 60 + wSecond) * 1000 + wMilliSeconds;
end;

function DtoS(const aDate: TDateTime): ShortString;
var
  Y, M, D: word;
begin
  DecodeDate(aDate, Y, M, D);
  Result := IntToStr(Y) + LeadZeroStr(M, 2) + LeadZeroStr(D, 2);
end;

function TtoS(const ATime: TDateTime; const aSeparator: string = ''): ShortString;
var
  H, Min, S, MS: word;
begin
  DecodeTime(aTime, H, Min, S, MS);
  Result := DtoS(aTime) + aSeparator + LeadZeroStr(H, 2) + LeadZeroStr(Min, 2) + LeadZeroStr(S, 2);
end;


procedure Swap(var A, B; Size: integer);
var
  Temp: pointer;
begin
  GetMem(Temp, Size);
  Move(A, Temp^, Size);
  Move(B, A, Size);
  Move(Temp^, B, Size);
  FreeMem(Temp, Size);
end;

function SwapWord(W: Word): Word;
begin
  Result := System.Swap(W);
end;

procedure FillDWord(var Dest; Count, Value: Integer); register;
asm
  XCHG  EDX, ECX
  PUSH  EDI
  MOV   EDI, EAX
  MOV   EAX, EDX
  REP   STOSD
  POP   EDI
end;


procedure SwapInts(var A, B: integer);
begin
  a := a xor b;
  b := b xor a;
  a := a xor b;
end;



{ Intern }

function IIF(aExpr: boolean; const aTrue, aFalse: pointer): pointer; overload;
begin
  if aExpr then Result := aTrue else Result := aFalse;
end;

function IIF(aExpr: boolean; const aTrue, aFalse: integer): integer; overload;
begin
  if aExpr then Result := aTrue else Result := aFalse;
end;

function IIF(aExpr, aTrue, aFalse: boolean): boolean; overload;
begin
  if aExpr then Result := aTrue else Result := aFalse;
end;

function IIF(aExpr: boolean; const aTrue, aFalse: string): string; overload;
begin
  if aExpr then Result := aTrue else Result := aFalse;
end;


function IIF(aExpr: boolean; const aTrue, aFalse: Char): Char; overload;
begin
  if aExpr then Result := aTrue else Result := aFalse;
end;

function IIF(aExpr: boolean; const aTrue, aFalse: Currency): Currency; overload;
begin
  if aExpr then Result := aTrue else Result := aFalse;
end;


function RectHeight(const aRect: TRect): integer;
begin
  with aRect do Result := Bottom - Top + 1;
end;

function RectWidth(const aRect: TRect): integer;
begin
  with aRect do Result := Right - Left + 1;
end;

procedure RectMove(var R: TRect; X, Y: integer);
begin
  with R do
  begin
    if X <> 0 then
    begin
      Inc(R.Left, X);
      Inc(R.Right, X);
    end;
    if Y <> 0 then
    begin
      Inc(R.Top, Y);
      Inc(R.Bottom, Y);
    end;
  end;
end;


function ZeroTopLeftRect(const aRect: TRect): TRect;
begin
  Result := aRect;
  with Result do
  begin
    Dec(Right, Left);
    Dec(Bottom, Top);
    Left := 0;
    Top := 0;
  end;
end;

{ Component Streaming }

function ComponentToString(Component: TComponent): string;

var
  BinStream: TMemoryStream;
  StrStream: TStringStream;
  s: string;
begin
  BinStream := TMemoryStream.Create;
  try
    StrStream := TStringStream.Create(s);
    try
      BinStream.WriteComponent(Component);
      BinStream.Seek(0, soFromBeginning);
      ObjectBinaryToText(BinStream, StrStream);
      StrStream.Seek(0, soFromBeginning);
      Result:= StrStream.DataString;
    finally
      StrStream.Free;

    end;
  finally
    BinStream.Free
  end;
end;



procedure ComponentToTextFile(C: TComponent; const AFileName: string);
var
  S: string;
  P: PChar;
  Stream: TFileStream;
begin
  S := ComponentToString(C);
  P := PChar(S);
  Stream := TFileStream.Create(AFileName, fmCreate);
  try
    Stream.Write(P^, Length(S));
  finally
    Stream.Free;
  end;
end;




{ Exception handling }

procedure AppError(const Msg: string; Sender: TObject = nil);
var
  ErrorStr: string;
begin
  if Sender <> nil then
  begin
    ErrorStr := 'Fout in ' + Sender.ClassName;
    ErrorStr := ErrorStr + ': ' + Chr(13) + Msg;
  end
  else ErrorStr := Msg;
  raise EAppError.Create(ErrorStr);
end;

procedure AppErrorFmt(const Msg: string;  const Args: array of const; Sender: TObject = nil);
var
  S: string;
begin
  try S := Format(Msg, Args) except S := Msg; end;
  AppError(S, Sender);
end;

{ -------- sysutilscode maar dan nederlands -------- }

{ Convert physical address to logical address }

function ConvertAddr(Address: Pointer): Pointer; assembler;
asm
        TEST    EAX,EAX         { Always convert nil to nil }
        JE      @@1
        SUB     EAX, $1000      { offset from code start; code start set by linker to $1000 }
@@1:
end;

{ Format and return an exception error message }

function ExceptionErrorMessage(ExceptObject: TObject; ExceptAddr: Pointer;
  Buffer: PChar; Size: Integer): Integer;
var
  MsgPtr: PChar;
  MsgEnd: PChar;
  MsgLen: Integer;
  ModuleName: array[0..MAX_PATH] of Char;
  Temp: array[0..MAX_PATH] of Char;
  Format: array[0..255] of Char;
  Info: TMemoryBasicInformation;
  ConvertedAddress: Pointer;
begin
  // to do: vertaling van exceptionnamen?
  // vertaling van messages?
  VirtualQuery(ExceptAddr, Info, sizeof(Info));
  if (Info.State <> MEM_COMMIT) or
    (GetModuleFilename(THandle(Info.AllocationBase), Temp, SizeOf(Temp)) = 0) then
  begin
    GetModuleFileName(HInstance, Temp, SizeOf(Temp));
    ConvertedAddress := ConvertAddr(ExceptAddr);
  end
  else
    Integer(ConvertedAddress) := Integer(ExceptAddr) - Integer(Info.AllocationBase);
  StrLCopy(ModuleName, AnsiStrRScan(Temp, '\') + 1, SizeOf(ModuleName) - 1);
  MsgPtr := '';
  MsgEnd := '';
  if ExceptObject is Exception then
  begin
    MsgPtr := PChar(Exception(ExceptObject).Message);
    MsgLen := StrLen(MsgPtr);
    if (MsgLen <> 0) and (MsgPtr[MsgLen - 1] <> '.') then MsgEnd := '.';
  end;
  LoadString(FindResourceHInstance(HInstance),
    PResStringRec(@SMyException).Identifier, Format, SizeOf(Format));
  StrLFmt(Buffer, Size, Format, [ExceptObject.ClassName, ModuleName,
    ConvertedAddress, MsgPtr, MsgEnd]);
  Result := StrLen(Buffer);
end;

{ Display exception message box }


procedure WinDlg(const S: string);
begin
  MessageBox(0, PChar(S), PChar('ok'), MB_OK + MB_TASKMODAL);
end;

procedure WinDlg(const AValues: array of const);

    function SetStr: string;
    var
      i: integer;
    begin
      Result := '';
      for i := Low (AValues) to High (AValues) do
      begin
        try
          Result := Result + '[' + TransForm(AValues[i]) + ']' + Chr(13);
        except
          Result := Result + '[¿NULL¿]' + Chr(13);
        end;
      end;
      Result := FastReplace(Result, '#0', ' ');
    end;

var
  S: string;
begin
  S := SetStr;

  MessageBox(0, PChar(S), PChar('ok'), MB_OK + MB_TASKMODAL);
end;


function GetApplicationPath: string;
begin
  Result := ExtractFilePath(ParamStr(0));
end;


end.



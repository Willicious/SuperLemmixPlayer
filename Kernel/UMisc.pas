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
  Windows, Classes, SysUtils, StrUtils, TypInfo, Math;

const
  CrLf = Chr(13) + Chr(10);

// Counts the number of characters C in the string S
function CountChars(C: Char; const S: string): integer;

// Pads the string S to length aLen by adding PadChar to the left resp. right.
// If S is already longer than aLen, then it gets truncated.
function PadL(const S: string; aLen: integer; PadChar: char = ' '): string;
function PadR(const S: string; aLen: integer; PadChar: char = ' '): string;

// This is PadL(IntToStr(Int), Len, '0')
function LeadZeroStr(Int, Len: integer): string;

// Saves a string to a file
procedure StringToFile(const aString, aFileName: string);

// Computes the height resp. width of a rectangle.
function RectHeight(const aRect: TRect): integer;
function RectWidth(const aRect: TRect): integer;




function Transform(const AVarRec: TVarRec): string;
    { transformeert een varrec naar string }

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

// No longer fast, but instead independent of UFastStrings.
// And the methods that uses FastCharPos should be rewritten anyway.
function FastCharPos(S, Seperator: String; Start: Integer): Integer;
var
  SubS: String;
begin
  SubS := Copy(S, Start, Length(S) - Start);
  Result := Start + Pos(Seperator, SubS);
end;


function CountChars(C: Char; const S: string): integer;
var
  i: integer;
begin
  Result := 0;
  for i := 1 to Length(S) do
    if S[i] = C then Inc(Result);
end;



function PadL(const S: string; aLen: integer; PadChar: char = ' '): string;
begin
  if Length(S) >= aLen then Result := RightStr(S, aLen)
  else Result := StringOfChar(PadChar, aLen - Length(S)) + S;
end;

function PadR(const S: string; aLen: integer; PadChar: char = ' '): string;
begin
  if Length(S) >= aLen then Result := LeftStr(S, aLen)
  else Result := S + StringOfChar(PadChar, aLen - Length(S));
end;

function LeadZeroStr(Int, Len: integer): string;
begin
  Result := PadL(IntToStr(Int), Len, '0')
end;


function Transform(const AVarRec: TVarRec): string;
begin
  with AVarRec do
    case VType of
      vtInteger     : Result := IntToStr(VInteger);
      vtBoolean     : if VBoolean then Result := 'TRUE' else Result := 'FALSE';
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


function RectHeight(const aRect: TRect): integer;
begin
  Result := aRect.Bottom - aRect.Top;
end;

function RectWidth(const aRect: TRect): integer;
begin
  Result := aRect.Right - aRect.Left;
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
      Result := StringReplace(Result, '#0', ' ', [rfReplaceAll]);
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



{$include lem_directives.inc}

unit GameTalismanScreen;

interface

uses
  Dialogs,
  Windows, Classes, SysUtils, Controls,
  UMisc,
  Gr32, Gr32_Image, Gr32_Layers,
  LemCore,
  LemTypes,
  LemStrings,
  LemGame,
  LemNeoLevelPack,
  GameControl,
  StrUtils,
  LemTalisman,
  GameBaseScreen;

const
  TALISMANS_PER_PAGE = 4;

type
  TGameTalismanScreen = class(TGameBaseScreen)
  private
    ScreenText: string;
    fPack: TNeoLevelGroup;
    function GetScreenText: string;
    procedure Form_KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Form_KeyPress(Sender: TObject; var Key: Char);
  protected
    procedure BuildScreen; override;
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
    function ShowScreen: Integer; override;
  published
  end;

implementation

uses Forms;

function TGameTalismanScreen.ShowScreen: Integer;
begin
  Result := inherited ShowScreen;
end;

procedure TGameTalismanScreen.BuildScreen;
var
  Temp: TBitmap32;
begin
  ScreenImg.BeginUpdate;
  Temp := TBitmap32.Create;
  try
    InitializeImageSizeAndPosition(640, 400);
    ExtractBackGround;
    ExtractPurpleFont;

    Temp.SetSize(640, 400);
    Temp.Clear(0);
    TileBackgroundBitmap(0, 0, Temp);
    ScreenText := GetScreenText;
    DrawPurpleTextCentered(Temp, ScreenText, 16);
    ScreenImg.Bitmap.Assign(Temp);
  finally
    ScreenImg.EndUpdate;
    Temp.Free;
  end;
end;

constructor TGameTalismanScreen.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  OnKeyDown := Form_KeyDown;
  OnKeyPress := Form_KeyPress;
end;

destructor TGameTalismanScreen.Destroy;
begin
  inherited Destroy;
end;

function TGameTalismanScreen.GetScreenText: string;
var
  FirstTalismanIndex: Integer;
  i: Integer;
  T: TTalisman;
  TalChar: Char;
  WA: TWordWrapArray;
  Level: TNeoLevelEntry;
  CutTitle: String;
  ReqText: String;

  procedure Add(aLine: String = ''; aPad: Integer = -1);
  begin
    if Length(aLine) < aPad then aLine := aLine + StringOfChar(' ', aPad - Length(aLine));
    Result := Result + aLine + #13;
  end;

  procedure AddHalfBreak(aLine: String = ''; aPad: Integer = -1);
  begin
    if Length(aLine) < aPad then aLine := aLine + StringOfChar(' ', aPad - Length(aLine));
    Result := Result + aLine + #12;
  end;

  procedure LF(aCount: Integer = 1);
  begin
    Result := Result + StringOfChar(#13, aCount);
  end;
begin
  fPack := GameParams.CurrentLevel.Group.ParentBasePack;
  FirstTalismanIndex := GameParams.TalismanPage * TALISMANS_PER_PAGE;
  Result := '';

  Add(fPack.Name);
  Add('Talismans (' + IntToStr(fPack.TalismansUnlocked) + ' of ' + IntToStr(fPack.Talismans.Count) + ')');
  LF;

  for i := FirstTalismanIndex to (FirstTalismanIndex + TALISMANS_PER_PAGE - 1) do
    if i >= fPack.Talismans.Count then
      LF(6)
    else begin
      T := fPack.Talismans[i];
      Level := TNeoLevelEntry(T.Data);

      if Level.Group.IsOrdered then
      begin
        if Level.Group.IsBasePack then
          ReqText := 'Level ' + IntToStr(Level.GroupIndex + 1) + ': '
        else
          ReqText := Level.Group.Name + ' ' + IntToStr(Level.GroupIndex + 1) + ': ';
      end else
        ReqText := Level.Title + ': ';

      ReqText := ReqText + T.RequirementText;

      WA := WordWrapString(ReqText, 34);
      CutTitle := LeftStr(T.Title, 34);

      case T.Color of
        tcBronze: TalChar := #26;
        tcSilver: TalChar := #28;
        tcGold: TalChar := #30;
      end;

      if Level.TalismanStatus[T.ID] then Inc(TalChar);

      case Length(WA) of
        0: begin // just in case
             LF(1);
             Add(TalChar, 38);
             Add('    ' + CutTitle, 38);
             LF(2);
           end;
        1: begin
             LF(1);
             AddHalfBreak(TalChar, 38);
             Add('    ' + CutTitle, 38);
             Add('    ' + WA[0], 38);
             AddHalfBreak;
             LF(1);
           end;
        2: begin
             LF(1);
             Add(TalChar + '   ' + CutTitle, 38);
             Add('    ' + WA[0], 38);
             Add('    ' + WA[1], 38);
             LF(1);
           end;
        3: begin
             AddHalfBreak;
             AddHalfBreak('    ' + CutTitle, 38);
             AddHalfBreak(TalChar, 38);
             Add('    ' + WA[0], 38);
             Add('    ' + WA[1], 38);
             Add('    ' + WA[2], 38);
             AddHalfBreak;
           end;
        else begin
               Add('    ' + CutTitle, 38);
               Add(TalChar + '   ' + WA[0], 38);
               Add('    ' + WA[1], 38);
               Add('    ' + WA[2], 38);
               Add('    ' + WA[3], 38);
             end;
      end;
    end;
end;

procedure TGameTalismanScreen.Form_KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_ESCAPE: CloseScreen(gstMenu);
    VK_LEFT: if GameParams.TalismanPage > 0 then
             begin
               GameParams.TalismanPage := GameParams.TalismanPage - 1;
               CloseScreen(gstTalisman);
             end;
    VK_RIGHT: if GameParams.TalismanPage < ((fPack.Talismans.Count - 1) div TALISMANS_PER_PAGE) then
              begin
                GameParams.TalismanPage := GameParams.TalismanPage + 1;
                CloseScreen(gstTalisman);
              end;
  end;
end;

procedure TGameTalismanScreen.Form_KeyPress(Sender: TObject; var Key: Char);
begin
end;

end.


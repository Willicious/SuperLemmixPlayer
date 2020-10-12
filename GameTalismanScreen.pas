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
  GameBaseScreenCommon, GameBaseMenuScreen;

const
  TALISMANS_PER_PAGE = 4;

type
  TGameTalismanScreen = class(TGameBaseMenuScreen)
  private
    ScreenText: string;
    fPack: TNeoLevelGroup;
    function GetScreenText: string;
  protected
    procedure BuildScreen; override;

    procedure OnMouseClick(aPoint: TPoint; aButton: TMouseButton); override;
    procedure OnKeyPress(aKey: Integer); override;
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
  published
  end;

implementation

uses Forms;

procedure TGameTalismanScreen.BuildScreen;
begin
  ScreenImg.BeginUpdate;
  try
    ScreenText := GetScreenText;
    MenuFont.DrawTextCentered(ScreenImg.Bitmap, ScreenText, 16);
  finally
    ScreenImg.EndUpdate;
  end;
end;

constructor TGameTalismanScreen.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
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
      else TalChar := #26;
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
             if CutTitle.Length > 0 then
             begin
               Add('    ' + CutTitle, 38);
               Add('    ' + WA[0], 38);
             end
             else
             begin
               Add('    ' + WA[0], 38);
               LF(1);
             end;
             AddHalfBreak;
             LF(1);
           end;
        2: begin
             LF(1);
             if CutTitle.Length > 0 then
             begin
               Add(TalChar + '   ' + CutTitle, 38);
               Add('    ' + WA[0], 38);
               Add('    ' + WA[1], 38);
             end
             else
             begin
               AddHalfBreak(TalChar, 38);
               Add('    ' + WA[0], 38);
               Add('    ' + WA[1], 38);
               AddHalfBreak;
             end;
             LF(1);
           end;
        3: begin
             if CutTitle.Length > 0 then
             begin
               AddHalfBreak;
               AddHalfBreak('    ' + CutTitle, 38);
               AddHalfBreak(TalChar, 38);
               Add('    ' + WA[0], 38);
               Add('    ' + WA[1], 38);
               Add('    ' + WA[2], 38);
               AddHalfBreak;
             end
             else
             begin
               LF(1);
               Add(TalChar + '   ' + WA[0], 38);
               Add('    ' + WA[1], 38);
               Add('    ' + WA[2], 38);
               LF(1);
             end;
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

procedure TGameTalismanScreen.OnKeyPress(aKey: Integer);
begin
  case aKey of
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

procedure TGameTalismanScreen.OnMouseClick(aPoint: TPoint;
  aButton: TMouseButton);
begin
  case aButton of
    mbLeft: if fPack.Talismans.Count > TALISMANS_PER_PAGE then
              begin
                if GameParams.TalismanPage = ((fPack.Talismans.Count - 1) div TALISMANS_PER_PAGE) then
                  GameParams.TalismanPage := 0
                else
                  GameParams.TalismanPage := GameParams.TalismanPage + 1;

                CloseScreen(gstTalisman);
              end;
    mbRight: CloseScreen(gstMenu);
  end;
end;

end.


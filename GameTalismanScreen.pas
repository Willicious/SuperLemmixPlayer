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
  GameControl,
  GameBaseScreen;

const
  TALISMANS_PER_PAGE = 6;

{-------------------------------------------------------------------------------
   The dos postview screen, which shows you how you've done it.
-------------------------------------------------------------------------------}
type
  TGameTalismanScreen = class(TGameBaseScreen)
  private
    fPage: Integer;
    ScreenText: string;
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
const
   pts_bronze = 3;
   pts_silver = 4;
   pts_gold = 5;
var
   lfc: byte;
   i: Integer;
   S: String;
   maxpoints, playerpoints, curpoints: Integer;

    procedure Add(const S: string);
    begin
      Result := Result + S + #13;
      Inc(lfc);
    end;

    procedure PreAdd(const S: string);
    begin
      Result := S + #13 + Result;
      Inc(lfc);
    end;

    procedure LF(aCount: Integer);
    begin
      Result := Result + StringOfChar(#13, aCount);
      Inc(lfc, aCount);
    end;

    procedure PreLF(aCount: Integer);
    begin
      Result := StringOfChar(#13, aCount) +  Result;
      Inc(lfc, aCount);
    end;

begin

  Result := '';
  lfc := 0;

  fPage := GameParams.TalismanPage;

  if GameParams.Talismans.VisibleCount = 0 then
  begin
    Add('This game does not have any talismans.');
    LF(10);
    PreLF(7);

    PreAdd('Talisman Record');
    Add('Press Esc for main menu');
    Exit;
  end;

  maxpoints := 0;
  playerpoints := 0;
  for i := 0 to GameParams.Talismans.Count-1 do
  begin
    case GameParams.Talismans[i].TalismanType of
      1: curpoints := pts_bronze;
      2: curpoints := pts_silver;
      3: curpoints := pts_gold;
      else curpoints := 0;
    end;
    maxpoints := maxpoints + curpoints;
    //if GameParams.SaveSystem.CheckTalisman(GameParams.Talismans[i].Signature) then playerpoints := playerpoints + curpoints;
  end;
  playerpoints := (playerpoints * 100) div maxpoints;

  for i := (fPage * TALISMANS_PER_PAGE) to (((fPage+1) * TALISMANS_PER_PAGE)-1) do
  begin
    if i > GameParams.Talismans.VisibleCount-1 then
    begin
      LF(3);
      Continue;
    end;
    //Add(BuildText(GameParams.Talismans[i].Description, GameParams.Talismans[i].TalismanType, GameParams.SaveSystem.CheckTalisman(GameParams.Talismans[i].Signature))); 
  end;

  LF(1);

  if GameParams.Talismans.VisibleCount <= TALISMANS_PER_PAGE then
    LF(1)
  else begin
    if fPage > 0 then
      S := '<<'
    else
      S := '  ';

    S := S + '       ';
    if fPage < 9 then S := S + ' ';
    S := S + 'Page ';
    S := S + IntToStr(fPage+1) + '/';
    S := S + IntToStr(((GameParams.Talismans.VisibleCount - 1) div TALISMANS_PER_PAGE) + 1);
    if GameParams.Talismans.VisibleCount < 46 then S := S + ' ';
    S := S + '       ';

    if fPage < (GameParams.Talismans.VisibleCount-1) div TALISMANS_PER_PAGE then
      S := S + '>>'
    else
      S := S + '  ';

    Add(S);
  end;

  Add('Press Esc for main menu');

  PreLF(1);
  PreAdd('Talisman Record (' + IntToStr(playerpoints) + '%)');

end;

procedure TGameTalismanScreen.Form_KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_ESCAPE: begin
                 //GameParams.TalismanPage := 0;
                 CloseScreen(gstMenu);
               end;
    VK_LEFT: if fPage > 0 then
             begin
               GameParams.TalismanPage := fPage - 1;
               CloseScreen(gstTalisman);
             end;
    VK_RIGHT: if fPage < ((GameParams.Talismans.VisibleCount - 1) div TALISMANS_PER_PAGE) then
              begin
                GameParams.TalismanPage := fPage + 1;
                CloseScreen(gstTalisman);
              end;
  end;
end;

procedure TGameTalismanScreen.Form_KeyPress(Sender: TObject; var Key: Char);
begin
end;

end.


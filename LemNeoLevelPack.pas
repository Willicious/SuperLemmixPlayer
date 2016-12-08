unit LemNeoLevelPack;

// Replaces LemDosStyle, LemDosLevelSystem etc. Those are messy. This should be tidier.

interface

uses
  GR32, CRC32, PngInterface,
  Classes, SysUtils, StrUtils, Contnrs,
  LemStrings, LemTypes, LemNeoParser;

const
  PKI_PANEL_BASE         = 0;
  PKI_PANEL_BASE_MASK    = 1;
  PKI_PANEL_BUTTONS      = 2;
  PKI_PANEL_BUTTONS_MASK = 3;
  PKI_PANEL_FONT         = 4;
  PKI_PANEL_FONT_MASK    = 5;
  PKI_PANEL_DIGITS       = 6;
  PKI_PANEL_DIGITS_MASK  = 7;
  PKI_PANEL_ERASE        = 8;


  PANEL_IMAGE_NAMES: array[0..8] of String = ('skill_panel.png', 'skill_panel_mask.png',
                                              'skill_buttons.png', 'skill_buttons_mask.png',
                                              'skill_panel_font.png', 'skill_panel_font_mask.png',
                                              'skill_panel_digits.png', 'skill_panel_digits_mask.png',
                                              'skill_count_erase.png');

type
  TNeoLevelEntry = class;
  TNeoLevelEntries = class;
  TNeoLevelGroup = class;
  TNeoLevelGroups = class;

  TNeoLevelEntry = class  // This is an entry in a level pack's list, and does NOT contain the level itself
    private
      fGroup: TNeoLevelGroup;

      fTitle: String;
      fFilename: String;
      fPreviewImage: TBitmap32; // cached
      // Should we cache the physics map too? I decided against it for the reason: It's not a critical problem if
      // the preview image is inaccurate, but it's far more serious if the physics map is wrong.

      fLastCRC32: Cardinal;

      procedure Wipe;
      procedure SetFilename(aValue: String);
      function GetFullPath: String;
    public
      constructor Create(aGroup: TNeoLevelGroup);
      destructor Destroy; override;

      procedure EnsureUpdated;

      property Title: String read fTitle;
      property Filename: String read fFilename write SetFilename;
      property Path: String read GetFullPath; // relative to base NeoLemmix folder
  end;

  TNeoLevelGroup = class
    private
      fParentGroup: TNeoLevelGroup;
      fChildGroups: TNeoLevelGroups;
      fLevels: TNeoLevelEntries;

      fPanelImages: array[0..8] of TBitmap32;

      fFolder: String;

      procedure SetFolderName(aValue: String);
      function GetFullPath: String;
      function GetPanelImage(Index: Integer): TBitmap32;
    public
      constructor Create(aParentGroup: TNeoLevelGroup);
      destructor Destroy; override;

      procedure EnsureUpdated;

      property Folder: String read fFolder write SetFolderName;
      property Path: String read GetFullPath; // relative to base NeoLemmix folder

      property PanelImage[Index: Integer]: TBitmap32 read GetPanelImage;
  end;


  // Lists //

  TNeoLevelEntries = class(TObjectList)
    private
      fOwner: TNeoLevelGroup;
      function GetItem(Index: Integer): TNeoLevelEntry;
    public
      constructor Create(aOwner: TNeoLevelGroup);
      function Add: TNeoLevelEntry;
      property Items[Index: Integer]: TNeoLevelEntry read GetItem; default;
      property List;
  end;

  TNeoLevelGroups = class(TObjectList)
    private
      fOwner: TNeoLevelGroup;
      function GetItem(Index: Integer): TNeoLevelGroup;
    public
      constructor Create(aOwner: TNeoLevelGroup);
      function Add: TNeoLevelGroup;
      property Items[Index: Integer]: TNeoLevelGroup read GetItem; default;
      property List;
  end;

implementation

{ TNeoLevelEntry }

constructor TNeoLevelEntry.Create(aGroup: TNeoLevelGroup);
begin
  inherited Create;
  fGroup := aGroup;
  fPreviewImage := nil;
end;

destructor TNeoLevelEntry.Destroy;
begin
  Wipe; // since object fields are freed and nil'd there, saves having to free everything in two places
  inherited;
end;

procedure TNeoLevelEntry.Wipe;
begin
  if fPreviewImage <> nil then
    fPreviewImage.Free;
  fPreviewImage := nil;

  fTitle := '';
end;

procedure TNeoLevelEntry.EnsureUpdated;
var
  CRC: Cardinal;
begin
  CRC := CalculateCRC32(fFilename);
  if CRC <> fLastCRC32 then Wipe;
  fLastCRC32 := CRC;
end;

procedure TNeoLevelEntry.SetFilename(aValue: String);
begin
  if fFilename = aValue then Exit;
  fFilename := aValue;
  EnsureUpdated; // firstly, in case of duplicate files; secondly, avoids duplicating code as much would be the same as what's done there
end;

function TNeoLevelEntry.GetFullPath: String;
begin
  if fGroup = nil then
    Result := ''
  else
    Result := fGroup.Path;

  Result := Result + fFilename;
end;

{ TNeoLevelGroup }

constructor TNeoLevelGroup.Create(aParentGroup: TNeoLevelGroup);
begin
  inherited Create;
  fChildGroups := TNeoLevelGroups.Create(self);
  fLevels := TNeoLevelEntries.Create(self);
  fParentGroup := aParentGroup;
end;

destructor TNeoLevelGroup.Destroy;
begin
  fChildGroups.Free;
  fLevels.Free;
  inherited;
end;

procedure TNeoLevelGroup.SetFolderName(aValue: String);
begin
  if fFolder = aValue then Exit;
  fFolder := aValue;
  EnsureUpdated;
end;

procedure TNeoLevelGroup.EnsureUpdated;
var
  i: Integer;
begin
  for i := 0 to fChildGroups.Count-1 do
    fChildGroups[i].EnsureUpdated;

  for i := 0 to fLevels.Count-1 do
    fLevels[i].EnsureUpdated;
end;

function TNeoLevelGroup.GetFullPath: String;
begin
  if fParentGroup = nil then
    Result := AppPath + SFLevels
  else
    Result := fParentGroup.Path;

  Result := Result + fFolder + '\';
end;

function TNeoLevelGroup.GetPanelImage(Index: Integer): TBitmap32;
begin
  Result := fPanelImages[Index];
end;



// --------- LISTS --------- //

{ TNeoLevelEntries }

constructor TNeoLevelEntries.Create(aOwner: TNeoLevelGroup);
var
  aOwnsObjects: Boolean;
begin
  aOwnsObjects := true;
  inherited Create(aOwnsObjects);
  fOwner := aOwner;
end;

function TNeoLevelEntries.Add: TNeoLevelEntry;
begin
  Result := TNeoLevelEntry.Create(fOwner);
  inherited Add(Result);
end;

function TNeoLevelEntries.GetItem(Index: Integer): TNeoLevelEntry;
begin
  Result := inherited Get(Index);
end;

{ TNeoLevelGroups }

constructor TNeoLevelGroups.Create(aOwner: TNeoLevelGroup);
var
  aOwnsObjects: Boolean;
begin
  aOwnsObjects := true;
  inherited Create(aOwnsObjects);
  fOwner := aOwner;
end;

function TNeoLevelGroups.Add: TNeoLevelGroup;
begin
  Result := TNeoLevelGroup.Create(fOwner);
  inherited Add(Result);
end;

function TNeoLevelGroups.GetItem(Index: Integer): TNeoLevelGroup;
begin
  Result := inherited Get(Index);
end;

end.
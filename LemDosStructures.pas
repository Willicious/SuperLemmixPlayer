{$include lem_directives.inc}
unit LemDosStructures;

interface

uses
  Types, GR32;

// NeoLemmix Save Data Structure
type
  TNeoRecordsTableEntry = packed record
    BestTime    : LongWord;
    BestSave    : Word;
    Removed2    : Word;
    Reserved    : array[0..21] of Byte;
    Zeroed      : Word;
  end;

  TNeoLevelTable = packed array[0..31] of byte;
  TNeoRecordTable = packed array[0..255] of TNeoRecordsTableEntry;

  TNeoConfigRecord = packed record
    ToggleOptions   : LongWord;
    Removed1        : array[0..2] of Byte;
    PercentOption   : Byte;
    Removed3        : LongWord;
    ForceSkillset   : Word;
    Removed4        : Byte;
    TestOption      : Byte;
    SoundOption     : Byte;
    Removed7        : LongWord;
    Removed8        : Longword;
    Reserved        : array[0..6] of Byte;
    PackName        : array[0..31] of Char;
    PrefixName      : array[0..15] of Char;
  end;

  TNeoSaveRecord = packed record
    UnlockTable   : packed array[0..14] of TNeoLevelTable;
    CompleteTable : packed array[0..14] of TNeoLevelTable;
    RecordTable   : packed array[0..14] of TNeoRecordTable;
    Config        : TNeoConfigRecord;
  end;


{-------------------------------------------------------------------------------
  LVL raw level file structure as used by dos en winlemmings.
-------------------------------------------------------------------------------}
const
  LVL_MAXOBJECTCOUNT  = 32;
  LVL_MAXTERRAINCOUNT = 400;
  LVL_MAXSTEELCOUNT   = 32;

type
  TLVLObject = packed record
  case Byte of
    0: ( AsInt64: Int64 );
    1: ( D0, D1: DWord);
    2: ( W0, W1, W2, W3: Word);
    3: ( B0, B1, B2, B3, B4, B5, B6, B7: Byte);
    4: (
          XPos              : Word; // swap lo and hi
          YPos              : Word; // swap lo and hi
          ObjectID          : Word;
          Modifier          : Byte;
          DisplayMode       : Byte; // $8F = invert; $0F = normal
        );

  end;

  {
    bits 0..3    = modifier
    bits 4..7    shl 8 for xpos
    bits 8..15   add to xpos
    bits 16..24  9 bits number YPos
  }

  TLVLTerrain = packed record
  case Byte of
    0: ( D0: DWord );
    1: ( W0, W1: Word );
    2: ( B0, B1, B2, B3: Byte );
    3: (
          XPos              : Word;
          YPos              : Byte; // 9 bits
          TerrainID         : Byte;
       );
  end;

  TLVLSteel = packed record
  case Byte of
    0: ( D0: DWord );
    1: ( W0, W1: Word);
    2: ( B0, B1, B2, B3: Byte);
    3: (
         XPos              : Byte; // 9 bits
         YPos              : Byte; // 7 bits bits 1..7
         Area              : Byte; // bits 0..3 is height in 4 pixel units (then add 4)
                                   // bit 4..7 is width in 4 pixel units (then add 4)
         b                 : Byte; // always zero
       );
  end;

  TLVLObjects = array[0..LVL_MAXOBJECTCOUNT - 1] of TLVLObject;
  TLVLTerrains = array[0..LVL_MAXTERRAINCOUNT - 1] of TLVLTerrain;
  TLVLSteels = array[0..LVL_MAXSTEELCOUNT - 1] of TLVLSteel;

  // the main record 2048 bytes
  TLVLRec = packed record
    {0000}  ReleaseRate                : Word; // big endian, swap!
    {    }  LemmingsCount              : Word; // big endian, swap!
    {    }  RescueCount                : Word; // big endian, swap!
            TimeSeconds                : Byte;
    {    }  TimeMinutes                : Byte; // big endian, swap!
    {0008}  ClimberCount               : Word; // big endian, swap!
    {    }  FloaterCount               : Word; // big endian, swap!
    {    }  BomberCount                : Word; // big endian, swap!
    {    }  BlockerCount               : Word; // big endian, swap!
    {    }  BuilderCount               : Word; // big endian, swap!
    {    }  BasherCount                : Word; // big endian, swap!
    {    }  MinerCount                 : Word; // big endian, swap!
    {    }  DiggerCount                : Word; // big endian, swap!
    {0018}  ScreenPosition             : Word; // big endian, swap!
    {001A}  GraphicSet                 : Word; // big endian, swap!
            LevelOptions               : Byte;
    {    }  GraphicSetEx               : Byte; // big endian, swap!
    {001E}  Reserved                   : Word; // big endian, swap! $FFFF if SuperLemming else $0000
    {0020}  Objects                    : TLVLObjects;
    {0120}  Terrain                    : TLVLTerrains;
    {0760}  Steel                      : TLVLSteels;
    {07E0}  LevelName                  : array[0..31] of Char;
  end;

const
  LVL_SIZE = SizeOf(TLVLRec);

type

  TNewNeoLVLObject = packed record
          XPos              : LongInt;
          YPos              : LongInt;
          ObjectID          : Word;
          SValue            : Byte;
          LValue            : Byte;
          ObjectFlags       : Word;
          GSIndex           : Byte;
          Reserved          : Array[0..3] of Byte;
          Locked            : Byte; // editor use only, but keeping consistency
  end;

  TNewNeoLVLTerrain = packed record
          XPos              : LongInt;
          YPos              : LongInt;
          TerrainID         : Word;
          TerrainFlags      : Word;
          GSIndex           : Byte;
          TerReserved       : Array[0..1] of Byte;
          Locked            : Byte; // editor use only
  end;

  TNewNeoLVLSteel = packed record
         XPos              : LongInt; // 9 bits
         YPos              : LongInt; // 7 bits bits 1..7
         SteelWidth        : LongWord;
         SteelHeight       : LongWord;
         SteelFlags        : Byte;
         SteReserved       : Array[0..1] of Byte;
         Locked            : Byte; // editor use only
  end;

  TNeoLVLHeader = packed record
    {0000}  FormatTag                  : Byte;
            MusicNumber                : Byte;
            LemmingsCount              : Word;
            RescueCount                : Word;
            TimeLimit                  : Word;
    {0008}  ReleaseRate                : Byte;
            LevelOptions               : Byte;
            Resolution                 : Byte;
            BgIndex                    : Byte;
            ScreenPosition             : Word;
            ScreenYPosition            : Word;
    {0010}  WalkerCount                : Byte;
            ClimberCount               : Byte;
            SwimmerCount               : Byte;
            FloaterCount               : Byte;
            GliderCount                : Byte;
            MechanicCount              : Byte;
            BomberCount                : Byte;
            StonerCount                : Byte;
    {0018}  BlockerCount               : Byte;
            PlatformerCount            : Byte;
            BuilderCount               : Byte;
            StackerCount               : Byte;
            BasherCount                : Byte;
            MinerCount                 : Byte;
            DiggerCount                : Byte;
            ClonerCount                : Byte;
    {0020}  Gimmick                    : LongWord;
            Skillset                   : Word;
            RefSection                 : Byte;
            RefLevel                   : Byte;
    {0028}  Width                      : LongWord;
            Height                     : LongWord;
            VgaspecX                   : LongInt;
            VgaspecY                   : LongInt;
            LevelID                    : LongWord;
            LevelOptions2              : Byte;
            FencerCount                : Byte;
            Reserved2                  : array[0..1] of Byte;
    {0040}  LevelAuthor                : array[0..15] of Char;
    {0050}  LevelName                  : array[0..31] of Char;
    {0070}  StyleName                  : array[0..15] of Char;
    {0080}  VgaspecName                : array[0..15] of Char;
    {0090}  ReservedStr                : array[0..31] of Char;
  end;

  TNeoLVLSecondHeader = packed record
    {0000} ScreenPosition: LongWord;
           ScreenYPosition: LongWord;
           GimmickFlags2: LongWord;
           GimmickFlags3: LongWord;
    {0010} MusicName: array[0..15] of Char;
    {0020} SecRedirectRank: Byte;
           SecRedirectLevel: Byte;
           BnsRedirectRank: Byte;
           BnsRedirectLevel: Byte;
           ClockGimStart: Word;
           ClockGimEnd: Word;
           ClockGimPieces: Word;
    {002A}
  end;



  TNeoLVLObject = packed record
  case Byte of
    0: ( AsInt64: Int64 );
    1: ( D0, D1: DWord);
    2: ( W0, W1, W2, W3: Word);
    3: ( B0, B1, B2, B3, B4, B5, B6, B7: Byte);
    4: (
          XPos              : SmallInt;
          YPos              : SmallInt;
          ObjectID          : Byte;
          SValue            : Byte;
          LValue            : Byte;
          ObjectFlags       : Byte;
        );

  end;

  TNeoLVLTerrain = packed record
  case Byte of
    0: ( AsInt64: Int64);
    1: ( D0, D1: DWord );
    2: ( W0, W1, W2, W3: Word );
    3: ( B0, B1, B2, B3, B4, B5, B6, B7: Byte );
    4: (
          XPos              : SmallInt;
          YPos              : SmallInt;
          TerrainID         : Byte;
          TerrainFlags      : Byte;
          TerReserved       : Word;
       );
  end;

  TNeoLVLSteel = packed record
  case Byte of
    0: ( AsInt64: Int64);
    1: ( D0, D1: DWord );
    2: ( W0, W1, W2, W3: Word );
    3: ( B0, B1, B2, B3, B4, B5, B6, B7: Byte );
    4: (
         XPos              : SmallInt; // 9 bits
         YPos              : SmallInt; // 7 bits bits 1..7
         SteelWidth        : Byte;
         SteelHeight       : Byte;
         SteelFlags        : Byte;
         SteReserved       : Byte;
       );
  end;

  TNeoLVLObjects = array[0..127] of TNeoLVLObject;
  TNeoLVLTerrains = array[0..999] of TNeoLVLTerrain;
  TNeoLVLSteels = array[0..127] of TNeoLVLSteel;

  TNeoLVLRec = packed record
    {0000}  FormatTag                  : Byte;
            MusicNumber                : Byte;
            LemmingsCount              : Word;
            RescueCount                : Word;
            TimeLimit                  : Word;
    {0008}  ReleaseRate                : Byte;
            LevelOptions               : Byte;
            GraphicSet                 : Byte;
            GraphicSetEx               : Byte;
            ScreenPosition             : Word;
            ScreenYPosition            : Word;
    {0010}  WalkerCount                : Byte;
            ClimberCount               : Byte;
            SwimmerCount               : Byte;
            FloaterCount               : Byte;
            GliderCount                : Byte;
            MechanicCount              : Byte;
            BomberCount                : Byte;
            StonerCount                : Byte;
    {0018}  BlockerCount               : Byte;
            PlatformerCount            : Byte;
            BuilderCount               : Byte;
            StackerCount               : Byte;
            BasherCount                : Byte;
            MinerCount                 : Byte;
            DiggerCount                : Byte;
            ClonerCount                : Byte;
    {0020}  Gimmick                    : LongWord;
            Skillset                   : Word;
            RefSection                 : Byte;
            RefLevel                   : Byte;
    {0028}  WidthAdjust                : SmallInt;
            HeightAdjust               : SmallInt;
            VgaspecX                   : SmallInt;
            VgaspecY                   : SmallInt;
    {0030}  LevelAuthor                : array[0..15] of Char;
    {0040}  LevelName                  : array[0..31] of Char;
    {0060}  StyleName                  : array[0..15] of Char;
    {0070}  VgaspecName                : array[0..15] of Char;
    {0080}  WindowOrder                : array[0..31] of Byte;
    {00A0}  ReservedStr                : array[0..31] of Char;

    {00C0}  Objects                    : TNeoLVLObjects;
    {04C0}  Terrain                    : TNeoLVLTerrains;
    {2400}  Steel                      : TNeoLVLSteels;

  end;

const
  NEO_LVL_SIZE = SizeOf(TNeoLVLRec);


type
{SYSTEM.DAT for Flexi player}

TSysDatRec = packed record
    {0000}  PackName                   : array[0..31] of Char;
	          SecondLine                 : array[0..31] of Char;
            RankNames                  : array[0..14] of array[0..15] of Char;
            RankCount                  : Byte;
            Removed                    : array[0..14] of Byte;
            TrackCount                 : Byte;
            CodeSeed                   : Byte;
            CheatCode                  : array[0..9] of Char;
            Options                    : Byte;
            Options2                   : Byte;
            Options3                   : Byte; //$20 here is highest currently used
            Options4                   : Byte;
            KResult                    : array[0..2] of array[0..1] of array[0..35] of Char;
            SResult                    : array[0..8] of array[0..1] of array[0..35] of Char;
            Congrats                   : array[0..17] of array[0..35] of Char;
            ScrollerTexts              : array[0..15] of array[0..35] of Char;
            StyleNames                 : array[0..255] of array[0..15] of Char;
            VgaspecNames               : array[0..255] of array[0..15] of Char;
  end;

const
  SYSDAT_SIZE = SizeOf(TSysDatRec);


{-------------------------------------------------------------------------------
  GROUNDXX.DAT files (1056 bytes) (16 objects, 64 terrain, color palette)
  o See documentation for details
  o Little Endian words, so we can just load them from disk halleluyah!
-------------------------------------------------------------------------------}

type
  TDosEGAPalette8 = packed array[0..7] of Byte;

  TDosVgaColorRec = packed record
    R, G, B: Byte;
  end;

  TDosVGAPalette8 = packed array[0..7] of TDosVGAColorRec;

  TDosVGAPalette16 = packed array[0..15] of TDosVGAColorRec;

  TDosVgaSpecPaletteHeader = packed record
    VgaPal: TDosVGAPalette8; // 24
    EgaPal: TDosEGAPalette8; // 8
    UnknownPal: array[0..7] of Byte; // maybe even less colors
  end;

const
  DosInLevelPalette: TDosVGAPalette8 =
  (
    (R: 000; G: 000; B: 000), // black
    (R: 016; G: 016; B: 056), // blue
    (R: 000; G: 044; B: 000), // green
    (R: 060; G: 052; B: 052), // white
    (R: 044; G: 044; B: 000), // yellow
    (R: 060; G: 008; B: 008), // red
    (R: 032; G: 032; B: 032), // gray
    (R: 000; G: 000; B: 000) // not used: probably this color is replaced with the standard palette entry in ground??.dat
  );

const
  { TODO : do not mix original rgb and converted rgb }
  DosMainMenuPalette: TDosVGAPalette16 = (
    (R: 000; G: 000; B: 000), // black
    (R: 128; G: 064; B: 032), // browns
    (R: 096; G: 048; B: 032),
    (R: 048; G: 000; B: 016),
    (R: 032; G: 008; B: 124), // purples
    (R: 064; G: 044; B: 144),
    (R: 104; G: 088; B: 164),
    (R: 152; G: 140; B: 188),
    (R: 000; G: 080; B: 000), // greens
    (R: 000; G: 096; B: 016),
    (R: 000; G: 112; B: 032),
    (R: 000; G: 128; B: 064),
    (R: 208; G: 208; B: 208), // white
    (R: 176; G: 176; B: 000), // yellow
    (R: 064; G: 080; B: 176), // blue
    (R: 224; G: 128; B: 144)  // pink
  );

function DosVgaColorToColor32(const ColorRec: TDosVgaColorRec): TColor32;
function GetDosMainMenuPaletteColors32(UseXmas: Boolean = false): TArrayOfColor32;

implementation

function GetDosMainMenuPaletteColors32(UseXmas: Boolean = false): TArrayOfColor32;
var
  i: Integer;
  P: PColor32;

begin
  SetLength(Result, 16);
  { TODO : move this conversion somewhere else }
  for i := 0 to 15 do // bad code
  begin
    P := @Result[i];
    TColor32Entry(P^).A := 0;
    TColor32Entry(P^).R := DosMainMenuPalette[i].R;
    TColor32Entry(P^).G := DosMainMenuPalette[i].G;
    TColor32Entry(P^).B := DosMainMenuPalette[i].B;
  end;

  if UseXmas then
  begin
    P := @Result[3];
    TColor32Entry(P^).A := 0;
    TColor32Entry(P^).R := 0;
    TColor32Entry(P^).G := 0;
    TColor32Entry(P^).B := 0;
    P := @Result[14];
    TColor32Entry(P^).A := 0;
    TColor32Entry(P^).R := 240;
    TColor32Entry(P^).G := 32;
    TColor32Entry(P^).B := 32;
  end;

end;

function DosVgaColorToColor32(const ColorRec: TDosVgaColorRec): TColor32;
begin
  with TColor32Entry(Result) do
  begin
    A := $FF;
    R := ColorRec.R * 4;
    G := ColorRec.G * 4;
    B := ColorRec.B * 4;
  end;
end;

end.


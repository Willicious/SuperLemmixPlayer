unit FMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  umisc, ucodes, Dialogs,uzip, StdCtrls;

type
  TForm1 = class(TForm)


    BtnSoundsOrig: TButton;
    btnFlexiData: TButton;

    procedure BtnDataClick(Sender: TObject);
    procedure BtnSoundsOrigClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    procedure CreateDatResource(const aSourcePath: string);


//    procedure DoCreateArcResource(const aResName, aResType: string)
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;


implementation

{$R *.dfm}

const
  TAG_FLEXI = 13;

procedure TForm1.FormCreate(Sender: TObject);
begin

  BtnFlexiData.Tag     := TAG_FLEXI;

end;

procedure TForm1.CreateDatResource(const aSourcePath: string);
{-------------------------------------------------------------------------------
  creates a zipped resourcefile of all *.dat files in <aSourcePath>
-------------------------------------------------------------------------------}
var
  Z: TArchive;
  Command, Param, ZipFileName, ScriptFileName: string;
begin
  ZipFileName    := GetApplicationPath + aSourcePath + 'lemdata.arc';
  ScriptFileName := GetApplicationPath + aSourcePath + 'lemdata.rc';

  DeleteFile(ZipFileName);
  DeleteFile(ScriptFileName);
  DeleteFile(ReplaceFileExt(ZipFileName, '.res'));

  Z := TArchive.Create;
  Z.OpenArchive(ZipFileName, amCreate);
  Z.ZipOptions := [];
  Z.AddFiles(IncludeTrailingBackslash(GetApplicationPath + aSourcePath) + '*.dat');
  //Z.AddFiles(IncludeTrailingBackslash(GetApplicationPath + aSourcePath) + '*.it');
  //Z.AddFiles(IncludeTrailingBackslash(GetApplicationPath + aSourcePath) + '*.ogg');
  Z.AddFiles(IncludeTrailingBackslash(GetApplicationPath + aSourcePath) + '*.nxmi');
  //Z.AddFiles(IncludeTrailingBackslash(GetApplicationPath + aSourcePath) + 'image\*.png');
  //Z.AddFiles(IncludeTrailingBackslash(GetApplicationPath + aSourcePath) + 'lems\*.png');
  Z.AddFiles(IncludeTrailingBackslash(GetApplicationPath + aSourcePath) + '*.txt');



  Z.Free;

  StringToFile('LANGUAGE 9, 5' + CrLf + 'LEMDATA' + ' ' + 'ARCHIVE ' + '"' + ZipFileName + '"', ScriptFileName);

  // compileer tot resource met brcc32.exe
  DoShellExecute('C:\Program Files (x86)\Borland\Delphi7\Bin\brcc32.exe', '"' + ScriptFileName + '"', '');
end;

procedure TForm1.BtnDataClick(Sender: TObject);
var
  Path: string;
  But: TButton absolute Sender;
begin
  if not (Sender is TButton) then
    Exit;
  Path := '';
  case But.Tag of
    TAG_FLEXI : Path := 'Data\';
  else
    raise Exception.Create('unknown button tag')
  end;
  CreateDatResource(Path);
end;

procedure TForm1.BtnSoundsOrigClick(Sender: TObject);
var
  Z: TArchive;
  Command, Param, ZipFileName, ScriptFileName: string;
begin
  ZipFileName    := GetApplicationPath + 'sounds\lemsounds.arc';
  ScriptFileName := GetApplicationPath + 'sounds\lemsounds.rc';

  DeleteFile(ZipFileName);
  DeleteFile(ScriptFileName);
  DeleteFile(ReplaceFileExt(ZipFileName, '.res'));

  Z := TArchive.Create;
  Z.OpenArchive(ZipFileName, amCreate);
  Z.ZipOptions := [];
  Z.AddFiles('sounds\*.wav');
  Z.AddFiles('sounds\*.ogg');
  Z.Free;

  StringToFile('LANGUAGE 9, 5' + CrLf + 'LEMSOUNDS' + ' ' + 'ARCHIVE ' + '"' + ZipFileName + '"', ScriptFileName);

  // compileer tot resource met brcc32.exe
  DoShellExecute('C:\Program Files (x86)\Borland\Delphi7\Bin\brcc32.exe', '"' +
                 ScriptFileName + '"', '');

end;

end.


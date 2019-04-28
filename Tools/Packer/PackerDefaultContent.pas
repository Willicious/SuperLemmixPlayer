unit PackerDefaultContent;

interface

uses
  GameSound,
  LemTypes,
  Classes,
  SysUtils,
  IOUtils;

  procedure LoadDefaultContentList;
  procedure BuildDefaultContentList;
  function IsStyleDefaultContent(aStyleName: String): Boolean;
  function IsFileDefaultContent(aFilePath: String): Boolean;

implementation

var
  _Styles, _Files: TStringList;

function IsStyleDefaultContent(aStyleName: String): Boolean;
begin
  Result := _Styles.IndexOf(aStyleName) >= 0;
end;

function IsFileDefaultContent(aFilePath: String): Boolean;
begin
  Result := _Files.IndexOf(aFilePath) >= 0;
end;

procedure LoadDefaultContentList;
var
  SL: TStringList;
  i: Integer;
begin
  SL := TStringList.Create;
  try
    if FileExists(AppPath + 'NLPackerDefaultData.ini') then
      SL.LoadFromFile(AppPath + 'NLPackerDefaultData.ini');

    for i := 0 to SL.Count-1 do
      if SL.Names[i] = 'STYLE' then
        _Styles.Add(SL.ValueFromIndex[i])
      else if SL.Names[i] = 'FILE' then
        _Files.Add(SL.ValueFromIndex[i]);
  finally
    SL.Free;
  end;
end;

procedure BuildDefaultContentList;
var
  SL: TStringList;
  SearchRec: TSearchRec;

  BasePath: String;

  procedure HandleAudioDir(aDir: String; aMusic: Boolean);
  var
    AudioList: TStringList;

    procedure HandleAudioDirRecursive(aPath: String);
    var
      SearchRec: TSearchRec; // needs a local one because recursive
    begin
      aPath := IncludeTrailingPathDelimiter(aPath);
      if FindFirst(BasePath + aPath + '*', faDirectory, SearchRec) = 0 then
      begin
        repeat
          if (SearchRec.Attr and faDirectory) <> 0 then
          begin
            if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
              HandleAudioDirRecursive(aPath + SearchRec.Name);
          end else
            AudioList.Add(aPath + ChangeFileExt(SearchRec.Name, ''));
        until FindNext(SearchRec) <> 0;
        FindClose(SearchRec);
      end;
    end;

    procedure ProcessAudioList;
    var
      i, n: Integer;
    begin
      for i := 0 to AudioList.Count-1 do
        for n := 0 to Length(VALID_AUDIO_EXTS)-1 do
        begin
          SL.Add('FILE=' + AudioList[i] + VALID_AUDIO_EXTS[n]);
          if (not aMusic) and (VALID_AUDIO_EXTS[n] = LAST_SOUND_EXT) then
            Break;
        end;

    end;
  begin
    AudioList := TStringList.Create;
    try
      AudioList.Sorted := true;
      AudioList.Duplicates := dupIgnore;

      HandleAudioDirRecursive(aDir);
      ProcessAudioList;
    finally
      AudioList.Free;
    end;
  end;
begin
  BasePath := ParamStr(2);
  if BasePath = '' then Exit;

  if not TPath.IsPathRooted(BasePath) then
    BasePath := AppPath + BasePath;

  BasePath := IncludeTrailingPathDelimiter(BasePath);

  SL := TStringList.Create;
  try
    if FindFirst(BasePath + 'styles/*', faDirectory, SearchRec) = 0 then
    begin
      repeat
        if (SearchRec.Attr and faDirectory) = 0 then
          Continue;

        if (SearchRec.Name = '.') or (SearchRec.Name = '..') then
          Continue;

        SL.Add('STYLE=' + SearchRec.Name);
      until FindNext(SearchRec) <> 0;
      FindClose(SearchRec);
    end;

    HandleAudioDir('music', true);
    HandleAudioDir('sound', false);

    SL.SaveToFile(AppPath + 'NLPackerDefaultData.ini');
  finally
    SL.Free;
  end;
end;

initialization

_Styles := TStringList.Create;
_Files := TStringList.Create;

finalization

_Styles.Free;
_Files.Free;

end.
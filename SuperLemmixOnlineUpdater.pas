
unit SuperLemmixOnlineUpdater;

interface

uses
  Classes, SysUtils, IOUtils, StdCtrls, UITypes,
  Dialogs, Controls, Forms, Windows, ShellApi,
  JSON, Net.HttpClient, RegularExpressions, Zip, Generics.Collections,
  GameControl,
  SuperLemmixManifest,
  LemStrings, LemVersion,
  SharedGlobals;

var
  fAssetName: String;
  fDownloadURL: String;
  fVersionText: String;
  fZipFileName: String;

  procedure PerformOnlineUpdate(Auto: Boolean);
  procedure CheckLatestVersion;
  procedure DownloadLatestRelease(const DestinationFolder: string);
  procedure ApplyUpdate(const BaseFolder: string);

  function ReplaceExecutable(const BaseFolder: string): Boolean;

implementation

const
  LATEST_RELEASE_URL =
    'https://api.github.com/repos/Willicious/SuperLemmix-Download/releases/latest';

procedure PerformOnlineUpdate(Auto: Boolean);
var
  BaseFolder, TempFolder: string;
  UpdateDialog: TForm;
  UpdateLabel: TLabel;
begin
  BaseFolder := ExtractFilePath(ParamStr(0));
  TempFolder := TPath.Combine(BaseFolder, 'updates');

  try
    CheckLatestVersion;

    if not IsNewerVersion(fVersionText) then
    begin
      if not Auto then
        ShowMessage('SuperLemmix is up to date!');

      GameParams.LastUpdateCheck := Now;
      Exit;
    end;

    if MessageDlg(Format(
      'SuperLemmix version %s is available.' + sLineBreak + sLineBreak +
      'Would you like to download and install it now?',
      [fVersionText]), mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    begin
      GameParams.LastUpdateCheck := 0;
      Exit;
    end;

    UpdateDialog := TForm.Create(nil);
    try
      UpdateDialog.BorderStyle := bsDialog;
      UpdateDialog.Position := poMainFormCenter;
      UpdateDialog.Caption := 'SuperLemmix';
      UpdateDialog.ClientWidth := 300;
      UpdateDialog.ClientHeight := 80;

      UpdateLabel := TLabel.Create(UpdateDialog);
      UpdateLabel.Parent := UpdateDialog;
      UpdateLabel.Align := alClient;
      UpdateLabel.Alignment := taCenter;
      UpdateLabel.Layout := tlCenter;
      UpdateLabel.Caption := 'Updating SuperLemmix. Please wait...';

      UpdateDialog.Show;
      UpdateDialog.Update;

      DownloadLatestRelease(TempFolder);
      ApplyUpdate(BaseFolder);

      UpdateDialog.Hide;

      MessageDlg(Format(
        'SuperLemmix has been updated to version %s!' + sLineBreak + sLineBreak +
        'The application will now restart to complete the update.',
        [fVersionText]), mtInformation, [mbOK], 0);

      if ReplaceExecutable(BaseFolder) then
        Application.Terminate
      else begin
        MessageDlg('Error replacing executable.', mtError, [mbOK], 0);
        Log('Error replacing executable.');
      end;

    finally
      UpdateDialog.Free;
    end;

  except
    on E: Exception do
    begin
      Log('Update check failed: ' + E.Message);

      if not Auto then
        ShowMessage('No published update is currently available.' + sLineBreak + E.Message);
    end;
  end;

  { Clean up downloaded ZIP }
  if (fZipFileName <> '') and TFile.Exists(fZipFileName) then
  begin
    try
      TFile.Delete(fZipFileName);
    except
      // Non-fatal if cleanup fails
    end;
  end;
end;

procedure CheckLatestVersion;
var
  Http: THTTPClient;
  Response: IHTTPResponse;
  JsonValue: TJSONValue;
  ReleaseObject, AssetObject: TJSONObject;
  AssetsArray: TJSONArray;
  AssetValue, NameValue, URLValue: TJSONValue;
  CandidateName, Version: string;
  Match: TMatch;
  i: Integer;
begin
  fAssetName := '';
  fVersionText := '';
  fDownloadURL := '';

  CandidateName := '';

  Http := THTTPClient.Create;
  JsonValue := nil;
  try
    Http.UserAgent := 'SuperLemmixOnlineUpdater';

    { Retrieve the latest published GitHub Release }
    Response := Http.Get(LATEST_RELEASE_URL);

    if Response.StatusCode <> 200 then
      raise Exception.CreateFmt(
        'Could not retrieve latest release. HTTP status: %d',
        [Response.StatusCode]);

    JsonValue := TJSONObject.ParseJSONValue(
      Response.ContentAsString(TEncoding.UTF8));

    if not (JsonValue is TJSONObject) then
      raise Exception.Create('Invalid GitHub release response.');

    ReleaseObject := JsonValue as TJSONObject;

    AssetValue := ReleaseObject.GetValue('assets');

    if not (AssetValue is TJSONArray) then
      raise Exception.Create('Invalid GitHub release asset list.');

    AssetsArray := AssetValue as TJSONArray;

    { Find the SuperLemmix ZIP in the release assets }
    for i := 0 to AssetsArray.Count - 1 do
    begin
      if not (AssetsArray.Items[i] is TJSONObject) then
        Continue;

      AssetObject := AssetsArray.Items[i] as TJSONObject;

      NameValue := AssetObject.GetValue('name');
      URLValue := AssetObject.GetValue('browser_download_url');

      if not (NameValue is TJSONString) then
        Continue;

      if not (URLValue is TJSONString) then
        Continue;

      CandidateName := TJSONString(NameValue).Value;

      if not SameText(ExtractFileExt(CandidateName), '.zip') then
        Continue;

      if not CandidateName.StartsWith('SuperLemmix', True) then
        Continue;

      Match := TRegEx.Match(CandidateName, '(\d+)\.(\d+)\.(\d+)');

      if not Match.Success then
        Continue;

      fDownloadURL := TJSONString(URLValue).Value;
      Break;
    end;

    if fDownloadURL = '' then
      raise Exception.Create(
        'No versioned SuperLemmix ZIP found in latest release.');

    Version := Match.Groups[1].Value + '.' +
               Match.Groups[2].Value + '.' +
               Match.Groups[3].Value;

    fAssetName := CandidateName;
    fVersionText := Version;
  finally
    JsonValue.Free;
    Http.Free;
  end;
end;

procedure DownloadLatestRelease(const DestinationFolder: String);
var
  Http: THTTPClient;
  Response: IHTTPResponse;
  TempPath: string;
  FileStream: TFileStream;
begin
  fZipFileName := '';

  Http := THTTPClient.Create;
  try
    Http.UserAgent := 'SuperLemmixOnlineUpdater';

    TDirectory.CreateDirectory(DestinationFolder);

    fZipFileName := TPath.Combine(DestinationFolder, fAssetName);
    TempPath := fZipFileName + '.part';

    if TFile.Exists(TempPath) then
      TFile.Delete(TempPath);

    try
      FileStream := TFileStream.Create(TempPath, fmCreate);
      try
        Response := Http.Get(fDownloadURL, FileStream);

        if Response.StatusCode <> 200 then
          raise Exception.CreateFmt(
            'ZIP download failed. HTTP status: %d',
            [Response.StatusCode]);
      finally
        FileStream.Free;
      end;

      if TFile.Exists(fZipFileName) then
        TFile.Delete(fZipFileName);

      if not RenameFile(TempPath, fZipFileName) then
        raise Exception.Create(
          'Could not finalise downloaded ZIP.');

    except
      if TFile.Exists(TempPath) then
        TFile.Delete(TempPath);

      fZipFileName := '';
      raise;
    end;

  finally
    Http.Free;
  end;
end;

procedure ApplyUpdate(const BaseFolder: string);
var
  Manifest: TSuperLemmixManifest;
  Plan: TObjectList<TUpdateActionItem>;
  Item: TUpdateActionItem;
  StageFolder, RelativePath, RecycleTarget, ManifestPath: string;
  SrcFile, DstFile, BackupFile: string;
  Zip: TZipFile;
  InstalledFiles: TStringList;
  BackupFiles: TDictionary<string, string>;
  RecycleFiles: TDictionary<string, string>;
  PreservedFiles: TDictionary<string, string>;
  Pair: TPair<string, string>;
  i, BackupIndex: Integer;
  ManifestBackupPath, ReportPath: string;
  Report: TStringList;
  ManifestBackupCreated, PreviousManifestExists: Boolean;
  ExeSource, ExeDownloadPath: string;
begin
  if not TFile.Exists(fZipFileName) then
    raise Exception.Create('Update ZIP file not found.');

  if not TDirectory.Exists(BaseFolder) then
    raise Exception.Create('Installation folder not found.');

  ReportPath := TPath.Combine(BaseFolder, 'UpdateReport.txt');
  Report := TStringList.Create;
  Report.Add('Applying SuperLemmix update...');

  { Load local history and scan the new release }
  Manifest := TSuperLemmixManifest.Create;
  InstalledFiles := TStringList.Create;
  BackupFiles := TDictionary<string, string>.Create;
  RecycleFiles := TDictionary<string, string>.Create;
  PreservedFiles := TDictionary<string, string>.Create;
  try
    ManifestPath := TPath.Combine(BaseFolder, 'data\manifest.ini');
    Manifest.LoadFromIni(ManifestPath);
    Manifest.ScanZipFile(fZipFileName);

    StageFolder := '';
    ManifestBackupCreated := False;
    PreviousManifestExists := TFile.Exists(ManifestPath);

    { Extract the release into a temporary staging directory }
    StageFolder := TPath.Combine(TPath.GetTempPath, 'SuperLemmixUpdater\Staging');
    if TDirectory.Exists(StageFolder) then
      TDirectory.Delete(StageFolder, True);
    TDirectory.CreateDirectory(StageFolder);

    Zip := TZipFile.Create;
    try
      Zip.Open(fZipFileName, zmRead);
      try
        Zip.ExtractAll(StageFolder);
      finally
        Zip.Close;
      end;
    finally
      Zip.Free;
    end;

    { Generate the update plan using the new release hashes }
    Plan := Manifest.GetUpdatePlan(BaseFolder);
    try
      try
        { Execute non-destructive copy/update/backup phases. No files are permanently deleted yet }
        for Item in Plan do
        begin
          RelativePath := Item.RelativePath;

          if SameText(ExtractFileDir(RelativePath), 'styles') or
             SameText(Copy(RelativePath, 1, 7), 'styles\') then
            Continue;

          { The running executable is handled separately if needed }
          if SameText(RelativePath, SProgramEXE) then
            Continue;

          DstFile := TPath.Combine(BaseFolder, RelativePath);

          case Item.Action of
            maInstall:
            begin
              SrcFile := TPath.Combine(StageFolder, RelativePath);

              if not TFile.Exists(SrcFile) then
                raise Exception.CreateFmt(
                  'Update file not found in staging directory: %s',
                  [RelativePath]);

              TDirectory.CreateDirectory(ExtractFilePath(DstFile));
              InstalledFiles.Add(DstFile);
              TFile.Copy(SrcFile, DstFile, True);

              Report.Add('Installed: ' + RelativePath);
            end;

            maUpdate:
            begin
              SrcFile := TPath.Combine(StageFolder, RelativePath);

              if not TFile.Exists(SrcFile) then
                raise Exception.CreateFmt(
                  'Update file not found in staging directory: %s',
                  [RelativePath]);

              { Back up the existing file before replacing it }
              BackupFile := DstFile + '.update-backup';

              if TFile.Exists(BackupFile) then
                raise Exception.CreateFmt(
                  'Temporary backup already exists: %s', [BackupFile]);

              BackupFiles.Add(DstFile, BackupFile);

              if not RenameFile(DstFile, BackupFile) then
                raise Exception.CreateFmt(
                  'Could not back up existing file: %s', [RelativePath]);

              TDirectory.CreateDirectory(ExtractFilePath(DstFile));
              InstalledFiles.Add(DstFile);
              TFile.Copy(SrcFile, DstFile, True);

              Report.Add('Updated: ' + RelativePath);
            end;

            maPreserve:
            begin
              SrcFile := TPath.Combine(StageFolder, RelativePath);

              { If the file was removed from the release, preserve the user's modified version }
              if not TFile.Exists(SrcFile) then
              begin
                Report.Add('Preserved (removed from release): ' + RelativePath);
                Continue;
              end;

              { Back up the user's modified file }
              if TFile.Exists(DstFile) then
              begin
                BackupFile := DstFile + '.backup';
                BackupIndex := 1;

                while TFile.Exists(BackupFile) do
                begin
                  BackupFile := DstFile + '.backup.' + IntToStr(BackupIndex);
                  Inc(BackupIndex);
                end;

                PreservedFiles.Add(DstFile, BackupFile);

                if not RenameFile(DstFile, BackupFile) then
                  raise Exception.CreateFmt(
                    'Could not preserve existing file: %s', [RelativePath]);
              end;

              { Install the official release version }
              TDirectory.CreateDirectory(ExtractFilePath(DstFile));
              InstalledFiles.Add(DstFile);
              TFile.Copy(SrcFile, DstFile, True);

              Report.Add('Preserved & Updated: ' + RelativePath);
            end;

            maReviewRemoval:
            begin
              { Defer deletion: stage for safe removal post-update }
              if TFile.Exists(DstFile) then
              begin
                RecycleTarget := DstFile + '.recycle';
                RecycleFiles.Add(DstFile, RecycleTarget);

                if not RenameFile(DstFile, RecycleTarget) then
                  raise Exception.CreateFmt(
                    'Could not stage file for removal: %s', [RelativePath]);
              end;
            end;
          end;
        end;

        { Prepare the executable for replacement after the game exits }
        ExeSource := TPath.Combine(StageFolder, SProgramEXE);
        ExeDownloadPath := TPath.Combine(BaseFolder, SProgramEXE + '.download');

        if not TFile.Exists(ExeSource) then
          raise Exception.Create('Updated executable not found in release ZIP.');

        if TFile.Exists(ExeDownloadPath) then
          TFile.Delete(ExeDownloadPath);

        TFile.Copy(ExeSource, ExeDownloadPath);
        Report.Add('Prepared executable replacement.');

        { Back up the existing manifest, if one exists }
        ManifestBackupPath := ManifestPath + '.update-backup';

        if PreviousManifestExists then
        begin
          if TFile.Exists(ManifestBackupPath) then
            raise Exception.CreateFmt(
              'Temporary manifest backup already exists: %s',
              [ManifestBackupPath]);

          TFile.Copy(ManifestPath, ManifestBackupPath);
          ManifestBackupCreated := True;
        end;

        { Save the updated manifest }
        Manifest.SaveToIni(ManifestPath);
        Report.Add('Manifest successfully updated.');
      except
        on E: Exception do
        begin
          Report.Add('Update failed. Rolling back changes...');
          Report.Add('Reason: ' + E.Message);

          { Remove newly installed files }
          for i := InstalledFiles.Count - 1 downto 0 do
          begin
            try
              if TFile.Exists(InstalledFiles[i]) then
                TFile.Delete(InstalledFiles[i]);
            except
              on E: Exception do
                Report.Add('Rollback error deleting ' + InstalledFiles[i] + ': ' + E.Message);
            end;
          end;

          { Restore files replaced during the update }
          for Pair in BackupFiles do
          begin
            try
              if TFile.Exists(Pair.Value) then
              begin
                if TFile.Exists(Pair.Key) then
                  TFile.Delete(Pair.Key);

                if not RenameFile(Pair.Value, Pair.Key) then
                  raise Exception.Create('Could not restore backup.');
              end;
            except
              on E: Exception do
                Report.Add('Rollback error restoring ' + Pair.Key + ': ' + E.Message);
            end;
          end;

          { Restore the user's original modified files }
          for Pair in PreservedFiles do
          begin
            try
              if TFile.Exists(Pair.Value) then
              begin
                if TFile.Exists(Pair.Key) then
                  TFile.Delete(Pair.Key);

                if not RenameFile(Pair.Value, Pair.Key) then
                  raise Exception.Create('Could not restore preserved file.');
              end;
            except
              on E: Exception do
                Report.Add('Rollback error restoring ' + Pair.Key + ': ' + E.Message);
            end;
          end;

          { Restore files staged for removal }
          for Pair in RecycleFiles do
          begin
            try
              if TFile.Exists(Pair.Value) then
              begin
                if TFile.Exists(Pair.Key) then
                  TFile.Delete(Pair.Key);

                if not RenameFile(Pair.Value, Pair.Key) then
                  raise Exception.Create('Could not restore recycled file.');
              end;
            except
              on E: Exception do
                Report.Add('Rollback error restoring ' + Pair.Key + ': ' + E.Message);
            end;
          end;

          { Remove the prepared executable replacement }
          try
            if TFile.Exists(ExeDownloadPath) then
              TFile.Delete(ExeDownloadPath);
          except
            on E: Exception do
              Report.Add('Rollback error deleting prepared executable: ' + E.Message);
          end;

          { Restore the original manifest }
          if PreviousManifestExists then
          begin
            if ManifestBackupCreated then
            begin
              try
                if TFile.Exists(ManifestBackupPath) then
                begin
                  TFile.Copy(ManifestBackupPath, ManifestPath, True);
                  TFile.Delete(ManifestBackupPath);
                end;
              except
                on E: Exception do
                  Report.Add('Rollback error restoring manifest: ' + E.Message);
              end;
            end;
          end else begin
            { Remove the newly created manifest }
            try
              if TFile.Exists(ManifestPath) then
                TFile.Delete(ManifestPath);
            except
              on E: Exception do
                Report.Add('Rollback error deleting new manifest: ' + E.Message);
            end;
          end;

          { Prevent entering cleanup }
          raise;
        end;
      end;

      { Successful update: remove temporary backups and recycled files }

      { Remove temporary backups of updated files }
      for Pair in BackupFiles do
      begin
        try
          if TFile.Exists(Pair.Value) then
            TFile.Delete(Pair.Value);
        except
          on E: Exception do
            Report.Add('Cleanup warning - could not delete temporary backup: ' + Pair.Value + ': ' + E.Message);
        end;
      end;

      { Permanently remove files staged for deletion }
      for Pair in RecycleFiles do
      begin
        try
          if TFile.Exists(Pair.Value) then
            TFile.Delete(Pair.Value);
        except
          on E: Exception do
            Report.Add('Cleanup warning - could not delete recycled file: ' + Pair.Value + ': ' + E.Message);
        end;
      end;

      { Remove the temporary manifest backup }
      if ManifestBackupCreated then
      begin
        try
          if TFile.Exists(ManifestBackupPath) then
            TFile.Delete(ManifestBackupPath);
        except
          on E: Exception do
            Report.Add('Cleanup warning - could not delete manifest backup: ' + E.Message);
        end;
      end;
    finally
      Plan.Free;
    end;
  finally
    try
      try
        if (StageFolder <> '') and TDirectory.Exists(StageFolder) then
          TDirectory.Delete(StageFolder, True);
      except
        on E: Exception do
          Report.Add('Cleanup warning - could not remove staging directory: ' + E.Message);
      end;
    finally
      { Write the update report, whether the update succeeded or failed }
      try
        Report.Add('');
        Report.Add('Finished: ' + DateTimeToStr(Now));

        TFile.WriteAllText(ReportPath, Report.Text, TEncoding.UTF8);
      except
        on E: Exception do
          Log('Could not write update report: ' + E.Message);
      end;

      Manifest.Free;
      InstalledFiles.Free;
      BackupFiles.Free;
      RecycleFiles.Free;
      PreservedFiles.Free;
      Report.Free;
    end;
  end;
end;

function ReplaceExecutable(const BaseFolder: string): Boolean;
var
  ExePath, TempPath, BackupPath, ScriptPath: string;
  Script, Arguments: string;
  ProcessId: Cardinal;
  ShellResult: HINST;

  function Quote(const Value: string): string;
  begin
    Result := '''' + StringReplace(Value, '''', '''''', [rfReplaceAll]) + '''';
  end;

begin
  Result := False;

  ProcessId := GetCurrentProcessId;

  ExePath := TPath.Combine(BaseFolder, SProgramEXE);
  TempPath := ExePath + '.download';

  if not TFile.Exists(TempPath) then
  begin
    Log('Could not start executable replacement: downloaded executable not found.');
    Exit;
  end;

  BackupPath := ExePath + '.backup.' + IntToStr(ProcessId);

  ScriptPath := TPath.Combine(
    TPath.GetTempPath,
    'SuperLemmixUpdate_' + IntToStr(ProcessId) + '.ps1');

  Script :=
    '$ErrorActionPreference = ''Stop''' + sLineBreak +
    '$processId = ' + IntToStr(ProcessId) + sLineBreak +
    '$exePath = ' + Quote(ExePath) + sLineBreak +
    '$tempPath = ' + Quote(TempPath) + sLineBreak +
    '$backupPath = ' + Quote(BackupPath) + sLineBreak +
    '$scriptPath = $PSCommandPath' + sLineBreak +
    '$originalMoved = $false' + sLineBreak +
    'try {' + sLineBreak +
    '    while (Get-Process -Id $processId -ErrorAction SilentlyContinue) {' + sLineBreak +
    '        Start-Sleep -Milliseconds 500' + sLineBreak +
    '    }' + sLineBreak +
    '    if (!(Test-Path -LiteralPath $tempPath -PathType Leaf)) {' + sLineBreak +
    '        throw ''Downloaded update not found.''' + sLineBreak +
    '    }' + sLineBreak +
    '    if (Test-Path -LiteralPath $backupPath) {' + sLineBreak +
    '        throw ''Executable backup already exists.''' + sLineBreak +
    '    }' + sLineBreak +
    '    if (Test-Path -LiteralPath $exePath) {' + sLineBreak +
    '        Move-Item -LiteralPath $exePath -Destination $backupPath' + sLineBreak +
    '        $originalMoved = $true' + sLineBreak +
    '    }' + sLineBreak +
    '    Move-Item -LiteralPath $tempPath -Destination $exePath' + sLineBreak +
    '    Start-Process -FilePath $exePath -WorkingDirectory (Split-Path -Parent $exePath)' + sLineBreak +
    '    if ($originalMoved) {' + sLineBreak +
    '        Remove-Item -LiteralPath $backupPath -Force -ErrorAction SilentlyContinue' + sLineBreak +
    '    }' + sLineBreak +
    '}' + sLineBreak +
    'catch {' + sLineBreak +
    '    if ($originalMoved -and (Test-Path -LiteralPath $backupPath)) {' + sLineBreak +
    '        Remove-Item -LiteralPath $exePath -Force -ErrorAction SilentlyContinue' + sLineBreak +
    '        Move-Item -LiteralPath $backupPath -Destination $exePath -ErrorAction SilentlyContinue' + sLineBreak +
    '    }' + sLineBreak +
    '}' + sLineBreak +
    'finally {' + sLineBreak +
    '    Remove-Item -LiteralPath $scriptPath -Force -ErrorAction SilentlyContinue' + sLineBreak +
    '}' + sLineBreak;

  try
    TFile.WriteAllText(ScriptPath, Script, TEncoding.UTF8);

    Arguments :=
      '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' +
      ScriptPath + '"';

    ShellResult := ShellExecute(
      0, 'open', 'powershell.exe', PChar(Arguments), nil, SW_HIDE);

    Result := NativeInt(ShellResult) > 32;

    if not Result then
      TFile.Delete(ScriptPath);
  except
    on E: Exception do
    begin
      Log('Could not start executable replacement: ' + E.Message);
      Result := False;
    end;
  end;
end;

end.

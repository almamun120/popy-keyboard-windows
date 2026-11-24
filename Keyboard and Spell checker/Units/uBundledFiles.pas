{
  =============================================================================
  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  =============================================================================

  Popy Keyboard carries its data files (Database.db3, autodict.dct, keyboard
  layouts, skins and the virtual font) inside the program as one zip resource.
  At start-up every file that is missing from the data folder is written there,
  so the same program works

    - installed          : data folder = common application data \Popy Keyboard
    - portable, anywhere : data folder = the folder of the program

  Existing files are never overwritten.
}

unit uBundledFiles;

interface

procedure EnsureBundledFiles;

implementation

{$R ../Layout/Bundled_Files.res}

uses
  Winapi.Windows,
  System.Classes,
  System.SysUtils,
  System.Zip,
  Vcl.Forms,
  uFileFolderHandling;

{ =============================================================================== }

procedure EnsureBundledFiles;
var
  Res:       TResourceStream;
  Zip:       TZipFile;
  I:         Integer;
  Name, Dest: string;
  Data:      TBytes;
  FS:        TFileStream;
begin
  try
    Res := TResourceStream.create(HInstance, 'ASSETS_ZIP', RT_RCDATA);
    try
      Zip := TZipFile.create;
      try
        Zip.Open(Res, zmRead);
        for I := 0 to Zip.FileCount - 1 do
        begin
          Name := StringReplace(Zip.FileNames[I], '/', '\', [rfReplaceAll]);

          if SameText(Copy(Name, 1, 13), 'Virtual Font\') then
          begin
            // The virtual font is only used by the portable copy
            if not IsPortableMode then
              Continue;
            Dest := ExtractFilePath(Application.ExeName) + Name;
          end
          else
            Dest := GetAvroDataDir + Name;

          if FileExists(Dest) then
            Continue;

          try
            ForceDirectories(ExtractFilePath(Dest));
            Zip.Read(I, Data);
            FS := TFileStream.create(Dest, fmCreate);
            try
              if Length(Data) > 0 then
                FS.WriteBuffer(Data[0], Length(Data));
            finally
              FS.Free;
            end;
          except
            // Folder not writable or file in use: try the next one
          end;
        end;
      finally
        Zip.Free;
      end;
    finally
      Res.Free;
    end;
  except
    // Never stop the program because of this
  end;
end;

{ =============================================================================== }

end.

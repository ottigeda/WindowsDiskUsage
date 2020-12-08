//WinDu.DirectoryEntry
//
//MIT License
//
//Copyright (c) 2020 ottigeda
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.

unit WinDu.DirectoryEntry;
interface
uses
  Generics.Collections,
  FMX.Controls,
  FMX.Objects,
  FMX.Types,
  System.SysUtils;

type
////////////////////////////////////////////////////////////////////////////////
  TDirectoryEntry = class(TObject)
  private
    FTotalFileSize: Int64;
    FPath: string;
    FSubDirs: TObjectList<TDirectoryEntry>;
    FParentDir : TDirectoryEntry;
    FLevel: Integer;
    FNumberOfFiles: Int64;
    FPie: TPie;
    FOtherControls: TObjectList<TControl>;
    FLineControls: TObjectList<TControl>;
    function GetTotalSize: Int64;
    function GetTotalFiles: Int64;
    function GetTotalSizeText: string;
    function GetIsLeft: Boolean;
    function GetIsRight: Boolean;
    function GetDirectory: string;
    function GetTotalFolders: Int64;
    function GetAngle: Extended;
  public
    constructor Create(ADirectory : string);
    destructor Destroy; override;

    property Path          : string read FPath write FPath;
    property Directory     : string read GetDirectory;
    property TotalFileSize : Int64 read FTotalFileSize write FTotalFileSize;
    property NumberOfFiles : Int64 read FNumberOfFiles write FNumberOfFiles;
    property ParentDir     : TDirectoryEntry read FParentDir write FParentDir;
    property SubDirs       : TObjectList<TDirectoryEntry> read FSubDirs;
    property TotalSize     : Int64 read GetTotalSize;
    property TotalSizeText : string read GetTotalSizeText;
    property TotalFiles    : Int64 read GetTotalFiles;
    property TotalFolders  : Int64 read GetTotalFolders;
    property Level         : Integer read FLevel write FLevel;
    property Angle         : Extended read GetAngle;
    property Pie           : TPie read FPie write FPie;
    property OtherControls : TObjectList<TControl> read FOtherControls;
    property LineControls  : TObjectList<TControl> read FLineControls;
    property IsLeft        : Boolean read GetIsLeft;
    property IsRight       : Boolean read GetIsRight;
  end;
////////////////////////////////////////////////////////////////////////////////

implementation

{ TDirectoryEntry }

////////////////////////////////////////////////////////////////////////////////
constructor TDirectoryEntry.Create(ADirectory: string);
begin
  FSubDirs       := TObjectList<TDirectoryEntry>.Create;
  FOtherControls := TObjectList<TControl>.Create;
  FLineControls  := TObjectList<TControl>.Create;
  FPath := ADirectory;
  FTotalFileSize := 0;
  FNumberOfFiles := 0;
  FLevel         := 0;
  FPie           := nil;
end;
////////////////////////////////////////////////////////////////////////////////
destructor TDirectoryEntry.Destroy;
begin
  FreeAndNil(FSubDirs);
  FreeAndNil(FOtherControls);
  FreeAndNil(FLineControls);
  FreeAndNil(FPie);
  inherited;
end;
////////////////////////////////////////////////////////////////////////////////
function TDirectoryEntry.GetTotalSize: Int64;
var
  entry : TDirectoryEntry;
begin
  Result := 0;
  for entry in FSubDirs do begin
    Result := Result + entry.TotalSize;
  end;
  Result := Result + TotalFileSize;
end;
////////////////////////////////////////////////////////////////////////////////
function TDirectoryEntry.GetTotalSizeText: string;
const
  SIZE_CLASS : array[0..6] of string = ('B', 'kB', 'MB', 'GB', 'TB', 'PB', 'EB');
var
  size : Extended;
  i : Integer;
begin
  size := TotalSize;
  i := 0;
  while (i < Length(SIZE_CLASS)-1) and (size > 1024) do begin
    size := size / 1024;
    i := i + 1;
  end;
  Result := Format('%.2f %s' ,[size, SIZE_CLASS[i]]);
end;
////////////////////////////////////////////////////////////////////////////////
function TDirectoryEntry.GetTotalFiles: Int64;
var
  entry : TDirectoryEntry;
begin
  Result := 0;
  for entry in FSubDirs do begin
    Result := Result + entry.TotalFiles;
  end;
  Result := Result + NumberOfFiles;
end;
////////////////////////////////////////////////////////////////////////////////
function TDirectoryEntry.GetTotalFolders: Int64;
var
  entry : TDirectoryEntry;
begin
  Result := 0;
  for entry in FSubDirs do begin
    Result := Result + entry.TotalFolders;
  end;
  Result := Result + 1;
end;
////////////////////////////////////////////////////////////////////////////////
function TDirectoryEntry.GetAngle: Extended;
begin
  Result := 0;
  if Assigned(FPie) then begin
    Result := FPie.EndAngle - FPie.StartAngle;
  end;
end;
////////////////////////////////////////////////////////////////////////////////
function TDirectoryEntry.GetDirectory: string;
var
  p : Integer;
begin
  Result := ExcludeTrailingPathDelimiter(FPath);
  p := Pos(PathDelim, Result);
  while p > 0 do begin
    Result := Copy(Result, p+1, Length(Result));
    p := Pos(PathDelim, Result);
  end;
end;
////////////////////////////////////////////////////////////////////////////////
function TDirectoryEntry.GetIsLeft: Boolean;
var
  angle : Extended;
begin
  Result := False;
  if Assigned(FPie) then begin
    angle := FPie.StartAngle + (FPie.EndAngle - FPie.StartAngle) / 2;
    Result := Cos(angle/180*Pi) <= 0;
  end;
end;
////////////////////////////////////////////////////////////////////////////////
function TDirectoryEntry.GetIsRight: Boolean;
var
  angle : Extended;
begin
  Result := False;
  if Assigned(FPie) then begin
    angle := (FPie.EndAngle - FPie.StartAngle) / 2;
    Result := Cos(angle/180*Pi) >= 0;
  end;
end;
////////////////////////////////////////////////////////////////////////////////

end.

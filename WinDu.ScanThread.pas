//WinDu.ScanThread
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

unit WinDu.ScanThread;
interface
uses
  NativeFileApi,
  System.Classes,
  System.SysUtils,
  WinDu.DirectoryEntry,
  WinDu.ScanThreadPool,
  Winapi.Windows;

type
////////////////////////////////////////////////////////////////////////////////
  TScanDirectoryThread = class(TThread)
  private
    FPool : TScanDirectoryThreadPool;
    FBufferPool : TList;
    FWorking: Boolean;
    procedure Scanner(ARootEntry : TDirectoryEntry);
  public
    constructor Create(APool : TScanDirectoryThreadPool);
    destructor Destroy; override;
    procedure Execute; override;

    property Working : Boolean read FWorking write FWorking;
  end;
////////////////////////////////////////////////////////////////////////////////

implementation

{ TScanDirectoryThread }

////////////////////////////////////////////////////////////////////////////////
constructor TScanDirectoryThread.Create(APool : TScanDirectoryThreadPool);
begin
  inherited Create(False);
  FPool := APool;
  FWorking := True;
  FreeOnTerminate := True;
  FBufferPool := TList.Create;
end;
////////////////////////////////////////////////////////////////////////////////
destructor TScanDirectoryThread.Destroy;
begin
  while FBufferPool.Count > 0 do begin
    FreeMemory(FBufferPool[0]);
    FBufferPool.Delete(0);
  end;
  FreeAndNil(FBufferPool);
  inherited;
end;
////////////////////////////////////////////////////////////////////////////////
procedure TScanDirectoryThread.Execute;
var
  entry : TDirectoryEntry;
begin
  while not Terminated do begin
    entry := FPool.GetWork(FWorking);
    if Assigned(entry) then begin
      Scanner(entry);
    end
    else begin
      FPool.WaitWork;
    end;
  end;
  FWorking := False;
end;
////////////////////////////////////////////////////////////////////////////////
procedure TScanDirectoryThread.Scanner(ARootEntry : TDirectoryEntry);
var
  handle   : THandle;
  buffer   : PFILE_BOTH_DIRECTORY_INFORMATION;
  status   : IO_STATUS_BLOCK;
  info     : PFILE_BOTH_DIRECTORY_INFORMATION;
  filename : string;
  dir      : string;
  entry    : TDirectoryEntry;
  stat     : NativeUint;
const
  BUFFER_SIZE = 1024*SizeOf(FILE_BOTH_DIRECTORY_INFORMATION);
begin
  handle := CreateFile(PWideChar(WideString(ARootEntry.Path)), FILE_LIST_DIRECTORY, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS or FILE_FLAG_SEQUENTIAL_SCAN, 0);
  if handle <> INVALID_HANDLE_VALUE then begin
    if FBufferPool.Count = 0 then begin
      buffer := GetMemory(BUFFER_SIZE);
    end
    else begin
      buffer := FBufferPool[0];
      FBufferPool.Delete(0);
    end;
    stat := NtQueryDirectoryFile(handle,0,nil,nil,@status,buffer,BUFFER_SIZE,FileBothDirectoryInformation,False,nil,True);
    while stat = 0 do begin
      info := buffer;
      while True do begin
        if info.FileAttributes and $400 <> 0 then begin
          //h := handle;
          //ignore reparse points (symbolic link to another directory)
        end
        else if info.FileAttributes and faDirectory <> 0 then begin
          SetLength(filename, info.FileNameLength div 2);
          Move(info.FileName, filename[1], info.FileNameLength);
          if (filename <> '.') and (filename <> '..') then begin
            dir := IncludeTrailingPathDelimiter(ARootEntry.Path + filename);
            entry := TDirectoryEntry.Create(dir);
            entry.ParentDir := ARootEntry;
            entry.Level := ARootEntry.Level + 1;
            ARootEntry.SubDirs.Add(entry);
            FPool.AddWork(entry);
          end;
        end
        else begin
          ARootEntry.TotalFileSize := ARootEntry.TotalFileSize + info.EndOfFile.QuadPart;
          ARootEntry.NumberOfFiles := ARootEntry.NumberOfFiles + 1;
        end;
        if info.NextEntryOffset = 0 then begin
          Break;
        end
        else begin
          info := PFILE_BOTH_DIRECTORY_INFORMATION(NativeUInt(info) + NativeUInt(info.NextEntryOffset));
        end;
      end;
      stat := NtQueryDirectoryFile(handle,0,nil,nil,@status,buffer,BUFFER_SIZE,FileBothDirectoryInformation,False,nil,False);
    end;
    FBufferPool.Add(buffer);
    CloseHandle(handle);
  end;
end;
////////////////////////////////////////////////////////////////////////////////

end.

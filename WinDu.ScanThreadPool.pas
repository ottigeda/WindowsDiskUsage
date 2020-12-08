//WinDu.ScanThreadPool
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

unit WinDu.ScanThreadPool;
interface
uses
  Generics.Collections,
  System.Classes,
  System.SyncObjs,
  System.SysUtils,
  WinDu.DirectoryEntry;

type
////////////////////////////////////////////////////////////////////////////////
  TScanDirectoryThreadPool = class(TObject)
  private
    FWork      : TList<TDirectoryEntry>;
    FWorkMutex : TMutex;
    FWorkSema  : TSemaphore;
    FThreads   : TList<TThread>;
  public
    constructor Create(AInitialWork : TDirectoryEntry);
    destructor Destroy; override;

    procedure AddWork(item : TDirectoryEntry);
    function  GetWork(var working : Boolean) : TDirectoryEntry;
    procedure WaitWork;
    function  Working : Boolean;
    procedure Stop;
  end;
////////////////////////////////////////////////////////////////////////////////

implementation
uses
  WinDu.ScanThread;

{ TScanDirectoryThreadPool }

////////////////////////////////////////////////////////////////////////////////
constructor TScanDirectoryThreadPool.Create(AInitialWork : TDirectoryEntry);
var
  i : Integer;
begin
  FWorkSema    := TSemaphore.Create(nil, 0, High(Integer), '');
  FWorkMutex   := TMutex.Create;
  FWork        := TList<TDirectoryEntry>.Create;
  FThreads     := TList<TThread>.Create;
  AddWork(AInitialWork);
  for i := 0 to 7 do begin
    FThreads.Add(TScanDirectoryThread.Create(Self));
  end;
end;
////////////////////////////////////////////////////////////////////////////////
destructor TScanDirectoryThreadPool.Destroy;
begin
  Stop;
  FreeAndNil(FThreads);
  FreeAndNil(FWork);
  FreeAndNil(FWorkMutex);
  FreeAndNil(FWorkSema);
end;
////////////////////////////////////////////////////////////////////////////////
procedure TScanDirectoryThreadPool.Stop;
var
  thread : TThread;
begin
  for thread in FThreads do begin
    thread.Terminate;
  end;
  for thread in FThreads do begin
    FWorkSema.Release;
  end;
  FThreads.Clear;
end;
////////////////////////////////////////////////////////////////////////////////
procedure TScanDirectoryThreadPool.AddWork(item : TDirectoryEntry);
begin
  FWorkMutex.Acquire;
  FWork.Add(item);
  FWorkMutex.Release;
  FWorkSema.Release;
end;
////////////////////////////////////////////////////////////////////////////////
function TScanDirectoryThreadPool.GetWork(var working : Boolean): TDirectoryEntry;
begin
  FWorkMutex.Acquire;
  Result := nil;
  if FWork.Count > 0 then begin
    Result := FWork[0];
    FWork.Delete(0);
  end;
  working := Assigned(Result);
  FWorkMutex.Release;
end;
////////////////////////////////////////////////////////////////////////////////
procedure TScanDirectoryThreadPool.WaitWork;
begin
  FWorkSema.Acquire;
end;
////////////////////////////////////////////////////////////////////////////////
function TScanDirectoryThreadPool.Working: Boolean;
var
  thread : TThread;
begin
  Result := False;
  for thread in FThreads do begin
    if (thread as TScanDirectoryThread).Working then begin
      Result := True;
    end;
  end;
end;
////////////////////////////////////////////////////////////////////////////////

end.

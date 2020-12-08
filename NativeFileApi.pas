//NativeFileApi
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

unit NativeFileApi;
interface

{$Z4}

uses
  Windows;

type
  NTSTATUS = NativeInt;
  ULONG_PTR = NativeUInt;
  USHORT = Word;
  PWSTR = LPWSTR;
  HANDLE = THandle;
  PVOID = Pointer;
  CCHAR = Char;

  _UNICODE_STRING = Record
    Length: USHORT;
    MaximumLength: USHORT;
    Buffer: PWSTR;
  end;
  PUNICODE_STRING = ^UNICODE_STRING;
  UNICODE_STRING = _UNICODE_STRING;

  _IO_STATUS_BLOCK = Record
    Status: NTSTATUS;
    Information: ULONG_PTR;
  end;

  IO_STATUS_BLOCK = _IO_STATUS_BLOCK;
  PIO_STATUS_BLOCK = ^IO_STATUS_BLOCK;
  TIOStatusBlock = IO_STATUS_BLOCK;
  PIOStatusBlock = PIO_STATUS_BLOCK;
  PIO_APC_ROUTINE = procedure(ApcContext: PVOID;
    IoStatusBlock: PIO_STATUS_BLOCK; Reserved: ULONG); stdcall;

  _FILE_INFORMATION_CLASS = (FileFiller0, FileDirectoryInformation, // 1
    FileFullDirectoryInformation, // 2
    FileBothDirectoryInformation, // 3
    FileBasicInformation, // 4 wdm
    FileStandardInformation, // 5 wdm
    FileInternalInformation, // 6
    FileEaInformation, // 7
    FileAccessInformation, // 8
    FileNameInformation, // 9
    FileRenameInformation, // 10
    FileLinkInformation, // 11
    FileNamesInformation, // 12
    FileDispositionInformation, // 13
    FilePositionInformation, // 14 wdm
    FileFullEaInformation, // 15
    FileModeInformation, // 16
    FileAlignmentInformation, // 17
    FileAllInformation, // 18
    FileAllocationInformation, // 19
    FileEndOfFileInformation, // 20 wdm
    FileAlternateNameInformation, // 21
    FileStreamInformation, // 22
    FilePipeInformation, // 23
    FilePipeLocalInformation, // 24
    FilePipeRemoteInformation, // 25
    FileMailslotQueryInformation, // 26
    FileMailslotSetInformation, // 27
    FileCompressionInformation, // 28
    FileObjectIdInformation, // 29
    FileCompletionInformation, // 30
    FileMoveClusterInformation, // 31
    FileQuotaInformation, // 32
    FileReparsePointInformation, // 33
    FileNetworkOpenInformation, // 34
    FileAttributeTagInformation, // 35
    FileTrackingInformation, // 36
    FileMaximumInformation);
  FILE_INFORMATION_CLASS = _FILE_INFORMATION_CLASS;
  PFILE_INFORMATION_CLASS = ^FILE_INFORMATION_CLASS;

  PFILE_BOTH_DIRECTORY_INFORMATION = ^FILE_BOTH_DIRECTORY_INFORMATION;
  _FILE_BOTH_DIRECTORY_INFORMATION = packed record
    NextEntryOffset: ULONG;
    FileIndex: ULONG;
    CreationTime: LARGE_INTEGER;
    LastAccessTime: LARGE_INTEGER;
    LastWriteTime: LARGE_INTEGER;
    ChangeTime: LARGE_INTEGER;
    EndOfFile: LARGE_INTEGER;
    AllocationSize: LARGE_INTEGER;
    FileAttributes: ULONG;
    FileNameLength: ULONG;
    EaSize: ULONG;
    ShortNameLength: CCHAR;
    ShortName: array [0 .. 11] of WCHAR;
    FileName: array [0 .. 0] of WCHAR;
  end;
  FILE_BOTH_DIRECTORY_INFORMATION = _FILE_BOTH_DIRECTORY_INFORMATION;

function NtQueryDirectoryFile(FileHandle: HANDLE; Event: HANDLE; ApcRoutine: PIO_APC_ROUTINE; ApcContext: PVOID;
  IoStatusBlock: PIO_STATUS_BLOCK; FileInformation: PVOID; FileInformationLength: ULONG; FileInformationClass: FILE_INFORMATION_CLASS;
  ReturnSingleEntry: ByteBool; FileName: PUNICODE_STRING; RestartScan: ByteBool) : NTSTATUS; stdcall;

implementation

function NtQueryDirectoryFile; external 'ntdll.dll' name 'NtQueryDirectoryFile';

end.

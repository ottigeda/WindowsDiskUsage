program WinDu;

uses
  FMX.Forms,
  NativeFileApi in 'NativeFileApi.pas',
  WinDuForm in 'WinDuForm.pas' {FrmWinDu},
  WinDu.ScanThread in 'WinDu.ScanThread.pas',
  WinDu.ScanThreadPool in 'WinDu.ScanThreadPool.pas',
  WinDu.DirectoryEntry in 'WinDu.DirectoryEntry.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFrmWinDu, FrmWinDu);
  Application.Run;
end.

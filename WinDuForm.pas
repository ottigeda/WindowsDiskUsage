//WinDuForm
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

unit WinDuForm;
interface
uses
  FMX.Controls,
  FMX.Controls.Presentation,
  FMX.Dialogs,
  FMX.Edit,
  FMX.Forms,
  FMX.Graphics,
  FMX.Layouts,
  FMX.Memo,
  FMX.Objects,
  FMX.StdCtrls,
  FMX.Types,
  FMX.Platform.Win,
  System.Classes,
  System.Generics.Collections,
  System.Generics.Defaults,
  System.Math,
  System.SysUtils,
  System.UITypes,
  Winapi.ShellApi,
  Winapi.Windows,
  WinDu.DirectoryEntry,
  WinDu.ScanThread,
  WinDu.ScanThreadPool;

type
  TFrmWinDu = class(TForm)
    btnBack: TButton;
    btnScan: TButton;
    btnUp: TButton;
    edtDirectory: TEdit;
    lblStatus: TLabel;
    pnlClient: TPanel;
    pnlScan: TPanel;
    StatusBar1: TStatusBar;
    timShow: TTimer;
    btnOpen: TButton;
    lblDirectory: TLabel;
    procedure btnBackClick(Sender: TObject);
    procedure btnScanClick(Sender: TObject);
    procedure btnUpClick(Sender: TObject);
    procedure pnlClientResize(Sender: TObject);
    procedure timShowTimer(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);
  private
    FRootDir    : TDirectoryEntry;
    FCurrDir    : TDirectoryEntry;
    FShowLineDir: TDirectoryEntry;
    FHistory    : TStack<TDirectoryEntry>;
    FPool       : TScanDirectoryThreadPool;
    FStartTime  : TDateTime;
    FEndTime    : TDateTime;
    procedure PieMouseEnter(Sender: TObject);
    procedure PieMouseLeave(Sender: TObject);
    procedure PieClick(Sender: TObject);
    procedure PieMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure LineClick(Sender: TObject);
    procedure LineMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure CircleClick(Sender: TObject);
    procedure CircleMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure LogDirectory(directory : TDirectoryEntry);
    procedure ShowResults(directory : TDirectoryEntry);
    procedure ShowLines(left : Boolean; dirs : TList<TDirectoryEntry>);
    function  HSVtoColor(H, S, V: Double): TAlphaColor;

  public
    constructor Create(AOnwer : TCOmponent); override;
    destructor Destroy; override;
  end;
////////////////////////////////////////////////////////////////////////////////
  TSinusComparer = class (TComparer<TDirectoryEntry>)
  public
    function Compare(const Left, Right: TDirectoryEntry): Integer; override;
  end;
////////////////////////////////////////////////////////////////////////////////
var
  FrmWinDu: TFrmWinDu;

implementation

{$R *.fmx}

const
  D = 100;

{ TWinRingChart }

////////////////////////////////////////////////////////////////////////////////
procedure TFrmWinDu.CircleClick(Sender: TObject);
var
  directory : TDirectoryEntry;
begin
  FHistory.Push(FCurrDir);
  directory := TDirectoryEntry((Sender as TCircle).Tag);
  if directory.SubDirs.Count > 0 then begin
    ShowResults(directory);
  end;
  btnBack.Enabled := True;
  btnUp.Enabled := Assigned(FCurrDir.ParentDir);
end;

procedure TFrmWinDu.CircleMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  entry : TDirectoryEntry;
begin
  if Sender is TCircle then begin
    entry := TDirectoryEntry((Sender as TCircle).Tag);
    if Button = TMouseButton.mbRight then begin
      ShellExecute(FmxHandleToHWND(Self.Handle),PChar('explore'),PChar(entry.Path),nil,nil,SW_SHOWNORMAL);
    end;
  end;
end;

constructor TFrmWinDu.Create(AOnwer: TCOmponent);
begin
  inherited;
  FHistory := TStack<TDirectoryEntry>.Create;
  FCurrDir := nil;
  FShowLineDir := nil;
end;
////////////////////////////////////////////////////////////////////////////////
destructor TFrmWinDu.Destroy;
begin
  FCurrDir := nil;
  FreeAndNil(FRootDir);
  FreeAndNil(FPool);
  FreeAndNil(FHistory);
  inherited;
end;
////////////////////////////////////////////////////////////////////////////////
procedure TFrmWinDu.btnOpenClick(Sender: TObject);
var
  dir : string;
begin
  dir := edtDirectory.Text;
  if SelectDirectory('','',dir) then begin
    edtDirectory.Text := dir;
  end;
end;
////////////////////////////////////////////////////////////////////////////////
procedure TFrmWinDu.btnScanClick(Sender: TObject);
begin
  btnScan.Enabled := False;
  timShow.Enabled := True;
  FreeAndNil(FRootDir);
  FRootDir := TDirectoryEntry.Create(IncludeTrailingPathDelimiter(edtDirectory.Text));
  FCurrDir := FRootDir;
  FStartTime := Now;
  FPool := TScanDirectoryThreadPool.Create(FRootDir);
  while FPool.Working do begin
    Application.ProcessMessages;
    Sleep(100);
  end;
  FPool.Stop;
  FEndTime := Now;
  btnScan.Enabled := True;
  timShow.Enabled := False;
  lblStatus.Text := Format('Total: %d files %d folders %s  Time: %3.1f seconds', [FRootDir.TotalFiles, FRootDir.TotalFolders-1, FRootDir.TotalSizeText, (FEndTime-FStartTime) * SecsPerDay]);
  ShowResults(FRootDir);
end;
////////////////////////////////////////////////////////////////////////////////
procedure TFrmWinDu.timShowTimer(Sender: TObject);
begin
  timShow.Enabled := False;
  FEndTime := Now;
  lblStatus.Text := Format('Total: %d files %d folders %s  Time: %3.1f seconds', [FRootDir.TotalFiles, FRootDir.TotalFolders-1, FRootDir.TotalSizeText, (FEndTime-FStartTime) * SecsPerDay]);
  timShow.Enabled := True;
end;
////////////////////////////////////////////////////////////////////////////////
procedure TFrmWinDu.LineClick(Sender: TObject);
var
  directory : TDirectoryEntry;
begin
  FHistory.Push(FCurrDir);
  directory := TDirectoryEntry((Sender as TLine).Tag);
  if directory.SubDirs.Count > 0 then begin
    ShowResults(directory);
  end;
  btnBack.Enabled := True;
  btnUp.Enabled := Assigned(FCurrDir.ParentDir);
end;

procedure TFrmWinDu.LineMouseDown(Sender: TObject; Button: TMouseButton;  Shift: TShiftState; X, Y: Single);
var
  entry : TDirectoryEntry;
begin
  if Sender is TLine then begin
    entry := TDirectoryEntry((Sender as TLine).Tag);
    if Button = TMouseButton.mbRight then begin
      ShellExecute(FmxHandleToHWND(Self.Handle),PChar('explore'),PChar(entry.Path),nil,nil,SW_SHOWNORMAL);
    end;
  end;
end;

procedure TFrmWinDu.LogDirectory(directory : TDirectoryEntry);
var
  item : TDirectoryEntry;
  spaces : string;
begin
  spaces := StringOfChar(' ', 80 - Length(directory.Path));
  for item in directory.SubDirs do begin
    LogDirectory(item);
  end;
end;
////////////////////////////////////////////////////////////////////////////////
procedure TFrmWinDu.btnBackClick(Sender: TObject);
var
  entry : TDirectoryEntry;
begin
  entry := FHistory.Pop;
  ShowResults(entry);
  btnBack.Enabled := FHistory.Count > 0;
  btnUp.Enabled := Assigned(FCurrDir.ParentDir);
end;
////////////////////////////////////////////////////////////////////////////////
procedure TFrmWinDu.btnUpClick(Sender: TObject);
begin
  FHistory.Push(FCurrDir);
  ShowResults(FCurrDir.ParentDir);
  btnUp.Enabled := Assigned(FCurrDir.ParentDir);
end;
////////////////////////////////////////////////////////////////////////////////
procedure TFrmWinDu.PieClick(Sender: TObject);
var
  directory : TDirectoryEntry;
begin
  FHistory.Push(FCurrDir);
  directory := TDirectoryEntry((Sender as TPie).Tag);
  if directory.SubDirs.Count > 0 then begin
    ShowResults(directory);
  end;
  btnBack.Enabled := True;
  btnUp.Enabled := Assigned(FCurrDir.ParentDir);
end;
////////////////////////////////////////////////////////////////////////////////
procedure TFrmWinDu.PieMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  entry : TDirectoryEntry;
begin
  if Sender is TPie then begin
    entry := TDirectoryEntry((Sender as TPie).Tag);
    if Button = TMouseButton.mbRight then begin
      ShellExecute(FmxHandleToHWND(Self.Handle),PChar('explore'),PChar(entry.Path),nil,nil,SW_SHOWNORMAL);
    end;
  end;
end;

procedure TFrmWinDu.PieMouseEnter(Sender: TObject);
var
  entry     : TDirectoryEntry;
  dirsleft  : TList<TDirectoryEntry>;
  dirsright : TList<TDirectoryEntry>;
const
  MIN_ANGLE = 5;

  procedure CollectSameLevel(dir : TDirectoryEntry);
  var
    subdir : TDirectoryEntry;
  begin
    if dir.Level = entry.Level - 1 then begin
      for subdir in dir.SubDirs do begin
        if subdir.IsLeft and (subdir.Angle >= MIN_ANGLE) then begin
          dirsleft.Add(subdir);
        end
        else if subdir.IsRight and (subdir.Angle >= MIN_ANGLE) then begin
          dirsright.Add(subdir);
        end;
      end;
    end
    else if dir.Level < entry.Level then begin
      for subdir in dir.SubDirs do begin
        CollectSameLevel(subdir);
      end;
    end;
  end;
begin
  entry := TDirectoryEntry((Sender as TPie).Tag);
  if entry <> FShowLineDir then begin
    FCurrDir.LineControls.Clear;
    FShowLineDir := entry;
    lblDirectory.Text := entry.Path + '  (' + entry.TotalSizeText + ')';
    dirsleft := TList<TDirectoryEntry>.Create;
    dirsright := TList<TDirectoryEntry>.Create;;
    CollectSameLevel(FCurrDir);
    ShowLines(True, dirsleft);
    ShowLines(False, dirsright);
    FreeAndNil(dirsleft);
    FreeAndNil(dirsright);
  end;
end;
////////////////////////////////////////////////////////////////////////////////
procedure TFrmWinDu.ShowLines(left: Boolean; dirs: TList<TDirectoryEntry>);
var
  dir        : TDirectoryEntry;
  angle      : Extended;
  lineangle  : Extended;
  line       : TLine;
  circle     : TCircle;
  lblName    : TLabel;
  level      : Integer;
  r          : Extended;
  x          : Extended;
  y          : Extended;
  w          : Extended;
  delta      : Extended;
  textY      : Extended;
  textWidth  : Extended;
  textHeight : Extended;
begin
  delta := Nan;
  y := 0;
  textWidth := 0;
  textHeight := 0;
  dirs.Sort(TSinusComparer.Create);
  for dir in dirs do begin
    lblName := TLabel.Create(Self);
    lblName.Font.Size := 14;
    lblName.Font.Style := lblName.Font.Style + [TFontStyle.fsBold];
    lblName.Parent := pnlClient;
    lblName.TextSettings.VertAlign := TTextAlign.Leading;
    lblName.WordWrap := True;
    lblName.Text := dir.Directory + sLineBreak + dir.TotalSizeText;
    if IsNan(delta) then begin
      textHeight := lblName.Height;
      delta      := (pnlClient.Height - dirs.Count*textHeight) / (dirs.Count + 1);
      y          := delta;
    end;
    if lblName.Width > textWidth then begin
      textWidth := lblName.Width;
    end;
    if left then begin
      lblName.TextAlign := TTextAlign.Trailing;
      lblName.SetBounds(0, y, lblName.Width, delta);
    end
    else begin
      lblName.TextAlign := TTextAlign.Leading;
      lblName.SetBounds(pnlClient.Width - textWidth , y, lblName.Width, delta);
    end;
    y := y + textHeight + delta;
    FCurrDir.LineControls.Add(lblName);
  end;

  textY := delta + textHeight / 2;
  for dir in dirs do begin
    angle := (dir.Pie.StartAngle + dir.Pie.EndAngle) / 2;
    level := dir.level - FCurrDir.level;
    r := D * (2*level + 1) / 4;
    x := pnlClient.Width/2 + Cos(angle/180*Pi)*r;
    y := pnlClient.Height/2 + Sin(angle/180*Pi)*r;
    if left then begin
      w := 0 - x + textWidth + 10 ;
    end
    else begin
      w := pnlClient.Width - x - textWidth - 10;
    end;
    lineangle := ArcTan2(textY-y,w)*180/Pi;
    line := TLine.Create(Self);
    line.HitTest := False;
    line.Parent := pnlClient;
    line.LineType := TLineType.Top;
    line.Position.X := x;
    line.Position.Y := y;
    line.Width := Abs(w/Cos(lineangle/180*Pi));
    line.RotationCenter.X := 0;
    line.RotationCenter.Y := 0;
    line.RotationAngle := lineangle;
    line.Stroke.Thickness := 1;
    line.Tag := NativeInt(dir);
    line.OnClick := LineClick;
    line.OnMouseDown := LineMouseDown;
    textY := textY + textHeight + delta;
    FCurrDir.LineControls.Add(line);

    circle := TCircle.Create(Self);
    circle.Parent := pnlClient;
    circle.SetBounds(x-5,y-5,10,10);
    circle.Fill.Kind := TBrushKind.None;
    circle.Tag := NativeInt(dir);
    circle.OnClick := CircleClick;
    circle.OnMouseDown := CircleMouseDown;
    FCurrDir.LineControls.Add(circle);
  end;
end;
////////////////////////////////////////////////////////////////////////////////
procedure TFrmWinDu.PieMouseLeave(Sender: TObject);
begin
//  FCurrDir.LineControls.Clear;
end;
////////////////////////////////////////////////////////////////////////////////
procedure TFrmWinDu.pnlClientResize(Sender: TObject);
begin
  if btnScan.Enabled and Assigned(FCurrDir) then begin
    ShowResults(FCurrDir);
  end;
end;
////////////////////////////////////////////////////////////////////////////////
function TFrmWinDu.HSVtoColor(H,S,V: Double): TAlphaColor;
var
  r,g,b: Double;
  i: integer;
  f: Double;
  p,q,t: Double;
  col : TAlphaColorRec;
begin
  while h > 360 do begin
    h := h - 360;
  end;
  if S = 0 then begin
    r := V;
    b := V;
    g := V;
  end
  else begin
    if H = 360 then begin
      H := 0;
    end;
    H := H/60;
    i := TRUNC(H);
    f := FRAC(H);
    p := V * (1.0 - S);
    q := V * (1.0 - (S * f));
    t := V * (1.0 - (S * (1.0 - f)));
    r := 0;
    g := 0;
    b := 0;
    case i of
      0: begin r := v; g := t; b := p  end;
      1: begin r := q; g := v; b := p  end;
      2: begin r := p; g := v; b := t  end;
      3: begin r := p; g := q; b := v  end;
      4: begin r := t; g := p; b := v  end;
      5: begin r := v; g := p; b := q  end
    end
  end;
  col.A  := $FF;
  col.R  := Trunc(r*255);
  col.G  := Trunc(g*255);
  col.B  := Trunc(b*255);
  Result := col.Color;
end;
////////////////////////////////////////////////////////////////////////////////
procedure TFrmWinDu.ShowResults(directory : TDirectoryEntry);
var
  centerX : Single;
  centerY : Single;
  circle  : TCircle;
  lblSize : TLabel;

  procedure ClearEntry(entry: TDirectoryEntry);
  var
    subdir : TDirectoryEntry;
  begin
    if Assigned(entry.Pie) then begin
      entry.Pie.Free;
      entry.Pie := nil;
    end;
    entry.OtherControls.Clear;
    entry.LineControls.Clear;
    for subdir in entry.SubDirs do begin
      ClearEntry(subdir);
    end;
  end;

  procedure ShowEntry(entry: TDirectoryEntry; dirsize : Int64; start : Single; range : Single);
  var
    subdir : TDirectoryEntry;
    level  : Integer;
    angle  : Single;
  begin
    level := entry.Level - FCurrDir.Level + 2;
    if (level * D < pnlClient.Width) and (level * D < pnlClient.Height) then begin
      for subdir in entry.SubDirs do begin
        angle := (range / dirsize * subdir.TotalSize);
        if angle > 1 then begin
          subdir.pie := TPie.Create(Self);
          subdir.pie.Parent := pnlClient;
          subdir.pie.SetBounds(centerX - D * level / 2, centerY -  D * level / 2, D * level, D * level);
          subdir.pie.StartAngle := start;
          subdir.pie.EndAngle := start + angle;
          subdir.pie.SendToBack;
          if subdir.SubDirs.Count > 0 then begin
            subdir.Pie.Fill.Color := HSVtoColor(start+angle/2, 1 - level/10, 1);
          end
          else begin
            subdir.Pie.Fill.Color := HSVtoColor(0, 0, 0.9);
          end;
          subdir.Pie.OnMouseEnter := PieMouseEnter;
          subdir.Pie.OnMouseDown  := PieMouseDown;
          subdir.Pie.OnMouseLeave := PieMouseLeave;
          subdir.Pie.OnClick := PieClick;
          subdir.Pie.Tag := NativeInt(subdir);
        end;
        start := start + angle;
      end;
      for subdir in entry.SubDirs do begin
        if Assigned(subdir.Pie) then begin
          ShowEntry(subdir, subdir.TotalSize, subdir.pie.StartAngle, subdir.Pie.EndAngle - subdir.pie.StartAngle);
        end;
      end;
    end;
  end;
begin
  centerX := pnlClient.Width / 2;
  centerY := pnlClient.Height / 2;
  ClearEntry(FCurrDir);
  FCurrDir := directory;

  circle := TCircle.Create(Self);
  circle.Parent := pnlClient;
  circle.SetBounds(centerX - (D / 2), centerY - (D / 2), D, D);
  circle.Fill.Color := TAlphaColorRec.White;
  FCurrDir.OtherControls.Add(circle);

  lblSize := TLabel.Create(Self);
  lblSize.Parent := pnlClient;
  lblSize.SetBounds(centerX - (D / 2), centerY - (D / 2), D, D);
  lblSize.TextAlign := TTextAlign.Center;
  lblSize.VertTextAlign := TTextAlign.Center;
  lblSize.Font.Style := lblSize.Font.Style + [TFontStyle.fsBold];
  lblSize.Font.Size := D / 5;
  lblSize.Text := FCurrDir.TotalSizeText;
  FCurrDir.OtherControls.Add(lblSize);
  ShowEntry(FCurrDir,FCurrDir.TotalSize,0,360);
end;
////////////////////////////////////////////////////////////////////////////////

{ TSinusComparer }

////////////////////////////////////////////////////////////////////////////////
function TSinusComparer.Compare(const Left, Right: TDirectoryEntry): Integer;
var
  angle1 : Extended;
  angle2 : Extended;
begin
  angle1 := 0;
  angle2 := 0;
  if Assigned(left.Pie) then begin
    angle1 := (left.Pie.StartAngle + left.Pie.EndAngle) / 360 * Pi;
  end;
  if Assigned(right.Pie) then begin
    angle2 := (right.Pie.StartAngle + right.Pie.EndAngle) / 360 * Pi;
  end;
  Result := Round(Sin(angle1)*1000 - Sin(angle2)*1000);
end;
////////////////////////////////////////////////////////////////////////////////

end.

unit M2MUnit1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Edit, FMX.Controls.Presentation, System.ImageList, FMX.ImgList,
  IniFiles, FMX.EditBox, FMX.NumberBox, FMX.ListBox, FMX.Layouts, FMX.ScrollBox,
  FMX.Memo, FMX.Surfaces, FMX.Consts, RegularExpressions,
  RegularExpressionsCore,

{$IFDEF MSWINDOWS}
Winapi.ShellAPI, Winapi.Windows, FMX.Objects;
{$ENDIF MSWINDOWS}
{$IFDEF MACOS}
Posix.Stdlib, FMX.Objects;
{$ENDIF MACOS}

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Label1: TLabel;
    edtMarkdown: TEdit;
    btnOpenFile: TSpeedButton;
    ImageList1: TImageList;
    OpenDialog1: TOpenDialog;
    Label2: TLabel;
    edtTitle: TEdit;
    Label3: TLabel;
    edtAuthor: TEdit;
    btnReadFile: TButton;
    btnEditBook: TSpeedButton;
    Label4: TLabel;
    edtCounter: TNumberBox;
    Label5: TLabel;
    lstCompress: TListBox;
    ListBoxItem1: TListBoxItem;
    lstCompressOption: TListBoxItem;
    ListBoxItem3: TListBoxItem;
    chkVerbose: TCheckBox;
    MemoStatus: TMemo;
    btnGenFiles: TButton;
    btnGenMobi: TButton;
    txtMsg: TLabel;
    GroupBox1: TGroupBox;
    btnBookHTML: TButton;
    btnBookOPF: TButton;
    btnTOCHTML: TButton;
    btnTOCNCX: TButton;
    btnBookBat: TButton;
    btnPreview: TButton;
    Image1: TImage;
    Button1: TButton;
    txtCount: TLabel;
    chkMarkdown: TCheckBox;
    btnEditMarkdown: TSpeedButton;
    btnSettings: TSpeedButton;
    chkLeadingSpaces: TCheckBox;
    chkVertical: TCheckBox;
    txtLink: TLabel;
    procedure btnOpenFileClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnReadFileClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    //----
    function getNavPoint(iPlayOrder: Integer; sHeader: String; sSpaces: String): String;
    function getTOC(iPlayOrder: Integer; sHeader: String; sSpaces: String): String;
    function getTOCHtml: String;
    function getNCXText: String;
    procedure generateHTML;
    procedure generateCover;
    procedure btnGenMobiClick(Sender: TObject);
    procedure btnBookHTMLClick(Sender: TObject);
    procedure btnBookOPFClick(Sender: TObject);
    procedure btnTOCHTMLClick(Sender: TObject);
    procedure btnTOCNCXClick(Sender: TObject);
    procedure btnBookBatClick(Sender: TObject);
    procedure btnPreviewClick(Sender: TObject);
    procedure btnGenFilesClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    function markdown(sText: String; lstExpr: TStringList): String;
    function symbolReplace(sText: String; lstSymbol: TStringList): String;
    procedure Timer1Timer(Sender: TObject);
    procedure btnEditBookClick(Sender: TObject);
    procedure btnEditMarkdownClick(Sender: TObject);
    procedure btnSettingsClick(Sender: TObject);
    procedure chkMarkdownChange(Sender: TObject);
    procedure txtLinkClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

const
  _DEBUG_: Boolean = false;
  _VERSION_: String = 'v0.03';

var
  Form1: TForm1;
  sFilename_, sAppDir_, sTitle_, sAuthor_, sUserName_: String;
  sToday_, sOutputBaseName_, sMobiFolder_, sMobiFilename_: String;
  sMailServer_, sTextFolder_, sCompress_: String;
  isVerbose_: Boolean;
  iLevel2MaxCount_: Integer;
  oIniFile_: TMemIniFile;
  oLevelList1_, oLevelList2_, oLevelList3_: TStringList;
  lstContent_: TStringList;
implementation

{$R *.fmx}

function OccurrencesOfChar(const S: string; const C: char): integer;
var
  i: Integer;
begin
  result := 0;
  for i := 1 to Length(S) do
    if S[i] = C then
      inc(result)
    else
      break;
end;

procedure open(sFilePath: String);
var
  _sEditor, _sExt: String;
begin
{$IFDEF MSWINDOWS}
  _sExt := UpperCase(ExtractFileExt(sFilePath));
  if _sExt = '.MOBI' then begin
    _sEditor := oIniFile_.ReadString('EDITOR_WIN', 'MOBI', 'C:\Program Files\kindle previewer 3\Kindle previewer 3.exe');
    if not FileExists(_sEditor) then begin
      ShowMessage('.MOBI預設程式不存在，請搜尋kindle previewer後安裝');
    end;
  end else if _sExt = '.HTML' then begin
    _sEditor := oIniFile_.ReadString('EDITOR_WIN', 'HTML', 'notepad');
  end else begin
    _sEditor := oIniFile_.ReadString('EDITOR_WIN', 'TEXT', 'notepad');
  end;

  ShellExecute(0, PChar('open'), PChar(_sEditor), PChar(sFilePath), nil, SW_SHOW);
{$ENDIF MSWINDOWS}

{$IFDEF MACOS}
  _system(PAnsiChar('open ' + '"' + AnsiString(sFilePath) + '"'));
{$ENDIF MACOS}
end;

procedure TForm1.btnBookBatClick(Sender: TObject);
var
  _sFilePath: String;
begin
{$IFDEF MSWINDOWS}
  _sFilePath := sAppDir_+'mybook.bat';
{$ENDIF MSWINDOWS}

{$IFDEF MACOS}
  _sFilePath := sAppDir_+'mybook.sh';
{$ENDIF MACOS}

  open(_sFilePath);
end;

procedure TForm1.btnBookHTMLClick(Sender: TObject);
begin
  open(sAppDir_ + 'mybook.html');
end;

procedure TForm1.btnBookOPFClick(Sender: TObject);
var
  _sEditor, _sFilePath: String;
begin
  _sFilePath := sAppDir_+sOutputBaseName_+'.opf';
  open(_sFilePath);
end;

procedure TForm1.btnEditBookClick(Sender: TObject);
var
  _sEditor, _sFilePath: String;
begin
  _sFilePath := edtMarkdown.Text;
  open(_sFilePath);
end;

procedure TForm1.btnEditMarkdownClick(Sender: TObject);
var
  _sEditor, _sMarkdownFilename, _sFilePath: String;
begin
  _sMarkdownFilename := ChangeFileExt(edtMarkdown.Text, '.markdown');
  if FileExists(_sMarkdownFilename) then begin
    _sEditor := oIniFile_.ReadString('EDITOR', 'HTML', 'notepad');
    _sFilePath := _sMarkdownFilename;

{$IFDEF MSWINDOWS}
    ShellExecute(0, PChar('open'), PChar(_sEditor), PChar(_sFilePath), nil, SW_SHOW);
{$ENDIF MSWINDOWS}

{$IFDEF MACOS}
    _sFilePath := _sFilePath;
    _system(PAnsiChar('open ' + '"' + _sFilePath + '"'));
{$ENDIF MACOS}
  end else begin
    ShowMessage(_sMarkdownFilename + ' 不存在。');
  end;
end;

procedure TForm1.btnGenFilesClick(Sender: TObject);
var
  _sText, _sNavPoint, _sLine, _sOptions, _sTOC, _sVerbose: String;
  _sFilePath, _sExt, _sKindleGen: String;
  _iPos1, _iPos2: Integer;
  _lstText: TStringList;
begin
  if (lstContent_.Count = 0) then begin
    ShowMessage('請先讀檔。');
    exit;
  end;
  if (edtTitle.Text = '') then begin
    ShowMessage('書名必須指定。');
    exit;
  end else begin
    sTitle_ := Trim(edtTitle.Text);
  end;
  if (edtAuthor.Text = '') then begin
    edtAuthor.Text := '(未知)';
    sAuthor_ := '(未知)';
  end else begin
    sAuthor_ := Trim(edtAuthor.Text);
  end;
  iLevel2MaxCount_ := StrToInt(edtCounter.Text);
  MemoStatus.Lines.Add('2.產生設定檔案----------');

  _lstText := TStringList.Create;
  _lstText.LoadFromFile(sAppDir_ + 'template.opf', TEncoding.UTF8);
  _sText := _lstText.Text;
  _sText := StringReplace(_sText, '%TITLE%', sTitle_, [rfReplaceAll]);
  _sText := StringReplace(_sText, '%AUTHOR%', sAuthor_, [rfReplaceAll]);
  _sText := StringReplace(_sText, '%USERNAME%', sUserName_, [rfReplaceAll]);
  _sText := StringReplace(_sText, '%DATE%', sToday_, [rfReplaceAll]);
  _lstText.Text := _sText;
  _lstText.SaveToFile(sAppdir_ + sOutputBaseName_ + '.opf', TEncoding.UTF8);
  _lstText.Add('  寫出 ' + sAppdir_ + sOutputBaseName_ + '.opf');

  generateHTML();  // Generating mybook.html
  _sTOC := getTOCHtml();  // Generating 目錄 toc.html

  _lstText.Clear;
  _lstText.LoadFromFile(sAppDir_ + 'template.toc.html', TEncoding.UTF8);
  _sText := _lstText.Text;
  _sText := StringReplace(_sText, '%TITLE%', '目錄', [rfReplaceAll]);
  if chkVertical.IsChecked then begin
    _sText := StringReplace(_sText, '%CSS%', 'style_vertical.css', [rfReplaceAll]);
  end else begin
    _sText := StringReplace(_sText, '%CSS%', 'style.css', [rfReplaceAll]);
  end;
  _sText := StringReplace(_sText, '%TOC_HTML%', _sTOC, [rfReplaceAll]);
  _lstText.Text := _sText;
  _lstText.SaveToFile(sAppdir_ + 'toc.html', TEncoding.UTF8);
  MemoStatus.Lines.Add('  寫出 ' + sAppdir_ + 'toc.html');

  _sNavPoint := getNCXText();

  _lstText.Clear;
  _lstText.LoadFromFile(sAppDir_ + 'template.ncx', TEncoding.UTF8);
  _sText := _lstText.Text;
  _sText := StringReplace(_sText, '%TITLE%', sTitle_, [rfReplaceAll]);
  _sText := StringReplace(_sText, '%AUTHOR%', sAuthor_, [rfReplaceAll]);
  _sText := StringReplace(_sText, '%NAVPOINT%', _sNavPoint, [rfReplaceAll]);
  _lstText.Text := _sText;
  _lstText.SaveToFile(sAppdir_ + 'toc.ncx', TEncoding.UTF8);
  _lstText.Add('  寫出 ' + sAppdir_ + 'toc.ncx');

  sCompress_ := Copy(lstCompress.Items[lstCompress.ItemIndex], 1, 3);

  isVerbose_ := chkVerbose.isChecked;
  _sVerbose := '';
  if (isVerbose_) then _sVerbose := '-verbose';

  _sOptions := sCompress_ + ' ' + _sVerbose;
  //oIniFile_.WriteString('SETTINGS', 'OPTIONS', _sOptions);
  sMobiFolder_ := oIniFile_.ReadString('SETTINGS','MOBI_FOLDER', sAppDir_);
  if (Copy(sMobiFolder_, Length(sMobiFolder_), 1) <> '\') and
     (Copy(sMobiFolder_, Length(sMobiFolder_), 1) <> '/') then begin
    sMobiFolder_ := sMobiFolder_ + '\';
  end;

{$IFDEF MSWINDOWS}
  _sKindleGen := oIniFile_.ReadString('SETTINGS','KINDLEGEN', sAppDir_ + 'kindlegen.exe');
  _sFilePath := sAppDir_ + 'template.bat';
  _sExt := '.bat';

  _lstText.Clear;
  _lstText.LoadFromFile(_sFilePath, TEncoding.UTF8);
  _sText := _lstText.Text;
  _sText := StringReplace(_sText, '%KINDLEGEN%', _sKindleGen, [rfReplaceAll]);
  _sText := StringReplace(_sText, '%OPF_FILENAME%', sOutputBaseName_ + '.opf', [rfReplaceAll]);
  sMobiFileName_ := sTitle_+'_'+sAuthor_;
  _sText := StringReplace(_sText, '%MOBI_FOLDER%', sMobiFolder_, [rfReplaceAll]);
  _sText := StringReplace(_sText, '%MOBI_FILENAME%', sMobiFileName_, [rfReplaceAll]);
  _sText := StringReplace(_sText, '%OPTIONS%', _sOptions, [rfReplaceAll]);
  _lstText.Text := _sText;
  _lstText.SaveToFile(sAppDir_ + sOutputBaseName_ + '.bat', TEncoding.UTF8);
  MemoStatus.Lines.Add('  寫出 ' + sAppDir_ + sOutputBaseName_ + _sExt);
{$ENDIF MSWINDOWS}

  generateCover;
  MemoStatus.Lines.Add('  寫出 ' + sAppDir_ + 'mybook.jpg');

  MemoStatus.Lines.Add('  設定檔產生完畢：'+sOutputBaseName_+'.html, '+
    sOutputBaseName_+'.opf, toc.html, toc.ncx, mybook.jpg');
  MemoStatus.Lines.Add('------------------------------');
  MemoStatus.Lines.Add('請按〔產生Mobi檔〕或執行 ' + sOutputBaseName_ + _sExt + ' 以產生新的Mobi電子書檔案。');
  MemoStatus.Lines.Add('------------------------------');

  DeleteFile(PWideChar(sMobiFolder_ + sOutputBaseName_ + '.mobi'));
  btnGenMobi.Visible := true;
  btnGenMobi.SetFocus;
  //btnGenMobi.Font..Color:=clRed;

  GroupBox1.Visible := true;
  btnPreview.Visible := false;
  btnGenMOBI.SetFocus;
end;

procedure TForm1.btnGenMobiClick(Sender: TObject);
var
  _sFilePath, _sCompressLevel, _sCommand, _sKindleGen, _sVerbose: String;
  _lstShell: TStringList;
begin
  if (lstContent_.Text = '') then begin
    ShowMessage('請先讀檔。');
    exit;
  end;

  // Call mybook.bat to execute kindlegen.bat for generating mybook.mobi
{$IFDEF MSWINDOWS}
  _sFilePath := sAppDir_+ sOutputBaseName_+'.bat';
  ShellExecute(0, PChar('open'), PChar(_sFilePath), nil, nil, SW_SHOW);
  MemoStatus.Lines.Add('  電子書 ' + sOutputBasename_ + '.mobi 將產生於m2m.exe所在資料夾');
{$ENDIF MSWINDOWS}

{$IFDEF MACOS}
  _sVerbose := '';
  if (isVerbose_) then _sVerbose := '-verbose';

  _sKindleGen := oIniFile_.ReadString('SETTINGS','KINDLEGEN', sAppDir_ + 'kindlegen');
  _sCompressLevel := Copy(lstCompressOption.Text, 1, 3);  // -c1, -c2
  _sFilePath := _sKindleGen + ' ' + sAppDir_ + 'mybook.opf ' + _sCompressLevel +
    ' -dont_append_source ' + _sVerbose;
  _sCommand := 'open ' + AnsiString(_sFilePath);
  //ShowMessage(_sCommand);
  _system(PAnsiChar(_sCommand));
  MemoStatus.Lines.Add('  執行命令以產生電子書: ' + Copy(_sCommand, 6, 255));
  MemoStatus.Lines.Add('  電子書 ' + sOutputBasename_ + '.mobi 將產生於m2m.app所在資料夾');
{$ENDIF MACOS}

  MemoStatus.Lines.Add('  並複製為 ' + sMobiFolder_ + sTitle_+'_'+sAuthor_ + '.mobi');
  btnPreview.Visible := true;
  //ShowMessage('電子書 ' + sOutputBasename_ + '.mobi 將產生於資料夾 ' + sMobiFolder_ + ' 裡。');
end;

procedure TForm1.btnPreviewClick(Sender: TObject);
begin
  open(sMobiFolder_ + sTitle_+'_'+sAuthor_ + '.mobi');
end;

procedure TForm1.btnReadFileClick(Sender: TObject);
var
  i, _iPos, _iPos2: Integer;
  _sFilename, _sDatetime: String;
  _sLine, _sReplacedLine, _sMarkdownFilename: String;
  today : TDateTime;
  re : TRegEx;
  _hasHashMark: Boolean;
  _lstExpr, _lstSymbol: TStringList;
begin
  sAuthor_ := '';
  sTitle_ := '';
  btnGenFiles.Visible := false;
  btnGenMobi.Visible := false;
  GroupBox1.Visible := false;
  //btnSendMail.Visible := false;

  sFilename_ := edtMarkdown.Text;
  _sFilename := ExtractFileName(sFilename_);
  MemoStatus.Lines.clear;
  MemoStatus.Lines.Add('==============================');
  MemoStatus.Lines.Add('1.讀檔');
  MemoStatus.Lines.Add('  開始讀取 ' + edtMarkdown.Text + ' 的內容...');
  oIniFile_.WriteString('RECENT_FILES', '1', edtMarkdown.Text);

  // 由檔名取出書名和作者
  _iPos := Pos('作者：', _sFilename);
  if _iPos > 0 then begin
    sTitle_ := Copy(_sFilename, 1, _iPos-1);
    _iPos2 := AnsiPos('.', _sFilename);
    sAuthor_ := Copy(_sFilename, _iPos+6, _iPos2-_iPos-6);
    //ShowMessage('TITLE=' + sTitle_ + ', Author=' + sAuthor_);
    edtTitle.Text := sTitle_;
    edtAuthor.Text := sAuthor_;
  end;
  if (sTitle_ = '') then begin
    _iPos := Pos('作者', _sFilename);
    if _iPos > 0 then begin
      sTitle_ := Copy(_sFilename, 1, _iPos-1);
      _iPos2 := Pos('.', _sFilename);
      sAuthor_ := Copy(_sFilename, _iPos+4, _iPos2-_iPos-4);
      edtTitle.Text := sTitle_;
      edtAuthor.Text := sAuthor_;
    end;
  end;

  //memo1.Lines.LoadFromFile(UTF8ToAnsi(sFilename_));
  txtMsg.Visible := true;
  today := now;
  //memo1.Lines.LoadFromFile(sFilename_, TEncoding.UTF8);
  lstContent_.Clear;
  lstContent_.LoadFromFile(sFilename_, TEncoding.UTF8);
  today := now;
  //Memo1.Lines.EndUpdate;
  //Memo1.Lines.Text := lst.Text;
  txtMsg.Visible := false;
  if (sTitle_ = '') then begin
    for i := 0 to 10 do begin
      _sLine := lstContent_.Strings[i];  //.Lines.Strings[i];
      _iPos := Pos('書名：', _sLine);
      if (_iPos > 0) then begin
        sTitle_ := Copy(_sLine, _iPos+3, 100);
        break;
      end;
    end;
  end;

  if (sAuthor_ = '') then begin
    for i := 0 to 10 do begin
      _sLine := lstContent_.Strings[i];
      _iPos := Pos('作者：', _sLine);
      if (_iPos > 0) then begin
        sAuthor_ := Copy(_sLine, _iPos+3, 100);
        break;
      end;
    end;
  end;
  if sAuthor_ = '' then begin
    sAuthor_ := lstContent_.Strings[1];
    if sAuthor_ = '' then sAuthor_ := '(未知)';

    sAuthor_ := StringReplace(sAuthor_, ':', '：', [rfReplaceAll]);
    sAuthor_ := StringReplace(sAuthor_, ' ', '_', [rfReplaceAll]);
  end;
  edtAuthor.Text := sAuthor_;

  if sTitle_ = '' then begin
    sTitle_ := lstContent_.Strings[0];
    sTitle_ := StringReplace(sTitle_, ':', '：', [rfReplaceAll]);
    sTitle_ := StringReplace(sTitle_, ' ', '_', [rfReplaceAll]);
  end;
  edtTitle.Text := sTitle_;

  _lstExpr := TStringList.Create;
  _lstSymbol := TStringList.Create;
  _sDatetime := DateTimeToStr(now);
  if chkMarkdown.isChecked then begin
    txtCount.Visible := true;
    txtCount.Text := '轉換Markdown格式中，請稍候...';
    memoStatus.Lines.Add('  開始轉換成Markdown格式... ' + _sDatetime);
    oIniFile_.ReadSectionValues('RegularExpressions', _lstExpr);
    if chkVertical.IsChecked then begin
      oIniFile_.ReadSectionValues('SymbolReplace_Vertical', _lstSymbol);
    end else begin
      oIniFile_.ReadSectionValues('SymbolReplace_Horizental', _lstSymbol);
    end;
  end;
  btnReadFile.Enabled := false;

  _hasHashMark := false;
  //txtCount.BeginUpdate;
  if chkMarkdown.IsChecked then begin
    for i := 0 to lstContent_.Count-1 do begin
      _sLine := lstContent_.Strings[i];
      if Copy(_sLine,1,1) = '#' then begin
        _hasHashMark := true;
        continue;
      end else if Tregex.IsMatch(_sLine, '^(\s)*') then begin
        _sLine := Trim(_sLine);
        lstContent_.Strings[i] := _sLine;
      end;

      if Length(_sLine) <= 2 then continue;
      if i=107 then begin
        _iPos := 1;
      end;

      _sReplacedLine := symbolReplace(_sLine, _lstSymbol);  // 標點符號轉換
      if _sReplacedLine <> _sLine then begin
        lstContent_.Strings[i] := _sReplacedLine;
      end;

      _sReplacedLine := markdown(_sLine, _lstExpr);
      if _sReplacedLine <> _sLine then begin
        _hasHashMark := true;
        lstContent_.Strings[i] := _sReplacedLine;
      end;
    end;
  end;

  for i := 0 to lstContent_.Count-1 do begin
    if Copy(_sLine,1,1) = '#' then begin
      _hasHashMark := true;
      break;
    end;
  end;

  //txtCount.EndUpdate;
  _lstExpr.Destroy;
  _lstSymbol.Destroy;
  if chkMarkdown.isChecked then begin
    _sDatetime := DateTimeToStr(now);
    memoStatus.Lines.Add('  結束轉換成Markdown格式... ' + _sDatetime);
  end;
  txtCount.Text := '';
  btnReadFile.Enabled := true;

  if _hasHashMark then begin
    _sMarkdownFilename := ChangeFileExt(sFilename_, '.markdown');
    MemoStatus.Lines.Add('  另存檔案：' + _sMarkdownFilename);
    lstContent_.SaveToFile(_sMarkdownFilename);
  end else begin
    ShowMessage(sFilename_ + ' 沒有標題符號（#），請檢查內容章節是否漏加井號');
  end;

  edtMarkdown.Text := sFilename_;
  sFilename_ := ChangeFileExt(sFilename_, '.html');
  ///!!! sOutputBasename_ := sTitle_;
  MemoStatus.Lines.Add('  書名：' + sTitle_);
  MemoStatus.Lines.Add('  作者：' + sAuthor_);
  MemoStatus.Lines.Add('  讀取行數：' + IntToStr(lstContent_.Count));


  btnGenFiles.Visible := true;
  btnGenFiles.setFocus;
end;


procedure TForm1.btnSettingsClick(Sender: TObject);
var
  _sEditor, _sFilePath: String;
begin
  _sEditor := oIniFile_.ReadString('EDITOR', 'HTML', 'notepad');
  _sFilePath := sAppDir_+'m2m.ini';

{$IFDEF MSWINDOWS}
  ShellExecute(0, PChar('open'), PChar(_sEditor), PChar(_sFilePath), nil, SW_SHOW);
{$ENDIF MSWINDOWS}

{$IFDEF MACOS}
  _system(PAnsiChar('open ' + '"' + _sFilePath + '"'));
{$ENDIF MACOS}

end;

procedure TForm1.btnTOCHTMLClick(Sender: TObject);
var
  _sEditor, _sFilePath: String;
begin
  _sEditor := oIniFile_.ReadString('EDITOR', 'HTML', 'notepad');
  _sFilePath := sAppDir_+'toc.html';

{$IFDEF MSWINDOWS}
  ShellExecute(0, PChar('open'), PChar(_sEditor), PChar(_sFilePath), nil, SW_SHOW);
{$ENDIF MSWINDOWS}

{$IFDEF MACOS}
  _system(PAnsiChar('open ' + '"' + _sFilePath + '"'));
{$ENDIF MACOS}

end;

procedure TForm1.btnTOCNCXClick(Sender: TObject);
var
  _sEditor, _sFilePath: String;
begin
  _sEditor := oIniFile_.ReadString('EDITOR', 'HTML', 'notepad');
  _sFilePath := sAppDir_+'toc.ncx';

{$IFDEF MSWINDOWS}
  ShellExecute(0, PChar('open'), PChar(_sEditor), PChar(_sFilePath), nil, SW_SHOW);
{$ENDIF MSWINDOWS}

{$IFDEF MACOS}
  _system(PAnsiChar('open ' + '"' + _sFilePath + '"'));
{$ENDIF MACOS}
end;

function TForm1.markdown(sText: String; lstExpr: TStringList): String;
var
  i, _iPos: Integer;
  _sExpr, _sPattern, _sReplaced: String;
begin
  // group使用大括號, 被替代token用$1, $2, ...
  for i := 0 to lstExpr.Count-1 do begin
    _sExpr := lstExpr.Strings[i];
    _iPos := Pos('=', _sExpr);
    _sPattern := Copy(_sExpr, 1, _iPos-1);
    _sReplaced := Copy(_sExpr, _iPos+1, 99);
    if _sReplaced = '' then _sReplaced := ' ';

    if Tregex.IsMatch(sText, _sPattern) then begin
      sText := Tregex.Replace(sText, _sPattern, _sReplaced);
      if Pos(',', sText) > 0 then begin
        sText := StringReplace(sText, ',', '·', [rfReplaceAll]);
      end;
      if Pos('，', sText) > 0 then begin
        sText := StringReplace(sText, '，', '·', [rfReplaceAll]);
      end;
    end;
  end;
  Result := sText;
end;

function TForm1.symbolReplace(sText: String; lstSymbol: TStringList): String;
var
  i, _iPos: Integer;
  _sExpr, _sPattern, _sReplaced: String;
begin
  // group使用大括號, 被替代token用$1, $2, ...
  for i := 0 to lstSymbol.Count-1 do begin
    _sExpr := lstSymbol.Strings[i];
    _iPos := Pos('=', _sExpr);
    _sPattern := Copy(_sExpr, 1, _iPos-1);
    _sReplaced := Copy(_sExpr, _iPos+1, 99);
    if _sReplaced = '' then _sReplaced := ' ';

    if Tregex.IsMatch(sText, _sPattern) then begin
      sText := Tregex.Replace(sText, _sPattern, _sReplaced);
    end;
  end;
  Result := sText;
end;


procedure TForm1.Button1Click(Sender: TObject);
var
  opt: TRegExOptions;
begin
//  markdown(lstContent_.Text);
end;

procedure TForm1.chkMarkdownChange(Sender: TObject);
begin
  if chkMarkdown.IsChecked then begin
    chkLeadingSpaces.isChecked := true;
  end;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  oIniFile_.Destroy;
  lstContent_.Destroy;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  _sText: String;
  _iPos, _iPos1, _iPos2: Integer;
begin
  Application.ShowHint := true;
  sAppDir_ := GetCurrentDir() + PathDelim;  // ExtractFileDir(Application.GetNamePath) + PathDelim;
{$IFDEF MACOS}
  _iPos1 := Pos('M2M.app', sAppDir_);
  _iPos2 := Pos('m2m.app', sAppDir_);
  if (_iPos1 > 0) then begin
    sAppDir_ := Copy(sAppDir_, 1, _iPos1-1);
  end else if (_iPos2 > 0) then begin
    sAppDir_ := Copy(sAppDir_, 1, _iPos2-1);
  end;
{$ENDIF MACOS}

  self.Caption := self.Caption + ' ' + _VERSION_;
//  oIniFile_ := TIniFile.Create(sAppDir_ + 'm2m.ini', TEncoding.UTF8);
  oIniFile_ := TMemIniFile.Create(sAppDir_ + 'm2m.ini', TEncoding.UTF8);
  sTextFolder_ := oIniFile_.ReadString('SETTINGS', 'TEXT_FOLDER', sAppDir_);
  OpenDialog1.InitialDir := sTextFolder_;
  edtCounter.Text := oIniFile_.ReadString('SETTINGS', 'LEVEL2_MAX_COUNT', '20');
  iLevel2MaxCount_ := StrToInt(edtCounter.Text);

  //_sText := Clipboard.AsText;
  _sText := oIniFile_.ReadString('RECENT_FILES', '1', '');
  //ShowMessage(_sText + '///' + AnsiToUTF8(_sText));
  if (_sText <> '') then begin
    edtMarkdown.Text := _sText;
  end;

  sUserName_ := GetEnvironmentVariable('USERNAME');
  sToday_ := DateToStr(Date);
  sOutputBaseName_ := 'mybook';
  lstContent_ := TStringList.Create;
  //Memo2.Lines.Clear;
  //MemoStatus.Lines.Clear;

  //Memo2.Visible := false;
  //Memo1.Width := Panel5.Width-20;
  GroupBox1.Visible := false;
  btnGenFiles.Visible := false;
  btnGenMobi.Visible := false;
  txtCount.Text := '讀檔時自動轉換Markdown格式，請稍候。';
  //btnSendMail.Visible := false;
  //ShowMessage(sToday_);

  // Init
  //SMTP1.OnError := @SMTP1Error;
  //FMimeStream := TMimeStream.Create;
  //FMimeStream.AddTextSection(''); // for the memo
end;

procedure TForm1.btnOpenFileClick(Sender: TObject);
begin
  OpenDialog1.InitialDir := oIniFile_.ReadString('SETTINGS', 'TEXT_FOLDER', sAppDir_);
  if OpenDialog1.Execute then begin
    sFilename_ := OpenDialog1.Filename;
    //Memo1.Lines.Clear;
    //memo1.Lines.LoadFromFile(sFilename_);
    edtMarkdown.Text := sFilename_;
    sFilename_ := ChangeFileExt(sFilename_, '.html');
    edtTitle.Text := '';
    edtAuthor.Text := '';
    MemoStatus.Text := '';
  end;

end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  txtCount.Text := DateTimeToStr(now);
end;

procedure TForm1.generateHTML();
var
  i, j, x, _iPlayOrder, _iLevelCount1, _iLevelCount2, _iLevelCount3: Integer;
  _iHeaderCount, _iPos: Integer;
  _sHeader, _sHeaderTitle, _sHeaderKey, _sLine, _sPrevLine, _sText: String;
  _lstText: TStringList;
begin
  _lstText := TStringList.Create;
  _lstText.Add('<!DOCTYPE html>');
  _lstText.Add('<html>');
  _lstText.Add('  <head>');
  _lstText.Add('  <title>' + sTitle_ + '</title>');
  _lstText.Add('  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />');
  if chkVertical.IsChecked then begin
    _lstText.Add('  <link rel="stylesheet" href="style_vertical.css"  type="text/css" />');
  end else begin
    _lstText.Add('  <link rel="stylesheet" href="style.css"  type="text/css" />');
  end;
  _lstText.Add('</head>');
  _lstText.Add('<body>');

  oLevelList1_ := TStringList.Create;
  oLevelList2_ := TStringList.Create;
  oLevelList3_ := TStringList.Create;
  _iLevelCount1 := 0;
  _iLevelCount2 := 0;
  _iLevelCount3 := 0;
  _iPlayOrder := 0;

  for i := 0 to lstContent_.Count-1 do begin
    //if i = 0 then begin
    //  x := 1;
    //end;
    _sLine := lstContent_.Strings[i];
    if (_sLine = '') then continue;

    _iHeaderCount := OccurrencesOfChar(_sLine, '#');
    if (_iHeaderCount > 3) then begin
      _sLine := '--------';
      _iHeaderCount := 0;
    end;

    if (_iHeaderCount > 0) then begin
      if (i>1) and (_sLine = lstContent_.Strings[i-1]) then begin  // 標題重覆
        continue;
      end;

      Inc(_iPlayOrder);
      _sHeader := Trim(Copy(_sLine, _iHeaderCount+1, Length(_sLine)));
      if (_iHeaderCount = 1) then begin
        Inc(_iLevelCount1);
        _iLevelCount2 := 0;
        _iLevelCount3 := 0;
        _sHeaderKey := IntToStr(_iLevelCount1)+' '+_sHeader;
        oLevelList1_.Add(_sHeaderKey);
      end else if (_iHeaderCount = 2) then begin
        Inc(_iLevelCount2);
        _iLevelCount3 := 0;
        _sHeaderKey := IntToStr(_iLevelCount1)+'-'+IntToStr(_iLevelCount2) + ' ' +_sHeader;
        oLevelList2_.Add(_sHeaderKey);
      end else if (_iHeaderCount = 3) then begin
        Inc(_iLevelCount3);
        _sHeaderKey := IntToStr(_iLevelCount1)+'-'+IntToStr(_iLevelCount2)+'-'+IntToStr(_iLevelCount3)+' '+_sHeader;
        oLevelList3_.Add(_sHeaderKey);
      end;
      if (_iHeaderCount >= 2) then begin
        _sLine := '<mbp:pagebreak /><!--Eject-->'#13#10;
      end else begin
        _sLine := '';
      end;
      _iPos := AnsiPos('，', _sHeader);
      if _iPos <= 0 then _iPos := AnsiPos('。', _sHeader);
      if _iPos > 0 then _sHeader := Copy(_sHeader, 1, _iPos);
      _iPos := AnsiPos(' ', _sHeader);
      if (_iPos > 0) then _sHeaderTitle := Copy(_sHeader, _iPos+1, 100);
      if (Length(_sHeaderTitle) > 30) then begin
        MemoStatus.Lines.Add('  !!! 第 ' + IntToStr(i+1) + '行 標題長度超過 30，可能有問題...');
      end;
      // # 改成 h2, ## 改成 h3以免字體太大
      _sLine := _sLine + '<a name="SECTION_' + IntToStr(_iPlayOrder) + '"><h' +
        IntToStr(_iHeaderCount+1) + '>' + _sHeader +
        '</h' + IntToStr(_iHeaderCount+1) + '></a>';
    end else begin
      if (chkLeadingSpaces.IsChecked) then begin
        _sLine := '　　' + _sLine;
      end;

      _sLine := '<p>' + _sLine + '</p>';
    end;
    _lstText.Add(_sLine);
  end;

  _lstText.Add('</body>');
  _lstText.Add('</html>');
  _sText := _lstText.Text;
  // 第一層不要跳頁
  _sText := StringReplace(_sText, '</h2></a>'#13#10+'<mbp:pagebreak /><!--Eject-->','</h2></a>'#13#10, [rfReplaceAll]);
  _lstText.Text := _sText;
  _lstText.SaveToFile(sAppDir_ + sOutputBaseName_ + '.html', TEncoding.UTF8);
  MemoStatus.Lines.Add('  寫出' + sAppDir_ + sOutputBaseName_ + '.html');

  _lstText.Destroy;
end;

// Generating 目錄 toc.html
function TForm1.getTOCHtml(): String;
var
  _sTOC, _sText, _sLevel, _sParentLevel: String;
  i, j, _iPlayOrder, _iPos, _iLevel1Count: Integer;
begin
  _sTOC := '';
  _iPlayOrder := 0;
  for i := 1 to oLevelList1_.Count do begin
    Inc(_iPlayOrder);
    _sText := oLevelList1_[i-1];
    _iPos := Pos(' ', _sText);
    if (i > 1) then begin
      _sLevel := Copy(_sText, 1, _iPos-1);
      //_sTOC := _sTOC + '    </li>'#13#10+'  </ul><!--' + _sLevel + '-->'#13#10;
      _sTOC := _sTOC + '  </ul>'#13#10;
    end;
    _sText := Copy(_sText, _iPos+1, Length(_sText));
    _sTOC := _sTOC + '  <div><a href="'+sOutputBaseName_+'.html#SECTION_'+ IntToStr(_iPlayOrder) + '">' + _sText + '</a></div>' + #13#10 +
       '  <ul>'#13#10;
    for j := 1 to oLevelList2_.Count do begin
      _sText := oLevelList2_[j-1];
      _iPos := Pos('-', _sText);
      _sParentLevel := Copy(_sText, 1, _iPos-1);  // 第幾個標題1
      if _sParentLevel = IntToStr(i) then begin
        Inc(_iPlayOrder);
        _iPos := Pos(' ', _sText);
        _sLevel := Copy(_sText, 1, _iPos-1);
        _sText := Copy(_sText, _iPos+1, Length(_sText));
        _sTOC := _sTOC + getTOC(_iPlayOrder, _sText, '    ') +
          '</li><!--' + _sLevel + '-->'#13#10;
      end;
    end;
  end;

  // 只有第二層，預設每20個自動插入一個第一層
  if oLevelList1_.Count = 0 then begin
    _iPlayOrder := 0;
    MemoStatus.Lines.Add('  只有第二層標題，自動插入第一層標題...');
    _iLevel1Count := 1;
    _iPlayOrder := 0;
    _sTOC := '  <div><a href="'+sOutputBaseName_+'.html#SECTION_1">第1部份</a></div>'#13#10+'    <ul>'#13#10;
    // oIniFile_.ReadInteger('SETTINGS', 'LEVEL2_MAX_COUNT', 20);
    for j := 1 to oLevelList2_.Count do begin
      _sText := oLevelList2_[j-1];
      Inc(_iPlayOrder);
      if ((j mod iLevel2MaxCount_) = 1) and (j > 1) then begin
        Inc(_iLevel1Count);
        _sTOC := _sTOC + '    </ul>'#13#10;
        _sTOC := _sTOC + '  <div><a href="'+sOutputBaseName_+'.html#SECTION_'+ IntToStr(_iPlayOrder) +
          '">第' + IntToStr(_iLevel1Count) + '部份</a></div>' + #13#10 + '    <ul>'#13#10;
      end;
      _iPos := Pos(' ', _sText);
      _sLevel := Copy(_sText, 1, _iPos-1);
      _sText := Copy(_sText, _iPos+1, Length(_sText));
      _sTOC := _sTOC + getTOC(_iPlayOrder, _sText, '    ') +
        '</li>'#13#10;
    end;
  end;

  _sTOC := _sTOC + '  </ul>'#13#10;
  _sTOC := StringReplace(_sTOC, '  <ul>'#13#10'  </ul>', '', [rfReplaceAll]);

  Result := _sTOC;
end;

procedure TForm1.txtLinkClick(Sender: TObject);
begin
{$IFDEF MSWINDOWS}
  ShellExecute(0, PChar('open'), PChar(txtLink.Text+'/5451'), PChar(''), nil, SW_SHOW);
{$ENDIF MSWINDOWS}

{$IFDEF MACOS}
  _system(PAnsiChar('open ' + '"' + AnsiString(txtLink.Text+'/5451') + '"'));
{$ENDIF MACOS}

end;

// Create .ncx content
function TForm1.getNCXText(): String;
var
  i, j, _iPos, _iPlayOrder, _iLevel1Count: Integer;
  _sNavPoint, _sText, _sLevel, _sParentLevel: String;
begin
  // 產生 toc.ncx
  _sNavPoint := '';
  _iPlayOrder := 0;
  for i := 1 to oLevelList1_.Count do begin
    Inc(_iPlayOrder);
    _sText := oLevelList1_[i-1];
    _iPos := Pos(' ', _sText);
    if (i > 1) then begin  // 第?卷結尾
      _sLevel := Copy(_sText, 1, _iPos-1);
      _sNavPoint := _sNavPoint + '  </navPoint><!--' + _sLevel + '-->'#13#10;
    end;
    _sText := Copy(_sText, _iPos+1, Length(_sText));
    _sNavPoint := _sNavPoint + getNavPoint(_iPlayOrder, _sText, '');
    for j := 1 to oLevelList2_.Count do begin
      _sText := oLevelList2_[j-1];
      _iPos := Pos('-', _sText);
      _sParentLevel := Copy(_sText, 1, _iPos-1);  // 第幾個標題1
      if _sParentLevel = IntToStr(i) then begin
        Inc(_iPlayOrder);
        _iPos := Pos(' ', _sText);
        _sLevel := Copy(_sText, 1, _iPos-1);
        _sText := Copy(_sText, _iPos+1, Length(_sText));
        _sNavPoint := _sNavPoint + getNavPoint(_iPlayOrder, _sText, '  ') +
          '    </navPoint><!--' + _sLevel + '-->'#13#10;
      end;
    end;
  end;
  // 只有第二層，預設每20個自動插入一個第一層
  if oLevelList1_.Count = 0 then begin
    MemoStatus.Lines.Add('  只有第二層標題，自動插插入第一層標題...');
    _iLevel1Count := 1;
    _iPlayOrder := 0;
    _sNavPoint := getNavPoint(1, '第1部份', '');
    for j := 1 to oLevelList2_.Count do begin
      Inc(_iPlayOrder);
      if ((j mod iLevel2MaxCount_) = 1) and (j > 1) then begin
        Inc(_iLevel1Count);
        _sNavPoint := _sNavPoint + '  </navPoint>'#13#10;
        _sNavPoint := _sNavPoint + getNavPoint(_iPlayOrder, '第'+IntToStr(_iLevel1Count)+'部份', '');
      end;
      _sText := oLevelList2_[j-1];
      _iPos := Pos(' ', _sText);
      _sLevel := Copy(_sText, 1, _iPos-1);
      _sText := Copy(_sText, _iPos+1, Length(_sText));
      _sNavPoint := _sNavPoint + getNavPoint(_iPlayOrder, _sText, '  ') +
        '    </navPoint><!--' + _sLevel + '-->'#13#10;
    end;
  end;
  _sNavPoint := _sNavPoint + '  </navPoint>'#13#10;

  Result := _sNavPoint;
end;

function TForm1.getNavPoint(iPlayOrder: Integer; sHeader: String; sSpaces: String): String;
begin
  Result := sSpaces + '  <navPoint class="welcome" id="welcome" playOrder="' + IntToStr(iPlayOrder) + '">'#13#10 +
      sSpaces + '    <navLabel>'#13#10 +
      sSpaces + '    <text>' + Trim(sHeader) + '</text>'#13#10 +
      sSpaces + '    </navLabel>'#13#10 +
      sSpaces + '    <content src="' + sOutputBaseName_ + '.html#SECTION_' + IntToStr(iPlayOrder) + '"/>'#13#10;
end;

// 產生目錄HTML
function TForm1.getTOC(iPlayOrder: Integer; sHeader: String; sSpaces: String): String;
begin
  Result := sSpaces + '  <li><a href="' + sOutputBaseName_ + '.html#SECTION_' + IntToStr(iPlayOrder) +
    '">' + Trim(sHeader) + '</a>';
end;

procedure TForm1.generateCover;
var
  canvas: TCanvas;
  mRect: TRectF;
  _sTitle1, _sTitle2, _sNow: String;
begin
  //Image1.Bitmap.LoadFromFile(sAppDir_ + 'blank.jpg');
  Image1.Bitmap.Create(600, 800);
  Image1.Bitmap.Clear(TAlphaColors.White);

  canvas := Image1.Bitmap.canvas;
  canvas.BeginScene();
  canvas.Stroke.Kind := TBrushKind.bkSolid;
  canvas.Font.Size := 48;
  //Image1.Bitmap.canvas.StrokeThickness := 1;
  canvas.Fill.Color := TAlphaColors.Black;
  //mRect.Create(100, 229, 300, 250);
  if Length(edtTitle.Text) > 10 then begin
    _sTitle1 := Copy(edtTitle.Text, 1, 10);
    _sTitle2 := Copy(edtTitle.Text, 10, 20);
  end else begin
    _sTitle1 := edtTitle.Text;
    _sTitle2 := '';
  end;

  mRect := TRectF.Create(50, 110, 580, 800);
  Canvas.FillText(mRect, _sTitle1, false, 100,
      [{TFillTextFlag.RightToLeft}], TTextAlign.Leading, TTextAlign.Leading);

  mRect := TRectF.Create(50, 180, 580, 800);
  Canvas.FillText(mRect, _sTitle2, false, 100,
      [{TFillTextFlag.RightToLeft}], TTextAlign.Leading, TTextAlign.Leading);

  canvas.Font.Size := 32;
  mRect := TRectF.Create(50, 500, 550, 800);
  Canvas.FillText(mRect, edtAuthor.Text, false, 100,
    [{TFillTextFlag.RightToLeft}], TTextAlign.Leading, TTextAlign.Leading);

  _sNow := FormatDateTime('yyyy"/"mm"/"dd', Now);
  canvas.Font.Size := 32;
  mRect := TRectF.Create(50, 600, 550, 800);
  Canvas.FillText(mRect, _sNow, false, 100,
    [{TFillTextFlag.RightToLeft}], TTextAlign.Leading, TTextAlign.Leading);

  canvas.endscene;

  //image1.Bitmap.Unmap(vBitMapData);         // unlock the bitmap
  image1.BitMap.SaveToFile(sAppDir_ + 'mybook.jpg');
end;

end.

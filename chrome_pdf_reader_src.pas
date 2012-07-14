{
  Chrome PDF Reader v1.2
 © 2012 by Victor Alberto Gil. All rights reserved

 WEB: apps.codigobit.info
 Mail: vhanla@gmail.com

 version 1.2 July 2012
 Licensed under MPL 1.1
}
unit chrome_pdf_reader_src;

interface

uses
  Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.Imaging.pngimage, Vcl.ExtCtrls, Vcl.ComCtrls;

type
  TForm1 = class(TForm)
    lblAbout: TLabel;
    Edit1: TEdit;
    Label3: TLabel;
    CheckBox1: TCheckBox;
    Image1: TImage;
    lblSetPDFReader: TLabel;
    PageControl1: TPageControl;
    chrome: TTabSheet;
    procedure Label1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormCreate(Sender: TObject);
    procedure Label2MouseEnter(Sender: TObject);
    procedure Label2MouseLeave(Sender: TObject);
    procedure Label2Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure lblSetPDFReaderClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    { Private declarations }
    procedure SaveINI;
    procedure LoadINI;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  cromo:string;
  h: THandle;
implementation

{$R *.dfm}
uses registry, inifiles, shellapi;

procedure BuscaFicheros(path, mask : AnsiString; var Value : TStringList; brec : Boolean);
var
  srRes : TSearchRec;
  iFound : Integer;
begin
  if ( brec ) then
    begin
    if path[Length(path)] <> '\' then path := path +'\';
    iFound := FindFirst( path + '*.*', faAnyfile, srRes );
    while iFound = 0 do
      begin
      if ( srRes.Name <> '.' ) and ( srRes.Name <> '..' ) then
	if srRes.Attr and faDirectory > 0 then
	  BuscaFicheros( path + srRes.Name, mask, Value, brec );
      iFound := FindNext(srRes);
      end;
    //Sysutils.FindClose(srRes);
    FindClose(srRes);
    end;
  if path[Length(path)] <> '\' then path := path +'\';
  iFound := FindFirst(path+mask, faAnyFile-faDirectory, srRes);
  while iFound = 0 do
    begin
    if ( srRes.Name <> '.' ) and ( srRes.Name <> '..' ) and ( srRes.Name <> '' ) then
      Value.Add(path+srRes.Name);
    iFound := FindNext(srRes);
    end;
  //Sysutils.FindClose( srRes );
  FindClose(srRes);
end;
function FindPath():String;
var
   reg: TRegistry;
   path, buf: string;
   ficheros: TStringList;
   i,p:integer;
begin
  ficheros:=TStringList.Create;
  reg:=TRegistry.Create;
  reg.RootKey:=HKEY_CLASSES_ROOT;

  with reg do
  begin
    try
      if OpenKey('\ChromeHTML\shell\open\command',false) then
      begin
        path:=ReadString('');
        cromo:=copy(path,2,length(path)-10);
        buf:=extractfilepath(cromo);
        BuscaFicheros(buf,'default.dll',ficheros,true);
        //listapath.Items.Assign(ficheros);
      end
      else if OpenKey('\Applications\chrome.exe\shell\open\command',false) then
      begin
        path:=ReadString('');
        cromo:=copy(path,0,length(path)-5);
        buf:=extractfilepath(cromo);
        BuscaFicheros(buf,'default.dll',ficheros,true);
      end
      else
      begin
        ///MessageDlg('Chrome not found', mtWarning,[mbOK], 0);
      end;
    finally
      free;
    end;
  end;
  //ficheros.Free;
  if(ficheros.Count<1) then
  begin
  	result:=''
  end
  else
  begin
	  for i:=0 to ficheros.count-1 do
  	begin
	    p:=pos(uppercase('\Themes\default.dll'),uppercase(ficheros[i]) );
	    if p>0 then begin {lo encontramos}
	  	path:=copy(ficheros[i],0,p);
		  result:=path+'Themes\';
    end
	  else result:=''
    end;
  end;
    ficheros.Free;
end;

procedure SetAsDefaultPDF;
var
  r: TRegistry;
begin
  r:=TRegistry.Create;
  try
    r.RootKey:=HKEY_CURRENT_USER;
    //first let's register the files
    if r.OpenKey('\Software\Classes\.pdf',true) then
    begin
      r.WriteString('','ChromePDF');
      r.WriteString('Content Type','application/pdf');
      r.CloseKey;
    end;
    //now let's create the file handler
    if r.OpenKey('\Software\Classes\ChromePDF',true) then
    begin
      r.WriteString('','PDF');
      r.CloseKey;
    end;
    if r.OpenKey('\Software\Classes\ChromePDF\DefaultIcon',true) then
    begin
      r.WriteString('',pchar(ExtractFilePath(ParamStr(0))+ExtractFileName(ParamStr(0))+',0'));
      r.CloseKey;
    end;
    if r.OpenKey('\Software\Classes\ChromePDF\shell',true) then
    begin
      r.WriteString('','Open');
      r.CloseKey;
    end;
    if r.OpenKey('\Software\Classes\ChromePDF\shell\Open',true) then
    begin
      r.WriteString('','Open');
      r.CloseKey;
    end;
    if r.OpenKey('\Software\Classes\ChromePDF\shell\Open\command',true) then
    begin
    //let's open it with chrome instead with this app
      r.WriteString('',pchar('"'+ExtractFilePath(ParamStr(0))+ExtractFileName(ParamStr(0))+'" "%1"'));
//      r.WriteString('',pchar('"'+cromo+'" "--app=%1"'));
      r.CloseKey;
    end;
  finally
    r.Free;
  end;
end;
procedure TForm1.FormCreate(Sender: TObject);
var
  sURL: string;
  attempts: integer;
  Style, ExStyle: Cardinal;
begin
  LoadINI;
  lblAbout.Caption:='Chrome PDF Reader v1.2'#13
  +'This is a utility to establish Google Chrome as your default PDF reader.'#13
  +'Since it contains an integrated plugin to show PDF files,'
  +'why don''t we use it?'#13'Maybe it is too basic, but it comes '
  +'handy when you don''t have a PDF reader software installed.';

  FindPath;
  Edit1.Text:=cromo;
// let's load files
  if ParamCount > 0 then
  begin
    if FileExists(ParamStr(1)) and (ExtractFileExt(ParamStr(1))='.pdf') then
    begin
      application.ShowMainForm:=false;
      sURL := '--app="'+ParamStr(1)+'"';
      if CheckBox1.Checked then
      begin
        ShellExecute(self.WindowHandle, 'open','chrome.exe', pchar(sURL),nil, SW_SHOW);
        application.Terminate;
      end
      else
      begin
        ShellExecute(self.WindowHandle, 'open','chrome.exe', pchar(sURL),nil, SW_SHOWMINIMIZED);
        h:=0;
        attempts:=0;
        while h = 0 do
        begin
          h:= Windows.FindWindow('Chrome_WidgetWin_0', pchar(ExtractFileName(ParamStr(1))));
          if h = 0 then
            h:= Windows.FindWindow('Chrome_WidgetWin_1', pchar(ExtractFileName(ParamStr(1))));

          sleep(500); //2 veces por segundo
          inc(attempts);
          if attempts > 10 then
          begin
            //better close it
            application.Terminate;
          end;
        end;
        //else
              application.ShowMainForm:=true;
        Caption:=ParamStr(1);
        BorderStyle:=bsSizeable;
        PageControl1.Align:=alClient;

        ShowWindow(h,SW_NORMAL);
        Windows.SetParent(h,chrome.Handle);
        MoveWindow(h,0,0,chrome.ClientWidth, chrome.ClientHeight, false);

        Style:=GetWindowLong(h, GWL_STYLE);
        ExStyle:= GetWindowLong(h, GWL_EXSTYLE);

        Style := Style and not (WS_POPUP or WS_CAPTION or WS_BORDER or WS_THICKFRAME or WS_DLGFRAME or DS_MODALFRAME);
        ExStyle := ExStyle and not (WS_EX_DLGMODALFRAME or WS_EX_WINDOWEDGE or WS_EX_TOOLWINDOW);

        SetWindowLong(h, GWL_STYLE, Style);
        SetWindowLong(h, GWL_EXSTYLE, ExStyle);
        PageControl1.ActivePage:=chrome;
        BringWindowToTop(h);
      end;
    end;

  end;

end;
procedure PerformCtrlW;
begin
  BringWindowToTop(h);
  keybd_event(VK_LCONTROL,0,0,0); //Ctrl key down
  keybd_event(Ord('W'), MapVirtualKey(Ord('W'),0),0,0); // m key is down
  //let's release those virtual keystrokes
  keybd_event(Ord('W'), MapVirtualKey(Ord('W'),0),KEYEVENTF_KEYUP,0);
  keybd_event(VK_LCONTROL,0,KEYEVENTF_KEYUP,0); //Ctrl key up
  keybd_event(VK_CANCEL, 0,0,0);
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  SaveINI;
//clear ram to avoid leaks of existing orphan windows running
  if h<>0 then
  begin
  PerformCtrlW;
  try
//  SendMessage(H, WM_CLOSE,0,0);
  except end;
  end;

end;

procedure TForm1.FormResize(Sender: TObject);
begin
Windows.MoveWindow(h,0,0,chrome.ClientWidth, chrome.ClientHeight, false);
end;

procedure TForm1.Label1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  ReleaseCapture;
  Perform(WM_SYSCOMMAND, $F012, 0)
end;

procedure TForm1.Label2Click(Sender: TObject);
begin
  close
end;

procedure TForm1.Label2MouseEnter(Sender: TObject);
begin
//  TLabel(Sender).Font.Style:=[fsBold];
    TLabel(Sender).Font.Size:=12;
end;

procedure TForm1.Label2MouseLeave(Sender: TObject);
begin
//    TLabel(Sender).Font.Style:=[];
    TLabel(Sender).Font.Size:=11;
end;

function RefreshScreenIcons : Boolean;
const
  KEY_TYPE = HKEY_CURRENT_USER;
  KEY_NAME = 'Control Panel\Desktop\WindowMetrics';
  KEY_VALUE = 'Shell Icon Size';
var
  Reg: TRegistry;
  strDataRet, strDataRet2: string;

 procedure BroadcastChanges;
 var
   success: DWORD;
 begin
   SendMessageTimeout(HWND_BROADCAST,
                      WM_SETTINGCHANGE,
                      SPI_SETNONCLIENTMETRICS,
                      0,
                      SMTO_ABORTIFHUNG,
                      10000,
                      success);
 end;


begin
  Result := False;
  Reg := TRegistry.Create;
  try
    Reg.RootKey := KEY_TYPE;
    // 1. open HKEY_CURRENT_USER\Control Panel\Desktop\WindowMetrics
    if Reg.OpenKey(KEY_NAME, False) then
    begin
      // 2. Get the value for that key
      strDataRet := Reg.ReadString(KEY_VALUE);
      Reg.CloseKey;
      if strDataRet <> '' then
      begin
        // 3. Convert sDataRet to a number and subtract 1,
        //    convert back to a string, and write it to the registry
        strDataRet2 := IntToStr(StrToInt(strDataRet) - 1);
        if Reg.OpenKey(KEY_NAME, False) then
        begin
          Reg.WriteString(KEY_VALUE, strDataRet2);
          Reg.CloseKey;
          // 4. because the registry was changed, broadcast
          //    the fact passing SPI_SETNONCLIENTMETRICS,
          //    with a timeout of 10000 milliseconds (10 seconds)
          BroadcastChanges;
          // 5. the desktop will have refreshed with the
          //    new (shrunken) icon size. Now restore things
          //    back to the correct settings by again writing
          //    to the registry and posing another message.
          if Reg.OpenKey(KEY_NAME, False) then
          begin
            Reg.WriteString(KEY_VALUE, strDataRet);
            Reg.CloseKey;
            // 6.  broadcast the change again
            BroadcastChanges;
            Result := True;
          end;
        end;
      end;
    end;
  finally
    Reg.Free;
  end;
end;
procedure TForm1.lblSetPDFReaderClick(Sender: TObject);
begin
//set
SetAsDefaultPDF;
RefreshScreenIcons;
MessageDlg('PDF files will open with Chrome',mtInformation,[mbOK],0);
end;

procedure TForm1.SaveINI;
var
ini: TIniFile;
begin
  ini:=TIniFile.Create(ExtractFilePath(ParamStr(0))+'settings.ini');
    try
      ini.WriteBool('ChromePDF','ownwindow',CheckBox1.Checked);
    finally
      ini.Free;
    end;
end;

procedure TForm1.LoadINI;
var
ini:tinifile;
begin
  ini:=TIniFile.Create(ExtractFilePath(ParamStr(0))+'settings.ini');
    try
      CheckBox1.Checked:=ini.ReadBool('ChromePDF','ownwindow',false);
    finally
      ini.Free;
    end;

end;


end.

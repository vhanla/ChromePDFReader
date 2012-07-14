program ChromePDFReader;

{$R *.dres}

uses
  Vcl.Forms,
  chrome_pdf_reader_src in 'chrome_pdf_reader_src.pas' {Form1},
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Metro Black');
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

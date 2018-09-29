program m2m;

uses
  System.StartUpCopy,
  FMX.Forms,
  m2mUnit1 in 'm2mUnit1.pas' {Form1},
  RegularExpressions in 'RegularExpressions.pas',
  RegularExpressionsCore in 'RegularExpressionsCore.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

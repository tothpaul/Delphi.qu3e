program Demo1;

uses
  Vcl.Forms,
  Demo1.Main in 'Demo1.Main.pas' {Form1},
  RandyGaul.qu3e in 'RandyGaul.qu3e.pas',
  Execute.GLPanel in 'Execute.GLPanel.pas' {GLPanel: TFrame};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

program CaptchaSolver;

uses
  Vcl.Forms,
  uMainForm in 'src\forms\uMainForm.pas' {MainForm},
  uCaptchaSonicClient in 'src\api\uCaptchaSonicClient.pas',
  uCaptchaTypes in 'src\types\uCaptchaTypes.pas',
  uHCaptchaAutomation in 'src\automation\uHCaptchaAutomation.pas',
  uImageProcessor in 'src\utils\uImageProcessor.pas',
  uLogger in 'src\utils\uLogger.pas',
  uConfig in 'src\utils\uConfig.pas',
  uDirectCompositionHost in 'WindowlessBrowser\uDirectCompositionHost.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end. 
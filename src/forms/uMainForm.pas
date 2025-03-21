unit uMainForm;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.JSON,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls,
  uCaptchaTypes, uCaptchaSonicClient, uHCaptchaAutomation,
  uImageProcessor, uLogger, uConfig, uDirectCompositionHost;

type
  TMainForm = class(TForm)
    pnlTop: TPanel;
    pnlBottom: TPanel;
    pnlMain: TPanel;
    lblURL: TLabel;
    edtURL: TEdit;
    btnStart: TButton;
    btnStop: TButton;
    mmLog: TMemo;
    StatusBar: TStatusBar;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
  private
    FConfig: TConfig;
    FWebView: TDirectCompositionHost;
    FCaptchaSonic: TCaptchaSonicClient;
    FImageProcessor: TImageProcessor;
    FAutomation: THCaptchaAutomation;
    FRunning: Boolean;
    FCurrentWebsiteKey: string;
    
    procedure InitializeComponents;
    procedure UpdateStatus(const Status: string);
    procedure LogMessage(const Msg: string);
    procedure HandleNavigationCompleted(Sender: TObject; IsSuccess: Boolean);
    procedure HandleScriptCompleted(Sender: TObject; const Result: string);
    function ExtractWebsiteKey(const JsonStr: string): string;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FConfig := TConfig.Create('config.ini');
  
  TLogger.Initialize(FConfig.LogFile, FConfig.LogLevel);
  TLogger.GetInstance.LogInfo('Application started');
  
  InitializeComponents;
  UpdateStatus('Ready');
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FAutomation.Free;
  FImageProcessor.Free;
  FCaptchaSonic.Free;
  FWebView.Free;
  FConfig.Free;
  
  TLogger.GetInstance.LogInfo('Application terminated');
  TLogger.Finalize;
end;

procedure TMainForm.InitializeComponents;
begin
  // Create WebView
  FWebView := TDirectCompositionHost.Create(Self);
  FWebView.Parent := pnlMain;
  FWebView.Align := alClient;
  FWebView.OnNavigationCompleted := HandleNavigationCompleted;
  FWebView.OnScriptCompleted := HandleScriptCompleted;
  
  // Create other components
  FCaptchaSonic := TCaptchaSonicClient.Create(FConfig.CaptchaConfig);
  FImageProcessor := TImageProcessor.Create;
  FAutomation := THCaptchaAutomation.Create(FConfig.CaptchaConfig, FWebView);
  
  // Initialize UI
  btnStop.Enabled := False;
  FRunning := False;
  FCurrentWebsiteKey := '';
end;

procedure TMainForm.UpdateStatus(const Status: string);
begin
  StatusBar.SimpleText := Status;
  Application.ProcessMessages;
end;

procedure TMainForm.LogMessage(const Msg: string);
begin
  mmLog.Lines.Add(Format('[%s] %s', [FormatDateTime('hh:nn:ss', Now), Msg]));
  mmLog.SelStart := mmLog.GetTextLen;
  mmLog.Perform(EM_SCROLLCARET, 0, 0);
end;

function TMainForm.ExtractWebsiteKey(const JsonStr: string): string;
var
  JsonObj: TJSONObject;
begin
  Result := '';
  try
    JsonObj := TJSONObject.ParseJSONValue(JsonStr) as TJSONObject;
    try
      if JsonObj.GetValue('type').Value = 'hcaptcha_found' then
        Result := JsonObj.GetValue('sitekey').Value;
    finally
      JsonObj.Free;
    end;
  except
    on E: Exception do
      TLogger.GetInstance.LogError('Error parsing JSON: ' + E.Message);
  end;
end;

procedure TMainForm.HandleNavigationCompleted(Sender: TObject; IsSuccess: Boolean);
begin
  if not FRunning then
    Exit;
    
  if IsSuccess then
  begin
    TLogger.GetInstance.LogInfo('Page loaded successfully');
    LogMessage('Página carregada, procurando hCaptcha');
    UpdateStatus('Procurando hCaptcha...');
    
    // Execute script to check for hCaptcha
    FWebView.ExecuteScript(
      'var hcaptchaFrame = document.querySelector("iframe[src*=''hcaptcha.com'']");' +
      'if (hcaptchaFrame) {' +
      '  window.chrome.webview.postMessage(JSON.stringify({' +
      '    type: "hcaptcha_found",' +
      '    sitekey: hcaptchaFrame.getAttribute("data-sitekey")' +
      '  }));' +
      '} else {' +
      '  window.chrome.webview.postMessage(JSON.stringify({' +
      '    type: "hcaptcha_not_found"' +
      '  }));' +
      '}');
  end
  else
  begin
    TLogger.GetInstance.LogError('Failed to load page');
    LogMessage('Falha ao carregar a página');
    UpdateStatus('Erro ao carregar página');
    
    btnStart.Enabled := True;
    btnStop.Enabled := False;
    FRunning := False;
  end;
end;

procedure TMainForm.HandleScriptCompleted(Sender: TObject; const Result: string);
var
  WebsiteKey: string;
begin
  if not FRunning then
    Exit;
    
  WebsiteKey := ExtractWebsiteKey(Result);
  
  if WebsiteKey <> '' then
  begin
    FCurrentWebsiteKey := WebsiteKey;
    TLogger.GetInstance.LogInfo('hCaptcha found with key: ' + WebsiteKey);
    LogMessage('hCaptcha detectado, iniciando solução');
    UpdateStatus('Resolvendo captcha...');
    
    if FAutomation.Solve(edtURL.Text, WebsiteKey) then
    begin
      LogMessage('Captcha resolvido com sucesso');
      UpdateStatus('Captcha resolvido');
    end
    else
    begin
      LogMessage('Falha ao resolver captcha: ' + FAutomation.LastError);
      UpdateStatus('Erro ao resolver captcha');
    end;
  end
  else if Result.Contains('"type":"solution_injected"') then
  begin
    LogMessage('Solução injetada, aguardando verificação');
    UpdateStatus('Aguardando verificação...');
  end
  else if Result.Contains('"type":"verification_success"') then
  begin
    LogMessage('Verificação concluída com sucesso');
    UpdateStatus('Verificação concluída');
  end
  else
  begin
    TLogger.GetInstance.LogInfo('No hCaptcha found on page');
    LogMessage('Nenhum hCaptcha encontrado na página');
    UpdateStatus('hCaptcha não encontrado');
    
    btnStart.Enabled := True;
    btnStop.Enabled := False;
    FRunning := False;
  end;
end;

procedure TMainForm.btnStartClick(Sender: TObject);
begin
  if Trim(edtURL.Text) = '' then
  begin
    ShowMessage('Por favor, insira uma URL válida.');
    Exit;
  end;
  
  btnStart.Enabled := False;
  btnStop.Enabled := True;
  FRunning := True;
  FCurrentWebsiteKey := '';
  
  LogMessage('Iniciando navegação para: ' + edtURL.Text);
  UpdateStatus('Carregando página...');
  
  FWebView.Navigate(edtURL.Text);
end;

procedure TMainForm.btnStopClick(Sender: TObject);
begin
  FRunning := False;
  btnStart.Enabled := True;
  btnStop.Enabled := False;
  
  FWebView.Stop;
  
  LogMessage('Operação interrompida pelo usuário');
  UpdateStatus('Operação interrompida');
end;

end. 
unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, EditBtn,
  StdCtrls, ExtCtrls, IniFiles, DateUtils, Menus;

type

  { TMainForm }

  TMainForm = class(TForm)
    btnAdd: TButton;
    cbDrinkType: TComboBox;
    edtDate: TDateEdit;
    edtCups: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    MemoLog: TMemo;
    Panel1: TPanel;
    Panel2: TPanel;
    edtTime: TTimeEdit;
    procedure btnAddClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure LoadConfig;
    function ValidateEntry:Boolean;
    function GetTodayTotal(drinkType: string): Integer;
    procedure SaveEntry;
  private
    ConfigFile: string;
    DataFile: string;
    MaxCoffee: Integer;
    MaxBlackTea: Integer;
    MaxGreenTea: Integer;
    StartTime: TTime;
    EndTime: TTime;
    AbsoluteEndTime: TTime;

  public

  end;

var
  MainForm: TMainForm;

implementation
  {$R *.lfm}
{ TMainForm }

procedure TMainForm.btnAddClick(Sender: TObject);
begin
    if ValidateEntry then
    SaveEntry;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  ConfigFile := GetEnvironmentVariable('COFFEE_CONFIG');
  if ConfigFile = '' then
    ConfigFile := ExpandFileName(ExtractFilePath(ParamStr(0)) + 'coffee.cfg');

  DataFile := ExpandFileName(ExtractFilePath(ParamStr(0)) + 'coffee.log');

  LoadConfig;

  edtDate.Date := Now;
  edtTime.Time := Now;

  cbDrinkType.Items.Add('coffee');
  cbDrinkType.Items.Add('black tea');
  cbDrinkType.Items.Add('green tea');
  cbDrinkType.ItemIndex := 0;

  if FileExists(DataFile) then
    MemoLog.Lines.LoadFromFile(DataFile);
end;

procedure TMainForm.LoadConfig;
var
  Config: TIniFile;
  StartStr, EndStr, AbsEndStr: string;
begin

  MaxCoffee := 2;
  MaxBlackTea := 2;
  MaxGreenTea := 2;
  StartTime := EncodeTime(6, 0, 0, 0);  // 06:00
  EndTime := EncodeTime(14, 0, 0, 0);   // 14:00
  AbsoluteEndTime := EncodeTime(16, 0, 0, 0); // 16:00

  if not FileExists(ConfigFile) then
  begin
    Config := TIniFile.Create(ConfigFile);
    try
      Config.WriteInteger('Limits', 'MaxCoffee', MaxCoffee);
      Config.WriteInteger('Limits', 'MaxBlackTea', MaxBlackTea);
      Config.WriteInteger('Limits', 'MaxGreenTea', MaxGreenTea);
      Config.WriteString('Time', 'StartTime', '06:00');
      Config.WriteString('Time', 'EndTime', '14:00');
      Config.WriteString('Time', 'AbsoluteEndTime', '16:00');
    finally
      Config.Free;
    end;
  end;

  Config := TIniFile.Create(ConfigFile);
  try
    MaxCoffee := Config.ReadInteger('Limits', 'MaxCoffee', MaxCoffee);
    MaxBlackTea := Config.ReadInteger('Limits', 'MaxBlackTea', MaxBlackTea);
    MaxGreenTea := Config.ReadInteger('Limits', 'MaxGreenTea', MaxGreenTea);

    StartStr := Config.ReadString('Time', 'StartTime', '06:00');
    EndStr := Config.ReadString('Time', 'EndTime', '14:00');
    AbsEndStr := Config.ReadString('Time', 'AbsoluteEndTime', '16:00');

    StartTime := StrToTime(StartStr);
    EndTime := StrToTime(EndStr);
    AbsoluteEndTime := StrToTime(AbsEndStr);
  except
    on E: Exception do
      ShowMessage('Ошибка загрузки конфига: ' + E.Message);
  end;
  Config.Free;
end;

function TMainForm.ValidateEntry: Boolean;
var
  EntryTime: TTime;
  TodayTotal: Integer;
  DrinkType: string;
  Cups: Integer;
begin
  Result := False;

  if not TryStrToInt(edtCups.Text, Cups) or (Cups <= 0) then
  begin
    ShowMessage('Введите корректное количество чашек');
    Exit;
  end;

  EntryTime := edtTime.Time;
  if (EntryTime < StartTime) or (EntryTime > AbsoluteEndTime) then
  begin
      if MessageDlg('Предупреждение',
       Format('Время приема должно быть между %s и %s',[TimeToStr(StartTime), TimeToStr(AbsoluteEndTime)]),
       mtWarning, [mbYes, mbNo], 0) = mrNo then
      Exit;
  end;

  if (EntryTime > EndTime) and (EntryTime <= AbsoluteEndTime) then
  begin
    if MessageDlg('Предупреждение',
       Format('Время после %s. Вы уверены, что хотите выпить кофеин?', [TimeToStr(EndTime)]),
       mtWarning, [mbYes, mbNo], 0) = mrNo then
      Exit;
  end;

  DrinkType := cbDrinkType.Text;
  TodayTotal := GetTodayTotal(DrinkType);

  case DrinkType of
    'coffee':
      if TodayTotal + Cups > MaxCoffee then
      begin
        ShowMessage(Format('Превышен дневной лимит кофе! Максимум: %d', [MaxCoffee]));
      end;
    'black tea':
      if TodayTotal + Cups > MaxBlackTea then
      begin
        ShowMessage(Format('Превышен дневной лимит черного чая! Максимум: %d', [MaxBlackTea]));
      end;
    'green tea':
      if TodayTotal + Cups > MaxGreenTea then
      begin
        ShowMessage(Format('Превышен дневной лимит зеленого чая! Максимум: %d', [MaxGreenTea]));
      end;
  end;

  Result := True;
end;

function TMainForm.GetTodayTotal(drinkType: string): Integer;
var
  Lines: TStringList;
  Line: string;
  Today: TDateTime;
  EntryDate: TDateTime;
  EntryDrink: string;
  EntryCups: Integer;
  i, ColonPos: Integer;
begin
  Result := 0;
  Today := Trunc(edtDate.Date);

  if not FileExists(DataFile) then
    Exit;

  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(DataFile);

    for i := 0 to Lines.Count - 1 do
    begin
      Line := Lines[i];
      if Line = '' then Continue;

      if (Length(Line) > 20) and (Line[1] = '[') then
      begin
        ColonPos := Pos('] :', Line);
        if ColonPos > 0 then
        begin
          try
            EntryDate := ScanDateTime('DD-MM-YYYY HH:NN', Copy(Line, 2, 16));

            if Trunc(EntryDate) = Today then
            begin
              EntryCups := StrToIntDef(Trim(Copy(Line, ColonPos + 4, 2)), 0);
              EntryDrink := Trim(Copy(Line, ColonPos + 7, Length(Line)));

              if EntryDrink = drinkType then
                Result := Result + EntryCups;
            end;
          except
            // Игнорируем строки с ошибками парсинга
          end;
        end;
      end;
    end;
  finally
    Lines.Free;
  end;
end;

procedure TMainForm.SaveEntry;
var
  LogFile: TextFile;
  LogLine: string;
begin
  AssignFile(LogFile, DataFile);

  if FileExists(DataFile) then
    Append(LogFile)
  else
    Rewrite(LogFile);

  try
    LogLine := Format('[%s %s] : %s %s',
      [FormatDateTime('DD-MM-YYYY', edtDate.Date),
       FormatDateTime('HH:NN', edtTime.Time),
       edtCups.Text,
       cbDrinkType.Text]);

    WriteLn(LogFile, LogLine);
    MemoLog.Lines.Add(LogLine);
  finally
    CloseFile(LogFile);
  end;

  edtCups.Text := '';
  edtCups.SetFocus;
end;



initialization
  {$I unit1.lrs}

end.


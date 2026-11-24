; ===========================================================================
;  «Steam па-беларуску by Dzed Ahey» - усталёўшчык плагіна для Millennium.
;
;  Збіраць уручную не трэба: «Собрать плагин.bat» сам выклікае
;  Inno Setup (ISCC.exe) і кладзе гатовы архіў з усталёўшчыкам у build\release.
;  Калі трэба сабраць асобна - адкрыць гэты файл у Inno Setup і Ctrl+F9
;  (плагін build\plugin\by.dzedahey.steam-be.star павінен быць ужо сабраны).
;
;  Што робіць усталёўшчык:
;    - знаходзіць папку Steam і папку Millennium (<Steam>\millennium);
;    - кладзе файл плагіна ў <Millennium>\plugins;
;    - уключае плагін у наладах Millennium (config\config.json,
;      спіс enabledPlugins; старая копія налад - config.json.bak-steam-be);
;    - пры выдаленні сцірае файл плагіна.
;  Steam падчас усталявання павінен быць закрыты: ён перазапісвае налады
;  Millennium пры выхадзе.
; ===========================================================================

#ifndef AppVersion
  #define AppVersion "0.6.1"
#endif
#ifndef StarFile
  #define StarFile SourcePath + "..\..\build\plugin\by.dzedahey.steam-be.star"
#endif
#ifndef OutDir
  #define OutDir SourcePath + "..\..\build\release"
#endif
#ifndef OutName
  #define OutName "Steam_pa-belarusku_v" + AppVersion
#endif

#define AppName      "Steam па-беларуску by Dzed Ahey"
#define AppPublisher "Dzed Ahey"
#define PluginId     "by.dzedahey.steam-be"

#if !FileExists(StarFile)
  #error Не знойдзены build\plugin\by.dzedahey.steam-be.star. Спачатку запусці «Собрать плагин.bat».
#endif

[Setup]
AppId={{6B0E8C3A-2D51-4C7F-9A1E-DA2E5D1A4E79}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL=https://t.me/Dzed_Ahey
AppCopyright=© Dzed Ahey
VersionInfoVersion={#AppVersion}
VersionInfoCopyright=© Dzed Ahey
VersionInfoDescription={#AppName} - пераклад Steam
OutputDir={#OutDir}
OutputBaseFilename={#OutName}
DefaultDirName={code:GetDefaultDir}
AppendDefaultDirName=no
DirExistsWarning=no
UsePreviousAppDir=yes
DisableProgramGroupPage=yes
; Правы адміністратара: Steam звычайна стаіць у Program Files, куды без іх нельга нічога пакласці.
; Усталёўшчык піша толькі файл плагіна і config.json Millennium — больш нічога ў сістэме не мяняе.
PrivilegesRequired=admin
UninstallFilesDir={app}\_pa-belarusku-steam
UninstallDisplayName={#AppName}
WizardStyle=modern
Compression=lzma2/max
SolidCompression=yes
CloseApplications=no

[Languages]
Name: "be"; MessagesFile: "Belarusian.isl"; InfoBeforeFile: "info_be.txt"
Name: "ru"; MessagesFile: "compiler:Languages\Russian.isl"; InfoBeforeFile: "info_ru.txt"

[CustomMessages]
be.SelectSteam=Выберыце папку, у якую ўсталяваны Steam (там ляжыць файл steam.exe).
ru.SelectSteam=Выберите папку, в которую установлен Steam (там лежит файл steam.exe).
be.NotSteamDir=У выбранай папцы не знойдзены Steam (няма файла steam.exe).%n%nВыберыце папку, у якую ўсталяваны Steam, напрыклад:%nC:\Program Files (x86)\Steam
ru.NotSteamDir=В выбранной папке не найден Steam (нет файла steam.exe).%n%nВыберите папку, в которую установлен Steam, например:%nC:\Program Files (x86)\Steam
be.NoMillennium=Не знойдзены Millennium - праграма, праз якую працуе плагін.%n%nСпачатку ўсталюйце Millennium з сайта https://steambrew.app (падрабязна - у інструкцыі), а потым запусціце гэты ўсталёўшчык зноў.%n%nУсё роўна ўсталяваць плагін?
ru.NoMillennium=Не найден Millennium - программа, через которую работает плагин.%n%nСначала установите Millennium с сайта https://steambrew.app (подробно - в инструкции), а потом запустите этот установщик снова.%n%nВсё равно установить плагин?
be.CloseSteam=Steam зараз запушчаны. Закрыйце яго цалкам (у Steam: меню Steam → Выйсці) і націсніце OK.
ru.CloseSteam=Steam сейчас запущен. Закройте его полностью (в Steam: меню Steam → Выход) и нажмите OK.
be.EnableManually=Плагін усталяваны, але ўключыць яго аўтаматычна не ўдалося.%n%nЗапусціце Steam, адкрыйце налады Millennium, раздзел Plugins, і ўключыце «{#AppName}».
ru.EnableManually=Плагин установлен, но включить его автоматически не удалось.%n%nЗапустите Steam, откройте настройки Millennium, раздел Plugins, и включите «{#AppName}».
be.Done=Плагін «{#AppName}» усталяваны і ўключаны.%n%nЗапусціце Steam. Пераклад працуе, калі мова Steam - руская, украінская, англійская або польская (Steam → Налады → Інтэрфейс → Мова). Найлепш выбраць рускую.
ru.Done=Плагин «{#AppName}» установлен и включён.%n%nЗапустите Steam. Перевод работает, если язык Steam - русский, украинский, английский или польский (Steam → Настройки → Интерфейс → Язык). Лучше всего выбрать русский.

[Files]
Source: "{#StarFile}"; DestDir: "{code:PluginsDir}"; DestName: "{#PluginId}.star"; Flags: ignoreversion overwritereadonly

[Code]
const
  PLUGIN_ID = '{#PluginId}';

var
  EnabledOK: Boolean;

function IsSteamDir(const Dir: String): Boolean;
begin
  Result := (Dir <> '') and FileExists(AddBackslash(Dir) + 'steam.exe');
end;

function SlashesToBackslashes(S: String): String;
begin
  StringChangeEx(S, '/', '\', True);
  Result := S;
end;

function FindSteamDir: String;
var
  S: String;
begin
  if RegQueryStringValue(HKCU, 'Software\Valve\Steam', 'SteamPath', S) then
  begin
    S := SlashesToBackslashes(S);
    if IsSteamDir(S) then begin Result := S; Exit; end;
  end;
  if RegQueryStringValue(HKLM32, 'SOFTWARE\Valve\Steam', 'InstallPath', S) then
    if IsSteamDir(S) then begin Result := S; Exit; end;
  if IsWin64 then
    if RegQueryStringValue(HKLM64, 'SOFTWARE\Valve\Steam', 'InstallPath', S) then
      if IsSteamDir(S) then begin Result := S; Exit; end;
  Result := ExpandConstant('{commonpf32}\Steam');
end;

function GetDefaultDir(Param: String): String;
begin
  Result := FindSteamDir;
end;

// Папка Millennium: звычайна <Steam>\millennium; у новых версіях можа быць %LOCALAPPDATA%\Millennium
function MillDirFor(const Dir: String): String;
begin
  Result := AddBackslash(Dir) + 'millennium';
  if DirExists(Result) then Exit;
  if DirExists(ExpandConstant('{localappdata}\Millennium')) then
  begin
    Result := ExpandConstant('{localappdata}\Millennium');
    Exit;
  end;
  Result := AddBackslash(Dir) + 'millennium';
end;

function HasMillennium(const Dir: String): Boolean;
begin
  Result := DirExists(AddBackslash(Dir) + 'millennium') or
            DirExists(ExpandConstant('{localappdata}\Millennium'));
end;

function PluginsDir(Param: String): String;
begin
  Result := MillDirFor(WizardDirValue) + '\plugins';
end;

function SteamRunning: Boolean;
var
  Tmp, T: String;
  S: AnsiString;
  RC: Integer;
begin
  Result := False;
  Tmp := ExpandConstant('{tmp}\steamcheck.txt');
  if Exec(ExpandConstant('{cmd}'), '/C tasklist /FI "IMAGENAME eq steam.exe" /NH > "' + Tmp + '"',
          '', SW_HIDE, ewWaitUntilTerminated, RC) then
    if LoadStringFromFile(Tmp, S) then
    begin
      T := S;
      Result := Pos('steam.exe', Lowercase(T)) > 0;
    end;
end;

// Дадае плагін у спіс уключаных у наладах Millennium.
// Шукаем менавіта масіў "enabledPlugins": [ ... ] і правяраем ID толькі ўнутры яго
// (ID можа сустракацца і ў іншых частках файла — напрыклад, у наладах самога плагіна).
// Запіс: копія налад -> новы файл побач -> праверка -> замена. Пры памылцы налады не чапаем.
function EnableInConfig(const Mill: String): Boolean;
var
  Cfg, Bak, Tmp, C: String;
  S, Arr, Ins, Chk: AnsiString;
  P, Q, E, L: Integer;
  InStr, Esc: Boolean;
begin
  Result := False;
  Cfg := Mill + '\config\config.json';
  Bak := Cfg + '.bak-steam-be';
  Tmp := Cfg + '.tmp-steam-be';
  if not LoadStringFromFile(Cfg, S) then Exit;
  P := Pos('"enabledPlugins"', S);
  if P = 0 then Exit;
  // пачатак масіва: першы '[' пасля ключа (паміж імі могуць быць толькі прабелы і ':')
  Q := P + Length('"enabledPlugins"');
  while (Q <= Length(S)) and (Copy(S, Q, 1) <> '[') do
  begin
    C := Copy(S, Q, 1);
    if (C <> ' ') and (C <> ':') and (C <> #9) and (C <> #13) and (C <> #10) then Exit;
    Q := Q + 1;
  end;
  if Q > Length(S) then Exit;
  // канец масіва: першы ']' па-за радкамі ў двукоссі
  E := Q + 1; InStr := False; Esc := False;
  while E <= Length(S) do
  begin
    C := Copy(S, E, 1);
    if InStr then
    begin
      if Esc then Esc := False
      else if C = '\' then Esc := True
      else if C = '"' then InStr := False;
    end
    else if C = '"' then InStr := True
    else if C = ']' then Break;
    E := E + 1;
  end;
  if E > Length(S) then Exit;
  Arr := Copy(S, Q + 1, E - Q - 1);
  if Pos('"' + PLUGIN_ID + '"', Arr) > 0 then begin Result := True; Exit; end;
  // масіў пусты (толькі прабелы)?
  L := 1;
  while (L <= Length(Arr)) and ((Copy(Arr, L, 1) = ' ') or (Copy(Arr, L, 1) = #9) or (Copy(Arr, L, 1) = #13) or (Copy(Arr, L, 1) = #10)) do
    L := L + 1;
  if L > Length(Arr) then
    Ins := '"' + PLUGIN_ID + '"'
  else
    Ins := '"' + PLUGIN_ID + '",';
  S := Copy(S, 1, Q) + Ins + Copy(S, Q + 1, Length(S) - Q);
  // 1) рэзервовая копія; не атрымалася — нічога не мяняем
  if not CopyFile(Cfg, Bak, False) then Exit;
  // 2) новы файл побач і праверка, што ён запісаўся цалкам
  if not SaveStringToFile(Tmp, S, False) then begin DeleteFile(Tmp); Exit; end;
  if not LoadStringFromFile(Tmp, Chk) then begin DeleteFile(Tmp); Exit; end;
  if Chk <> S then begin DeleteFile(Tmp); Exit; end;
  // 3) замена старога файла новым; калі не выйшла — аднаўляем з копіі
  if not DeleteFile(Cfg) then begin DeleteFile(Tmp); Exit; end;
  if RenameFile(Tmp, Cfg) then
    Result := True
  else
    CopyFile(Bak, Cfg, False);
end;

procedure InitializeWizard;
begin
  WizardForm.SelectDirLabel.Caption := CustomMessage('SelectSteam');
  if not IsSteamDir(WizardForm.DirEdit.Text) then
    WizardForm.DirEdit.Text := FindSteamDir;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  if CurPageID = wpSelectDir then
  begin
    if not IsSteamDir(WizardDirValue) then
    begin
      MsgBox(CustomMessage('NotSteamDir'), mbError, MB_OK);
      Result := False;
      Exit;
    end;
    if not HasMillennium(WizardDirValue) then
      if MsgBox(CustomMessage('NoMillennium'), mbConfirmation, MB_YESNO) = IDNO then
      begin
        Result := False;
        Exit;
      end;
  end;
  if CurPageID = wpReady then
    while SteamRunning do
      if MsgBox(CustomMessage('CloseSteam'), mbInformation, MB_OKCANCEL) = IDCANCEL then
      begin
        Result := False;
        Exit;
      end;
end;

// Апошняя праверка (працуе і пры ціхім усталяванні)
function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  Result := '';
  if not IsSteamDir(ExpandConstant('{app}')) then
    Result := CustomMessage('NotSteamDir')
  else if SteamRunning then
    Result := CustomMessage('CloseSteam');
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    EnabledOK := EnableInConfig(MillDirFor(ExpandConstant('{app}')));
    if (not EnabledOK) and (not WizardSilent) then
      MsgBox(CustomMessage('EnableManually'), mbInformation, MB_OK);
  end;
end;

procedure CurPageChanged(CurPageID: Integer);
begin
  if (CurPageID = wpFinished) and EnabledOK then
    WizardForm.FinishedLabel.Caption := CustomMessage('Done');
end;

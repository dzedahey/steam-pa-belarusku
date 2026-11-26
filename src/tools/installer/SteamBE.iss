; ===========================================================================
;  «Steam па-беларуску by Dzed Ahey» - усталёўшчык плагіна для Millennium.
;
;  Збіраць уручную не трэба: «Собрать плагин.bat» сам выклікае
;  Inno Setup (ISCC.exe) і кладзе гатовы архіў з усталёўшчыкам у build\github.
;  Калі трэба сабраць асобна - адкрыць гэты файл у Inno Setup і Ctrl+F9
;  (плагін build\plugin\by.dzedahey.steam-be.star павінен быць ужо сабраны).
;
;  Што робіць усталёўшчык:
;    - знаходзіць папку Steam і папку Millennium (<Steam>\millennium);
;    - калі Millennium няма — прапануе спампаваць афіцыйны ўсталёўшчык Millennium
;      (github.com/SteamClientHomebrew/Installer, зафіксаваны выпуск), правярае
;      SHA-256 і лічбавы подпіс (SignPath) і запускае; інакш нічога не запускае;
;    - запамінае выбар аўтаабнаўлення (%LOCALAPPDATA%\SteamBE\settings.txt карыстальніка);
;    - пры выдаленні па жаданні запускае ўсталёўшчык Millennium для яго выдалення.
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

; Зафіксаваны афіцыйны ўсталёўшчык Millennium (адрас канкрэтнага выпуску + SHA-256).
; Сборшчык (build_plugin.py) кожны раз бярэ апошні выпуск SteamClientHomebrew/Installer, правярае
; SHA-256 і лічбавы подпіс і перадае іх сюды; значэнні ніжэй — толькі для ручной зборкі.
#ifndef MillUrl
  #define MillUrl "https://github.com/SteamClientHomebrew/Installer/releases/download/v1.12.1/MillenniumInstaller-Windows.exe"
#endif
#ifndef MillSha256
  #define MillSha256 "1a3baf49f20c321bdcc9421f5b7aab8c1e8a33792c93086463d148b502c1be3d"
#endif

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
be.AskMillTitle=Не знойдзены Millennium
be.AskMillennium=Millennium — праграма, праз якую працуе пераклад. Усталёўшчык можа спампаваць афіцыйны ўсталёўшчык Millennium з GitHub (github.com/SteamClientHomebrew/Installer), праверыць яго кантрольную суму і лічбавы подпіс і запусціць. Файл захаваецца ў часовую папку і будзе выдалены адразу пасля ўсталявання.
be.AskMillYes=Так, усталяваць Millennium%nСпампаваць яго ўсталёўшчык у часовую папку і запусціць
be.AskMillNo=Не, толькі пераклад%nMillennium вы ўсталюеце самі
be.BtnYes=Так
be.BtnNo=Не
be.BtnCancel=Скасаваць
ru.AskMillTitle=Не найден Millennium
ru.AskMillennium=Millennium — программа, через которую работает перевод. Установщик может скачать официальный установщик Millennium с GitHub (github.com/SteamClientHomebrew/Installer), проверить его контрольную сумму и цифровую подпись и запустить. Файл сохранится во временную папку и будет удалён сразу после установки.
ru.AskMillYes=Да, установить Millennium%nСкачать его установщик во временную папку и запустить
ru.AskMillNo=Нет, только перевод%nMillennium вы установите сами
ru.BtnYes=Да
ru.BtnNo=Нет
ru.BtnCancel=Отмена
be.MillDownloadFail=Не ўдалося спампаваць усталёўшчык Millennium:%n%1%n%nПраверце злучэнне з інтэрнэтам і паспрабуйце зноў або ўсталюйце Millennium самі з сайта https://steambrew.app
ru.MillDownloadFail=Не удалось скачать установщик Millennium:%n%1%n%nПроверьте подключение к интернету и попробуйте снова или установите Millennium сами с сайта https://steambrew.app
be.MillBadSig=Спампаваны ўсталёўшчык Millennium не прайшоў праверку (кантрольная сума або лічбавы подпіс), таму ён НЕ запушчаны.%n%nУсталюйце Millennium самі з афіцыйнага сайта https://steambrew.app і запусціце гэты ўсталёўшчык зноў.
ru.MillBadSig=Скачанный установщик Millennium не прошёл проверку (контрольная сумма или цифровая подпись), поэтому он НЕ запущен.%n%nУстановите Millennium сами с официального сайта https://steambrew.app и запустите этот установщик снова.
be.MillRun=Зараз адкрыецца ўсталёўшчык Millennium. Прайдзіце ўсе яго крокі і закрыйце яго — пасля гэтага ўсталяванне перакладу працягнецца.%n%nКалі ўсталёўшчык Millennium прапануе запусціць Steam — пакуль не запускайце.
ru.MillRun=Сейчас откроется установщик Millennium. Пройдите все его шаги и закройте его — после этого установка перевода продолжится.%n%nЕсли установщик Millennium предложит запустить Steam — пока не запускайте.
be.MillStillMissing=Millennium так і не знойдзены ў папцы Steam.%n%nУсё роўна ўсталяваць пераклад? Ён запрацуе, калі потым усталяваць Millennium.
ru.MillStillMissing=Millennium так и не найден в папке Steam.%n%nВсё равно установить перевод? Он заработает, когда вы потом установите Millennium.
be.AutoUpdateTask=Аўтаматычна абнаўляць пераклад (з праверкай подпісу аўтара; змяніць можна потым у наладах плагіна)
ru.AutoUpdateTask=Автоматически обновлять перевод (с проверкой подписи автора; изменить можно потом в настройках плагина)
be.UnAskMillTitle=Выдаліць таксама Millennium?
be.UnAskMill=Пераклад выдалены. Millennium — праграма, праз якую працаваў пераклад, — пакуль застаецца на камп’ютары: ён можа быць патрэбны іншым плагінам і тэмам.%n%nКаб выдаліць і Millennium, трэба спампаваць з інтэрнэту яго афіцыйны ўсталёўшчык (github.com/SteamClientHomebrew/Installer). Гэта будзе зроблена аўтаматычна: файл захаваецца ў часовую папку, будуць правераны яго кантрольная сума і лічбавы подпіс, потым адкрыецца ўсталёўшчык Millennium — у ім выберыце выдаленне. Пасля гэтага спампаваны файл будзе выдалены.
be.UnAskMillYes=Так, выдаліць і Millennium%nСпампаваць яго ўсталёўшчык у часовую папку і запусціць
be.UnAskMillNo=Не, пакінуць Millennium
be.UnMillRun=Зараз адкрыецца ўсталёўшчык Millennium. Выберыце ў ім выдаленне і прайдзіце крокі. Пасля яго закрыцця спампаваны файл будзе выдалены.
be.UnMillDownloadFail=Не ўдалося спампаваць усталёўшчык Millennium, Millennium застаўся на камп’ютары.%n%nКаб выдаліць яго, спампуйце ўсталёўшчык з https://steambrew.app, запусціце і выберыце выдаленне.
be.UnMillBadSig=Спампаваны ўсталёўшчык Millennium не прайшоў праверку (кантрольная сума або лічбавы подпіс), таму ён НЕ запушчаны і выдалены. Millennium застаўся на камп’ютары.%n%nКаб выдаліць яго, спампуйце ўсталёўшчык з https://steambrew.app і выберыце выдаленне.
be.UnMillStill=Millennium усё яшчэ ўсталяваны. Каб выдаліць яго, запусціце ўсталёўшчык Millennium з https://steambrew.app і выберыце выдаленне.
ru.UnAskMillTitle=Удалить также Millennium?
ru.UnAskMill=Перевод удалён. Millennium — программа, через которую работал перевод, — пока остаётся на компьютере: он может быть нужен другим плагинам и темам.%n%nЧтобы удалить и Millennium, нужно скачать из интернета его официальный установщик (github.com/SteamClientHomebrew/Installer). Это будет сделано автоматически: файл сохранится во временную папку, будут проверены его контрольная сумма и цифровая подпись, затем откроется установщик Millennium — в нём выберите удаление. После этого скачанный файл будет удалён.
ru.UnAskMillYes=Да, удалить и Millennium%nСкачать его установщик во временную папку и запустить
ru.UnAskMillNo=Нет, оставить Millennium
ru.UnMillRun=Сейчас откроется установщик Millennium. Выберите в нём удаление и пройдите шаги. После его закрытия скачанный файл будет удалён.
ru.UnMillDownloadFail=Не удалось скачать установщик Millennium, Millennium остался на компьютере.%n%nЧтобы удалить его, скачайте установщик с https://steambrew.app, запустите и выберите удаление.
ru.UnMillBadSig=Скачанный установщик Millennium не прошёл проверку (контрольная сумма или цифровая подпись), поэтому он НЕ запущен и удалён. Millennium остался на компьютере.%n%nЧтобы удалить его, скачайте установщик с https://steambrew.app и выберите удаление.
ru.UnMillStill=Millennium всё ещё установлен. Чтобы удалить его, запустите установщик Millennium с https://steambrew.app и выберите удаление.
be.AutoSaveFail=Не ўдалося захаваць выбар аўтаабнаўлення. Пераклад усталяваны; змяніце выбар у наладах плагіна ў Millennium (старонка «Steam па-беларуску by Dzed Ahey»).
ru.AutoSaveFail=Не удалось сохранить выбор автообновления. Перевод установлен; измените выбор в настройках плагина в Millennium (страница «Steam па-беларуску by Dzed Ahey»).
be.MillExecFail=Не ўдалося запусціць усталёўшчык Millennium:%n%1
ru.MillExecFail=Не удалось запустить установщик Millennium:%n%1
be.UnMillLeft=Millennium выдалены. У папцы %1 засталіся іншыя файлы (налады Millennium, тэмы або плагіны) — пераклад іх не чапае. Калі яны не патрэбныя, выдаліце папку самі.
ru.UnMillLeft=Millennium удалён. В папке %1 остались другие файлы (настройки Millennium, темы или плагины) — перевод их не трогает. Если они не нужны, удалите папку сами.
be.CloseSteam=Steam зараз запушчаны. Закрыйце яго цалкам (у Steam: меню Steam → Выйсці) і націсніце OK.
ru.CloseSteam=Steam сейчас запущен. Закройте его полностью (в Steam: меню Steam → Выход) и нажмите OK.
be.EnableManually=Плагін усталяваны, але ўключыць яго аўтаматычна не ўдалося.%n%nЗапусціце Steam, адкрыйце налады Millennium, раздзел Plugins, і ўключыце «{#AppName}».
ru.EnableManually=Плагин установлен, но включить его автоматически не удалось.%n%nЗапустите Steam, откройте настройки Millennium, раздел Plugins, и включите «{#AppName}».
be.Done=Плагін «{#AppName}» усталяваны і ўключаны.%n%nЗапусціце Steam. Пераклад працуе, калі мова Steam - руская, украінская, англійская або польская (Steam → Налады → Інтэрфейс → Мова). Найлепш выбраць рускую.
ru.Done=Плагин «{#AppName}» установлен и включён.%n%nЗапустите Steam. Перевод работает, если язык Steam - русский, украинский, английский или польский (Steam → Настройки → Интерфейс → Язык). Лучше всего выбрать русский.

[Tasks]
Name: "autoupdate"; Description: "{cm:AutoUpdateTask}"

[Files]
Source: "{#StarFile}"; DestDir: "{code:PluginsDir}"; DestName: "{#PluginId}.star"; Flags: ignoreversion overwritereadonly

[UninstallDelete]
; дамп радкоў ранніх тэставых версій плагіна (0.5.x)
Type: filesandordirs; Name: "{app}\millennium\be_dump"

[Code]
const
  PLUGIN_ID = '{#PluginId}';
  // афіцыйны ўсталёўшчык Millennium (падпісаны праз SignPath)
  MILL_URL = '{#MillUrl}';
  MILL_SHA = '{#MillSha256}';
  MILL_EXE = 'MillenniumInstaller-Windows.exe';

var
  EnabledOK: Boolean;
  InstallMill: Boolean;
  AutoTaskInit: Boolean;
  DownloadPage: TDownloadWizardPage;

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

// Millennium сапраўды ўсталяваны: яго бібліятэка wsock32.dll у папцы Steam або яго папкі bin/lib.
// Адна толькі папка millennium не лічыцца: пасля выдалення Millennium у ёй застаюцца налады (config).
function MillInstalledIn(const Dir: String): Boolean;
begin
  Result := FileExists(AddBackslash(Dir) + 'wsock32.dll') or
            DirExists(AddBackslash(Dir) + 'millennium\bin') or
            DirExists(AddBackslash(Dir) + 'millennium\lib');
end;

// Папка Millennium: звычайна <Steam>\millennium; у новых версіях можа быць %LOCALAPPDATA%\Millennium
function MillDirFor(const Dir: String): String;
begin
  Result := AddBackslash(Dir) + 'millennium';
  if MillInstalledIn(Dir) then Exit;
  if DirExists(ExpandConstant('{localappdata}\Millennium')) then
  begin
    Result := ExpandConstant('{localappdata}\Millennium');
    Exit;
  end;
  Result := AddBackslash(Dir) + 'millennium';
end;

function HasMillennium(const Dir: String): Boolean;
begin
  Result := MillInstalledIn(Dir) or DirExists(ExpandConstant('{localappdata}\Millennium\bin')) or
            DirExists(ExpandConstant('{localappdata}\Millennium\lib'));
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
// Наступны не прабельны сімвал пачынаючы з пазіцыі I (або '' у канцы файла)
function NextNonSpace(const S: AnsiString; I: Integer): String;
begin
  Result := '';
  while I <= Length(S) do
  begin
    if (S[I] <> ' ') and (S[I] <> #9) and (S[I] <> #13) and (S[I] <> #10) then
    begin
      Result := S[I];
      Exit;
    end;
    I := I + 1;
  end;
end;

// Калі ў наладах яшчэ няма спіса "enabledPlugins" (свежы Millennium дадае яго толькі пасля першага
// ўключанага плагіна) — дадаём яго ў "plugins" або, калі няма і "plugins", у корань налад.
function AddEnabledList(var S: AnsiString): Boolean;
var
  P, Q: Integer;
  Ins: String;
begin
  Result := False;
  P := Pos('"plugins"', S);
  if P > 0 then
  begin
    Q := P + Length('"plugins"');
    while (Q <= Length(S)) and (S[Q] <> '{') do
    begin
      if (S[Q] <> ' ') and (S[Q] <> ':') and (S[Q] <> #9) and (S[Q] <> #13) and (S[Q] <> #10) then Exit;
      Q := Q + 1;
    end;
    if Q > Length(S) then Exit;
    Ins := '"enabledPlugins": ["' + PLUGIN_ID + '"]';
  end
  else
  begin
    Q := Pos('{', S);
    if Q = 0 then Exit;
    Ins := '"plugins": {"enabledPlugins": ["' + PLUGIN_ID + '"]}';
  end;
  if NextNonSpace(S, Q + 1) <> '}' then Ins := Ins + ',';
  S := Copy(S, 1, Q) + Ins + Copy(S, Q + 1, Length(S) - Q);
  Result := True;
end;

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
  if not FileExists(Cfg) then
  begin
    // свежаўсталяваны Millennium яшчэ не стварыў налады: кладзём мінімальныя (астатняе ён дапіша сам)
    ForceDirectories(Mill + '\config');
    Result := SaveStringToFile(Cfg, '{' + #13#10 + '  "plugins": {' + #13#10 + '    "enabledPlugins": [' + #13#10 +
                               '      "' + PLUGIN_ID + '"' + #13#10 + '    ]' + #13#10 + '  }' + #13#10 + '}' + #13#10, False);
    Exit;
  end;
  if not LoadStringFromFile(Cfg, S) then Exit;
  P := Pos('"enabledPlugins"', S);
  if P = 0 then
  begin
    if not AddEnabledList(S) then Exit;
  end
  else
  begin
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
  end;
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

// ---- PowerShell без падстаноўкі шляхоў у код ----
// Скрыпты фіксаваныя і кладуцца ў {tmp}; шляхі і хешы перадаюцца ім АРГУМЕНТАМІ ў двукоссі
// (у шляхах Windows двукоссяў не бывае), таму апостраф або іншыя сімвалы ў шляху не становяцца кодам.
function PowerShellExe: String;
begin
  Result := ExpandConstant('{sysnative}\WindowsPowerShell\v1.0\powershell.exe');
end;

// Запускае фіксаваны скрыпт Body з аргументамі Args. Вяртае код выхаду або -1, калі не запусціўся.
function RunPSScript(const Name, Body, Args: String): Integer;
var
  Script: String;
  RC: Integer;
begin
  Result := -1;
  Script := ExpandConstant('{tmp}\') + Name;
  if not SaveStringToFile(Script, Body, False) then Exit;
  if Exec(PowerShellExe, '-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' + Script + '" ' + Args,
          '', SW_HIDE, ewWaitUntilTerminated, RC) then
    Result := RC;
  DeleteFile(Script);
end;

// Файл — менавіта той усталёўшчык Millennium, які зафіксаваны ў гэтым выпуску перакладу:
// SHA-256 супадае з зафіксаваным, а лічбавы подпіс Authenticode сапраўдны (SignPath).
function MillFileOK(const FileName: String): Boolean;
begin
  Result := RunPSScript('steambe-check.ps1',
    'param([string]$Path, [string]$Sha)' + #13#10 +
    '$ErrorActionPreference = ''Stop''' + #13#10 +
    'try {' + #13#10 +
    '  if ((Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLower() -ne $Sha.ToLower()) { exit 2 }' + #13#10 +
    '  $s = Get-AuthenticodeSignature -LiteralPath $Path' + #13#10 +
    '  if ($s.Status -ne ''Valid'' -or $s.SignerCertificate.Subject -notmatch ''SignPath'') { exit 3 }' + #13#10 +
    '  exit 0' + #13#10 +
    '} catch { exit 1 }' + #13#10,
    '"' + FileName + '" "' + MILL_SHA + '"') = 0;
end;

// Спампоўка (для выдалення: у дэінсталятары няма старонкі спампоўкі Inno)
function DownloadFile(const Url, OutFile: String): Boolean;
begin
  Result := (RunPSScript('steambe-download.ps1',
    'param([string]$Url, [string]$Out)' + #13#10 +
    '$ErrorActionPreference = ''Stop''' + #13#10 +
    '$ProgressPreference = ''SilentlyContinue''' + #13#10 +
    'try {' + #13#10 +
    '  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12' + #13#10 +
    '  Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $Out' + #13#10 +
    '  exit 0' + #13#10 +
    '} catch { exit 1 }' + #13#10,
    '"' + Url + '" "' + OutFile + '"') = 0) and FileExists(OutFile);
end;

function WaitSteamClosed: Boolean;
begin
  Result := True;
  while SteamRunning do
    if TaskDialogMsgBox('', CustomMessage('CloseSteam'), mbInformation, MB_OKCANCEL, ['OK', CustomMessage('BtnCancel')], 0) = IDCANCEL then
    begin
      Result := False;
      Exit;
    end;
end;

// Спампоўка, праверка і запуск афіцыйнага ўсталёўшчыка Millennium. False — застаемся на старонцы.
function InstallMillennium: Boolean;
var
  Exe: String;
  RC: Integer;
  Ran: Boolean;
begin
  Result := False;
  Exe := ExpandConstant('{tmp}\') + MILL_EXE;
  DownloadPage.Clear;
  // трэці параметр — чаканы SHA-256: Inno сам правярае спампаваны файл
  DownloadPage.Add(MILL_URL, MILL_EXE, MILL_SHA);
  DownloadPage.Show;
  try
    try
      DownloadPage.Download;
    except
      DeleteFile(Exe);
      MsgBox(FmtMessage(CustomMessage('MillDownloadFail'), [GetExceptionMessage]), mbError, MB_OK);
      Exit;
    end;
  finally
    DownloadPage.Hide;
  end;
  try
    if not MillFileOK(Exe) then
    begin
      MsgBox(CustomMessage('MillBadSig'), mbError, MB_OK);
      Exit;
    end;
    MsgBox(CustomMessage('MillRun'), mbInformation, MB_OK);
    Ran := Exec(Exe, '', '', SW_SHOW, ewWaitUntilTerminated, RC);
  finally
    // спампаваны ўсталёўшчык Millennium выдаляецца адразу (а ўся {tmp} — пры выхадзе)
    DeleteFile(Exe);
  end;
  if not Ran then
  begin
    MsgBox(FmtMessage(CustomMessage('MillExecFail'), [SysErrorMessage(RC)]), mbError, MB_OK);
    Exit;
  end;
  // усталёўшчык Millennium мог запусціць Steam — перад усталяваннем перакладу ён павінен быць закрыты
  if not WaitSteamClosed then Exit;
  if HasMillennium(WizardDirValue) then
    Result := True
  else
    Result := TaskDialogMsgBox('', CustomMessage('MillStillMissing'), mbConfirmation, MB_YESNO, [CustomMessage('BtnYes'), CustomMessage('BtnNo')], 0) = IDYES;
end;

procedure InitializeWizard;
begin
  DownloadPage := CreateDownloadPage(SetupMessage(msgWizardPreparing), SetupMessage(msgPreparingDesc), nil);
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
    InstallMill := False;
    if not HasMillennium(WizardDirValue) then
      // (масіў не з пачатку радка: радок, які пачынаецца з «[», Inno лічыць назвай раздзела)
      case TaskDialogMsgBox(CustomMessage('AskMillTitle'), CustomMessage('AskMillennium'), mbConfirmation, MB_YESNOCANCEL, [
                              CustomMessage('AskMillYes'), CustomMessage('AskMillNo'), CustomMessage('BtnCancel')], 0) of
        IDYES: InstallMill := True;
        IDCANCEL: begin Result := False; Exit; end;
      end;
  end;
  if CurPageID = wpReady then
  begin
    Result := WaitSteamClosed;
    if Result and InstallMill and not HasMillennium(WizardDirValue) then
      Result := InstallMillennium;
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

// Налада аўтаабнаўлення: %LOCALAPPDATA%\SteamBE\settings.txt ТАГО карыстальніка, які запусціў усталёўшчык
// (а не адміністратара, чые ўліковыя даныя ўвялі ў акне UAC): PowerShell запускаецца ад яго імя
// (ExecAsOriginalUser) і сам бярэ свой LOCALAPPDATA — ніякіх шляхоў у камандзе няма.
// Код выхаду: 0 — запісана і праверана; інакш — не атрымалася.
function SaveAutoUpdate(const On: Boolean): Boolean;
var
  V, Cmd: String;
  RC: Integer;
begin
  if On then V := '1' else V := '0';
  Cmd := '-NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "' +
    '$ErrorActionPreference = ''Stop''; try { ' +
    '$d = Join-Path $env:LOCALAPPDATA ''SteamBE''; New-Item -ItemType Directory -Force -Path $d | Out-Null; ' +
    '$f = Join-Path $d ''settings.txt''; [IO.File]::WriteAllText($f + ''.tmp'', ''autoupdate=' + V + ''' + [char]13 + [char]10); ' +
    'Move-Item -Force -LiteralPath ($f + ''.tmp'') -Destination $f; ' +
    'if (([IO.File]::ReadAllText($f)).Trim() -eq ''autoupdate=' + V + ''') { exit 0 } else { exit 2 } ' +
    '} catch { exit 1 }"';
  Result := ExecAsOriginalUser(PowerShellExe, Cmd, '', SW_HIDE, ewWaitUntilTerminated, RC) and (RC = 0);
end;

// Ужо зроблены выбар (для пачатковага стану птушкі пры абнаўленні): 0 — выключана, 1 — уключана, -1 — невядома
function LoadAutoUpdate: Integer;
var
  Cmd: String;
  RC: Integer;
begin
  Result := -1;
  Cmd := '-NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "' +
    'try { $f = Join-Path $env:LOCALAPPDATA ''SteamBE\settings.txt''; ' +
    'if (Test-Path -LiteralPath $f) { $t = [IO.File]::ReadAllText($f); ' +
    'if ($t -match ''autoupdate=0'') { exit 10 }; if ($t -match ''autoupdate=1'') { exit 11 } } } catch { }; exit 0"';
  if ExecAsOriginalUser(PowerShellExe, Cmd, '', SW_HIDE, ewWaitUntilTerminated, RC) then
    if RC = 10 then Result := 0
    else if RC = 11 then Result := 1;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    if not SaveAutoUpdate(WizardIsTaskSelected('autoupdate')) and not WizardSilent then
      MsgBox(CustomMessage('AutoSaveFail'), mbError, MB_OK);
    EnabledOK := EnableInConfig(MillDirFor(ExpandConstant('{app}')));
    if (not EnabledOK) and (not WizardSilent) then
      MsgBox(CustomMessage('EnableManually'), mbInformation, MB_OK);
  end;
end;

procedure CurPageChanged(CurPageID: Integer);
var
  A: Integer;
begin
  // пры абнаўленні — пачынаем з таго выбару, які ўжо зроблены ў наладах плагіна
  if (CurPageID = wpSelectTasks) and not AutoTaskInit then
  begin
    AutoTaskInit := True;
    A := LoadAutoUpdate;
    if A = 0 then WizardSelectTasks('!autoupdate')
    else if A = 1 then WizardSelectTasks('autoupdate');
  end;
  if (CurPageID = wpFinished) and EnabledOK then
    WizardForm.FinishedLabel.Caption := CustomMessage('Done');
end;

// ---- Выдаленне Millennium разам з перакладам (па жаданні карыстальніка) ----
// Зафіксаваны афіцыйны ўсталёўшчык Millennium спампоўваецца ва ўнікальную часовую папку {tmp},
// правяраюцца SHA-256 і подпіс, ён запускаецца (карыстальнік выбірае ў ім выдаленне), потым файл выдаляецца.
// Самі файлы Millennium мы НЕ выдаляем: гэта робіць яго ўсталёўшчык. Прыбіраем толькі свае рэшткі.
procedure UninstallMillennium;
var
  App, Exe, Cfg: String;
  RC: Integer;
begin
  App := ExpandConstant('{app}');
  Exe := ExpandConstant('{tmp}\') + MILL_EXE;
  DeleteFile(Exe);
  if not DownloadFile(MILL_URL, Exe) then
  begin
    DeleteFile(Exe);
    MsgBox(CustomMessage('UnMillDownloadFail'), mbError, MB_OK);
    Exit;
  end;
  try
    if not MillFileOK(Exe) then
    begin
      MsgBox(CustomMessage('UnMillBadSig'), mbError, MB_OK);
      Exit;
    end;
    if not WaitSteamClosed then Exit;
    MsgBox(CustomMessage('UnMillRun'), mbInformation, MB_OK);
    if not Exec(Exe, '', '', SW_SHOW, ewWaitUntilTerminated, RC) then
    begin
      MsgBox(FmtMessage(CustomMessage('MillExecFail'), [SysErrorMessage(RC)]), mbError, MB_OK);
      Exit;
    end;
  finally
    DeleteFile(Exe);
  end;
  if HasMillennium(App) then
    MsgBox(CustomMessage('UnMillStill'), mbInformation, MB_OK)
  else
  begin
    // толькі нашы файлы (копія налад, зробленая пры ўключэнні плагіна) і пустыя папкі
    Cfg := AddBackslash(App) + 'millennium\config';
    DeleteFile(Cfg + '\config.json.bak-steam-be');
    DeleteFile(Cfg + '\config.json.tmp-steam-be');
    RemoveDir(Cfg);
    RemoveDir(AddBackslash(App) + 'millennium\plugins');
    RemoveDir(AddBackslash(App) + 'millennium');
    if DirExists(AddBackslash(App) + 'millennium') then
      MsgBox(FmtMessage(CustomMessage('UnMillLeft'), [AddBackslash(App) + 'millennium']), mbInformation, MB_OK);
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if (CurUninstallStep = usPostUninstall) and (not UninstallSilent) and HasMillennium(ExpandConstant('{app}')) then
    if TaskDialogMsgBox(CustomMessage('UnAskMillTitle'), CustomMessage('UnAskMill'), mbConfirmation, MB_YESNO, [
                          CustomMessage('UnAskMillYes'), CustomMessage('UnAskMillNo')], 0) = IDYES then
      UninstallMillennium;
end;

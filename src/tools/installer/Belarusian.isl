; *** Inno Setup version 7.1+ Belarusian messages ***
;
; Перакладзена з рускай/англійскай для ўсталёўшчыка «Вядзьмар па-беларуску».
;
; Note: When translating this text, do not add periods (.) to the end of
; messages that didn't have them already, because on those messages Inno
; Setup adds the periods automatically (appending a period would result in
; two periods being displayed).

[LangOptions]
LanguageName=Беларуская
LanguageID=$0423
LanguageCodePage=1251

[Messages]

; *** Application titles
SetupAppTitle=Усталяванне
SetupWindowTitle=Усталяванне — %1
UninstallAppTitle=Выдаленне
UninstallAppFullTitle=Выдаленне — %1

; *** Misc. common
InformationTitle=Інфармацыя
ConfirmTitle=Пацвярджэнне
ErrorTitle=Памылка

; *** SetupLdr messages
SetupLdrStartupMessage=Гэтая праграма ўсталюе %1 на ваш камп'ютар. Працягнуць?
LdrCannotCreateTemp=Немагчыма стварыць часовы файл. Усталяванне перапынена
LdrCannotExecTemp=Немагчыма выканаць файл у часовай папцы. Усталяванне перапынена
HelpTextNote=

; *** Startup error messages
LastErrorMessage=%1.%n%nПамылка %2: %3
SetupFileMissing=Файл %1 адсутнічае ў папцы ўсталявання. Калі ласка, выпраўце праблему або атрымайце новую копію праграмы.
SetupFileCorrupt=Файлы ўсталявання пашкоджаныя. Калі ласка, атрымайце новую копію праграмы.
SetupFileCorruptOrWrongVer=Файлы ўсталявання пашкоджаныя або несумяшчальныя з гэтай версіяй праграмы ўсталявання. Калі ласка, выпраўце праблему або атрымайце новую копію праграмы.
InvalidParameter=Камандны радок змяшчае недапушчальны параметр:%n%n%1
SetupAlreadyRunning=Праграма ўсталявання ўжо запушчана.
WindowsVersionNotSupported=Гэтая праграма не падтрымлівае версію Windows, усталяваную на гэтым камп'ютары.
WindowsServicePackRequired=Гэтай праграме патрэбны %1 Service Pack %2 або навейшы.
NotOnThisPlatform=Гэтая праграма не будзе працаваць у %1.
OnlyOnThisPlatform=Гэтую праграму можна запускаць толькі ў %1.
OnlyOnTheseArchitectures=Усталяваць гэтую праграму можна толькі ў версіях Windows для такіх архітэктур працэсара:%n%n%1
WinVersionTooLowError=Гэтай праграме патрэбна %1 версіі %2 або навейшай.
WinVersionTooHighError=Гэтую праграму нельга ўсталяваць у %1 версіі %2 або навейшай.
AdminPrivilegesRequired=Каб усталяваць гэтую праграму, трэба ўвайсці ў сістэму як адміністратар.
PowerUserPrivilegesRequired=Каб усталяваць гэтую праграму, трэба ўвайсці ў сістэму як адміністратар або ўдзельнік групы «Дасведчаныя карыстальнікі» (Power Users).
SetupAppRunningError=Выяўлена, што %1 зараз запушчана.%n%nКалі ласка, закрыйце ўсе яе вокны і націсніце «OK», каб працягнуць, або «Скасаваць», каб выйсці.
UninstallAppRunningError=Праграма выдалення выявіла, што %1 зараз запушчана.%n%nКалі ласка, закрыйце ўсе яе вокны і націсніце «OK», каб працягнуць, або «Скасаваць», каб выйсці.

; *** Startup questions
PrivilegesRequiredOverrideTitle=Выбар рэжыму ўсталявання
PrivilegesRequiredOverrideInstruction=Выберыце рэжым усталявання
PrivilegesRequiredOverrideText1=%1 можна ўсталяваць для ўсіх карыстальнікаў (патрэбныя правы адміністратара) або толькі для вас.
PrivilegesRequiredOverrideText2=%1 можна ўсталяваць толькі для вас або для ўсіх карыстальнікаў (патрэбныя правы адміністратара).
PrivilegesRequiredOverrideAllUsers=Усталяваць для &ўсіх карыстальнікаў
PrivilegesRequiredOverrideAllUsersRecommended=Усталяваць для &ўсіх карыстальнікаў (рэкамендуецца)
PrivilegesRequiredOverrideCurrentUser=Усталяваць толькі для &мяне
PrivilegesRequiredOverrideCurrentUserRecommended=Усталяваць толькі для &мяне (рэкамендуецца)

; *** Misc. errors
ErrorCreatingDir=Немагчыма стварыць папку "%1"
ErrorTooManyFilesInDir=Немагчыма стварыць файл у папцы "%1", бо ў ёй занадта шмат файлаў

; *** Setup common messages
ExitSetupTitle=Выхад з праграмы ўсталявання
ExitSetupMessage=Усталяванне не завершана. Калі вы выйдзеце зараз, праграма не будзе ўсталявана.%n%nЗавяршыць усталяванне можна, запусціўшы праграму ўсталявання пазней.%n%nВыйсці з праграмы ўсталявання?
AboutSetupMenuItem=&Пра праграму...
AboutSetupTitle=Пра праграму
AboutSetupMessage=%1, версія %2%n%3%n%nСайт %1:%n%4
AboutSetupNote=
TranslatorNote=Belarusian translation: Dzed Ahey

; *** Buttons
ButtonBack=< &Назад
ButtonNext=&Далей >
ButtonInstall=&Усталяваць
ButtonOK=OK
ButtonCancel=Скасаваць
ButtonYes=&Так
ButtonYesToAll=Так для &ўсіх
ButtonNo=&Не
ButtonNoToAll=Н&е для ўсіх
ButtonFinish=&Завяршыць
ButtonBrowse=&Агляд...
ButtonWizardBrowse=&Агляд...
ButtonNewFolder=&Стварыць папку

; *** "Select Language" dialog messages
SelectLanguageTitle=Выберыце мову ўсталявання
SelectLanguageLabel=Выберыце мову, якая будзе выкарыстоўвацца падчас усталявання.

; *** Common wizard text
ClickNext=Націсніце «Далей», каб працягнуць, або «Скасаваць», каб выйсці з праграмы ўсталявання.
BeveledLabel=
BrowseDialogTitle=Агляд папак
BrowseDialogLabel=Выберыце папку са спісу і націсніце «OK».
NewFolderName=Новая папка

; *** "Welcome" wizard page
WelcomeLabel1=Вас вітае майстар усталявання [name]
WelcomeLabel2=Праграма ўсталюе [name/ver] на ваш камп'ютар.%n%nПерад тым як працягнуць, рэкамендуецца закрыць усе іншыя праграмы.

; *** "Password" wizard page
WizardPassword=Пароль
PasswordLabel1=Гэтая праграма абаронена паролем.
PasswordLabel3=Калі ласка, увядзіце пароль і націсніце «Далей». Пароль адчувальны да рэгістра.
PasswordEditLabel=&Пароль:
IncorrectPassword=Уведзены пароль няправільны. Калі ласка, паспрабуйце яшчэ раз.

; *** "License Agreement" wizard page
WizardLicense=Ліцэнзійнае пагадненне
LicenseLabel=Калі ласка, перад тым як працягнуць, прачытайце наступную важную інфармацыю.
LicenseLabel3=Калі ласка, прачытайце наступнае ліцэнзійнае пагадненне. Каб працягнуць, трэба прыняць яго ўмовы.
LicenseAccepted=Я &прымаю ўмовы пагаднення
LicenseNotAccepted=Я &не прымаю ўмовы пагаднення

; *** "Information" wizard pages
WizardInfoBefore=Інфармацыя
InfoBeforeLabel=Калі ласка, перад тым як працягнуць, прачытайце наступную важную інфармацыю.
InfoBeforeClickLabel=Калі будзеце гатовыя працягнуць усталяванне, націсніце «Далей».
WizardInfoAfter=Інфармацыя
InfoAfterLabel=Калі ласка, перад тым як працягнуць, прачытайце наступную важную інфармацыю.
InfoAfterClickLabel=Калі будзеце гатовыя працягнуць, націсніце «Далей».

; *** "User Information" wizard page
WizardUserInfo=Звесткі пра карыстальніка
UserInfoDesc=Калі ласка, увядзіце звесткі пра сябе.
UserInfoName=&Імя карыстальніка:
UserInfoOrg=&Арганізацыя:
UserInfoSerial=&Серыйны нумар:
UserInfoNameRequired=Трэба ўвесці імя.

; *** "Select Destination Location" wizard page
WizardSelectDir=Выбар папкі ўсталявання
SelectDirDesc=У якую папку ўсталяваць [name]?
SelectDirLabel3=Праграма ўсталюе [name] у наступную папку.
SelectDirBrowseLabel=Націсніце «Далей», каб працягнуць. Каб выбраць іншую папку, націсніце «Агляд».
DiskSpaceGBLabel=Патрэбна не менш за [gb] ГБ вольнага месца на дыску.
DiskSpaceMBLabel=Патрэбна не менш за [mb] МБ вольнага месца на дыску.
CannotInstallToNetworkDrive=Усталяванне на сеткавы дыск немагчымае.
CannotInstallToUNCPath=Усталяванне ў папку па UNC-шляху немагчымае.
InvalidPath=Трэба ўказаць поўны шлях з літарай дыска, напрыклад:%n%nC:\APP%n%nабо ў фармаце UNC:%n%n\\імя_сервера\імя_рэсурсу
InvalidDrive=Выбраны дыск або сеткавы шлях не існуе ці недаступны. Калі ласка, выберыце іншы.
DiskSpaceWarningTitle=Не хапае месца на дыску
DiskSpaceWarning=Для ўсталявання патрэбна не менш за %1 КБ вольнага месца, а на выбраным дыску даступна толькі %2 КБ.%n%nУсё роўна працягнуць?
DirNameTooLong=Імя папкі або шлях да яе занадта доўгія.
InvalidDirName=Указанае імя папкі недапушчальнае.
BadDirName32=Імя папкі не можа змяшчаць такія сімвалы:%n%n%1
DirExistsTitle=Папка існуе
DirExists=Папка%n%n%1%n%nужо існуе. Усё роўна ўсталяваць у гэтую папку?
DirDoesntExistTitle=Папка не існуе
DirDoesntExist=Папка%n%n%1%n%nне існуе. Стварыць яе?

; *** "Select Components" wizard page
WizardSelectComponents=Выбар кампанентаў
SelectComponentsDesc=Якія кампаненты трэба ўсталяваць?
SelectComponentsLabel2=Адзначце кампаненты, якія хочаце ўсталяваць, і зніміце адзнакі з тых, што не патрэбныя. Калі будзеце гатовыя, націсніце «Далей».
FullInstallation=Поўнае ўсталяванне
; if possible don't translate 'Compact' as 'Minimal' (I mean 'Minimal' in your language)
CompactInstallation=Кампактнае ўсталяванне
CustomInstallation=Выбарачнае ўсталяванне
NoUninstallWarningTitle=Кампаненты ўжо ўсталяваныя
NoUninstallWarning=Праграма ўсталявання выявіла, што наступныя кампаненты ўжо ўсталяваныя на вашым камп'ютары:%n%n%1%n%nКалі зняць з іх адзнаку, яны не выдаляцца.%n%nПрацягнуць?
ComponentSize1=%1 КБ
ComponentSize2=%1 МБ
ComponentsDiskSpaceGBLabel=Для выбраных кампанентаў патрэбна не менш за [gb] ГБ на дыску.
ComponentsDiskSpaceMBLabel=Для выбраных кампанентаў патрэбна не менш за [mb] МБ на дыску.

; *** "Select Additional Tasks" wizard page
WizardSelectTasks=Выбар дадатковых задач
SelectTasksDesc=Якія дадатковыя задачы трэба выканаць?
SelectTasksLabel2=Выберыце дадатковыя задачы, якія трэба выканаць пры ўсталяванні [name], і націсніце «Далей»:

; *** "Select Start Menu Folder" wizard page
WizardSelectProgramGroup=Выбар папкі ў меню «Пуск»
SelectStartMenuFolderDesc=Дзе праграма ўсталявання павінна стварыць ярлыкі?
SelectStartMenuFolderLabel3=Праграма створыць ярлыкі ў наступнай папцы меню «Пуск».
SelectStartMenuFolderBrowseLabel=Націсніце «Далей», каб працягнуць. Каб выбраць іншую папку, націсніце «Агляд».
MustEnterGroupName=Трэба ўвесці імя папкі.
GroupNameTooLong=Імя папкі або шлях да яе занадта доўгія.
InvalidGroupName=Указанае імя папкі недапушчальнае.
BadGroupName=Імя папкі не можа змяшчаць такія сімвалы:%n%n%1
NoProgramGroupCheck2=&Не ствараць папку ў меню «Пуск»

; *** "Ready to Install" wizard page
WizardReady=Усё гатова да ўсталявання
ReadyLabel1=Праграма гатовая ўсталяваць [name] на ваш камп'ютар.
ReadyLabel2a=Націсніце «Усталяваць», каб працягнуць, або «Назад», каб праглядзець ці змяніць налады.
ReadyLabel2b=Націсніце «Усталяваць», каб працягнуць.
ReadyMemoUserInfo=Звесткі пра карыстальніка:
ReadyMemoDir=Папка ўсталявання:
ReadyMemoType=Тып усталявання:
ReadyMemoComponents=Выбраныя кампаненты:
ReadyMemoGroup=Папка ў меню «Пуск»:
ReadyMemoTasks=Дадатковыя задачы:

; *** TDownloadWizardPage wizard page and DownloadTemporaryFile
DownloadingLabel2=Спампоўка файлаў...
ButtonStopDownload=&Спыніць спампоўку
StopDownload=Вы сапраўды хочаце спыніць спампоўку?
ErrorDownloadAborted=Спампоўка перапынена
ErrorDownloadFailed=Памылка спампоўкі: %1 %2
ErrorDownloadSizeFailed=Памылка атрымання памеру: %1 %2
ErrorProgress=Памылка выканання: %1 з %2
ErrorFileSize=Няправільны памер файла: чакалася %1, атрымана %2

; *** TExtractionWizardPage wizard page and ExtractArchive
ExtractingLabel=Распакоўка файлаў...
ButtonStopExtraction=&Спыніць распакоўку
StopExtraction=Вы сапраўды хочаце спыніць распакоўку?
ErrorExtractionAborted=Распакоўка перапынена
ErrorExtractionFailed=Памылка распакоўкі: %1

; *** Archive extraction failure details
ArchiveIncorrectPassword=Няправільны пароль
ArchiveIsCorrupted=Архіў пашкоджаны
ArchiveUnsupportedFormat=Непадтрымліваемы фармат архіва

; *** "Preparing to Install" wizard page
WizardPreparing=Падрыхтоўка да ўсталявання
PreparingDesc=Праграма рыхтуецца ўсталяваць [name] на ваш камп'ютар.
PreviousInstallNotCompleted=Усталяванне або выдаленне папярэдняй праграмы не было завершана. Каб яго завяршыць, трэба перазапусціць камп'ютар.%n%nПасля перазапуску зноў запусціце праграму ўсталявання, каб усталяваць [name].
CannotContinue=Немагчыма працягнуць усталяванне. Націсніце «Скасаваць», каб выйсці.
ApplicationsFound=Наступныя праграмы выкарыстоўваюць файлы, якія трэба абнавіць. Рэкамендуецца дазволіць праграме ўсталявання аўтаматычна закрыць іх.
ApplicationsFound2=Наступныя праграмы выкарыстоўваюць файлы, якія трэба абнавіць. Рэкамендуецца дазволіць праграме ўсталявання аўтаматычна закрыць іх. Пасля ўсталявання праграма паспрабуе зноў іх запусціць.
CloseApplications=&Аўтаматычна закрыць гэтыя праграмы
DontCloseApplications=&Не закрываць гэтыя праграмы
ErrorCloseApplications=Не ўдалося аўтаматычна закрыць усе праграмы. Перад тым як працягнуць, рэкамендуецца закрыць усе праграмы, якія выкарыстоўваюць файлы, што трэба абнавіць.
PrepareToInstallNeedsRestart=Праграме ўсталявання трэба перазапусціць камп'ютар. Пасля перазапуску зноў запусціце праграму ўсталявання, каб завяршыць усталяванне [name].%n%nПеразапусціць зараз?

; *** "Installing" wizard page
WizardInstalling=Усталяванне
InstallingLabel=Калі ласка, пачакайце, пакуль [name] усталёўваецца на ваш камп'ютар.

; *** "Setup Completed" wizard page
FinishedHeadingLabel=Завяршэнне майстра ўсталявання [name]
FinishedLabelNoIcons=[name] усталявана на ваш камп'ютар.
FinishedLabel=[name] усталявана на ваш камп'ютар. Праграму можна запусціць праз створаныя ярлыкі.
ClickFinish=Націсніце «Завяршыць», каб выйсці з праграмы ўсталявання.
FinishedRestartLabel=Каб завяршыць усталяванне [name], трэба перазапусціць камп'ютар. Перазапусціць зараз?
FinishedRestartMessage=Каб завяршыць усталяванне [name], трэба перазапусціць камп'ютар.%n%nПеразапусціць зараз?
ShowReadmeCheck=Я хачу прачытаць файл README
YesRadio=&Так, перазапусціць камп'ютар зараз
NoRadio=&Не, я перазапушчу камп'ютар пазней
; used for example as 'Run MyProg.exe'
RunEntryExec=Запусціць %1
; used for example as 'View Readme.txt'
RunEntryShellExec=Праглядзець %1

; *** "Setup Needs the Next Disk" stuff
ChangeDiskTitle=Патрэбны наступны дыск
SelectDiskLabel2=Калі ласка, устаўце дыск %1 і націсніце «OK».%n%nКалі файлы з гэтага дыска знаходзяцца ў іншай папцы, чым паказана ніжэй, увядзіце правільны шлях або націсніце «Агляд».
PathLabel=&Шлях:
FileNotInDir2=Файл "%1" не знойдзены ў "%2". Калі ласка, устаўце правільны дыск або выберыце іншую папку.
SelectDirectoryLabel=Калі ласка, укажыце шлях да наступнага дыска.

; *** Installation phase messages
SetupAborted=Усталяванне не было завершана.%n%nКалі ласка, выпраўце праблему і запусціце ўсталяванне зноў.
AbortRetryIgnoreSelectAction=Выберыце дзеянне
AbortRetryIgnoreRetry=Паспрабаваць &зноў
AbortRetryIgnoreIgnore=&Ігнараваць памылку і працягнуць
AbortRetryIgnoreCancel=Скасаваць усталяванне
RetryCancelSelectAction=Выберыце дзеянне
RetryCancelRetry=Паспрабаваць &зноў
RetryCancelCancel=Скасаваць

; *** Installation status messages
StatusClosingApplications=Закрыццё праграм...
StatusCreateDirs=Стварэнне папак...
StatusExtractFiles=Распакоўка файлаў...
StatusDownloadFiles=Спампоўка файлаў...
StatusCreateIcons=Стварэнне ярлыкоў...
StatusCreateIniEntries=Стварэнне INI-запісаў...
StatusCreateRegistryEntries=Стварэнне запісаў у рэестры...
StatusRegisterFiles=Рэгістрацыя файлаў...
StatusSavingUninstall=Захаванне звестак для выдалення...
StatusRunProgram=Завяршэнне ўсталявання...
StatusRestartingApplications=Перазапуск праграм...
StatusRollback=Адкат змяненняў...

; *** Misc. errors
ErrorInternal2=Унутраная памылка: %1
ErrorFunctionFailedNoCode=%1: збой
ErrorFunctionFailed=%1: збой; код %2
ErrorFunctionFailedWithMessage=%1: збой; код %2.%n%3
ErrorExecutingProgram=Немагчыма выканаць файл:%n%1

; *** Registry errors
ErrorRegOpenKey=Памылка адкрыцця ключа рэестра:%n%1\%2
ErrorRegCreateKey=Памылка стварэння ключа рэестра:%n%1\%2
ErrorRegWriteKey=Памылка запісу ў ключ рэестра:%n%1\%2

; *** INI errors
ErrorIniEntry=Памылка стварэння запісу ў INI-файле "%1".

; *** File copying errors
FileAbortRetryIgnoreSkipNotRecommended=&Прапусціць гэты файл (не рэкамендуецца)
FileAbortRetryIgnoreIgnoreNotRecommended=&Ігнараваць памылку і працягнуць (не рэкамендуецца)
SourceIsCorrupted=Зыходны файл пашкоджаны
SourceDoesntExist=Зыходны файл "%1" не існуе
SourceVerificationFailed=Зыходны файл не прайшоў праверку: %1
VerificationSignatureDoesntExist=Файл подпісу "%1" не існуе
VerificationSignatureInvalid=Файл подпісу "%1" няправільны
VerificationKeyNotFound=Файл подпісу "%1" выкарыстоўвае невядомы ключ
VerificationFileNameIncorrect=Няправільнае імя файла
VerificationFileTagIncorrect=Няправільны тэг файла
VerificationFileSizeIncorrect=Няправільны памер файла
VerificationFileHashIncorrect=Няправільны хэш файла
ExistingFileReadOnly2=Немагчыма замяніць існуючы файл, бо ён пазначаны як «толькі для чытання».
ExistingFileReadOnlyRetry=&Зняць атрыбут «толькі для чытання» і паспрабаваць зноў
ExistingFileReadOnlyKeepExisting=&Пакінуць існуючы файл
ErrorReadingExistingDest=Пры спробе прачытаць існуючы файл адбылася памылка:
FileExistsSelectAction=Выберыце дзеянне
FileExists2=Файл ужо існуе.
FileExistsOverwriteExisting=&Замяніць існуючы файл
FileExistsKeepExisting=&Пакінуць існуючы файл
FileExistsOverwriteOrKeepAll=&Паўтараць гэта дзеянне для ўсіх наступных выпадкаў
ExistingFileNewerSelectAction=Выберыце дзеянне
ExistingFileNewer2=Існуючы файл навейшы за той, што ўсталёўваецца.
ExistingFileNewerOverwriteExisting=&Замяніць існуючы файл
ExistingFileNewerKeepExisting=&Пакінуць існуючы файл (рэкамендуецца)
ExistingFileNewerOverwriteOrKeepAll=&Паўтараць гэта дзеянне для ўсіх наступных выпадкаў
ErrorChangingAttr=Пры спробе змяніць атрыбуты існуючага файла адбылася памылка:
ErrorCreatingTemp=Пры спробе стварыць файл у папцы ўсталявання адбылася памылка:
ErrorReadingSource=Пры спробе прачытаць зыходны файл адбылася памылка:
ErrorCopying=Пры спробе скапіяваць файл адбылася памылка:
ErrorDownloading=Пры спробе спампаваць файл адбылася памылка:
ErrorExtracting=Пры спробе распакаваць архіў адбылася памылка:
ErrorReplacingExistingFile=Пры спробе замяніць існуючы файл адбылася памылка:
ErrorRestartReplace=Памылка RestartReplace:
ErrorRenamingTemp=Пры спробе перайменаваць файл у папцы ўсталявання адбылася памылка:
ErrorRegisterServer=Немагчыма зарэгістраваць DLL/OCX: %1
ErrorRegSvr32Failed=Памылка выканання RegSvr32, код вяртання %1
ErrorRegisterTypeLib=Немагчыма зарэгістраваць бібліятэку тыпаў: %1

; *** Uninstall display name markings
; used for example as 'My Program (32-bit)'
UninstallDisplayNameMark=%1 (%2)
; used for example as 'My Program (32-bit, All users)'
UninstallDisplayNameMarks=%1 (%2, %3)
UninstallDisplayNameMark32Bit=32 біты
UninstallDisplayNameMark64Bit=64 біты
UninstallDisplayNameMarkAllUsers=Усе карыстальнікі
UninstallDisplayNameMarkCurrentUser=Бягучы карыстальнік

; *** Post-installation errors
ErrorOpeningReadme=Пры спробе адкрыць файл README адбылася памылка.
ErrorRestartingComputer=Праграме ўсталявання не ўдалося перазапусціць камп'ютар. Калі ласка, зрабіце гэта самастойна.

; *** Uninstaller messages
UninstallNotFound=Файл "%1" не існуе. Выдаленне немагчымае.
UninstallOpenError=Немагчыма адкрыць файл "%1". Выдаленне немагчымае
UninstallUnsupportedVer=Файл журнала выдалення "%1" мае фармат, які гэтая версія праграмы выдалення не распазнае. Выдаленне немагчымае
UninstallUnknownEntry=У журнале выдалення сустрэўся невядомы запіс (%1)
ConfirmUninstall=Вы сапраўды хочаце выдаліць %1 і ўсе яе кампаненты?
UninstallOnlyOnWin64=Выдаліць гэтую праграму можна толькі ў 64-бітнай Windows.
OnlyAdminCanUninstall=Выдаліць гэтую праграму можа толькі карыстальнік з правамі адміністратара.
UninstallStatusLabel=Калі ласка, пачакайце, пакуль %1 выдаляецца з вашага камп'ютара.
UninstalledAll=%1 цалкам выдалена з вашага камп'ютара.
UninstalledMost=Выдаленне %1 завершана.%n%nНекаторыя элементы не ўдалося выдаліць. Іх можна выдаліць уручную.
UninstalledAndNeedsRestart=Каб завяршыць выдаленне %1, трэба перазапусціць камп'ютар.%n%nПеразапусціць зараз?
UninstallDataCorrupted=Файл "%1" пашкоджаны. Выдаленне немагчымае

; *** Uninstallation phase messages
ConfirmDeleteSharedFileTitle=Выдаліць агульны файл?
ConfirmDeleteSharedFile2=Сістэма паказвае, што наступны агульны файл больш не выкарыстоўваецца іншымі праграмамі. Выдаліць яго?%n%nКалі нейкія праграмы яшчэ выкарыстоўваюць гэты файл, пасля выдалення яны могуць працаваць няправільна. Калі вы не ўпэўненыя, выберыце «Не». Пакінуты файл не пашкодзіць сістэме.
SharedFileNameLabel=Імя файла:
SharedFileLocationLabel=Размяшчэнне:
WizardUninstalling=Стан выдалення
StatusUninstalling=Выдаленне %1...

; *** Shutdown block reasons
ShutdownBlockReasonInstallingApp=Усталяванне %1.
ShutdownBlockReasonUninstallingApp=Выдаленне %1.

; The custom messages below aren't used by Setup itself, but if you make
; use of them in your scripts, you'll want to translate them.

[CustomMessages]

NameAndVersion=%1, версія %2
AdditionalIcons=Дадатковыя значкі:
CreateDesktopIcon=Стварыць значок на &Працоўным стале
CreateQuickLaunchIcon=Стварыць значок на панэлі &хуткага запуску
ProgramOnTheWeb=Сайт %1 у Інтэрнэце
UninstallProgram=Выдаліць %1
LaunchProgram=Запусціць %1
AssocFileExtension=&Звязаць %1 з файламі з пашырэннем %2
AssocingFileExtension=Звязванне %1 з файламі %2...
AutoStartProgramGroupDescription=Аўтазапуск:
AutoStartProgram=Аўтаматычна запускаць %1
AddonHostProgramNotFound=%1 не знойдзена ў выбранай папцы.%n%nУсё роўна працягнуць?

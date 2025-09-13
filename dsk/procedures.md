--- >

## [pn] New Account (Нов акаунт)
### [kw] Keywords: New Account; Нов акаунт; new user; onboarding; онбординг; нов служител; назначаване
#### [id] PR000001

### [pr] Procedure
- Проверете името на ENG в AD.
- Ако има съвпадение на име: обновете Display Name и Full Name, добавяйки суфикс (напр. - Department Name).
- IDM > Work Items > Approvals – намерете ID и Approve.
- Ако не намирате: изпратете имейл с поръчката (Remedy) до Tsvetelin.Tsvetanov@dskbank.bg.
- Ако няма съвпадение в AD: одобрете в IDM > Approve.

### [ext] AD конфигурация
- Account таб: добавете UID в User Logon Name и задайте домейн @dsk.grp.
- Object таб: проверете контейнера за Location.

### [ext] IDM – Accounts
- Accounts > Find Users – проверете ID.

### [ext] Специфика за KIB / SBO / CASHIER TELLER
- IDM за KIB: добавете FG CREDITS.
- IDM за SBO и CASHIER TELLER: добавете FG Bank Operations.
- Job Definition (JD):
  - SBO: BRSBO010
  - KIB: BRCRIN07 / (BRCRINK6 за CASH)

### [ext] Общи AD групи
- FG Bank Operations
- GpG M365 OneDrive
- M365 Authentication - Certificates
- M365 Licensing - E5

### [ext] Действия
- Изберете update AD.
- Одобрете в IDM висящото ID.

### [ext] AD – добавяне на липсващи M365 групи
- M365 Authentication - Certificates
- M365 Licensing - E5

### [ext] SUB справки
- Файлове:
- Проверете последните файлове за Субординация
- Проверете roles в IDM за съответния UID.
- Не добавяйте DFS, SAG, Jira, Confluence, Muvex, WIFI
- Добавете роли на UID според модела.
- Потвърдете съвпадения в конзолата.

### [ext] Head Office – добавете
- GpG M365 OneDrive
- M365 Auth Passwordless
- M365 Licensing - E5

### [ext] Финализиране
- Work Items: Approve за UID.
- Проверете M365, ако не е добавено:
  - M365 Authentication - Passwordless and SSPR
  - M365 Licensing - E5d

### [re] Email шаблон
- До: ITHO@dskbankbg.mail.onmicrosoft.com; IT.Regions@dskbank.bg
- Текст:
  - Назначена е парола за Dimension и Bankway BW@y1134.
  - Акаунтът е създаден, назначена е стандартна парола SiLn@Parola132.
  - Данни: три имена, ID.
  - Забележка: паролата е автоматична.

--- <

--- >

## [pn] Reset / Ресет пароли
### [kw] Keywords: Reset; Ресет; password reset; password; парола; акаунт; unlock
#### [id] R000002

### [pr] Procedure
- В AD ресет на паролата и задаване на default.
- Формат: SiLn@<timestamp>.

### [re] Email шаблон
- Акаунтът е възстановен.
- Назначена е нова парола SiLn@Parola1214 за AD, която трябва да се смени след първо влизане.
- Паролата се назначава от администратора.

--- <

--- >

## [pn] Change / Промяна на длъжност (JD)
### [kw] Keywords: Change; Промяна; JD; Job Definition; role change; промяна на длъжност; преназначаване
#### [id] PR000003

### [pr] Procedure
- Необходима е заповед за преназначаване или Order ID.
- Намерете моделния UID и вземете GPO/Groups от него за вашия UID.
- В IDM добавете новите groups и проверете обновяване в AD.
- В DIM сменете JD.
- В BW за UID променете:
  - Работна дефиниция
  - Като Служител
  - Титуляр

### [re] Email шаблон
- Преназначаването е направено, достъпът е предоставен съобразно заеманата длъжност.
- Необходимо е Log Off и Log On. Време за репликиране – до 30 мин.

--- <

--- >

## [pn] Location / Командировка и смяна на локация
### [kw] Keywords: Location; Локация; командировка; месторабота; смена на офис; location change
#### [id] PR000004

### [pr] Procedure
- В AD променете LG и STG (DL – само при изрично искане).
- В DIM меню 1 / 16 – сменете и двата клона.

### [re] Email шаблон
- Локационната група е сменена. Време за репликиране – до 30 мин. Нужен е Log Off / Log On.

--- <

--- >

## [pn] Add / Change – Teller
### [kw] Keywords: Teller; Add; Change; каса; телър; branch teller; банкови операции
#### [id] PR000005

### [pr] Procedure
- Проверете LG в AD.
- В DB намерете destination.
- В source таблица добавете запис с ID и NAME.
- Ако teller ID е за друг офис, добавете D накрая.
- Обновете destination таблица със записа без D.
- В BW: Каса на телър → Add teller.
- Само за счет. в ЦУ – телър за 0099.

--- <

--- >

## [pn] Достъп до: SonarQube, White list
### [kw] Keywords: Достъп до SonarQube; White list; Bulpost
#### [id] PR000006

### [pr] Procedure
- Моля за пренасочване.

--- <

--- >

## [pn] Reply / Отговори към заявители
### [kw] Keywords: Reply; Отговор; шаблон; заявители; email; комуникация; response
#### [id] PR000008

### [re] Procedure
- Достъпът е предоставен съобразно заеманата длъжност. Необходимо е Log Off и Log On. Време за репликиране – до 30 мин.
- Достъпът е предоставен. Необходимо е Log Off и Log On. Време за репликиране – 30 мин.
- Достъпът е предоставен. Необходимо е да се разпишете DIMENSION и BANKWAY.

### [ext] Teams съобщения
- Достъпът е предоставен. Необходимо е Log Off и Log On. Време за репликиране – 48 часа.

--- <

--- >

## [pn] Clavis – достъпи и заместване на мениджър
### [kw] Keywords: Clavis; достъп; роли; мениджър; access; JD
#### [id] PR000009

### [pr] Procedure
- DIM: проверете ID за Job Definition.
- Обновете с нов JD от DB.
- В Clavis добавете роли според JD.
- Потвърдете в AD и IDM.

--- <

--- >

## [pn] Начални пари на каса (КИБ)
### [kw] Keywords: начални пари; пари на каса; изравняване на каса
#### [id] PR000010

### [pr] Procedure
- В DIM проверете ID на служител и вземете текущата JD и я запишете.
- Сменете текущате JD със 12345678
- Върнете старата JD на служителя.

### [re] Procedure
Достъпът е предоставен. Необходимо е Log Off и Log On. Имате 30 минути да изравните касата. След изравняване на касата се обадете за възстановяване на вашият достъп.

Вашият достъп е възстановен. Необходимо е Log Off и Log On.

--- <

--- >

## [pn] След майчинство / двугодишен отпуск
### [kw] Keywords: Maternity; отпуск; майчинство; return; акаунт; AD
#### [id] PR000014

### [pr] Procedure
- Проверете AD.
- Създайте нов акаунт или обновете съществуващ.
- Потвърдете JD и групи.

--- <

--- >

## [pn] Инциденти – шаблон
### [kw] Keywords: Incidents; инциденти; Remedy; тикет; UID; troubleshooting
#### [id] PR000015

### [pr] Procedure
- Отворете тикет в Remedy.
- Прикрепете информация за UID.
- Следвайте стъпките за разрешаване.

--- <

--- >

## [pn] Offboarding accounts
### [kw] Keywords: Offboarding; акаунт; деактивация; UID; access removal
#### [id] PR000016

### [pr] Procedure
- AD: Disable account.
- IDM: Remove access от DIM и Bankway.
- Ако има м365 групи в АД се премахват.
- Ако има телър се обозначавава в базата със D

--- <

--- >

## [pn] Add to Bankway & Dimension
### [kw] Keywords: Bankway; Dimension; add; UID; access; roles
#### [id] PR000017

### [pr] Procedure
- Добавете UID към Bankway.
- Обновете DIM с роли.
- Потвърдете access.

--- <

--- >

## [pn] DK / LOS groups (Кредитни карти – CAS)
### [kw] Keywords: DK; LOS; groups; Кредитни карти; CAS
#### [id] PR000018

### [pr] Procedure
- КК в БДСК – изисква се Order attached / достъп „кредитни карти“.
- DIM с ID вземете JD.
- BW > Admin > Access > Work definitions – по JD търсете DK____.
- AD проверете FG групи и членовете – вземете модел за LOS групи.

### [ext] Добавете тези групи в АД
- RLG LOS Credit Expert
- RLG LOS Credit Expert 2
- RuG LOS Branches
- RlG LOS Branch Manager (само мениджъри)

### [ext] За отговорник офис за CAS се дава
- RlG LOS Branch Manager 
- RlG LOS Credit Expert 
- RlG LOS Credit Expert 2 
- RuG LOS Branches + DK____

### [re] Email шаблони
- Достъпът е предоставен съобразно заеманата длъжност. Необходимо е Log Off и Log On. Време за репликиране – до 30 мин.
- Достъпът е предоставен. Необходимо е Log Off и Log On. Време за репликиране – до 30 мин.

--- <

--- >

## [pn] Archimed – стъпки
### [kw] Keywords: Archimed; достъп; добавяне; преместване; нов акаунт
#### [id] PR000020

### [pr] Procedure
- Създайте акаунт.
- Присвоете роли.
- Потвърдете access в AD.

--- <

--- >

## [pn] CRM 
### [kw] Keywords: CRM; роли
#### [id] PR000021

### [pr] Procedure
- Проверете CRM акаунт.
- Добавете роли и бележки.
- Потвърдете с мениджъра.

--- <

--- >

## [pn] Разни бележки / Issues / Notes / Back / DWH / DWHA
### [kw] Keywords: Notes; Issues; DWH; DWHA; documentation; problems; бележки; проблеми
#### [id] PR000022

### [pr] Procedure
- Документирайте проблеми.
- Обновете DWH/DWHA.
- Потвърдете със съответния отдел.

--- <

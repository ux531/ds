--- # open procedure

## New Account (Нов акаунт)

### Procedure
- Проверете името на ENG в AD.
- Ако има съвпадение на име: обновете Display Name и Full Name, добавяйки суфикс (напр. - Department Name).

### IDM
- IDM > Work Items > Approvals – намерете ID и Approve.
- Ако не намирате: изпратете имейл с поръчката (Remedy) до Tsvetelin.Tsvetanov@dskbank.bg.
- Ако няма съвпадение в AD: одобрете в IDM > Approve.

### AD конфигурация
- Account таб: добавете UID в User Logon Name и задайте домейн @dsk.grp.
- Object таб: проверете контейнера за Location.

### IDM – Accounts
- Accounts > Find Users – проверете ID.

### Специфика за KIB / SBO / CASHIER TELLER
- IDM за KIB: добавете FG CREDITS.
- IDM за SBO и CASHIER TELLER: добавете FG Bank Operations.
- Job Definition (JD):
  - SBO: BRSBO010
  - KIB: BRCRIN07 / (BRCRINK6 за CASH)

### Общи AD групи
- FG Bank Operations
- GpG M365 OneDrive
- M365 Authentication - Certificates
- M365 Licensing - E5

### Действия
- Изберете update AD.
- Одобрете в IDM висящото ID.

### AD – добавяне на липсващи M365 групи
- M365 Authentication - Certificates
- M365 Licensing - E5

### SUB справки
- Файлове:
  - SUBORDINATION-HO-31.07.2025-sent.xlsx
  - SUBORDINATION-REGIONS-31.07.2025-sent.xlsb
  - SUBORDINATION-CFD-31.07.2025-sent.xlsx
- Вземете JD от WO и търсете подобни записи в DB по Dep Owner.
- Проверете roles в IDM за съответния UID.
- Не добавяйте DFS и SAG.
- Не добавяйте достъпи в Jira, Confluence, Muvex, WIFI.
- Добавете роли на UID според модела.
- Потвърдете съвпадения в конзолата.

### Head Office – добавете
- GpG M365 OneDrive
- M365 Auth Passwordless
- M365 Licensing - E5

### Финализиране
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

### Keywords: New Account; Нов акаунт; new user; onboarding; онбординг; нов служител; назначаване

#### PR000001

--- # close procedure

--- # open procedure

## Reset / Ресет пароли

### Procedure
- В AD ресет на паролата и задаване на default.
- Формат: SiLn@<timestamp>.

### [re] Email шаблон
- Акаунтът е възстановен.
- Назначена е нова парола SiLn@Parola1214 за AD, която трябва да се смени след първо влизане.
- Паролата се назначава от администратора.

### Keywords: Reset; Ресет; password reset; password; парола; акаунт; unlock

#### PR000002

--- # close procedure

--- # open procedure

## Change / Промяна на длъжност (JD)

### Procedure
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

### Keywords: Change; Промяна; JD; Job Definition; role change; промяна на длъжност; преназначаване

#### PR000003

--- # close procedure

--- # open procedure

## Location / Командировка и смяна на локация

### Procedure
- В AD променете LG и STG (DL – само при изрично искане).
- В DIM меню 1 / 16 – сменете и двата клона.

### [re] Email шаблон
- Локационната група е сменена. Време за репликиране – до 30 мин. Нужен е Log Off / Log On.

### Keywords: Location; Локация; командировка; месторабота; смена на офис; location change

#### PR000004

--- # close procedure

--- # open procedure

## Add / Change – Teller

### Procedure
- Проверете LG в AD.
- В DB намерете destination.
- В source таблица добавете запис с ID и NAME.
- Ако teller ID е за друг офис, добавете D накрая.
- Обновете destination таблица със записа без D.
- В BW: Каса на телър → Add teller.
- Само за счет. в ЦУ – телър за 0099.

### Keywords: Teller; Add; Change; каса; телър; branch teller; банкови операции

#### PR000005

--- # close procedure

--- # open procedure

## Достъп до SonarQube

### Procedure
Моля за пренасочване.

### Keywords: Достъп до SonarQube

#### PR000006

--- # close procedure

--- # open procedure

## Добавяне на имейли в White list

### Procedure
Моля за пренасочване.

### Keywords: имейлив White list

#### PR000007

--- # close procedure

--- # open procedure

## Reply / Отговори към заявители

### [re] Procedure
- Достъпът е предоставен съобразно заеманата длъжност. Необходимо е Log Off и Log On. Време за репликиране – до 30 мин.
- Достъпът е предоставен. Необходимо е Log Off и Log On. Време за репликиране – 30 мин.
- Достъпът е предоставен. Необходимо е да се разпишете DIMENSION и BANKWAY.

### Teams съобщения
- Достъпът е предоставен. Необходимо е Log Off и Log On. Време за репликиране – 48 часа.

### Keywords: Reply; Отговор; шаблон; заявители; email; комуникация; response

#### PR000008

--- # close procedure

--- # open procedure

## Clavis – достъпи и заместване на мениджър

### Procedure
- DIM: проверете ID за Job Definition.
- Обновете с нов JD от DB.
- В Clavis добавете роли според JD.
- Потвърдете в AD и IDM.

### Keywords: Clavis; достъп; роли; мениджър; access; JD

#### PR000009

--- # close procedure

--- # open procedure

## Начални пари на каса (КИБ)

### Procedure

- В DIM проверете ID на служител и вземете текущата JD и я запишете.
- Сменете текущате JD със 12345678
- Върнете старата JD на служителя.

### Keywords: начални пари; пари на каса; изравняване на каса

## Reply / Отговори към заявители

### [re] Procedure
- Достъпът е предоставен. Необходимо е Log Off и Log On. Имате 30 минути да изравните касата. След изравняване на касата се обадете за възстановяване на вашият достъп.
- Вашият достъп е възстановен. Необходимо е Log Off и Log On.

#### PR000010

--- # close procedure

--- # open procedure

## Bulpost – заявка за достъп

### Procedure
- Изпратете имейл с поръчката.
- Одобрете в IDM.
- Потвърдете в AD.

### Keywords: Bulpost; достъп; заявка; access request; IDM; AD

#### PR000011

--- # close procedure

--- # open procedure

## Отказан достъп – шаблон

### Procedure
- Изпратете имейл на заявителя.
- Обяснете причината.
- Добавете ID на поръчката.

### Keywords: Denied; отказ; access denied; шаблон; email

#### PR000012

--- # close procedure

--- # open procedure

## Одобрение – шаблон за имейл

### Procedure
- Потвърдете одобрението.
- Добавете ID.
- Изпратете имейл към IT отдел.

### Keywords: Approval; одобрение; template; email; IDM

#### PR000013

--- # close procedure

--- # open procedure

## След майчинство / двугодишен отпуск

### Procedure
- Проверете AD.
- Създайте нов акаунт или обновете съществуващ.
- Потвърдете JD и групи.

### Keywords: Maternity; отпуск; майчинство; return; акаунт; AD

#### PR000014

--- # close procedure

--- # open procedure

## Инциденти – шаблон

### Procedure
- Отворете тикет в Remedy.
- Прикрепете информация за UID.
- Следвайте стъпките за разрешаване.

### Keywords: Incidents; инциденти; Remedy; тикет; UID; troubleshooting

#### PR000015

--- # close procedure

--- # open procedure

## Offboarding accounts

### Procedure
- Disable UID в AD.
- Remove access от DIM и Bankway.
- Обновете групи.

### Keywords: Offboarding; акаунт; деактивация; UID; access removal

#### PR000016

--- # close procedure

--- # open procedure

## Add to Bankway & Dimension

### Procedure
- Добавете UID към Bankway.
- Обновете DIM с роли.
- Потвърдете access.

### Keywords: Bankway; Dimension; add; UID; access; roles

#### PR000017

--- # close procedure

--- # open procedure

## DK / LOS groups (Кредитни карти – CAS)

### Procedure
КК в БДСК – изисква се Order attached / достъп „кредитни карти“.

- DIM с ID вземете JD.
- BW > Admin > Access > Work definitions – по JD търсете DK____.
- AD проверете FG групи и членовете – вземете модел за LOS групи.

#### Добавете тези групи в АД:
RLG LOS Credit Expert
RLG LOS Credit Expert 2
RuG LOS Branches
RlG LOS Branch Manager (само мениджъри)
#### За отговорник офис за CAS се дава: 
  - RlG LOS Branch Manager 
  - RlG LOS Credit Expert 
  - RlG LOS Credit Expert 2 
  - RuG LOS Branches + DK____

### Email шаблони
- Достъпът е предоставен съобразно заеманата длъжност. Необходимо е Log Off и Log On. Време за репликиране – до 30 мин.
- Достъпът е предоставен. Необходимо е Log Off и Log On. Време за репликиране – до 30 мин.

### Keywords: DK; LOS; groups; Кредитни карти; CAS; access; достъп; AD; IDM

#### PR000018

--- # close procedure

--- # open procedure

## Access – специални системи и роли

### Procedure
- В IDM проверете роли.
- В AD добавете или премахнете групи.
- Потвърдете access.

### Keywords: Access; специални системи; роли; IDM; AD; access control

#### PR000019

--- # close procedure

--- # open procedure

## Archimed – стъпки

### Procedure
- Създайте акаунт.
- Присвоете роли.
- Потвърдете access в AD.

### Keywords: Archimed; достъп; роли; account; AD; procedure

#### PR000020

--- # close procedure

--- # open procedure

## CRM – роли и бележки

### Procedure
- Проверете CRM акаунт.
- Добавете роли и бележки.
- Потвърдете с мениджъра.

### Keywords: CRM; роли; бележки; account; access; управление

#### PR000021

--- # close procedure

--- # open procedure

## Разни бележки / Issues / Notes / Back / DWH / DWHA

### Procedure
- Документирайте проблеми.
- Обновете DWH/DWHA.
- Потвърдете със съответния отдел.

### Keywords: Notes; Issues; DWH; DWHA; documentation; problems; бележки; проблеми

#### PR000022

--- # close procedure

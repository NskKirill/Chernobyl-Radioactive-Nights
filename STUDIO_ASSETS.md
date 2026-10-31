# Реестр Studio-объектов и ресурсов

| Имя / путь | Назначение и зависимость | Статус | Метод проверки |
|---|---|---|---|
| `Workspace.CRN_Expedition` | Карта главы; создаётся `WorldBuilder.server.lua` при запуске | Проверена в предыдущем Play-сеансе; построение идёт из стандартных деталей | Дерево Server во время Play, стартовый тест 2026-10-31 |
| `Workspace.CRN_Expedition.Shelter.StartConsole.Interact` | Начало вылазки через ProximityPrompt | `MaxActivationDistance=18` и `MaxIndicatorDistance=18` проверены в Play. В свежем QA Play prompt был включён в `READY` и стал `Enabled=false` после старта; возврат включения при WIN/LOSE → READY пока проверен только по коду | `WorldBuilder.server.lua`, `NightService.server.lua`; MCP Play session |
| `Workspace.CRN_Expedition.Shelter.CameraAnchors` | Три локальных направления разведки из убежища | Генерируются кодом; полнота переключений в актуальной копии не проверена | `WorldBuilder.server.lua`, `HUD.client.lua` |
| `Workspace.CRN_Expedition.Objectives.Relay_01_Station` | Цель этапа станции | Генерируется кодом; присутствие и порядок подтверждались в предыдущем полном проходе другой QA-сессии | `WorldBuilder.server.lua`, `NightService.server.lua` |
| `Workspace.CRN_Expedition.Objectives.Relay_02_Tunnel` | Цель тоннеля | Генерируется кодом; прежняя QA-сессия собрала по порядку | `WorldBuilder.server.lua`, `NightService.server.lua` |
| `Workspace.CRN_Expedition.Objectives.Relay_03_Surface` | Цель поверхности | Генерируется кодом; прежняя QA-сессия собрала по порядку | `WorldBuilder.server.lua`, `NightService.server.lua` |
| `Workspace.CRN_Expedition.Objectives.ExtractionBeacon` | Финишный маяк | Генерируется кодом; WIN проверен ранее в отдельной QA-сессии; повторно для сохранённой копии не проверен | `NightService.server.lua`, исторический Play-output |
| `Workspace.CRN_Expedition.Checkpoints.*` | Безопасные позиции по маршруту | Генерируются кодом; часть checkpoints встречалась в прежнем игровом проходе | `WorldBuilder.server.lua`, `NightService.server.lua` |
| `Workspace.CRN_Expedition.Hazards.*` | Радиация, электричество, аномалия, падение | Объёмы и серверные предупреждения создаются исходником; предупреждения не все подтверждены визуально | `NightService.server.lua`, `WorldBuilder.server.lua` |
| `ReplicatedStorage.CRN_Remotes.Action`, `Notice` | Действия клиента и серверные уведомления | Создаются/переиспользуются `NightService`; серверная валидация просмотрена в коде | `NightService.server.lua` |
| `ReplicatedStorage.GameState.*` | Состояние экспедиции, цели и таймер | Значения создаются/переиспользуются `NightService`; полный reset проверялся для WIN в исторической QA-сессии | `NightService.server.lua` |
| `Dog`, `ConnectionTestModel` | Проверочные объекты из ранних сессий | Назначение не установлено в актуальном проекте; не изменять и не удалять без проверки | В текущем Rojo mapping отсутствуют; активный Studio hierarchy недоступен в этой сессии |
| `rbxassetid://203785492` | Источник ошибки «Asset type does not match requested type» | В свежем Play ошибка повторилась трижды; текущий скан скриптов, атрибутов, ValueBase и распространённых content-свойств в загруженной копии ID не обнаружил. Ресурс не заменять без установленного владельца и подходящего ID | Studio Output, `script_grep`, Luau scan DataModel, поиск Rojo |
| `Subject 06`, `CRN_Bunker/EnemyActors` | Ресурс старого прототипа ночной охраны | Не входит в текущую вылазку. README сообщает, что архивный скрипт ожидает устаревшую структуру; повторно не импортировать без решения владельца | `README_RU.md`; текущий `default.project.json` |

## Ограничения

- В текущем вызове Studio MCP не вернул подключённых Studio-документов.
- Список путей карты отражает объекты, генерируемые кодом, а не вручную подтверждённый актуальный Explorer.
- Внешние изображения, звуки и анимации не требуются проекту по README; сообщение `203785492` остаётся необъяснённым.

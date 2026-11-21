# Источник 203785492 — 21 ноября 2026

Сборка игры не менялась: Night1_RELEASE_20261121.rbxl, SHA-256 919DC3D77195D079EF8EB312F2E521664BC0C5B5700D6C874B6FF69F52A5FF07.

| Проверка | Результат | Доказательство |
| --- | --- | --- |
| Поиск ID в исходниках игры | PASS | rg по src не нашёл 203785492. |
| Поиск в текущем QA DataModel (Edit) | PASS | Ноль совпадений в Source, SoundId, атрибутах и проверенных свойствах Image/Texture/TextureID/MeshId/AnimationId/Video/Skybox*. |
| Источник и назначение | PASS | ID найден в распакованных PROP-данных установленного RojoManagedPlugin.rbxm: Assets.Sounds.Notification. |
| Место запуска | PASS по коду плагина | Notification:didMount и FullscreenNotification:didMount вызывают soundPlayer:play(Assets.Sounds.Notification). SoundPlayer создаёт Sound под widget, задаёт SoundId и вызывает Play. Настройка playSounds=false подавляет этот вызов. |
| Устранение сообщения | NOT_TESTED / не исправлено | Настройки и файл плагина не менялись. В последнем Output оставались три сообщения Asset type does not match requested type. Повторный Play с выключенным звуком уведомлений не выполнялся. |

Проверенный файл инструмента: `C:\Users\admin\AppData\Local\Roblox\Plugins\RojoManagedPlugin.rbxm`.
SHA-256: `9412C5CE010E18342A4470A48F516772127649216AA3FBF55B8FE1369CA5DB7F`.
Прочитан бинарный RBXM без исполнения его кода; распакованы блоки PROP. Вхождение ID — offset 2412845 распакованного блока, обращения Sounds.Notification — offsets 2194166 и 2198677. Временный проверяющий скрипт сохранён в outputs/night1_release_qa_20261121/inspect-plugin.cjs внешней папки Night1.

Владелец использующего ресурс кода — Rojo-плагин; назначение — уведомление интерфейса Studio. Автор/права самого Roblox-ресурса не устанавливались. Ресурс не удалялся и не подменялся. Это источник вне экспортируемой Rojo-сборки игры. Полная очистка Output не подтверждена и не подменяет проверку пяти игровых звуков в целевом experience.

Игровой цикл и оставшиеся условия выпуска: [QA_RELEASE_20261121.md](QA_RELEASE_20261121.md). Локализация ошибки инструмента завершена; человеческий плейтест, слышимый микс и целевой experience остаются открытыми.

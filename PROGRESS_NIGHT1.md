# Night 1 — состояние на 21 ноября 2026

Ветка codex/night1-original-horror. Последняя правка — только компактные кнопки ПК в src/StarterPlayer/StarterPlayerScripts/Night1HUD.client.lua. Сервер и баланс не менялись.
Новая QA: C:/Users/admin/Downloads/ChernobylRadioactiveNights_Night1/outputs/night1_compact_controls_qa_20261121/Night1_COMPACT_CONTROLS_20261121.rbxl
SHA-256: EFA0CC6E4338E7E67571F2CB90100CB7915FA90E574D7EFF4C1FA16537AF1B62.

RUNNING: два ряда, 420×86 вместо 480×159, текст 14 px без TextScaled, выбранная камера выделена. READY/LOSE/WIN: только старт/повтор, 240×48.
PASS в Studio: мышь (старт, две двери, камеры 1/2/3/C), Q/E/1/2/3/C/N, естественный LOSE и повтор мышью и клавишей, Desktop VGA/HD720/HD1080. TextFits и границы видимых кнопок без ошибок; 1 HUD/карта/GameState/RemoteEvent. Output — только три старых ошибки 203785492 Rojo-плагина.

Тестовый хост — отдельная копия Night1_PUBLISH_20261121 с временно установленным кандидатом HUD; оба runtime Source совпали с новыми src. Затем временный HUD восстановлен, собственная тестовая Play остановлена. Прямое открытие нового rbxl пока не подтверждено: новое окно не подключилось к MCP. Это не выдаётся за проверку запуска нового файла.

Полный WIN после HUD-правки НЕ повторялся. Предыдущие полные WIN, разряд, обе ветки повторов, плохая связь и запись аудио относятся к Night1_SOUND_INTRO (код 8d75abb). Текущие ограничения выпуска: целевой experience и права аудио, слуховая оценка и независимый плейтест, ввод при открытом чате. Телефон/геймпад не подтверждены. Разрешение пользователя на публикацию получено, но облачной публикации и ссылки ещё нет; старые файлы PUBLISH и SOUND_INTRO не содержат новую правку.

Пользовательскую Studio 1754e928-b198-45cd-89b7-9cf436974055 (Night1_SOUND_INTRO) НЕ останавливать и не изменять. Оригиналы и AutoRecovery сохранены. Резервные копии — outputs/night1_compact_controls_qa_20261121/backup.
Отчёт: QA_COMPACT_CONTROLS_20261121.md; наблюдения: qa/Night1_COMPACT_CONTROLS_20261121.json.

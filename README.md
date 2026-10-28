# TV

Тюнинг домашнего TCL Android TV 12 через adb по сети.

## Подготовка ТВ
1. Настройки → Система → Об устройстве → 7 раз нажать на «Сборка ОС Android TV» → включится режим разработчика.
2. Настройки → Система → Для разработчиков → включить «Отладка по USB» / «Отладка по сети» (ADB).
3. Узнать IP: Настройки → Сеть и интернет → твоя сеть.

## Запуск (Linux, в той же Wi-Fi сети)
```bash
sudo apt install adb
./scripts/tv-tune.sh 192.168.1.50 status
./scripts/tv-tune.sh 192.168.1.50 speed
```
`undo` возвращает анимации как было, `apps` показывает список приложений.
`debloat` отключает рекламу/демо/телеметрию TCL и ненужные в РФ сервисы, `restore` включает их обратно.

## Лаунчер Projectivy
```bash
./scripts/tv-tune.sh 192.168.1.110 launcher-get   # открыть Projectivy в Google Play на ТВ
./scripts/tv-tune.sh 192.168.1.110 launcher-on    # «Домой» → Projectivy
./scripts/tv-tune.sh 192.168.1.110 launcher-off   # вернуть Google TV
./scripts/tv-tune.sh 192.168.1.110 wallpapers     # закинуть обои из wallpapers/ на ТВ
```
Обои генерирует `python3 tools/make_wallpapers.py`.

#!/usr/bin/env bash
# Ускорение TCL Android TV по сети через adb.
# Использование: ./scripts/tv-tune.sh <IP телевизора> [status|speed|undo|apps]
set -euo pipefail

IP="${1:?Укажи IP телевизора: Настройки → Сеть и интернет → (твоя сеть)}"
CMD="${2:-status}"
TV="$IP:5555"

command -v adb >/dev/null || { echo "Нет adb. Установи: sudo apt install adb"; exit 1; }

adb connect "$TV" >/dev/null
# При первом подключении на ТВ появится окно «Разрешить отладку?» — нажми «Разрешить».
adb -s "$TV" wait-for-device
sh() { adb -s "$TV" shell "$@"; }

case "$CMD" in
  status)
    echo "Модель:   $(sh getprop ro.product.model)"
    echo "Android:  $(sh getprop ro.build.version.release)"
    echo "Патч:     $(sh getprop ro.build.version.security_patch)"
    echo "Анимации: $(sh settings get global window_animation_scale) / $(sh settings get global transition_animation_scale) / $(sh settings get global animator_duration_scale)"
    sh cat /proc/meminfo | grep -E 'MemTotal|MemAvailable'
    ;;
  speed)
    # Анимации в 0.5x — интерфейс ощущается заметно быстрее.
    sh settings put global window_animation_scale 0.5
    sh settings put global transition_animation_scale 0.5
    sh settings put global animator_duration_scale 0.5
    # Не держать в фоне больше 2 приложений.
    sh settings put global background_process_limit 2 || true
    # Сжатие кэша неиспользуемых приложений.
    sh pm trim-caches 999G || true
    echo "Готово. Перезагрузи ТВ: adb -s $TV reboot"
    ;;
  undo)
    sh settings put global window_animation_scale 1
    sh settings put global transition_animation_scale 1
    sh settings put global animator_duration_scale 1
    sh settings delete global background_process_limit || true
    echo "Вернул как было."
    ;;
  apps)
    # Сторонние и предустановленные приложения — чтобы решить, что отключить.
    # Отключить:  adb -s IP:5555 shell pm disable-user --user 0 <пакет>
    # Вернуть:    adb -s IP:5555 shell pm enable <пакет>
    sh pm list packages | sed 's/^package://' | sort
    ;;
  *)
    echo "Команды: status | speed | undo | apps"; exit 1 ;;
esac

#!/usr/bin/env bash
# Ускорение TCL Android TV по сети через adb.
# Использование: ./scripts/tv-tune.sh <IP телевизора> <команда>   (неверная команда покажет список)
set -euo pipefail

IP="${1:?Укажи IP телевизора: Настройки → Сеть и интернет → (твоя сеть)}"
CMD="${2:-status}"
TV="$IP:5555"

command -v adb >/dev/null || { echo "Нет adb. Установи: sudo apt install adb"; exit 1; }

adb connect "$TV" >/dev/null
# При первом подключении на ТВ появится окно «Разрешить отладку?» — нажми «Разрешить».
adb -s "$TV" wait-for-device
sh() { adb -s "$TV" shell "$@"; }

# Тяжёлые приложения, которым незачем работать, пока они не открыты.
NO_BG=(
  com.google.android.youtube.tv com.google.android.youtube.tvmusic
  ru.kinopoisk.tv gpm.tnt_premier ru.rt.video.app.tv ru.more.play rtb.mobile.android
  com.vk.tv com.yandex.browser.tv tv.twitch.android.app com.google.android.videos
)

PROJECTIVY=com.spocky.projengmenu
GTV_HOME=com.google.android.apps.tv.launcherx

# Лишнее, что висит в фоне и ест память. Системное и нужное не трогаем.
# Всё отключается обратимо (команда restore).
BLOAT=(
  tv.samba.ssm.ui                       # Samba TV — слежка за просмотром ради рекламы
  com.tcl.messagebox                    # рекламные сообщения TCL
  com.tcl.waterfall.overseas            # рекомендации/реклама TCL
  com.tcl.usercenter                    # аккаунт TCL
  com.tcl.logkit                        # сбор логов
  com.tcl.exhibit                       # демо-режим для магазина
  com.tcl.esticker                      # наклейки демо-режима
  com.tcl.hotelmenu                     # меню для отелей
  com.tcl.ocean.instructions            # электронная инструкция
  com.tcl.repairguide                   # руководство по ремонту
  com.google.android.feedback           # отправка отзывов в Google
  com.google.android.play.games         # Play Игры
  com.google.android.marvin.talkback    # озвучка для слабовидящих
  com.android.printspooler              # печать
  com.amazon.amazonvideo.livingroom     # Prime Video (в РФ не работает)
  com.netflix.ninja                     # Netflix (в РФ не работает)
  com.iqiyi.i18n.tv                     # iQIYI
)

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
  debloat)
    for p in "${BLOAT[@]}"; do
      if sh pm disable-user --user 0 "$p" >/dev/null 2>&1; then echo "отключено: $p"; else echo "пропуск:   $p"; fi
    done
    echo "Готово. Перезагрузи ТВ: adb -s $TV reboot"
    ;;
  restore)
    for p in "${BLOAT[@]}"; do sh pm enable "$p" >/dev/null 2>&1 && echo "включено: $p" || true; done
    ;;
  boost)
    # Оптимизация (предкомпиляция) приложений — быстрее запускаются. Занимает 5–15 минут.
    echo "Оптимизирую приложения, это 5–15 минут, ТВ не выключай..."
    sh cmd package bg-dexopt-job || true
    # Запрет фоновой работы тяжёлым приложениям.
    for p in "${NO_BG[@]}"; do
      sh cmd appops set "$p" RUN_ANY_IN_BACKGROUND ignore >/dev/null 2>&1 && echo "без фона: $p" || true
    done
    echo "Свободно на диске:"; sh df -h /data | tail -1
    echo "Готово. Перезагрузи ТВ: adb -s $TV reboot"
    ;;
  boost-undo)
    for p in "${NO_BG[@]}"; do sh cmd appops set "$p" RUN_ANY_IN_BACKGROUND allow >/dev/null 2>&1 || true; done
    echo "Фоновая работа приложений возвращена."
    ;;
  launcher-get)
    # Открывает страницу Projectivy Launcher в Google Play на ТВ — останется нажать «Установить».
    sh am start -a android.intent.action.VIEW -d "market://details?id=$PROJECTIVY" >/dev/null
    echo "На ТВ открылся Google Play — нажми «Установить»."
    ;;
  launcher-on)
    # Кнопка «Домой» начнёт открывать Projectivy вместо Google TV.
    # Внимание: без Google TV перестаёт работать кнопка «TV/Live TV» на пульте TCL.
    # Мягче — не делать этого, а включить в Projectivy «Override Home button».
    sh pm path "$PROJECTIVY" >/dev/null || { echo "Сначала установи Projectivy: launcher-get"; exit 1; }
    sh pm disable-user --user 0 "$GTV_HOME" >/dev/null
    sh input keyevent KEYCODE_HOME
    echo "Готово. Если ТВ спросит, какой лаунчер использовать — выбери Projectivy «Всегда»."
    ;;
  launcher-off)
    sh pm enable "$GTV_HOME" >/dev/null
    sh input keyevent KEYCODE_HOME
    echo "Вернул стандартный Google TV."
    ;;
  wallpapers)
    # Копирует обои из папки wallpapers/ в «Изображения» на ТВ.
    sh mkdir -p /sdcard/Pictures/Wallpapers
    adb -s "$TV" push "$(dirname "$0")"/../wallpapers/*.jpg /sdcard/Pictures/Wallpapers/ >/dev/null
    sh am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Pictures/Wallpapers >/dev/null || true
    echo "Обои лежат на ТВ в Pictures/Wallpapers."
    ;;
  *)
    echo "Команды: status | speed | undo | apps | debloat | restore | boost | boost-undo | launcher-get | launcher-on | launcher-off | wallpapers"; exit 1 ;;
esac

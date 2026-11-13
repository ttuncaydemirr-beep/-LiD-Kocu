#!/usr/bin/env bash
# LiD Koçu — açılış duman testi: APK'yı emülatöre kurar, açar, 15 sn bekler.
# Süreç ölürse veya logcat'te FATAL / ANR varsa hata döner.
# Kullanım: acilis-testi.sh <apk> [paket]
set -u
APK="$1"
PAKET="${2:-com.lidkocu.app}"
BEKLE="${BEKLE:-15}"

adb wait-for-device
# Açılış animasyonu bitsin
for i in $(seq 1 60); do [ "$(adb shell getprop sys.boot_completed | tr -d '\r')" = "1" ] && break; sleep 2; done
adb shell settings put global window_animation_scale 0 || true
adb shell settings put global transition_animation_scale 0 || true
adb shell settings put global animator_duration_scale 0 || true

adb install -r -g "$APK" || { echo "::error::APK kurulamadı"; exit 1; }
AKTIVITE=$(adb shell cmd package resolve-activity --brief -c android.intent.category.LAUNCHER "$PAKET" | tr -d '\r' | tail -1)
echo "Ana aktivite: $AKTIVITE"
adb logcat -c || true
adb logcat -b crash -c || true

adb shell am start -W -n "$AKTIVITE" || true
sleep "$BEKLE"

PID=$(adb shell pidof "$PAKET" | tr -d '\r')
ODAK=$(adb shell dumpsys window | grep -E 'mCurrentFocus|mFocusedApp' | tr -d '\r')
adb logcat -d > logcat.txt || true
adb logcat -d -b crash > logcat-crash.txt || true
adb exec-out screencap -p > ekran.png || true

echo "===== crash buffer ====="
cat logcat-crash.txt
echo "===== FATAL / AndroidRuntime / DEBUG (tombstone) ====="
grep -nE 'FATAL|AndroidRuntime|DEBUG   :|libc    :|ANR in|Abort message|Process .* has died|Force finishing' logcat.txt | head -200
echo "===== Uygulama / Flutter logları ====="
grep -nE "flutter|$PAKET|Ads|FirebaseApp|UserMessagingPlatform" logcat.txt | head -150
echo "===== Odak ====="
echo "$ODAK"
echo "PID: ${PID:-yok}"

HATA=0
[ -z "$PID" ] && { echo "::error::Uygulama ${BEKLE} sn sonra çalışmıyor (süreç yok)"; HATA=1; }
if grep -qE "FATAL EXCEPTION|Fatal signal|ANR in $PAKET" logcat.txt logcat-crash.txt; then
  echo "::error::Logcat'te çökme var:"
  grep -m3 -A25 -E "FATAL EXCEPTION|Fatal signal|ANR in" logcat-crash.txt logcat.txt | head -80
  HATA=1
fi
echo "$ODAK" | grep -q "$PAKET" || { echo "::error::Ön planda uygulama yok"; HATA=1; }
[ "$HATA" = 0 ] && echo "AÇILIŞ TESTİ GEÇTİ: uygulama ${BEKLE} sn ayakta, FATAL yok."
exit $HATA

#!/usr/bin/env bash
# Gün 009: Process yönetimi ve sinyaller
# Arka planda "graceful shutdown" yapan küçük bir işçi (worker) başlatır,
# ona farklı sinyaller gönderir ve exit kodlarını gösterir.
# Çalıştırmak için: bash 01_process_yonetimi_ve_sinyaller.sh
set -euo pipefail

calisma=$(mktemp -d)
trap 'rm -rf "$calisma"' EXIT
log_dosyasi="$calisma/worker.log"

# --- 1) Süreç bilgisi ---
echo "== Bu betiğin süreci =="
echo "PID (\$\$) = $$ | PPID = $PPID"
ps -o pid,ppid,stat,cmd -p $$
echo "Durum /proc'tan: $(grep State /proc/$$/status)"
echo

# --- 2) Sinyal yakalayan işçi ---
# Ayrı bir bash süreci olarak çalışır. SIGTERM gelince temizlik yapıp 0 ile çıkar,
# SIGHUP gelince "config yeniden okundu" der ve çalışmaya devam eder.
isci_baslat() {
    bash -c '
        trap "echo \"[isci] HUP: config yeniden okundu\"" HUP
        trap "echo \"[isci] TERM: düzgün kapanıyorum\"; exit 0" TERM
        echo "[isci] başladı, PID=$$"
        while true; do sleep 0.2; done
    ' >>"$log_dosyasi" 2>&1 &
    pid=$!                                # $! : son arka plan sürecinin PID'i
}
# Not: pid=$(isci_baslat) YAZMA. $( ) alt kabukta (subshell) çalışır, işçi o alt
# kabuğun çocuğu olur ve ana betikteki "wait" onu bekleyemez.

echo "== Graceful shutdown (SIGHUP + SIGTERM) =="
isci_baslat
sleep 0.5
echo "İşçi PID: $pid"
ps -o pid,ppid,stat,cmd -p "$pid"
kill -HUP "$pid"; sleep 0.5               # yakalanır, süreç yaşamaya devam eder
kill -0 "$pid" && echo "kill -0: süreç hâlâ hayatta"   # -0 sinyal göndermez, sadece kontrol
kill -TERM "$pid"                         # kill'in varsayılanı da TERM'dir
kod=0; wait "$pid" || kod=$?              # wait: sürecin exit kodunu alır
echo "SIGTERM sonrası exit kodu: $kod (trap içinde exit 0)"
echo

# --- 3) SIGKILL yakalanamaz ---
echo "== SIGKILL (-9) =="
isci_baslat
sleep 0.5
kill -9 "$pid"                            # trap çalışmaz, temizlik yapılamaz
kod=0; wait "$pid" || kod=$?
echo "SIGKILL sonrası exit kodu: $kod (= 128 + 9)"
echo

# --- 4) Yakalanmayan SIGTERM ---
echo "== Trap'siz süreç + SIGTERM =="
sleep 30 &
pid=$!
kill "$pid"
kod=0; wait "$pid" || kod=$?
echo "sleep SIGTERM ile öldü, exit kodu: $kod (= 128 + 15)"
echo

# --- 5) Durdur / devam ettir (Ctrl+Z ve bg'nin yaptığı) ---
echo "== SIGSTOP / SIGCONT =="
sleep 30 &
pid=$!
kill -STOP "$pid"; sleep 0.2
echo "STOP sonrası durum: $(ps -o stat= -p "$pid")  (T = stopped)"
kill -CONT "$pid"; sleep 0.2
echo "CONT sonrası durum: $(ps -o stat= -p "$pid")  (S = sleeping)"
kill "$pid"; wait "$pid" 2>/dev/null || true
echo

# --- 6) Paralel işler ve wait ---
echo "== Arka plan işleri ve wait =="
baslangic=$SECONDS
for i in 1 2 3; do
    ( sleep 1; echo "  iş $i bitti" ) &   # üçü aynı anda çalışır
done
jobs -l
wait                                      # hepsini bekle
echo "3 iş toplam ~$(( SECONDS - baslangic )) sn sürdü (sırayla olsa 3 sn)"
echo

# --- 7) İşçinin log'u ---
echo "== İşçi log'u =="
cat "$log_dosyasi"
echo
echo "Sinyal numaraları: $(kill -l TERM)=TERM, $(kill -l KILL)=KILL, $(kill -l HUP)=HUP"

#!/usr/bin/env bash
# Gün 009: systemd ve servisler
# sudo gerektirmez: "kullanıcı servisi" (systemctl --user) kullanır.
# Çalıştırmak için:
#   bash 02_systemd_ve_servisler.sh          -> salt okunur inceleme (hiçbir şey değiştirmez)
#   bash 02_systemd_ve_servisler.sh kur      -> gun009-nabiz servisini kurar ve başlatır
#   bash 02_systemd_ve_servisler.sh durum    -> durum + son loglar
#   bash 02_systemd_ve_servisler.sh coktur   -> süreci kill -9 ile öldürür, Restart= ile kalkışını izler
#   bash 02_systemd_ve_servisler.sh kaldir   -> servisi durdurur ve siler
set -euo pipefail

readonly SERVIS="gun009-nabiz"
readonly UNIT_DIZIN="$HOME/.config/systemd/user"
readonly UNIT_DOSYA="$UNIT_DIZIN/$SERVIS.service"

kullanim() { echo "Kullanım: $0 [incele|kur|durum|coktur|kaldir]" >&2; exit 2; }

# systemd yoksa (ör. bazı container'lar, WSL1, macOS) anlamlı bir hata ver
command -v systemctl >/dev/null || { echo "Bu sistemde systemd yok" >&2; exit 1; }

# Unit dosyasının içeriği. Yorumlar satır başında olmalı (satır sonu yorum desteklenmez).
unit_icerigi() {
    cat <<'EOF'
[Unit]
Description=Gün 009 nabız servisi (5 sn'de bir log yazar)

[Service]
Type=simple
# Servisin stdout'u otomatik olarak journal'a gider
ExecStart=/usr/bin/env bash -c 'trap "echo SIGTERM geldi, kapaniyorum; exit 0" TERM; while true; do echo "nabiz: $$(date +%%T)"; sleep 5 & wait $$!; done'
# Sinyalle ölür veya 0 dışı kodla çıkarsa 3 sn sonra yeniden başlat
Restart=on-failure
RestartSec=3
TimeoutStopSec=5

[Install]
WantedBy=default.target
EOF
}
# Not: unit dosyasında % özel karakterdir (%h = home vb.), bu yüzden date için %%T yazdık.
# $ de özeldir (systemd $DEGISKEN'i kendisi açar), bash'e düz $ gitmesi için $$ yazdık.
# "sleep 5 & wait $!": sleep ön planda olsaydı trap, sleep bitene kadar beklerdi.

incele() {
    echo "== systemd sürümü ve PID 1 =="
    systemctl --version | head -n1
    echo "PID 1: $(ps -o comm= -p 1)"
    echo

    echo "== Sistem durumu =="
    # is-system-running: running / degraded (çöken unit var) / ...
    echo "Sistem: $(systemctl is-system-running 2>/dev/null || true)"
    echo "Çöken unit sayısı: $(systemctl --failed --no-legend 2>/dev/null | wc -l)"
    echo

    echo "== Çalışan servislerden ilk 10 =="
    # || true: head erken kapanırsa systemctl SIGPIPE alır, pipefail betiği durdurmasın
    systemctl list-units --type=service --state=running --no-pager --no-legend | head -n 10 || true
    echo

    echo "== Betikte exit koduyla kontrol (Gün 008) =="
    for s in sshd ssh docker NetworkManager systemd-journald; do
        if systemctl is-active --quiet "$s"; then
            printf "  %-18s aktif  | açılışta: %s\n" "$s" "$(systemctl is-enabled "$s" 2>/dev/null || true)"
        else
            printf "  %-18s aktif değil / yok\n" "$s"
        fi
    done
    echo

    echo "== Bir servisin ayrıntıları: systemd-journald =="
    systemctl show systemd-journald -p MainPID -p ActiveState -p Restart -p FragmentPath --no-pager
    echo

    echo "== Zamanlayıcılar (timer) =="
    systemctl list-timers --no-pager | head -n 6 || true
    echo

    echo "== 'kur' ile oluşturulacak unit dosyası =="
    unit_icerigi
}

kur() {
    mkdir -p "$UNIT_DIZIN"
    unit_icerigi > "$UNIT_DOSYA"
    echo "Yazıldı: $UNIT_DOSYA"
    systemctl --user daemon-reload                  # yeni/değişen unit dosyasını oku
    if command -v systemd-analyze >/dev/null; then
        systemd-analyze --user verify "$UNIT_DOSYA" && echo "verify: unit dosyası geçerli"
    fi
    systemctl --user enable --now "$SERVIS"         # açılışta başlat + şimdi başlat
    sleep 1
    durum
}

durum() {
    systemctl --user status "$SERVIS" --no-pager || true   # status, servis durmuşsa 3 döner
    echo
    echo "== Son loglar (journalctl) =="
    journalctl --user -u "$SERVIS" -n 5 --no-pager || true
}

coktur() {
    local eski yeni
    eski=$(systemctl --user show "$SERVIS" -p MainPID --value)
    (( eski > 0 )) || { echo "Servis çalışmıyor, önce: $0 kur" >&2; exit 1; }
    echo "Ana süreç PID=$eski, kill -9 gönderiliyor (yakalanamaz, exit 137)"
    kill -9 "$eski"
    echo "RestartSec=3 bekleniyor..."
    sleep 5
    yeni=$(systemctl --user show "$SERVIS" -p MainPID --value)
    echo "Yeni PID=$yeni | yeniden başlatma sayısı: $(systemctl --user show "$SERVIS" -p NRestarts --value)"
    journalctl --user -u "$SERVIS" -n 6 --no-pager || true
}

kaldir() {
    # stop: systemd önce SIGTERM gönderir, trap "kapaniyorum" yazar
    systemctl --user disable --now "$SERVIS" 2>/dev/null || true
    rm -f "$UNIT_DOSYA"
    systemctl --user daemon-reload
    systemctl --user reset-failed "$SERVIS" 2>/dev/null || true
    echo "Kaldırıldı. Kapanış logu:"
    journalctl --user -u "$SERVIS" -n 3 --no-pager || true
}

case "${1:-incele}" in
    incele) incele ;;
    kur)    kur ;;
    durum)  durum ;;
    coktur) coktur ;;
    kaldir) kaldir ;;
    *)      kullanim ;;
esac

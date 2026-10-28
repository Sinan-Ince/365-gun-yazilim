#!/usr/bin/env bash
# Gün 011: Ortam değişkenleri, PATH ve cron
# Salt okunur: crontab'a bir şey eklemez, dosya değiştirmez.
# Çalıştırmak için:
#   bash 02_cron_ve_ortam_degiskenleri.sh                       -> ortam, PATH, mevcut zamanlanmış görevler
#   bash 02_cron_ve_ortam_degiskenleri.sh acikla '*/5 * * * *'  -> cron ifadesini Türkçe açıkla
set -euo pipefail

baslik() { printf '\n== %s ==\n' "$1"; }

ortam_demo() {
    baslik "export farkı: kabuk değişkeni vs ortam değişkeni"
    YEREL="sadece bu kabukta"
    export ORTAMDA="çocuk process'e geçer"
    # bash -c yeni bir çocuk process: sadece export edilenleri görür
    bash -c 'echo "  çocuk YEREL   = [${YEREL:-yok}]"; echo "  çocuk ORTAMDA = [${ORTAMDA:-yok}]"'

    baslik "Tek komutluk değişken: AD=deger komut"
    SELAM=merhaba bash -c 'echo "  çocukta SELAM = $SELAM"'
    echo "  kabukta SELAM = [${SELAM:-yok}]   (kabuğa kalmadı)"

    baslik "Çocuk değiştirse ebeveyn etkilenmez"
    export SAYAC=1
    bash -c 'SAYAC=99; echo "  çocukta SAYAC = $SAYAC"'
    echo "  ebeveynde SAYAC = $SAYAC"

    baslik "Varsayılan değer ve zorunlu değişken"
    echo "  PORT = ${PORT:-8080}   (\${PORT:-8080}: yoksa 8080)"
    # ${X:?mesaj}: X yoksa mesajla çık. Alt kabukta deniyoruz ki betik ölmesin
    ( : "${OLMAYAN_TOKEN:?OLMAYAN_TOKEN tanımlı değil}" ) 2>&1 | sed 's/^/  hata: /' || true
}

path_incele() {
    baslik "PATH (aranma sırası, soldan sağa)"
    local i=0 dizin
    # IFS=':' ile PATH'i parçala; read -ra diziye okur
    IFS=':' read -ra dizinler <<< "$PATH"
    for dizin in "${dizinler[@]}"; do
        i=$((i + 1))
        if [[ -d $dizin ]]; then
            printf '  %2d. %-35s %4d dosya\n' "$i" "$dizin" "$(find "$dizin" -maxdepth 1 -type f -perm -u+x 2>/dev/null | wc -l)"
        else
            printf '  %2d. %-35s (yok!)\n' "$i" "$dizin"
        fi
    done

    baslik "Bu komutlar nereden geliyor"
    local k
    for k in bash python3 git docker claude; do
        printf '  %-8s -> %s\n' "$k" "$(command -v "$k" || echo 'PATH içinde yok')"
    done

    baslik "cron'un göreceği ortam (env -i ile simülasyon)"
    # cron neredeyse boş bir ortamla başlar; aynı komutu öyle dene
    env -i PATH=/usr/bin:/bin bash -c 'echo "  PATH=$PATH"; echo "  HOME=[${HOME:-yok}]"; command -v claude >/dev/null && echo "  claude bulundu" || echo "  claude BULUNAMADI -> cron içinde mutlak yol kullan"'
}

zamanlanmis_gorevler() {
    baslik "Senin crontab'ın"
    if command -v crontab >/dev/null; then
        crontab -l 2>/dev/null | sed 's/^/  /' || echo "  (crontab boş)"
    else
        echo "  crontab komutu yok (Arch'ta cronie paketi). systemd timer'lara bak:"
    fi

    baslik "systemd timer'lar (ilk 5)"
    if command -v systemctl >/dev/null; then
        systemctl list-timers --all --no-pager 2>/dev/null | head -n 6 | sed 's/^/  /' || true
    fi
}

# Tek bir cron alanını Türkçe'ye çevir: alan_acikla <deger> <birim>
alan_acikla() {
    local d=$1 birim=$2 ekli
    # Türkçe bulunma eki: dakikada, saatte, günde, ayda
    case $birim in
        saat) ekli=saatte ;;
        *gün*) ekli=günde ;;
        *)    ekli=${birim}da ;;
    esac
    case $d in
        '*')     echo "her $birim" ;;
        '*/'*)   echo "her ${d#*/} $ekli bir" ;;       # ${d#*/}: "*/" kısmını at
        *-*)     echo "$birim ${d%-*} ile ${d#*-} arası" ;;
        *,*)     echo "$birim ${d//,/, }" ;;            # virgülleri ", " yap
        *)       echo "$birim $d" ;;
    esac
}

acikla() {
    local ifade=$1
    # @ kısayolları
    case $ifade in
        @reboot)  echo "  açılışta bir kez"; return ;;
        @hourly)  ifade='0 * * * *' ;;
        @daily)   ifade='0 0 * * *' ;;
        @weekly)  ifade='0 0 * * 0' ;;
        @monthly) ifade='0 0 1 * *' ;;
    esac
    local alanlar
    read -ra alanlar <<< "$ifade"
    if (( ${#alanlar[@]} != 5 )); then
        echo "Geçersiz: 5 alan olmalı (dakika saat gün ay haftanın_günü), ${#alanlar[@]} var" >&2
        exit 2
    fi
    echo "  '$ifade':"
    echo "    dakika : $(alan_acikla "${alanlar[0]}" dakika)"
    echo "    saat   : $(alan_acikla "${alanlar[1]}" saat)"
    echo "    gün    : $(alan_acikla "${alanlar[2]}" gün)"
    echo "    ay     : $(alan_acikla "${alanlar[3]}" ay)"
    echo "    hafta  : $(alan_acikla "${alanlar[4]}" "haftanın günü") (0/7=Pazar, 1=Pazartesi)"
}

case ${1:-incele} in
    incele)
        ortam_demo
        path_incele
        zamanlanmis_gorevler
        baslik "Örnek cron ifadeleri"
        for e in '*/5 * * * *' '15 3 * * *' '30 9 * * 1-5' '@weekly'; do acikla "$e"; done
        ;;
    acikla)
        [[ $# -eq 2 ]] || { echo "Kullanım: $0 acikla '<cron ifadesi>'" >&2; exit 2; }
        acikla "$2"
        ;;
    *)
        echo "Kullanım: $0 [incele | acikla '<cron ifadesi>']" >&2; exit 2 ;;
esac

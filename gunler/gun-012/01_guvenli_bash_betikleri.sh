#!/usr/bin/env bash
# Gün 012: Güvenli Bash betik pratikleri
# Sisteme bir şey yazmaz; sadece kendi geçici klasörünü açar ve çıkarken siler.
# Çalıştırmak için:
#   bash 01_guvenli_bash_betikleri.sh            -> tüm demolar
#   bash 01_guvenli_bash_betikleri.sh -v -n 3    -> ayrıntılı, 3 geçici dosya
#   bash 01_guvenli_bash_betikleri.sh -k         -> trap'i görmek için bilerek hata ver
#   bash 01_guvenli_bash_betikleri.sh -h         -> yardım
set -euo pipefail

BETIK=$(basename "$0")
ayrintili=0
adet=2
kasten_hata=0

kullanim() {
    cat <<EOF
Kullanım: $BETIK [-v] [-n ADET] [-k] [-h]
  -v        ayrıntılı çıktı
  -n ADET   oluşturulacak geçici dosya sayısı (varsayılan 2)
  -k        trap'i görmek için ortada bilerek hata ver
  -h        bu yardım
EOF
}

log()   { (( ayrintili )) && echo "  [ayrıntı] $*" >&2; return 0; }
baslik() { printf '\n== %s ==\n' "$1"; }

# --- getopts ile seçenekleri oku ---
while getopts ":vn:kh" sec; do
    case $sec in
        v) ayrintili=1 ;;
        n) adet=$OPTARG ;;
        k) kasten_hata=1 ;;
        h) kullanim; exit 0 ;;
        :) echo "Hata: -$OPTARG bir değer ister" >&2; kullanim >&2; exit 2 ;;
        \?) echo "Hata: bilinmeyen seçenek -$OPTARG" >&2; kullanim >&2; exit 2 ;;
    esac
done
shift $((OPTIND - 1))

# -n sayı mı? [[ =~ ]] ile regex kontrolü
if ! [[ $adet =~ ^[0-9]+$ ]] || (( adet < 1 || adet > 20 )); then
    echo "Hata: -n 1 ile 20 arası bir sayı olmalı (verilen: $adet)" >&2
    exit 2
fi
(( $# == 0 )) || log "Fazladan argümanlar yok sayıldı: $*"

# --- trap: geçici klasör her durumda silinsin ---
gecici=$(mktemp -d)
temizle() {
    local kod=$?                          # betiğin çıkış kodunu sakla
    rm -rf "${gecici:?}"                  # ${x:?}: x boşsa rm hiç çalışmaz
    echo "  [trap EXIT] geçici klasör silindi: $gecici (çıkış kodu $kod)" >&2
}
trap temizle EXIT
trap 'echo "  [trap ERR] satır $LINENO hata verdi" >&2' ERR
trap 'echo; echo "  [trap INT] Ctrl+C alındı, çıkılıyor" >&2; exit 130' INT TERM

baslik "getopts sonucu"
echo "  ayrintili=$ayrintili  adet=$adet  kasten_hata=$kasten_hata"

baslik "set -e: ilk hatada dur"
# Her demo ayrı bir bash'te çalışır, böylece bu betik ölmez
bash -c 'false; echo "  set yok  : false sonrası devam etti"' || true
bash -c 'set -e; false; echo "  ASLA YAZILMAZ"' || echo "  set -e   : false'ta durdu (exit $?)"

baslik "set -u: tanımsız değişken"
bash -c 'echo "  set yok  : [$YAZIM_HATASI] boş geçti"'
bash -c 'set -u; echo "$YAZIM_HATASI"' 2>/dev/null || echo "  set -u   : tanımsız değişkende durdu (exit $?)"

baslik "pipefail: pipe'ın ortasındaki hata"
bash -c 'false | true; echo "  pipefail yok: false | true -> $?"'
bash -c 'set -o pipefail; false | true; echo "  pipefail var: false | true -> $?"' || true
bash -c 'set -o pipefail; cat /olmayan/dosya 2>/dev/null | wc -l >/dev/null; echo "  cat | wc -> $?"' || true

baslik "-e tuzağı: ((i++)) i=0 iken"
bash -c 'set -e; i=0; ((i++)); echo "  ASLA YAZILMAZ"' || echo "  ((i++)) 0 döndürdü, -e betiği öldürdü -> i=\$((i+1)) kullan"
bash -c 'set -e; i=0; i=$((i+1)); echo "  i=\$((i+1)) güvenli, i=$i"'

baslik "Tırnak: boşluklu dosya adı"
touch "$gecici/benim dosyam.txt"
log "oluşturuldu: $gecici/benim dosyam.txt"
dosya="$gecici/benim dosyam.txt"
# shellcheck disable=SC2086  # bilerek tırnaksız: hatayı göstermek için
ls $dosya >/dev/null 2>&1 && echo "  tırnaksız: bulundu" || echo "  tırnaksız: bulunamadı (iki ayrı kelime sandı)"
ls "$dosya" >/dev/null 2>&1 && echo "  tırnaklı : bulundu"

baslik "mktemp + trap: $adet geçici dosya"
for ((i = 1; i <= adet; i++)); do
    f=$(mktemp "$gecici/kayit.XXXX")
    echo "kayıt $i" > "$f"
    log "yazıldı: $f"
done
echo "  $(find "$gecici" -name 'kayit.*' | wc -l) kayıt dosyası var: $gecici"

if (( kasten_hata )); then
    baslik "Bilerek hata (-k)"
    echo "  Şimdi 'cat /olmayan' çalışacak: önce ERR, sonra EXIT trap'i göreceksin"
    cat /olmayan/dosya
    echo "  ASLA YAZILMAZ"
fi

baslik "shellcheck"
if command -v shellcheck >/dev/null; then
    shellcheck "$0" && echo "  bu betikte uyarı yok"
else
    echo "  shellcheck kurulu değil: sudo pacman -S shellcheck"
fi

echo
echo "Bitti. Çıkışta trap EXIT çalışacak:"

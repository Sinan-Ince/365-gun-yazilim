#!/usr/bin/env bash
# Gün 008: Fonksiyon, argümanlar ve exit kodları ile mini "deploy" aracı
# Çalıştırmak için:
#   bash 02_bash_fonksiyon_arguman_exit.sh            -> demo modu
#   bash 02_bash_fonksiyon_arguman_exit.sh -v prod v1.2.0
#   bash 02_bash_fonksiyon_arguman_exit.sh yanlis     -> exit 2
set -euo pipefail

ayrinti=0

# --- Yardımcı fonksiyonlar ---
log()  { echo "[$(date +%T)] $*"; }
hata() { echo "HATA: $*" >&2; }           # >&2 : hatalar stderr'e
debug() { (( ayrinti )) && echo "  (debug) $*" || true; }

kullanim() {
    cat >&2 <<EOF
Kullanım: $0 [-v] <ortam> [versiyon]
  ortam    : dev | test | prod
  versiyon : vX.Y.Z (varsayılan: latest)
  -v       : ayrıntılı çıktı
EOF
    exit 2                                # 2 = yanlış kullanım
}

# return ile doğru/yanlış: 0 = geçerli, 1 = geçersiz
gecerli_ortam_mi() {
    case "$1" in
        dev|test|prod) return 0 ;;
        *)             return 1 ;;
    esac
}

gecerli_versiyon_mu() {
    [[ "$1" == latest || "$1" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

# echo ile "değer döndürme": çağıran $( ) ile yakalar
replika_sayisi() {
    local ortam="$1"                      # local: dışarı sızmaz
    case "$ortam" in
        prod) echo 3 ;;
        *)    echo 1 ;;
    esac
}

deploy() {
    local ortam="$1" versiyon="$2"
    local replika
    replika=$(replika_sayisi "$ortam")
    log "Deploy başlıyor: ortam=$ortam versiyon=$versiyon replika=$replika"
    for (( i=1; i<=replika; i++ )); do
        debug "replika $i ayağa kaldırılıyor"
    done
    log "Deploy tamam ✔"
}

# --- Exit kodu demosu ---
exit_kodu_demo() {
    echo "== Exit kodları =="
    grep -q root /etc/passwd && echo "grep root     -> \$? = $?"
    grep -q yokboyle /etc/passwd || echo "grep yokboyle -> \$? = $?"
    ( exit 42 ) || echo "alt kabuk (subshell) exit 42 -> \$? = $?"
    olmayan_komut_xyz 2>/dev/null || echo "olmayan komut  -> \$? = $? (127)"
    if gecerli_ortam_mi staging; then :; else echo "gecerli_ortam_mi staging -> $?"; fi
    echo
}

# --- Argümanların işlenmesi ---
argumanlari_isle() {
    echo "== Argümanlar =="
    echo "Betik: $0 | argüman sayısı: $# | hepsi: $*"
    local i=1
    for a in "$@"; do                     # "$@" boşluklu argümanları korur
        echo "  \$$i = '$a'"
        (( i++ ))
    done
    echo
}

ana() {
    # Argümansız çalıştırılırsa demo moduna geç
    if (( $# == 0 )); then
        log "Argüman verilmedi, demo modu"
        exit_kodu_demo
        argumanlari_isle -v "ilk arg" prod v1.2.0
        set -- -v prod v1.2.0             # set -- : $1 $2 ... değerlerini yeniden ata
    fi

    # Bayrakları getopts ile oku
    local secenek
    while getopts "vh" secenek; do
        case "$secenek" in
            v) ayrinti=1 ;;
            h|*) kullanim ;;
        esac
    done
    shift $(( OPTIND - 1 ))               # bayrakları at, kalan: ortam versiyon

    (( $# >= 1 )) || kullanim
    local ortam="$1"
    local versiyon="${2:-latest}"

    if ! gecerli_ortam_mi "$ortam"; then
        hata "geçersiz ortam: '$ortam'"
        kullanim
    fi
    if ! gecerli_versiyon_mu "$versiyon"; then
        hata "geçersiz versiyon: '$versiyon'"
        exit 1
    fi

    deploy "$ortam" "$versiyon"
    exit 0
}

ana "$@"

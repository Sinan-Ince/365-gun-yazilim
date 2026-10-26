#!/usr/bin/env bash
# Gün 010: Paket yönetimi
# Salt okunur: hiçbir paket kurmaz/silmez, sudo istemez. apt, dnf/yum, pacman ve apk'yi tanır.
# Çalıştırmak için:
#   bash 02_paket_yonetimi.sh               -> dağıtım, paket yöneticisi, kurulu paket özeti
#   bash 02_paket_yonetimi.sh sorgu curl    -> "curl" kurulu mu, sürümü ne, dosyaları neler
#   bash 02_paket_yonetimi.sh kimin /usr/bin/ls  -> bu dosya hangi pakete ait
set -euo pipefail

kullanim() { echo "Kullanım: $0 [incele | sorgu <paket> | kimin <dosya>]" >&2; exit 2; }

# /etc/os-release: tüm modern dağıtımlarda var, KEY=deger biçiminde.
# Alt kabukta source ediyoruz ki değişkenler (ID, NAME...) betiğe sızmasın.
dagitim() { ( . /etc/os-release && echo "${PRETTY_NAME:-$ID} (ID=$ID, aile=${ID_LIKE:-$ID})" ); }

# Hangi paket yöneticisi var? İlk bulunanı döndür (Gün 008: fonksiyon + return kodu)
pm_bul() {
    local pm
    for pm in apt-get dnf yum pacman apk; do
        if command -v "$pm" >/dev/null; then echo "$pm"; return 0; fi
    done
    return 1
}

PM=$(pm_bul) || { echo "Tanınan bir paket yöneticisi yok" >&2; exit 1; }

incele() {
    echo "== Dağıtım ve paket yöneticisi =="
    echo "Dağıtım: $(dagitim)"
    echo "Paket yöneticisi: $PM"
    echo

    echo "== Kurulu paket sayısı =="
    case $PM in
        apt-get) dpkg-query -f '.\n' -W | wc -l ;;
        dnf|yum) rpm -qa | wc -l ;;
        pacman)  pacman -Q | wc -l
                 # -Qe: açıkça (explicitly) kurulanlar, gerisi bağımlılık olarak gelmiş
                 echo "  açıkça kurulan: $(pacman -Qeq | wc -l), sahipsiz bağımlılık: $(pacman -Qdtq | wc -l || true)" ;;
        apk)     apk info | wc -l ;;
    esac
    echo

    echo "== En büyük 5 paket =="
    case $PM in
        apt-get) dpkg-query -W -f '${Installed-Size}\t${Package}\n' | sort -rn | head -n 5 \
                   | awk -F'\t' '{printf "  %-30s %6.1f MB\n", $2, $1/1024}' ;;
        dnf|yum) rpm -qa --qf '%{SIZE}\t%{NAME}\n' | sort -rn | head -n 5 \
                   | awk -F'\t' '{printf "  %-30s %6.1f MB\n", $2, $1/1048576}' ;;
        # expac her sistemde yok, bu yüzden pacman -Qi çıktısını awk ile ayrıştırıyoruz
        pacman)  LC_ALL=C pacman -Qi | awk -F': ' '
                   /^Name/           {ad=$2}
                   /^Installed Size/ {split($2, a, " "); b=a[1]
                                      if (a[2]=="KiB") b/=1024; else if (a[2]=="GiB") b*=1024; else if (a[2]=="B") b/=1048576
                                      printf "%.1f\t%s\n", b, ad}' \
                   | sort -rn | head -n 5 | awk -F'\t' '{printf "  %-30s %6.1f MB\n", $2, $1}' ;;
        apk)     echo "  (apk için atlandı)" ;;
    esac || true   # head erken kapanınca SIGPIPE, pipefail betiği durdurmasın
    echo

    echo "== Sabitlenmiş (hold) paketler =="
    case $PM in
        apt-get) apt-mark showhold | sed 's/^/  /' ;;
        dnf)     dnf versionlock list 2>/dev/null | sed 's/^/  /' || echo "  versionlock eklentisi kurulu değil" ;;
        pacman)  grep -E '^\s*IgnorePkg' /etc/pacman.conf | sed 's/^/  /' || echo "  IgnorePkg tanımlı değil" ;;
        *)       echo "  (desteklenmiyor)" ;;
    esac
    echo

    echo "== Güncelleme var mı (yerel indekse göre, ağ/sudo yok) =="
    case $PM in
        apt-get) apt list --upgradable 2>/dev/null | tail -n +2 | wc -l | xargs echo "  güncellenebilir:" ;;
        dnf|yum) # check-update exit kodu: 0 = güncel, 100 = güncelleme var, 1 = hata
                 rc=0; "$PM" -q -C check-update >/dev/null 2>&1 || rc=$?
                 case $rc in 0) echo "  güncel" ;; 100) echo "  güncelleme var" ;; *) echo "  kontrol edilemedi (rc=$rc)" ;; esac ;;
        pacman)  if command -v checkupdates >/dev/null; then
                     checkupdates 2>/dev/null | wc -l | xargs echo "  güncellenebilir:"
                 else
                     echo "  checkupdates yok (pacman-contrib). 'pacman -Sy' root ister ve kısmi güncelleme riski taşır"
                 fi ;;
        apk)     echo "  'apk version -l <' ile bakılabilir" ;;
    esac
}

sorgu() {
    local p=$1
    echo "== '$p' kurulu mu =="
    # Her komut kurulu değilse 0 dışı döner, bunu if ile kullanıyoruz (Gün 008)
    case $PM in
        apt-get) if dpkg-query -W -f '${Status} ${Version}\n' "$p" 2>/dev/null | grep -q '^install ok installed'; then
                     echo "  kurulu: $(dpkg-query -W -f '${Version}' "$p")"
                     echo "  depodaki sürümler:"; apt-cache policy "$p" | sed -n '2,3p'
                     echo "  ilk 5 dosya:"; dpkg -L "$p" | grep -v '/$' | head -n 5 || true
                 else echo "  kurulu değil. Kurmak için: sudo apt-get install -y $p"; fi ;;
        dnf|yum) if rpm -q "$p" >/dev/null; then
                     echo "  kurulu: $(rpm -q --qf '%{VERSION}-%{RELEASE}' "$p")"
                     echo "  ilk 5 dosya:"; rpm -ql "$p" | head -n 5 || true
                 else echo "  kurulu değil. Kurmak için: sudo $PM install -y $p"; fi ;;
        pacman)  if pacman -Q "$p" >/dev/null 2>&1; then
                     echo "  kurulu: $(pacman -Q "$p")"
                     # Depends On satırı: bağımlılıklar
                     LC_ALL=C pacman -Qi "$p" | grep -E '^(Depends On|Required By)' | sed 's/^/  /'
                     echo "  ilk 5 dosya:"; pacman -Qlq "$p" | grep -v '/$' | head -n 5 || true
                 else echo "  kurulu değil. Kurmak için: sudo pacman -Syu $p"; fi ;;
        apk)     apk info -e "$p" >/dev/null && apk info -v "$p" || echo "  kurulu değil: apk add $p" ;;
    esac
}

kimin() {
    local f=$1
    [[ -e $f ]] || { echo "Dosya yok: $f" >&2; exit 1; }
    # readlink -f: sembolik linki gerçek yola çevir (/bin -> /usr/bin gibi, Gün 007)
    f=$(readlink -f "$f")
    echo "== $f hangi pakete ait =="
    case $PM in
        apt-get) dpkg -S "$f" 2>/dev/null || echo "  hiçbir pakete ait değil (elle kurulmuş olabilir)" ;;
        dnf|yum) rpm -qf "$f" 2>/dev/null || echo "  hiçbir pakete ait değil" ;;
        pacman)  pacman -Qo "$f" 2>/dev/null || echo "  hiçbir pakete ait değil" ;;
        apk)     apk info --who-owns "$f" 2>/dev/null || echo "  hiçbir pakete ait değil" ;;
    esac
}

case "${1:-incele}" in
    incele) incele ;;
    sorgu)  [[ $# -eq 2 ]] || kullanim; sorgu "$2" ;;
    kimin)  [[ $# -eq 2 ]] || kullanim; kimin "$2" ;;
    *)      kullanim ;;
esac

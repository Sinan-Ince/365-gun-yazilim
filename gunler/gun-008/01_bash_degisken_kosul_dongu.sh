#!/usr/bin/env bash
# Gün 008: Bash değişken, koşul ve döngü ile basit "sunucu sağlık raporu"
# Çalıştırmak için: bash 01_bash_degisken_kosul_dongu.sh
set -euo pipefail

calisma=$(mktemp -d)
trap 'rm -rf "$calisma"' EXIT

# --- Değişkenler ---
readonly ESIK=80                      # disk uyarı eşiği (%)
ortam="${ORTAM:-dev}"                 # ORTAM tanımsızsa "dev"
proje="365 gun"                       # boşluklu değer: tırnak şart
echo "== Değişkenler =="
echo "Proje: $proje | Ortam: $ortam | Eşik: %$ESIK"
echo "Proje adı uzunluğu: ${#proje}"
dosya="app-2026.log"
echo "Uzantısız: ${dosya%.log}, uzantı: ${dosya##*.}"

# --- Aritmetik ---
echo
echo "== Aritmetik (( )) =="
toplam=0
for n in 10 20 30; do
    (( toplam += n ))
done
echo "Toplam: $toplam, ortalama: $(( toplam / 3 ))"

# --- Dizi (array) ---
echo
echo "== Dizi =="
sunucular=(web1 web2 db1 cache1)
echo "Sunucu sayısı: ${#sunucular[@]}, ilki: ${sunucular[0]}"

# --- Örnek veri: sunucu adı ve disk doluluk oranı ---
cat > "$calisma/disk.txt" <<'VERI'
web1 45
web2 91
db1 83
cache1 12
VERI

# --- while read + if/elif/else ---
echo
echo "== Disk raporu (while read + if) =="
uyari=0
while read -r ad doluluk; do
    if (( doluluk >= 90 )); then
        durum="KRİTİK"
        (( uyari += 1 ))
    elif (( doluluk >= ESIK )); then
        durum="UYARI"
        (( uyari += 1 ))
    else
        durum="ok"
    fi
    printf "%-8s %3s%%  %s\n" "$ad" "$doluluk" "$durum"
done < "$calisma/disk.txt"
echo "Sorunlu sunucu sayısı: $uyari"

# --- case: sunucu rolünü adından çıkar ---
echo
echo "== case ile rol tespiti =="
for s in "${sunucular[@]}"; do
    case "$s" in
        web*)   rol="nginx" ;;
        db*)    rol="postgres" ;;
        cache*) rol="redis" ;;
        *)      rol="bilinmiyor" ;;
    esac
    echo "$s -> $rol"
done

# --- String ve dosya testleri ---
echo
echo "== [[ ]] testleri =="
[[ -d "$calisma" ]] && echo "Çalışma dizini var: $calisma"
[[ -f "$calisma/yok.txt" ]] || echo "yok.txt bulunamadı"
etiket="v1.4.2"
if [[ "$etiket" =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
    echo "Sürüm etiketi geçerli. major=${BASH_REMATCH[1]} minor=${BASH_REMATCH[2]}"
fi
bos=""
[[ -z "$bos" ]] && echo "bos değişkeni boş"

# --- C stili for ve break/continue ---
echo
echo "== for (( )) + continue/break =="
for (( i=1; i<=10; i++ )); do
    (( i % 2 == 0 )) && continue      # çiftleri atla
    (( i > 7 )) && break              # 7'yi geçince dur
    echo -n "$i "
done
echo

# --- Glob ile dosyalar üzerinde döngü ---
echo
echo "== Glob döngüsü =="
touch "$calisma"/{a,b,c}.log "$calisma/not.txt"
for f in "$calisma"/*.log; do
    echo "log: $(basename "$f")"
done

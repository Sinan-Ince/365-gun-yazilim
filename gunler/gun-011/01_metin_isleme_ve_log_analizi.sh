#!/usr/bin/env bash
# Gün 011: Metin işleme ile log analizi (grep, sed, awk, cut, sort | uniq -c)
# Sisteme dokunmaz: geçici klasöre örnek bir nginx erişim logu üretir ve analiz eder.
# Çalıştırmak için:
#   bash 01_metin_isleme_ve_log_analizi.sh             -> örnek log üret + analiz et
#   bash 01_metin_isleme_ve_log_analizi.sh dosya.log   -> kendi logunu analiz et (nginx "combined" formatı)
set -euo pipefail

# Geçici klasör, betik bitince (hata olsa bile) silinir: trap (Gün 009 sinyaller)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Örnek log satırı (nginx combined formatı), alan numaraları awk'a göre:
# 203.0.113.7 - - [29/Oct/2026:10:15:02 +0300] "GET /api/users HTTP/1.1" 200 512 "-" "curl/8.5"
# $1=IP  $4=[tarih  $6="METOT  $7=yol  $9=durum  $10=bayt
ornek_log_uret() {
    local ipler=(203.0.113.7 198.51.100.23 192.0.2.44 203.0.113.7 10.0.0.5 203.0.113.7 198.51.100.23)
    local yollar=(/ /api/users /api/orders /health /login /api/users /static/app.js)
    local durumlar=(200 200 200 200 304 404 500 200 401 502)
    local i ip yol durum dk
    for ((i = 0; i < 300; i++)); do
        # RANDOM: Bash'in 0-32767 arası rastgele sayısı; % ile diziden eleman seçiyoruz
        ip=${ipler[RANDOM % ${#ipler[@]}]}
        yol=${yollar[RANDOM % ${#yollar[@]}]}
        durum=${durumlar[RANDOM % ${#durumlar[@]}]}
        dk=$(printf '%02d' $((i / 10)))
        printf '%s - - [29/Oct/2026:10:%s:%02d +0300] "GET %s HTTP/1.1" %s %d "-" "curl/8.5"\n' \
            "$ip" "$dk" $((RANDOM % 60)) "$yol" "$durum" $((RANDOM % 5000 + 100))
    done
    # Gizli bilgi sızdıran kötü bir satır: sed ile maskeleyeceğiz
    echo '10.0.0.5 - - [29/Oct/2026:10:29:59 +0300] "GET /login?user=ali&password=Gizli123 HTTP/1.1" 200 90 "-" "curl/8.5"'
}

baslik() { printf '\n== %s ==\n' "$1"; }

LOG=${1:-}
if [[ -z $LOG ]]; then
    LOG=$TMP/access.log
    ornek_log_uret > "$LOG"
    echo "Örnek log üretildi: $(wc -l < "$LOG") satır"
    echo "İlk 2 satır:"; head -n 2 "$LOG"
elif [[ ! -r $LOG ]]; then
    echo "Okunamıyor: $LOG" >&2; exit 2
fi

baslik "grep: sayım ve süzme"
echo "Toplam istek       : $(wc -l < "$LOG")"
# '" 500 ' deseni: durum kodu tırnaktan sonra gelir, bayt alanıyla karışmaz
echo "500 hatası         : $(grep -c '" 500 ' "$LOG" || true)"
# -E: genişletilmiş regex. 5[0-9]{2} = 500-599
echo "Tüm 5xx            : $(grep -cE '" 5[0-9]{2} ' "$LOG" || true)"
# -v: /health OLMAYAN satırlar (izleme gürültüsünü at)
echo "/health hariç      : $(grep -vc '/health' "$LOG" || true)"
# grep -c eşleşme yoksa exit 1 döner; set -e betiği öldürmesin diye "|| true"

baslik "awk + sort + uniq: en çok istek atan 3 IP"
awk '{print $1}' "$LOG" | sort | uniq -c | sort -rn | head -n 3

baslik "awk: durum kodu dağılımı (dizi ile, sort|uniq'siz)"
awk '{n[$9]++} END {for (k in n) printf "  %s  %4d\n", k, n[k]}' "$LOG" | sort

baslik "awk: en çok hata (>=400) alan yollar"
# $9 >= 400 koşulu; sonra yol ($7) başına say. Sorgu dizesini (?...) sed ile at
awk '$9 >= 400 {print $7}' "$LOG" | sed 's/?.*//' | sort | uniq -c | sort -rn | head -n 3

baslik "awk: toplam gönderilen veri ve ortalama yanıt boyutu"
awk '{s += $10} END {printf "  toplam %.1f KB, ortalama %.0f bayt (%d istek)\n", s/1024, s/NR, NR}' "$LOG"

baslik "cut: dakika başına istek (zaman çizelgesi, ilk 5)"
# [29/Oct/2026:10:15:02 -> ":" ile böl, 2. ve 3. alan = saat ve dakika
cut -d' ' -f4 "$LOG" | cut -d: -f2,3 | sort | uniq -c | head -n 5

baslik "sed: gizli bilgiyi maskele (sadece ekrana, dosya değişmez)"
grep 'password=' "$LOG" | sed -E 's/(password=)[^& ]+/\1***/'
# \1: parantez içindeki ilk grubu geri koy. Yerinde değiştirmek için: sed -i.bak ...

baslik "grep -o: logdaki benzersiz IP'ler (regex ile çıkar)"
grep -oE '^([0-9]{1,3}\.){3}[0-9]{1,3}' "$LOG" | sort -u | paste -sd' ' -

baslik "grep -q: betikte koşul olarak"
if grep -qE '" 50[23] ' "$LOG"; then
    echo "  UYARI: 502/503 var, upstream (uygulama) çökmüş olabilir"
else
    echo "  502/503 yok"
fi

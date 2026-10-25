#!/usr/bin/env bash
# Gün 007: Pipe ve yönlendirme ile log analizi
# Çalıştırmak için: bash 03_pipe_ve_yonlendirme.sh
set -euo pipefail

calisma=$(mktemp -d)
cd "$calisma"
trap 'rm -rf "$calisma"' EXIT

# --- Örnek bir web sunucusu logu oluştur (heredoc: çok satırlı metin) ---
cat > access.log <<'LOG'
10.0.0.1 GET /index.html 200
10.0.0.2 GET /login 200
10.0.0.1 POST /login 401
10.0.0.3 GET /admin 403
10.0.0.1 GET /index.html 200
10.0.0.2 GET /api/users 500
10.0.0.4 GET /index.html 200
10.0.0.1 GET /api/users 500
10.0.0.2 POST /login 200
10.0.0.3 GET /admin 403
LOG

echo "== Kaç istek var? =="
wc -l < access.log                      # < : stdin'i dosyadan al

echo
echo "== Sadece 5xx hataları (grep) =="
grep ' 5[0-9][0-9]$' access.log

echo
echo "== Durum kodlarına göre sayım: cut | sort | uniq -c | sort -rn =="
cut -d' ' -f4 access.log | sort | uniq -c | sort -rn

echo
echo "== En çok istek atan 3 IP =="
cut -d' ' -f1 access.log | sort | uniq -c | sort -rn | head -3

echo
echo "== awk ile: başarısız (>=400) istekler, IP ve yol =="
awk '$4 >= 400 {print $1, "->", $3, "(" $4 ")"}' access.log

echo
echo "== sed ile IP'leri maskele (log paylaşırken gizlilik) =="
sed -E 's/^10\.0\.0\.[0-9]+/10.0.0.x/' access.log | head -3

echo
echo "== stdout ve stderr'i ayırmak =="
ls access.log yok.txt > cikti.txt 2> hata.txt || true   # || true: set -e betiği durdurmasın
echo "stdout: $(cat cikti.txt)"
echo "stderr: $(cat hata.txt)"

echo
echo "== İkisini aynı dosyaya: > dosya 2>&1 =="
ls access.log yok.txt > hepsi.txt 2>&1 || true
cat hepsi.txt

echo
echo "== > üzerine yazar, >> ekler =="
echo "satır 1" > not.txt
echo "satır 2" > not.txt                # satır 1 silindi
echo "satır 3" >> not.txt               # sona eklendi
cat not.txt

echo
echo "== tee: hem ekrana hem dosyaya =="
grep ' 403$' access.log | tee yasak.txt | wc -l
echo "yasak.txt içinde $(wc -l < yasak.txt) satır var"

echo
echo "== Komut yerine koyma ve && / || =="
hata_sayisi=$(grep -c ' 5[0-9][0-9]$' access.log)
echo "5xx hata sayısı: $hata_sayisi"
[ "$hata_sayisi" -gt 1 ] && echo "UYARI: birden fazla sunucu hatası var!"
grep -q ' 418$' access.log || echo "418 (I'm a teapot) hiç yok"

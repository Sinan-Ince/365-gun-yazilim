#!/usr/bin/env bash
# Gün 007: Dosya izinleri (chmod)
# Çalıştırmak için: bash 02_dosya_izinleri.sh
set -euo pipefail

calisma=$(mktemp -d)
cd "$calisma"
trap 'rm -rf "$calisma"' EXIT           # betik nasıl biterse bitsin, sonda temizle

izin() { stat -c '%A  %a  %n' "$1"; }  # harfli izin, sayısal izin, ad

echo "== Ben kimim? =="
id

echo
echo "== Yeni dosyanın varsayılan izni =="
echo 'echo "betik çalıştı"' > betik.sh
izin betik.sh                           # genelde -rw-r--r-- 644 (umask belirler)
echo "umask: $(umask)  (yeni dosyalardan kaldırılan haklar)"

echo
echo "== x izni olmadan ./betik.sh çalışır mı? =="
if ./betik.sh 2>/dev/null; then
    echo "çalıştı"
else
    echo "Permission denied: x izni yok"
fi

echo
echo "== chmod +x sonrası =="
chmod +x betik.sh
izin betik.sh
./betik.sh

echo
echo "== Sayısal izinler =="
touch normal.txt gizli.env anahtar.pem
chmod 644 normal.txt
chmod 600 gizli.env
chmod 400 anahtar.pem
mkdir ozel && chmod 700 ozel
for f in normal.txt gizli.env anahtar.pem ozel; do izin "$f"; done

echo
echo "== 400 izinli dosyaya yazmayı dene =="
if { echo "deneme" > anahtar.pem; } 2>/dev/null; then   # {} : yönlendirme hatasını da sustur
    echo "yazıldı (root olarak çalışıyor olabilirsin, root izinleri aşar)"
else
    echo "Permission denied: sadece okuma izni var"
fi

echo
echo "== Harfli chmod =="
touch ortak.txt
chmod u=rw,g=r,o= ortak.txt             # sahip rw, grup r, diğerleri hiç
izin ortak.txt
chmod g+w ortak.txt                     # gruba yazma ekle
izin ortak.txt

echo
echo "== Klasörde x izni: içine girebilme hakkı =="
mkdir kilitli && echo "içerik" > kilitli/dosya.txt
chmod 600 kilitli                       # r ve w var, x yok
if cat kilitli/dosya.txt 2>/dev/null; then
    echo "okundu (root olabilirsin)"
else
    echo "Klasörde x yok: içindeki dosyaya ulaşılamıyor"
fi
chmod 700 kilitli                       # temizlik için izni geri ver

#!/usr/bin/env bash
# Gün 007: Linux dosya sistemi ve temel komutlar
# Çalıştırmak için: bash 01_dosya_sistemi.sh
# Her şey geçici bir klasörde yapılır ve sonda silinir.
set -euo pipefail

echo "== Neredeyim? =="
echo "pwd   : $(pwd)"
echo "HOME  : $HOME  (kısaltması ~)"
echo "Kullanıcı: $(whoami) | Shell: ${SHELL:-bilinmiyor}"

echo
echo "== Önemli klasörler var mı? =="
for k in /etc /var/log /usr/bin /tmp /proc /dev; do
    if [ -d "$k" ]; then
        echo "  [var] $k  ($(ls "$k" | wc -l) öğe)"
    fi
done

echo
echo "== Geçici bir proje klasörü oluştur =="
calisma=$(mktemp -d)                    # /tmp altında benzersiz bir klasör
cd "$calisma"
mkdir -p proje/src proje/logs           # -p: ara klasörleri de oluştur
touch proje/src/app.py proje/.env       # .env gizli dosya
echo "print('merhaba')" > proje/src/app.py
echo "INFO başladı" > proje/logs/app.log

echo "--- ls proje (gizliler görünmez):"
ls proje
echo "--- ls -a proje (gizliler de görünür):"
ls -a proje

echo
echo "== Kopyala, taşı, yeniden adlandır =="
cp proje/src/app.py proje/src/app_yedek.py
mv proje/src/app_yedek.py proje/src/eski_app.py
ls proje/src

echo
echo "== find ile ara =="
find proje -name "*.py"
find proje -type d                      # sadece klasörler

echo
echo "== Göreli ve mutlak yol =="
cd proje/src
echo "Şu an: $(pwd)"
echo "Göreli ../logs/app.log içeriği: $(cat ../logs/app.log)"
cd - > /dev/null                        # önceki klasöre dön, çıktıyı at
echo "Geri döndüm: $(pwd)"

echo
echo "== Komutlar nerede? =="
for komut in bash git python ls; do
    echo "  $komut -> $(command -v "$komut" || echo 'yok')"
done

echo
echo "== Temizlik =="
cd /
rm -rf "$calisma"                       # tırnak önemli: boşluklu yollarda bozulmaz
[ ! -d "$calisma" ] && echo "Geçici klasör silindi."

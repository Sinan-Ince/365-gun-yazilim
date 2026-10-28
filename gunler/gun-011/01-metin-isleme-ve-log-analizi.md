# Bash: Metin İşleme ve Log Analizi (`grep`, `sed`, `awk`, `cut`, `sort | uniq -c`)

**Tanım:**
- **Metin işleme (text processing):** Linux'ta neredeyse her şey satır satır metindir: loglar, config dosyaları, komut çıktıları. Unix felsefesi: her araç tek işi iyi yapar, araçlar **pipe** (Gün 007) ile birbirine bağlanır.
- **`grep`:** Satır **süzer** (filter). Desene (pattern) uyan satırları basar.
- **`sed` (stream editor):** Satırları **dönüştürür**: bul-değiştir, satır silme, aralık basma.
- **`awk`:** Satırları **alanlara (field)** böler ve üzerinde hesap yapar. Küçük bir programlama dilidir: değişken, koşul, dizi (array), `printf`.
- **`cut` / `sort` / `uniq` / `wc` / `head` / `tail`:** Sütun kesme, sıralama, tekrar sayma, sayma, baş/son.
- **Düzenli ifade (regular expression, regex):** Metin deseni dili. `^` satır başı, `$` satır sonu, `.` herhangi bir karakter, `*` sıfır veya daha fazla, `+` bir veya daha fazla (ERE), `[0-9]` karakter sınıfı, `( | )` gruplama/veya.

**Neden önemli:** Bir sunucu yavaşladığında ilk iş loglara bakmaktır: "son 1 saatte kaç 500 hatası var, hangi IP en çok istek atıyor, hangi endpoint yavaş?" Bunun cevabı tek satırlık bir pipe'tır. `journalctl`, `kubectl logs`, `docker logs`, CloudWatch'tan indirilen loglar, CI çıktıları: hepsi metin. Betiklerde config düzenlemek (`sed -i`), komut çıktısından değer çekmek (`awk '{print $2}'`) DevOps'un günlük işidir. Mülakatlarda "bu logdan en çok istek atan 10 IP'yi bul" klasik sorudur.

## grep: süz
| Bayrak | Anlamı |
|---|---|
| `-i` | büyük/küçük harf duyarsız |
| `-v` | uymayanları bas (tersine çevir) |
| `-c` | eşleşen satır **sayısı** |
| `-n` | satır numarası |
| `-o` | sadece eşleşen **parçayı** bas |
| `-E` | genişletilmiş regex (ERE): `+ ? \| ()` kaçışsız |
| `-F` | regex değil düz metin (hızlı, `.` gibi karakterler sorun olmaz) |
| `-r` | klasörde özyinelemeli ara |
| `-A 3 / -B 3 / -C 3` | eşleşmeden sonra/önce/etrafında 3 satır |
| `-q` | hiçbir şey basma, sadece exit kodu (betikte `if grep -q ...`) |

```bash
grep -c ' 500 ' access.log                    # kaç tane 500
grep -E '" (4|5)[0-9]{2} ' access.log         # tüm 4xx ve 5xx
grep -v '/health' access.log                  # health check gürültüsünü at
grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' x.log  # metindeki tüm IP'ler
grep -rn 'TODO' src/                          # kodda TODO ara
```

## sed: dönüştür
```bash
sed 's/http:/https:/' f          # her satırdaki İLK eşleşmeyi değiştir
sed 's/http:/https:/g' f         # g: hepsini
sed -n '10,20p' f                # sadece 10-20. satırları bas (-n: otomatik basmayı kapat)
sed '/^#/d; /^$/d' nginx.conf    # yorum ve boş satırları sil
sed -E 's/password=[^ ]+/password=***/' app.log   # gizli bilgiyi maskele
sed -i.bak 's/^PORT=.*/PORT=8080/' .env           # dosyayı yerinde düzenle, .bak yedeği al
```
> `sed -i` dosyayı **yerinde** değiştirir. Önce `-i` olmadan çalıştırıp çıktıyı gör, sonra `-i` ekle. macOS'ta (BSD sed) `-i ''` gerekir.

## awk: alanlara böl, hesapla
`awk` her satırı boşluklara göre böler: `$1` ilk alan, `$NF` son alan, `$0` satırın tamamı, `NR` satır numarası, `-F` ayraç.
```bash
awk '{print $1}' access.log                     # sadece IP sütunu
awk -F: '{print $1, $7}' /etc/passwd            # kullanıcı adı ve kabuğu (Gün 010)
awk '$9 >= 500' access.log                      # koşul: durum kodu 500 ve üstü
awk '{s += $10} END {print s/1024/1024 " MB"}' access.log   # toplam gönderilen bayt
awk '{n[$1]++} END {for (ip in n) print n[ip], ip}' access.log  # IP başına sayım (dizi)
```

## Klasik pipe: "en çok ... olan 10 tane"
```bash
awk '{print $1}' access.log | sort | uniq -c | sort -rn | head -n 10
#  └─ IP'leri çek ─┘   └ grupla ┘ └ say ┘ └ çoktan aza ┘ └ ilk 10 ┘
```
`uniq` sadece **yan yana** tekrarları birleştirir, bu yüzden önce `sort` şarttır.

## Hangi araç ne zaman
| İş | Araç |
|---|---|
| Satır seç | `grep` |
| Satır değiştir / sil | `sed` |
| Sütun seç, hesapla, grupla | `awk` (basit sabit ayraçta `cut -d: -f1`) |
| Say | `wc -l`, `grep -c`, `uniq -c` |
| JSON log | `jq` (bu araçlar JSON'u anlamaz) |

> Canlı log izlemek: `tail -F /var/log/nginx/access.log | grep --line-buffered ' 500 '`. `-F` dosya döndürülse (logrotate) bile takibe devam eder.

Kod: [`01_metin_isleme_ve_log_analizi.sh`](01_metin_isleme_ve_log_analizi.sh). Örnek bir nginx erişim logu üretip üzerinde analiz yapar.

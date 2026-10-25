# Pipe ve Yönlendirme

**Tanım:**
- **Standart akışlar:** Her komutun üç kanalı vardır. **stdin (0)** girdi, **stdout (1)** normal çıktı, **stderr (2)** hata çıktısı.
- **Yönlendirme (redirection):** Bu kanalları dosyaya bağlamak ya da dosyadan almak: `>`, `>>`, `<`, `2>`.
- **Pipe (`|`):** Bir komutun stdout çıktısını doğrudan bir sonrakinin stdin girdisine bağlamak.

**Neden önemli:** Unix felsefesi şudur: "Her program tek bir işi iyi yapsın, programlar birbirine bağlansın." Küçük komutları pipe ile birleştirerek, tek satırda program yazmadan bir log dosyasını analiz edebilirsin. Sunucuda bir sorun çıkınca ilk yapılan iş budur: `grep ERROR app.log | tail -20`.

## Yönlendirme
| Yazım | Anlamı |
|---|---|
| `komut > dosya` | stdout'u dosyaya yaz (**üzerine yazar**) |
| `komut >> dosya` | stdout'u dosyanın sonuna ekle |
| `komut < dosya` | stdin'i dosyadan al |
| `komut 2> hata.log` | Sadece hataları dosyaya yaz |
| `komut > cikti.log 2>&1` | stdout ve stderr'i aynı dosyaya yaz |
| `komut &> hepsi.log` | Aynısı, bash kısayolu |
| `komut > /dev/null 2>&1` | Bütün çıktıyı at (sessiz çalıştır) |
| `komut \| tee dosya` | Hem ekrana yaz hem dosyaya kaydet |

> `2>&1` şu demek: "2 numaralı kanalı (stderr), 1 numaralı kanalın (stdout) gittiği yere gönder." Sıra önemlidir: `> dosya 2>&1` doğrudur, `2>&1 > dosya` yazarsan hatalar yine ekrana gider.

## Pipe ile en sık kullanılan komutlar
| Komut | İşi | Örnek |
|---|---|---|
| `grep` | Satır filtrele | `grep -i error app.log`, `grep -v DEBUG` (eşleşmeyenler) |
| `wc -l` | Satır say | `grep ERROR app.log \| wc -l` |
| `sort` | Sırala | `sort -n` (sayısal), `sort -r` (ters) |
| `uniq -c` | Ardışık tekrarları say (önce `sort` gerekir) | `sort \| uniq -c` |
| `cut` | Sütun al | `cut -d' ' -f1` (boşluğa göre 1. sütun) |
| `awk` | Sütun işleme, küçük hesaplar | `awk '{print $1, $9}'` |
| `sed` | Bul-değiştir | `sed 's/eski/yeni/g'` |
| `head`, `tail` | İlk / son N satır | `head -5` |
| `tr` | Karakter dönüştür | `tr 'a-z' 'A-Z'` |
| `xargs` | Girdiyi komut argümanına çevir | `find . -name "*.tmp" \| xargs rm` |

## Klasik örnek: en çok istek atan 3 IP
```bash
cat access.log | cut -d' ' -f1 | sort | uniq -c | sort -rn | head -3
#     IP'leri al  →  sırala  →  say  →  çoktan aza  →  ilk 3
```

## Komut yerine koyma (command substitution) ve zincirleme
```bash
bugun=$(date +%F)                 # komutun çıktısını değişkene al
echo "Yedek: yedek-$bugun.tar.gz"

mkdir build && cd build           # && : ilki başarılıysa ikincisini çalıştır
ping -c1 sunucu || echo "erişilemiyor"   # || : ilki başarısızsa ikincisini çalıştır
```

## Python ile karşılaştırma
Aynı "en çok görülen IP" işini Python'da 10 satırda yazarsın (Gün 006'daki dosya okuma ve Gün 003'teki sözlük ile). Bash'te tek satır yeter. Hızlı bir analiz için pipe, kalıcı ve karmaşık bir iş için Python seçilir.

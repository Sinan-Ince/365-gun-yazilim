# Dosya İşlemleri ve `with`

**Tanım:**
- **Dosya işlemleri (file I/O):** Programın diskteki dosyaları okuması ve dosyalara yazması. `open()` fonksiyonu dosyayı açar ve bir dosya nesnesi döndürür.
- **Context manager (`with`):** Bir kaynağı açıp iş bitince **otomatik kapatan** yapı. `with` bloğundan çıkıldığında, arada hata olsa bile, dosya kapanır.
- **JSON:** Veriyi metin olarak saklamanın yaygın biçimi. Python'daki `dict` ve `list` yapılarına doğrudan karşılık gelir.

**Neden önemli:**
- DevOps işinin büyük kısmı dosyalarla ilgilidir: config dosyaları (JSON, YAML, `.env`), log dosyaları, raporlar.
- AWS CLI çıktıları, Terraform state dosyası ve API yanıtları JSON biçimindedir.
- Kapatılmayan dosya sızıntıya yol açar: veri diske yazılmadan kalabilir, işletim sisteminin açık dosya sınırı dolabilir. `with` bunu kendiliğinden çözer.

## open() modları
| Mod | Anlamı | Dosya yoksa |
|---|---|---|
| `"r"` | Okuma (varsayılan) | Hata: `FileNotFoundError` |
| `"w"` | Yazma, **içeriği siler** | Oluşturur |
| `"a"` | Sona ekleme (log için ideal) | Oluşturur |
| `"x"` | Sadece yeni dosya oluştur | Oluşturur. Dosya varsa hata verir |
| `"b"` eki | İkili mod (`"rb"`, `"wb"`): resim, zip vb. | |

> Metin dosyalarında her zaman `encoding="utf-8"` yaz. Yazmazsan Windows'ta Türkçe karakterler bozulabilir.

## with olmadan ve with ile
```python
# Kötü: arada hata çıkarsa close() hiç çalışmaz
f = open("not.txt", "w", encoding="utf-8")
f.write("merhaba")
f.close()

# İyi: blok bitince dosya kendiliğinden kapanır
with open("not.txt", "w", encoding="utf-8") as f:
    f.write("merhaba")
```

## Okuma yöntemleri
| Yöntem | Döndürür | Ne zaman |
|---|---|---|
| `f.read()` | Tüm içerik, tek string | Küçük dosyalar |
| `f.readlines()` | Satır listesi | Küçük dosyalar |
| `for satir in f:` | Satır satır okur | **Büyük dosyalar** (log). Dosyanın tamamı belleğe alınmaz |

## pathlib
`pathlib.Path` dosya yollarıyla nesne olarak çalışmayı sağlar. `os.path` fonksiyonlarının modern karşılığıdır.
```python
from pathlib import Path
yol = Path("veri") / "ayar.json"     # / işareti ile yol birleştirilir, Windows'ta da çalışır
yol.parent.mkdir(exist_ok=True)      # klasörü oluştur
yol.write_text("{}", encoding="utf-8")
print(yol.exists(), yol.suffix)      # True .json
```

## Diğer dillerde
```go
// Go: defer, fonksiyon bitince çalışır. with'in Go'daki karşılığıdır.
f, err := os.Open("not.txt")
if err != nil { log.Fatal(err) }
defer f.Close()
```
```java
// Java: try-with-resources
try (var r = Files.newBufferedReader(Path.of("not.txt"))) {
    System.out.println(r.readLine());
}
```
```csharp
// C#: using
using var r = new StreamReader("not.txt");
Console.WriteLine(r.ReadLine());
```
```bash
# Bash: Linux ayında çok kullanacağız
echo "merhaba" > not.txt     # "w" gibi (üzerine yazar)
echo "ikinci" >> not.txt     # "a" gibi (sona ekler)
cat not.txt                  # oku
```

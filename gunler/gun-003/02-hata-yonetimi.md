# Hata Yönetimi (try / except)

**Tanım:** Program çalışırken oluşan hatayı (exception) yakalayıp programın çökmesini engellemek ve hataya uygun tepki vermektir.

**Neden önemli:** Dosya olmayabilir, ağ kopabilir, kullanıcı sayı yerine harf girebilir. İyi bir program bu durumlarda çökmez, anlamlı bir mesaj verir ya da tekrar dener.

## Yapı
```python
try:
    ...                     # hata çıkabilecek kod
except ValueError as e:
    ...                     # bu hata tipi olursa
else:
    ...                     # hata OLMAZSA
finally:
    ...                     # her durumda (dosya/bağlantı kapatma)
```

## Sık görülen hata tipleri
| Hata | Ne zaman |
|---|---|
| `ValueError` | `int("abc")` |
| `TypeError` | `"5" + 5` |
| `KeyError` | Sözlükte olmayan anahtar |
| `IndexError` | Listede olmayan indeks |
| `FileNotFoundError` | Dosya yok |
| `ZeroDivisionError` | Sıfıra bölme |

## Kurallar
- ❌ Çıplak `except:` yazma. Bütün hataları yutar, gerçek sorunu gizler.
- ✅ Beklediğin hata tipini yakala.
- `raise` ile kendin hata fırlatabilirsin: `raise ValueError("port 1-65535 arası olmalı")`

## Diğer dillerde
```java
// Java / C# / JS: try - catch - finally
try { int x = Integer.parseInt("abc"); }
catch (NumberFormatException e) { System.out.println("sayı değil"); }
finally { System.out.println("bitti"); }
```
```go
// Go'da exception yok: hata bir dönüş değeridir
n, err := strconv.Atoi("abc")
if err != nil {
    fmt.Println("hata:", err)
    return
}
```
```bash
# Bash: her komutun çıkış kodu vardır. 0 = başarılı, diğerleri = hata
set -e                              # bir komut hata verirse scripti durdur
cp ayar.conf /yedek/ || echo "kopyalama başarısız"
if ! ping -c 1 db1 > /dev/null; then
    echo "db1 erişilemiyor"; exit 1
fi
```

> **DevOps bağlantısı:** CI/CD pipeline'ı bir adımın çıkış kodu 0 değilse durur. Scriptlerinde hatayı doğru yönetmek, pipeline'ın doğru çalışması demektir.

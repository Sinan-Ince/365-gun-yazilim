# Fonksiyonlar

**Tanım:** Fonksiyon, bir işi yapan ve isim verilmiş kod bloğudur. Dışarıdan **parametre** alır, işini yapar ve isterse bir değer **döndürür** (`return`).

**Neden önemli:**
- **Tekrarı önler (DRY: Don't Repeat Yourself).** Aynı kodu 10 yere kopyalamak yerine bir kez yazıp 10 yerden çağırırsın.
- **Okunabilirlik.** `yedek_al()` satırını okuyan biri, içindeki 30 satırı okumadan ne yapıldığını anlar.
- **Test edilebilirlik.** Küçük fonksiyonları tek tek test etmek kolaydır.

## Kavramlar
| Kavram | Anlamı |
|---|---|
| Parametre | Fonksiyon tanımındaki değişken: `def selam(isim)` |
| Argüman | Çağırırken verilen değer: `selam("Sinan")` |
| Varsayılan değer | Argüman verilmezse kullanılır: `def selam(isim="dünya")` |
| `return` | Sonucu çağırana geri verir. `return` yoksa Python `None` döndürür |
| Scope (kapsam) | Fonksiyon içinde tanımlanan değişken dışarıdan görülmez |

## Diğer dillerde
```java
// Java: dönüş tipi ve parametre tipleri yazılır
static int topla(int a, int b) { return a + b; }
```
```go
// Go: birden fazla değer döndürebilir (hata yönetiminde çok kullanılır)
func bol(a, b float64) (float64, error) {
    if b == 0 { return 0, errors.New("sıfıra bölme") }
    return a / b, nil
}
```
```javascript
// JavaScript: arrow function
const topla = (a, b) => a + b;
```
```bash
# Bash: parametreler $1, $2 ile alınır. return sadece çıkış kodu (0-255) döndürür
selam() { echo "Merhaba $1"; }
selam "Sinan"
```

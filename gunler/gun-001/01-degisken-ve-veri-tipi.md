# Değişken ve Veri Tipi

**Tanım:** Değişken, bellekte bir değeri tutan ve isimle erişilen bir alandır. Veri tipi, o değerin ne tür olduğunu söyler: sayı, metin, mantıksal değer gibi.

**Neden önemli:** Tip, o değerle neler yapılabileceğini belirler. Örneğin `"5" * 3` sonucu `"555"` olur, `5 * 3` sonucu ise `15`.

## Statik tip ve dinamik tip
| | Statik tipli (Java, C#, Go) | Dinamik tipli (Python, JS) |
|---|---|---|
| Tip ne zaman belli olur? | Derleme anında | Çalışma anında |
| Örnek | `int yas = 21;` | `yas = 21` |
| Artısı | Hatalar erken yakalanır | Hızlı ve esnek yazılır |

## Diğer dillerde aynı kod
```java
// Java
int yas = 21;
String isim = "Kiroschi";
```
```go
// Go
yas := 21          // tip çıkarımı: int
var isim string = "Kiroschi"
```
```bash
# Bash: her şey metindir
yas=21
isim="Kiroschi"
echo "$isim $yas yaşında"
```

Örnek kod için `01_degisken_ve_veri_tipi.py` dosyasına bak.

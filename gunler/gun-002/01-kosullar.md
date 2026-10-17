# Koşullar (if / else)

**Tanım:** Koşul, bir ifadenin doğru (`True`) ya da yanlış (`False`) olmasına göre programın hangi yoldan gideceğine karar verir.

**Neden önemli:** Karar vermeyen bir program her seferinde aynı şeyi yapar. Kullanıcı giriş yapmış mı, dosya var mı, sunucu cevap verdi mi gibi bütün kontroller koşulla yazılır.

## Karşılaştırma ve mantık operatörleri
| Operatör | Anlamı | Örnek |
|---|---|---|
| `==` `!=` | Eşit mi, eşit değil mi | `yas == 18` |
| `<` `>` `<=` `>=` | Küçük, büyük | `not >= 50` |
| `and` / `&&` | İkisi de doğru | `yas > 18 and ogrenci` |
| `or` / `\|\|` | Biri doğru | `admin or sahip` |
| `not` / `!` | Tersi | `not bos` |

## Diğer dillerde
```java
// Java, JS, C#, Go: süslü parantez kullanılır
if (not >= 85) { harf = "AA"; }
else if (not >= 50) { harf = "CC"; }
else { harf = "FF"; }
```
```bash
# Bash: DevOps scriptlerinde en sık görülen koşul
if [ -f "/etc/nginx/nginx.conf" ]; then
    echo "nginx ayarı var"
elif [ -d "/etc/nginx" ]; then
    echo "klasör var, ayar dosyası yok"
else
    echo "nginx kurulu değil"
fi
```

> **Truthy / Falsy:** Python ve JS'de `0`, `""`, `[]`, `None`/`null` değerleri koşulda **yanlış** sayılır. Bu yüzden `if liste:` yazmak, "liste boş değilse" demektir.

# Koleksiyonlar (list, tuple, set, dict)

**Tanım:** Koleksiyon, birden çok değeri tek bir değişkende tutan veri yapısıdır.

**Neden önemli:** Sunucu listesi, kullanıcı bilgileri, ayar dosyaları, API'den dönen JSON gibi gerçek hayattaki verilerin neredeyse hepsi koleksiyondur.

## Dört temel yapı
| Yapı | Yazımı | Sıralı mı | Değiştirilebilir mi | Tekrar eden eleman | Ne zaman |
|---|---|---|---|---|---|
| **list** | `[1, 2, 3]` | ✅ | ✅ | ✅ | Sırası önemli, büyüyüp küçülen veri |
| **tuple** | `(1, 2, 3)` | ✅ | ❌ | ✅ | Sabit veri: koordinat, `(host, port)` |
| **set** | `{1, 2, 3}` | ❌ | ✅ | ❌ | Tekrarları silmek, "içinde var mı" kontrolü |
| **dict** | `{"ad": "Sinan"}` | ✅ (3.7+) | ✅ | Anahtar tekrar etmez | Anahtar ile değere ulaşmak |

## Hız notu
`x in liste` her elemana tek tek bakar (yavaş, O(n)).
`x in kume` ve `x in sozluk` doğrudan bulur (hızlı, O(1)). Büyük veride "var mı?" sorusu için set veya dict kullan.

## Diğer dillerde
| Python | Java | C# | JS/TS | Go |
|---|---|---|---|---|
| list | `ArrayList` | `List<T>` | `Array` | slice `[]int` |
| tuple | `record` | `(int, string)` | yok (dizi kullanılır) | yok (struct) |
| set | `HashSet` | `HashSet<T>` | `Set` | `map[T]bool` |
| dict | `HashMap` | `Dictionary<K,V>` | `Object` / `Map` | `map[K]V` |

```go
// Go: map
portlar := map[string]int{"http": 80, "https": 443}
fmt.Println(portlar["https"])
```
```bash
# Bash: dizi ve sözlük (associative array)
sunucular=(web1 web2 db1)
echo "${sunucular[0]}"         # web1
declare -A portlar=([http]=80 [ssh]=22)
echo "${portlar[ssh]}"         # 22
```

> **DevOps bağlantısı:** JSON ve YAML dosyaları aslında iç içe dict ve list'tir. Docker compose, Kubernetes ve GitHub Actions dosyalarını okurken bu yapıları göreceksin.

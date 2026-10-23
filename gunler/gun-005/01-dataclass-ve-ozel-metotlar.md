# Dataclass ve Özel Metotlar (dunder)

**Tanım:**
- **Özel metot (dunder method):** Adı iki alt çizgiyle başlayıp biten metotlardır (`__init__`, `__repr__`, `__eq__`). Python bunları kendisi çağırır. Örneğin `print(x)` aslında `x.__str__()` metodunu, `a == b` ise `a.__eq__(b)` metodunu çağırır. "dunder" kelimesi "double underscore" ifadesinin kısaltmasıdır.
- **Dataclass:** Asıl işi **veri taşımak** olan sınıflar için `@dataclass` süsleyicisi (decorator). Bu süsleyici `__init__`, `__repr__` ve `__eq__` metotlarını senin yerine yazar.

**Neden önemli:** Gerçek projelerde sınıfların çoğu "ayar", "kayıt", "istek" gibi veri kutularıdır. Bunlar için her seferinde `__init__` yazmak hem uzun hem de hataya açık. Dataclass bu işi tek satıra indirir. Ayrıca nesneyi yazdırınca `<Sunucu object at 0x7f...>` yerine okunabilir bir çıktı alırsın, bu da hata ayıklamayı kolaylaştırır.

## En sık kullanılan özel metotlar
| Metot | Ne zaman çalışır | Örnek |
|---|---|---|
| `__init__` | Nesne oluşurken | `Sunucu("web1")` |
| `__repr__` | Geliştiriciye gösterim: konsol, log, hata ayıklama | `Sunucu(ad='web1', port=80)` |
| `__str__` | Kullanıcıya gösterim (`print`, `str()`) | `web1:80` |
| `__eq__` | `a == b` | İki nesneyi içeriğine göre karşılaştırır |
| `__lt__` | `a < b` | `sorted()` ile sıralama |
| `__len__` | `len(x)` | Bir koleksiyonun eleman sayısı |

> `__eq__` yazılmazsa `==` iki değişkenin **aynı nesne** olup olmadığına bakar, içeriğe bakmaz. Yani iki ayrı `Sunucu("web1")` nesnesi eşit sayılmaz.

## Dataclass seçenekleri
| Yazım | Anlamı |
|---|---|
| `@dataclass` | `__init__`, `__repr__` ve `__eq__` metotlarını otomatik yazar |
| `@dataclass(frozen=True)` | Nesne oluştuktan sonra değiştirilemez (immutable), sözlükte anahtar olarak kullanılabilir |
| `@dataclass(order=True)` | `<` ve `>` karşılaştırmalarını ekler, `sorted()` çalışır |
| `etiketler: list = field(default_factory=list)` | Değiştirilebilir varsayılan değer verir. `= []` yazmak **hatadır**, çünkü aynı liste bütün nesneler arasında paylaşılır |

## Ne zaman dataclass, ne zaman normal sınıf?
- **Dataclass:** Sınıfın asıl işi veri tutmaksa. Örnek: ayar, API yanıtı, veritabanı satırı.
- **Normal sınıf:** Davranış ağır basıyorsa, iç durumu gizlemek gerekiyorsa ya da kurucu (`__init__`) karmaşıksa.

## Diğer dillerde
```java
// Java 16+: record = değiştirilemez veri sınıfı. equals, hashCode ve toString otomatik gelir.
public record Sunucu(String ad, int port) {}
var web1 = new Sunucu("web1", 80);
System.out.println(web1);   // Sunucu[ad=web1, port=80]
```
```csharp
// C# 9+: record
public record Sunucu(string Ad, int Port);
```
```typescript
// TypeScript'te dataclass yok. Veri şekli genelde interface ya da type ile tanımlanır.
interface Sunucu { ad: string; port: number }
const web1: Sunucu = { ad: "web1", port: 80 };
```
```go
// Go: struct zaten bir veri kutusudur. == alan alan karşılaştırır.
type Sunucu struct { Ad string; Port int }
fmt.Printf("%+v\n", Sunucu{"web1", 80})   // {Ad:web1 Port:80}
```

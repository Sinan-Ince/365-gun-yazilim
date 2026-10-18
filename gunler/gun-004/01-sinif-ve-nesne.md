# Sınıf ve Nesne (class, object, static)

**Tanım:**
- **Sınıf (class):** Bir şeyin kalıbıdır. Hangi verileri (özellik / attribute) ve hangi davranışları (metot) taşıyacağını tanımlar.
- **Nesne (object / instance):** O kalıptan üretilmiş somut örnektir. `Sunucu` bir sınıftır, `web1` ise bir nesnedir.

**Neden önemli:** Birbiriyle ilgili veriyi ve o veri üzerinde çalışan fonksiyonları bir arada tutar. Java ve C#'ta her şey sınıfların içinde yazılır. Python'da da kütüphanelerin çoğu (ör. AWS'nin `boto3` kütüphanesi) sınıflarla çalışır.

## Temel parçalar
| Parça | Python | Anlamı |
|---|---|---|
| Kurucu (constructor) | `__init__` | Nesne oluşurken çalışır, başlangıç değerlerini atar |
| `self` | `self.ad` | "Bu nesnenin kendisi". Java/C#/JS'deki `this` |
| Nesne metodu | `def baslat(self)` | Belirli bir nesne üzerinde çalışır |
| Sınıf değişkeni | `sayac = 0` (sınıf gövdesinde) | Bütün nesneler için ortaktır |
| Static metot | `@staticmethod` | Nesneye de sınıfa da ihtiyaç duymayan yardımcı fonksiyon |
| Sınıf metodu | `@classmethod` | Nesneye değil sınıfın kendisine erişir (`cls`) |

## static ne demek?
**static**, "nesneye değil sınıfa ait" demektir. Nesne oluşturmadan `Sinif.metot()` şeklinde çağrılır.
- Örnek: `Math.max(3, 5)` (Java). Bir "Math nesnesi" oluşturmaya gerek yoktur.
- Ne zaman kullanılır: Nesnenin verisine ihtiyaç duymayan yardımcı işlerde (doğrulama, dönüştürme) ve bütün nesnelerin paylaştığı sayaç ya da ayarlarda.

## Kapsülleme (encapsulation)
Nesnenin iç verisini dışarıdan doğrudan değiştirilmeye karşı korumaktır.
- Java/C#: `private`, `protected`, `public` anahtar kelimeleri vardır.
- Python'da bu kural bir gelenektir: `_ad` "dokunma, iç kullanım" demektir. `__ad` ise ismi değiştirerek erişimi zorlaştırır.

## Diğer dillerde
```java
// Java
public class Sunucu {
    private String ad;                  // kapsülleme
    private static int adet = 0;        // sınıf değişkeni

    public Sunucu(String ad) {          // kurucu
        this.ad = ad;
        adet++;
    }
    public static int getAdet() { return adet; }
}
Sunucu web1 = new Sunucu("web1");
```
```go
// Go'da class yok: struct + metot
type Sunucu struct { Ad string; Port int }
func (s Sunucu) Adres() string { return fmt.Sprintf("%s:%d", s.Ad, s.Port) }
web1 := Sunucu{Ad: "web1", Port: 80}
```
```typescript
// TypeScript
class Sunucu {
  static adet = 0;
  constructor(private ad: string, public port = 80) { Sunucu.adet++; }
}
```

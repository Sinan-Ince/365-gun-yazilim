# Kalıtım, Polimorfizm ve Interface

**Tanım:**
- **Kalıtım (inheritance):** Bir sınıfın başka bir sınıfın özelliklerini ve metotlarını devralmasıdır. `Kedi`, `Hayvan`'dan türer.
- **Polimorfizm (çok biçimlilik):** Farklı sınıfların aynı isimli metodu kendi yöntemiyle uygulaması. Hepsine `ses_cikar()` dersin, her biri kendi sesini çıkarır.
- **Interface / abstract class:** "Bu metotları uygulamak zorundasın" diyen bir sözleşmedir. Nasıl yapılacağını söylemez, ne yapılması gerektiğini söyler.

**Neden önemli:** Ortak kodu bir kez yazarsın. Kod, somut sınıfa değil sözleşmeye bağlı olur. Örnek: Uygulaman bir `Depolama` interface'ine bağlıysa, yerel diskten AWS S3'e geçerken sadece yeni bir sınıf yazarsın, kodun geri kalanı değişmez.

## OOP'nin 4 temel ilkesi (mülakatta çok sorulur)
| İlke | Kısaca |
|---|---|
| **Kapsülleme** (encapsulation) | Veriyi gizle, erişimi metotlarla kontrol et |
| **Kalıtım** (inheritance) | Ortak özellikleri üst sınıftan devral |
| **Polimorfizm** (polymorphism) | Aynı arayüz, farklı davranış |
| **Soyutlama** (abstraction) | Detayı gizle, sadece gerekeni göster |

## Önemli kavramlar
- `super()`: Üst sınıfın metodunu çağırır. Genelde kurucuda kullanılır.
- **Override:** Alt sınıfın, üst sınıftaki metodu kendi hâliyle yeniden yazması.
- **Kalıtım yerine birleştirme (composition over inheritance):** "Araba bir Motordur" yanlıştır, "Araba'nın bir Motoru vardır" doğrudur. Derin kalıtım zincirleri yerine nesneleri birbirinin içinde kullanmak genelde daha iyidir.

## Diğer dillerde
```java
// Java: interface ve implements
interface Depolama { void kaydet(String veri); }

class S3Depolama implements Depolama {
    public void kaydet(String veri) { /* S3'e yükle */ }
}
class Kedi extends Hayvan { @Override public String sesCikar() { return "Miyav"; } }
```
```go
// Go: interface "örtük" uygulanır. implements yazılmaz,
// metodu olan her tip o interface'i sağlamış sayılır.
type Depolama interface { Kaydet(veri string) error }

type YerelDisk struct{}
func (y YerelDisk) Kaydet(veri string) error { return nil }  // artık bir Depolama
```
> Go'da kalıtım yoktur. Go composition (struct içine struct gömme) ve interface kullanır.

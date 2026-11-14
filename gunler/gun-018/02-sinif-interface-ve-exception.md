# Java'da Sınıf, Interface, Record ve Exception

**Tanım:**
- **Sınıf (class):** Veri (alan, field) + davranış (metot) birlikte. Java'da alanlar genelde `private` yapılır, dışarıya metotla açılır: **kapsülleme (encapsulation)**. Nesne `new` ile oluşturulur, başlangıç değerleri **kurucu (constructor)** ile verilir.
- **Erişim belirleyiciler (access modifiers):** `public` (herkes), `private` (sadece sınıfın içi), `protected` (alt sınıflar + aynı paket), hiçbiri (sadece aynı paket). Go'daki büyük/küçük harf kuralının açık hali.
- **Kalıtım (inheritance):** `class Ec2Sunucu extends Sunucu`. Java'da bir sınıf **tek bir** sınıftan türeyebilir. Üst sınıfın metodu `@Override` ile değiştirilir.
- **Interface:** "Şu metotları sağlıyorum" sözleşmesi. Bir sınıf birden fazla interface uygulayabilir (`implements A, B`). Go'dan farkı: Java'da **açıkça** `implements` yazılır, Go'da metotları yazmak yeter (örtük, implicit).
- **Record (Java 16+):** Sadece veri taşıyan değiştirilemez (immutable) sınıf tek satırda: `record Olay(String kaynak, int seviye) {}`. Kurucu, getter, `equals`, `hashCode`, `toString` otomatik gelir. Python'daki `@dataclass(frozen=True)` gibi.
- **Enum:** Sabit değerler kümesi: `enum Durum { CALISIYOR, DURDU }`. Java'da enum'un alanı ve metodu olabilir.
- **Exception (istisna):** Hata `throw` ile fırlatılır, `try/catch` ile yakalanır. İki tür var:
  - **Checked exception:** `IOException` gibi. Derleyici seni zorlar: ya yakalarsın ya da metoda `throws IOException` yazarsın.
  - **Unchecked exception:** `RuntimeException` alt sınıfları (`NullPointerException`, `IllegalArgumentException`). Zorunlu değil.
- **try-with-resources:** `try (var dosya = ...) { }`. Blok bitince kaynak otomatik kapanır. Python'daki `with`, Go'daki `defer` karşılığı.
- **Generics:** Tipten bağımsız kod: `List<String>`, `Map<String, Integer>`, `static <T> T ilk(List<T> l)`.
- **Lambda ve Stream API (Java 8+):** Koleksiyonu fonksiyonel tarzda işlemek: `liste.stream().filter(s -> s.cpu() > 80).map(Sunucu::ad).toList()`. Python'daki list comprehension, JS'teki `filter/map` gibi.

**Neden önemli:** Spring Boot mikroservisleri, Jenkins eklentileri ve Kafka istemcileri hep bu yapılarla yazılır. Bir Java servisinin logunda **stack trace** (yığın izi) görünce hangi exception'ın nereden fırladığını okuyabilmek, DevOps'ta olay müdahalesinin (incident) en sık yapılan işlerinden biri. `NullPointerException` Java'nın en meşhur hatasıdır ve `Caused by:` satırları gerçek sebebi gösterir. Interface ve generics mantığını bilmek, AWS SDK for Java kodunu (`S3Client`, `Ec2Client` builder'ları) okumanı da kolaylaştırır.

## Go ve Java: aynı fikir, farklı yazım
| Kavram | Go | Java |
|---|---|---|
| Veri yapısı | `type Sunucu struct {...}` | `class Sunucu {...}` / `record` |
| Metot | `func (s Sunucu) Ad() string` | Sınıfın içinde `String ad() {...}` |
| Kurucu | Gelenek: `NewSunucu(...)` fonksiyonu | `Sunucu(...)` kurucusu + `new` |
| Kalıtım | Yok, gömme (embedding) var | `extends` (tek sınıf) |
| Interface | Örtük (metotları yazmak yeter) | Açık (`implements`) |
| Hata | `error` değeri döndürülür | Exception fırlatılır |
| Kaynak kapatma | `defer f.Close()` | try-with-resources |

## Stack trace okumak
```
Exception in thread "main" SaglikHatasi: db-1 yanıt vermiyor
    at SinifOrnek.kontrolEt(Saglik.java:95)
    at SinifOrnek.main(Saglik.java:160)
Caused by: java.net.ConnectException: Connection refused
```
- İlk satır: exception tipi ve mesajı.
- `at ...` satırları: en üstteki, hatanın fırladığı yer. Aşağı doğru çağıran metotlar.
- `Caused by:`: asıl kök neden (root cause). Genelde en alttaki `Caused by` en faydalısıdır.

## Örnek kod
`02_sinif_interface_exception.java`: kapsüllenmiş sınıf, kalıtım + `@Override`, interface (default metotlu), record, enum, checked/unchecked exception, özel exception, try-with-resources, generics, lambda ve stream.

```bash
java 02_sinif_interface_exception.java
```

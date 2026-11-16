# Class, Record ve async/await

**Tanım:**
- **class:** Java'daki gibi: alanlar, property'ler, metotlar, kurucu (constructor). **Primary constructor (C# 12+):** `class Sunucu(string ad, int port)` yazınca parametreler tüm sınıfta kullanılabilir, ayrıca alan tanımlamaya gerek kalmaz.
- **record:** Veri taşımak için yazılmış, **değiştirilemez (immutable)** sınıf. Tek satır: `record SaglikSonucu(string Url, int Durum, long SureMs);`. Derleyici kurucuyu, property'leri, `Equals` / `GetHashCode` (içeriğe göre eşitlik) ve okunabilir `ToString` metodunu kendisi yazar. Kopyalayarak değiştirmek için `with`: `sonuc with { Durum = 500 }`. Java'daki `record` (Java 16+) ve Python'daki `@dataclass(frozen=True)` karşılığı.
- **interface:** Sözleşme. Adı gelenek olarak `I` ile başlar: `ISaglikKontrol`. Bir sınıf birden çok interface uygulayabilir.
- **Exception:** Java'daki gibi `try / catch / finally`, `throw`. Fark: C#'ta **checked exception yok**, metot imzasına `throws` yazılmaz; hangi hatayı yakalayacağına sen karar verirsin. Kendi hatanı `Exception`'dan türetirsin.
- **`using`:** Dosya, bağlantı gibi kaynakları iş bitince otomatik kapatır. Java'daki try-with-resources, Python'daki `with`.
- **async/await:** Bekleme gerektiren işi (ağ isteği, dosya, veritabanı) **thread'i bloklamadan** yapmak. `async` metot bir **`Task`** (ya da `Task<T>`) döndürür, `await` sonucu bekler, beklerken thread başka işe geçer. Python'daki `asyncio` ve JavaScript'teki `async/await` ile aynı fikir; zaten `async/await` sözdizimi ilk C#'ta (2012) çıktı, sonra JS ve Python'a geçti.
- **`Task.WhenAll`:** Birden çok işi **aynı anda** başlatıp hepsinin bitmesini bekler. JS'teki `Promise.all`, Python'daki `asyncio.gather`, Go'daki goroutine + `WaitGroup` karşılığı.
- **`CancellationToken`:** Uzun süren async işi iptal etmek / zaman aşımı koymak için. Go'daki `context.Context` karşılığı.

**Neden önemli:** Modern .NET kodu (ASP.NET Core API'leri, AWS SDK for .NET, Azure SDK) baştan sona `async` yazılır; bir controller'ın her metodu `async Task<...>` döner. DevOps tarafında: sağlık kontrolü (health check) endpoint'leri, kuyruk tüketicileri (SQS, Kafka), arka plan servisleri (`BackgroundService`) hep bu yapıyla yazılır. `record` ise API istek/cevap modelleri ve olay (event) mesajları için standart. Async'i yanlış kullanmak (`.Result` ya da `.Wait()` ile bloklamak) yük altında **thread havuzunun tükenmesine (thread pool starvation)** yol açar: servis CPU'su düşükken bile istekler yavaşlar, en çok karşılaşılan .NET performans sorunlarından biri.

## Senkron ve asenkron: 3 sunucuya sağlık kontrolü
```
Senkron (sırayla):      [web-1 300ms][web-2 500ms][db-1 200ms]       = ~1000 ms
Asenkron (Task.WhenAll): [web-1 300ms]
                         [web-2 500ms]                             = ~500 ms (en yavaşı kadar)
                         [db-1 200ms]
```

## Diller arası karşılaştırma
| | C# | Java | Python | JavaScript | Go |
|---|---|---|---|---|---|
| Veri sınıfı | `record` | `record` | `@dataclass` | nesne `{}` | `struct` |
| Async dönüş tipi | `Task<T>` | `CompletableFuture<T>` | coroutine | `Promise` | (channel) |
| Hepsini bekle | `Task.WhenAll` | `allOf` | `asyncio.gather` | `Promise.all` | `WaitGroup` |
| İptal / zaman aşımı | `CancellationToken` | `Future.cancel` | `asyncio.timeout` | `AbortController` | `context` |
| Kaynak kapatma | `using` | try-with-resources | `with` | `try/finally` | `defer` |
| Checked exception | Yok | Var | Yok | Yok | Hata değer olarak döner |

## Örnek kod
`02_class_record_async.cs`: interface, primary constructor'lı class, record ve `with`, özel exception, `async`/`await`, `Task.WhenAll` ile paralel sağlık kontrolü ve `CancellationToken` ile zaman aşımı. Ağ isteği yerine `Task.Delay` ile gecikme taklit ediliyor (internet gerekmesin diye).

```bash
dotnet run 02_class_record_async.cs
```

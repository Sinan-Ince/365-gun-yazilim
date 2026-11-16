// Gün 019: class, record, interface, exception ve async/await.
// Çalıştır (.NET 10+): dotnet run 02_class_record_async.cs
// Ağ isteği yerine Task.Delay ile gecikme taklit ediliyor.

using System.Diagnostics;

Baslik("1) record: değiştirilemez veri sınıfı");
var s1 = new SaglikSonucu("web-1", 200, 120);
var s2 = new SaglikSonucu("web-1", 200, 120);
Console.WriteLine(s1);                                  // otomatik okunabilir ToString
Console.WriteLine($"s1 == s2: {s1 == s2}  (içeriğe göre eşitlik)");
var s3 = s1 with { Durum = 503 };                       // kopyala ve değiştir, s1 aynı kalır
Console.WriteLine($"s3: {s3}");

Baslik("2) Senkron vs Task.WhenAll");
var sunucular = new List<ISaglikKontrol>
{
    new SahteSunucu("web-1", gecikmeMs: 300),
    new SahteSunucu("web-2", gecikmeMs: 500),
    new SahteSunucu("db-1", gecikmeMs: 200),
};

var saat = Stopwatch.StartNew();
foreach (var s in sunucular)
{
    await s.KontrolEtAsync(CancellationToken.None);      // tek tek bekle
}
Console.WriteLine($"sırayla:  {saat.ElapsedMilliseconds} ms");

saat.Restart();
var gorevler = sunucular.Select(s => s.KontrolEtAsync(CancellationToken.None));
SaglikSonucu[] sonuclar = await Task.WhenAll(gorevler);  // hepsi aynı anda
Console.WriteLine($"paralel:  {saat.ElapsedMilliseconds} ms");
foreach (var r in sonuclar)
{
    Console.WriteLine($"  {r.Url,-6} {r.Durum}  {r.SureMs} ms");
}

Baslik("3) Exception ve CancellationToken (zaman aşımı)");
var yavas = new SahteSunucu("yavas-1", gecikmeMs: 2000);
var bozuk = new SahteSunucu("bozuk-1", gecikmeMs: 100, bozuk: true);

foreach (var s in new[] { yavas, bozuk })
{
    // Her kontrole ayrı token: 400 ms sonra otomatik iptal edilir.
    // Tek token paylaşılsaydı, ilk sunucu beklerken süre dolar ve ikincisi hiç başlamadan iptal olurdu.
    using var zamanAsimi = new CancellationTokenSource(TimeSpan.FromMilliseconds(400));
    try
    {
        var r = await s.KontrolEtAsync(zamanAsimi.Token);
        Console.WriteLine($"  {r.Url}: {r.Durum}");
    }
    catch (OperationCanceledException)
    {
        Console.WriteLine($"  {s.Ad}: zaman aşımı (400 ms)");
    }
    catch (SaglikHatasi e)
    {
        Console.WriteLine($"  {e.Sunucu}: {e.Message}");
    }
    finally
    {
        Console.WriteLine($"  {s.Ad} kontrolü bitti");
    }
}

static void Baslik(string metin) => Console.WriteLine($"\n=== {metin} ===");

// --- Tip tanımları (top-level kodun altında olmak zorunda) ---

// record: kurucu, property'ler, Equals, ToString otomatik
record SaglikSonucu(string Url, int Durum, long SureMs);

// interface: sözleşme, adı I ile başlar
interface ISaglikKontrol
{
    string Ad { get; }
    Task<SaglikSonucu> KontrolEtAsync(CancellationToken iptal);
}

// Kendi exception tipimiz. C#'ta checked exception yok: imzaya throws yazılmaz.
class SaglikHatasi(string sunucu, string mesaj) : Exception(mesaj)
{
    public string Sunucu { get; } = sunucu;
}

// Primary constructor (C# 12+): parametreler sınıfın her yerinde kullanılabilir
class SahteSunucu(string ad, int gecikmeMs, bool bozuk = false) : ISaglikKontrol
{
    public string Ad => ad;   // sadece okunabilir property

    public async Task<SaglikSonucu> KontrolEtAsync(CancellationToken iptal)
    {
        var saat = Stopwatch.StartNew();
        await Task.Delay(gecikmeMs, iptal);   // ağ isteği taklidi; iptal edilirse exception fırlatır
        if (bozuk)
        {
            throw new SaglikHatasi(ad, "bağlantı reddedildi");
        }
        return new SaglikSonucu(ad, 200, saat.ElapsedMilliseconds);
    }
}

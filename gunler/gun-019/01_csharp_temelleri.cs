// Gün 019: C# temelleri.
// Çalıştır (.NET 10+): dotnet run 01_csharp_temelleri.cs

// Top-level statements: sınıf ve Main yazmadan doğrudan kod.
// Derleyici bu satırları arka planda bir Main metodunun içine koyar.

const string VarsayilanBolge = "eu-north-1";

Baslik("1) Tipler ve var");
int port = 8080;
double cpu = 72.5;
bool aktif = true;
long bayt = 5_000_000_000;   // _ okunabilirlik için, Python'daki gibi
var sunucu = "web-1";        // tip çıkarımı: derleyici string olduğunu bilir
Console.WriteLine($"{sunucu}:{port} cpu={cpu} aktif={aktif} bayt={bayt}");
Console.WriteLine($"bölge: {VarsayilanBolge}");

Baslik("2) String işlemleri");
var log = "  ERROR disk dolu: /var/log  ";
Console.WriteLine($"trim:     '{log.Trim()}'");
Console.WriteLine($"küçük:    {log.Trim().ToLower()}");
Console.WriteLine($"içeriyor: {log.Contains("ERROR")}");
Console.WriteLine($"parçala:  [{string.Join(", ", log.Trim().Split(' '))}]");

// Java'nın aksine string'de == içeriği karşılaştırır
string a = new string("web-1".ToCharArray());
string b = "web-1";
Console.WriteLine($"a == b: {a == b}   (Java'da bu false olurdu)");

Baslik("3) List ve Dictionary");
var sunucular = new List<string> { "web-1", "web-2", "db-1" };
sunucular.Add("cache-1");
Console.WriteLine($"{sunucular.Count} sunucu: {string.Join(", ", sunucular)}");

var cpuKullanimi = new Dictionary<string, double>
{
    ["web-1"] = 72.5,
    ["web-2"] = 91.0,
    ["db-1"] = 45.3,
    ["cache-1"] = 88.8,
};
foreach (var (ad, deger) in cpuKullanimi)
{
    Console.WriteLine($"  {ad,-8} {deger,5:F1}%");
}

// TryGetValue: anahtar yoksa hata fırlatmadan false döner
if (!cpuKullanimi.TryGetValue("web-9", out var bulunan))
{
    Console.WriteLine("web-9 yok");
}

Baslik("4) Switch ifadesi ve metotlar");
foreach (var kod in new[] { 200, 404, 503, 418 })
{
    Console.WriteLine($"  {kod}: {DurumAciklama(kod)}");
}
Console.WriteLine($"topla(2, 3) = {Topla(2, 3)}, topla(1, 2, 3, 4) = {Topla(1, 2, 3, 4)}");

Baslik("5) Nullable");
string? etiket = null;   // ? = null olabilir
Console.WriteLine($"etiket uzunluğu: {etiket?.Length ?? 0}");   // ?. ve ?? ile güvenli erişim

Baslik("6) LINQ");
var yuksek = cpuKullanimi
    .Where(kv => kv.Value > 80)
    .OrderByDescending(kv => kv.Value)
    .Select(kv => kv.Key)
    .ToList();
Console.WriteLine($"cpu > 80: {string.Join(", ", yuksek)}");
Console.WriteLine($"ortalama cpu: {cpuKullanimi.Values.Average():F1}");
Console.WriteLine($"web sunucusu sayısı: {sunucular.Count(s => s.StartsWith("web"))}");

// --- Yerel fonksiyonlar (top-level statements ile dosyanın altında tanımlanabilir) ---

static void Baslik(string metin) => Console.WriteLine($"\n=== {metin} ===");

static string DurumAciklama(int kod) => kod switch
{
    200 or 201 => "başarılı",
    404 => "bulunamadı",
    >= 500 and < 600 => "sunucu hatası",
    _ => "bilinmiyor",
};

// params: değişken sayıda parametre (Java'daki int... gibi)
static int Topla(params int[] sayilar) => sayilar.Sum();

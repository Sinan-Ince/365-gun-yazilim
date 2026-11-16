# C# ve .NET Temelleri (CLR, dotnet CLI, tipler, LINQ)

**Tanım:**
- **C#:** Microsoft'un 2000'de çıkardığı, **statik tipli (static typing)** ve **nesne yönelimli (object-oriented)** dil. Java'ya çok benzer başladı, sonra daha hızlı gelişti: `record`, `async/await`, LINQ, pattern matching ilk C#'ta yaygınlaştı.
- **.NET:** C#'ın çalıştığı platform. Eskiden sadece Windows'ta çalışan **.NET Framework** vardı. 2016'dan beri açık kaynak ve **çapraz platform (cross-platform)** olan **.NET (Core)** var: Linux, macOS, Windows, konteyner. Güncel sürüm .NET 10.
- **CLR (Common Language Runtime):** Java'daki JVM'in karşılığı. C# kodu **IL (Intermediate Language)** denen ara koda derlenir (Java'daki bytecode gibi), CLR bunu çalışma anında **JIT** ile makine koduna çevirir.
- **`dotnet` CLI:** Tek araç her şeyi yapar: proje açar (`dotnet new`), derler (`dotnet build`), çalıştırır (`dotnet run`), test eder (`dotnet test`), paket ekler (`dotnet add package`), yayına hazırlar (`dotnet publish`). Java'da `javac` + Maven/Gradle'ın yaptığı iş tek araçta.
- **Top-level statements (C# 9+):** `Main` metodu ve sınıf yazmadan, dosyanın en üstünden kod yazılabilir. Derleyici arka planda `Main`'i kendisi oluşturur. Python'a yakın bir başlangıç.
- **Değer tipleri (value types) ve referans tipleri (reference types):** `int`, `double`, `bool`, `struct` değer tipidir (kopyalanır). `class`, `string`, `List<T>` referans tipidir. Java'dan farkı: C#'ta kendi değer tipini (`struct`) yazabilirsin ve `List<int>` yazılabilir, kutulama (boxing) gerekmez.
- **Nullable:** `string?` = null olabilir, `string` = olamaz. Derleyici null olabilecek değeri kontrol etmeden kullanırsan uyarır. Java'daki `NullPointerException` derdine karşı.
- **Property:** `public string Ad { get; set; }`. Java'daki `getAd()` / `setAd()` metotlarının yerine geçer.
- **LINQ (Language Integrated Query):** Koleksiyonlar üzerinde SQL benzeri sorgu: `sunucular.Where(s => s.Cpu > 80).Select(s => s.Ad)`. Python'daki list comprehension'ın ve Java Stream API'sinin karşılığı.

**Neden önemli:** Kurumsal dünyada Java'nın en büyük rakibi: bankalar, sigorta, oyun (Unity), Windows masaüstü ve **ASP.NET Core** web API'leri. Türkiye'de özellikle kurumsal şirketlerde çok yaygın. DevOps tarafında: .NET uygulamaları artık Linux konteynerlerde çalışıyor, bu yüzden `dotnet publish`, çok aşamalı (multi-stage) Docker imajı (`sdk` ile derle, `aspnet`/`runtime` ile çalıştır) ve `appsettings.json` + ortam değişkenleriyle yapılandırma bilinmeli. AWS'de: Lambda'nın .NET runtime'ları (`dotnet8` ve sonrası), Elastic Beanstalk, ECS; AWS SDK for .NET resmi ve olgun. Azure'un ana dili de C#.

## Derleme yolu: Java ve C#
```
Java:  Kaynak.java --javac-->  .class (bytecode) --> JVM (JIT) --> makine kodu
C#:    Kaynak.cs   --dotnet build--> .dll (IL)    --> CLR (JIT) --> makine kodu
```
| | Java | C# / .NET |
|---|---|---|
| Ara kod | Bytecode (`.class`, `.jar`) | IL (`.dll`) |
| Çalışma ortamı | JVM | CLR |
| Derleme/paket aracı | `javac` + Maven/Gradle | Tek araç: `dotnet` |
| Paket deposu | Maven Central | NuGet (03. kavram) |
| Tek dosya çalıştırma | `java Dosya.java` | `dotnet run dosya.cs` (.NET 10+) |
| `List<int>` | Yazılamaz, `List<Integer>` | Yazılır, kutulama yok |
| Getter/setter | `getAd()` metodu | `Ad { get; set; }` property |
| Native derleme | GraalVM | Native AOT (`PublishAot`) |

## Python / Java / C# karşılaştırması
| | Python | Java | C# |
|---|---|---|---|
| Değişken | `x = 5` | `var x = 5;` | `var x = 5;` |
| Sabit | `X = 5` | `final int X = 5;` | `const int X = 5;` |
| Liste | `list` | `ArrayList<Integer>` | `List<int>` |
| Sözlük | `dict` | `HashMap<String, Integer>` | `Dictionary<string, int>` |
| Metin birleştirme | `f"{ad}: {cpu}"` | `String.format(...)` | `$"{ad}: {cpu}"` |
| Metin eşitliği | `a == b` | `a.equals(b)` | `a == b` (string için içerik karşılaştırır) |
| Filtreleme | `[s for s in l if s > 5]` | `l.stream().filter(...)` | `l.Where(s => s > 5)` |

Java'daki `==` tuzağı C#'ta yok: `string` için `==` içeriği karşılaştırır.

## Örnek kod
`01_csharp_temelleri.cs`: top-level statements, tipler, `var`, string interpolation, `List`, `Dictionary`, döngüler, switch ifadesi, metotlar, nullable ve LINQ.

```bash
dotnet run 01_csharp_temelleri.cs     # .NET 10+: tek dosyayı derle + çalıştır
dotnet --version                      # kurulu SDK sürümü
```
> Normal projelerde dosya tek başına değil, bir `.csproj` projesinin içinde durur (03. kavram).

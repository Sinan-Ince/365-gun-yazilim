# NuGet ve .NET Proje Yapısı (csproj, publish, Docker)

**Tanım:**
- **`.csproj`:** Projenin tanım dosyası (XML). Hedef sürüm (`<TargetFramework>net10.0</TargetFramework>`), bağımlılıklar ve derleme ayarları burada. Maven'daki `pom.xml` karşılığı, ama çok daha kısa: kaynak dosyaları tek tek yazılmaz, klasördeki tüm `.cs` dosyaları otomatik dahil edilir.
- **`.sln` / `.slnx` (solution):** Birden çok projeyi bir arada tutar (ör. `Api`, `Core`, `Tests`). Maven'daki çok modüllü (multi-module) proje gibi.
- **NuGet:** .NET'in paket yöneticisi ve deposu (nuget.org). Python'daki pip + PyPI, Java'daki Maven Central karşılığı. Paketler `~/.nuget/packages` altında önbelleğe alınır.
- **`dotnet add package <Ad>`:** Paketi `.csproj`'a `<PackageReference>` olarak ekler. **`dotnet restore`:** Bağımlılıkları indirir (`build` ve `run` bunu kendisi de yapar).
- **`dotnet publish`:** Çalıştırılmaya hazır çıktı üretir. Seçenekler: **framework-dependent** (küçük, sunucuda .NET runtime gerekir), **self-contained** (`--self-contained -r linux-x64`, runtime dahil, büyük), **single-file** (`-p:PublishSingleFile=true`, tek dosya), **Native AOT** (`-p:PublishAot=true`, Go gibi doğrudan makine kodu: hızlı açılış, az bellek; Lambda soğuk başlangıcı için ideal).
- **Yapılandırma:** `appsettings.json` + `appsettings.Production.json` + ortam değişkenleri. Ortam değişkeninde iç içe ayar `__` ile yazılır: `ConnectionStrings__Db=...`. Hangi ortamda çalıştığını `ASPNETCORE_ENVIRONMENT` / `DOTNET_ENVIRONMENT` belirler.

**Neden önemli:** CI/CD pipeline'ında .NET adımları hep aynıdır: `dotnet restore` → `dotnet build -c Release` → `dotnet test` → `dotnet publish`. `~/.nuget/packages` önbelleklenmezse her build paketleri baştan indirir. Şirket içi paketler için özel NuGet deposu kullanılır: **AWS CodeArtifact**, Azure Artifacts, GitHub Packages. Konteynerde Microsoft'un resmi imajları kullanılır: derlemek için `mcr.microsoft.com/dotnet/sdk`, çalıştırmak için `mcr.microsoft.com/dotnet/aspnet` (web) ya da `runtime`. Gizli bilgiler `appsettings.json`'a değil ortam değişkenine veya AWS Secrets Manager'a konur.

## Proje yapısı
```
SaglikApi/
├── SaglikApi.slnx
├── src/SaglikApi/
│   ├── SaglikApi.csproj
│   ├── Program.cs
│   └── appsettings.json
└── tests/SaglikApi.Tests/
    ├── SaglikApi.Tests.csproj
    └── SaglikTests.cs
```

## Örnek `.csproj`
```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net10.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="AWSSDK.S3" Version="4.0.0" />
  </ItemGroup>
</Project>
```

## Sık kullanılan komutlar
```bash
dotnet new console -n Saglik           # konsol projesi (webapi, worker, xunit de var)
cd Saglik
dotnet add package Spectre.Console     # NuGet paketi ekle
dotnet run                             # derle + çalıştır
dotnet build -c Release                # Release derlemesi
dotnet test                            # testleri çalıştır
dotnet publish -c Release -o out       # yayın çıktısı out/ klasörüne
dotnet list package --outdated         # güncellenebilir paketler
```

## Maven ve dotnet
| İş | Maven | dotnet |
|---|---|---|
| Proje dosyası | `pom.xml` | `.csproj` |
| Bağımlılık indir | `mvn dependency:resolve` | `dotnet restore` |
| Derle | `mvn compile` | `dotnet build` |
| Test | `mvn test` | `dotnet test` |
| Paketle | `mvn package` (JAR) | `dotnet publish` |
| Depo | Maven Central | nuget.org |
| Önbellek | `~/.m2` | `~/.nuget/packages` |

## Multi-stage Dockerfile
```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY *.csproj .
RUN dotnet restore              # bağımlılık katmanı: csproj değişmezse önbellekten gelir
COPY . .
RUN dotnet publish -c Release -o /app

FROM mcr.microsoft.com/dotnet/aspnet:10.0
WORKDIR /app
COPY --from=build /app .
USER app                        # root olmayan kullanıcı (imajda hazır)
ENTRYPOINT ["dotnet", "SaglikApi.dll"]
```
SDK imajı ~800 MB, aspnet imajı ~220 MB. Native AOT ile `runtime-deps` imajı kullanılırsa 100 MB'ın altına iner.

Bu kavram teorik, ayrı kod dosyası yok. Alıştırma Obsidian gün notunda.

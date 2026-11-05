# Go Temelleri (derleme, tipler, slice, map, fonksiyon)

**Tanım:**
- **Go (Golang):** Google'ın 2009'da çıkardığı, **derlenen (compiled)** ve **statik tipli (static typing)** bir dil. Kod, çalıştırılmadan önce makine koduna çevrilir. Çıktı **tek bir çalıştırılabilir dosya (single binary)**: Python ya da Node gibi bir yorumlayıcı (interpreter) kurmak gerekmez.
- **`go run dosya.go`:** Derleyip hemen çalıştırır (geliştirirken). **`go build`:** Binary üretir. **`go mod init <ad>`:** Projeyi başlatır, `go.mod` dosyasını oluşturur (Node'daki `package.json`).
- **`:=` (kısa tanımlama):** Tip çıkarımıyla değişken tanımlar: `ad := "web-1"`. Fonksiyon dışında `var` gerekir.
- **Sıfır değer (zero value):** Atanmamış değişken boş kalmaz: `int` → `0`, `string` → `""`, `bool` → `false`, pointer/map/slice → `nil`. `undefined` yok.
- **Slice:** Büyüyebilen dizi: `[]string{"a", "b"}`, ekleme `append`. **Map:** Sözlük: `map[string]int{}`.
- **Çoklu dönüş değeri:** Fonksiyon birden fazla değer döndürebilir: `func bol(a, b int) (int, error)`. Go hata yönetimini buna kurar (02. kavram).
- **Büyük harf = dışa açık (exported):** `Topla` paket dışından görülür, `topla` görülmez. `public`/`private` anahtar kelimesi yok.
- **`gofmt`:** Resmi biçimlendirici. Tartışma yok, herkesin kodu aynı görünür.

**Neden önemli:** DevOps araçlarının çoğu Go ile yazılmış: **Docker, Kubernetes, Terraform, Prometheus, Grafana Agent, etcd, Helm, Hugo**. Tek binary ve hızlı açılış, konteyner imajını küçük tutar: `FROM scratch` ile sadece binary içeren birkaç MB'lık imaj yapılabilir. **Çapraz derleme (cross compilation)** tek satır: `GOOS=linux GOARCH=arm64 go build` ile Graviton (AWS ARM) için binary çıkar. Kubernetes operatörü ya da Terraform provider yazmak istersen Go şart. AWS Lambda'da da Go çalışır (`provided.al2023` runtime).

## Derlenen ve yorumlanan dil
| | Python / JS (yorumlanan) | Go (derlenen) |
|---|---|---|
| Çalıştırma | `python x.py` (yorumlayıcı lazım) | `./x` (sadece binary) |
| Tip hatası | Çalışırken patlar | Derlerken yakalanır |
| Dağıtım | Kod + bağımlılıklar + runtime | Tek dosya |
| Açılış süresi | Yavaş (runtime yüklenir) | Çok hızlı |
| Konteyner imajı | 100+ MB | 5-20 MB |

## Python / JS ile karşılaştırma
| | Python | JavaScript | Go |
|---|---|---|---|
| Değişken | `x = 5` | `let x = 5` | `x := 5` |
| Sabit | (yok, gelenek: `X`) | `const X = 5` | `const X = 5` |
| Liste | `list` | `Array` | slice `[]int` |
| Sözlük | `dict` | `Object` / `Map` | `map[string]int` |
| Döngü | `for`, `while` | `for`, `while` | sadece `for` (hepsini yapar) |
| Hata | `try/except` | `try/catch` | `if err != nil` |
| Paket | `pip` | `npm` | `go mod` |

## Proje yapısı
```bash
mkdir saglik && cd saglik
go mod init github.com/kiroschi/saglik   # go.mod oluşur
# main.go yaz
go run .                                 # derle + çalıştır
go build -o saglik .                     # ./saglik binary'si
GOOS=linux GOARCH=arm64 go build -o saglik-arm64 .   # AWS Graviton için
go vet ./...  &&  gofmt -l .             # CI kalite kontrolleri
```

## Örnek kod
`01_go_temelleri.go`: değişkenler, sıfır değerler, slice, map, `for`, `switch`, çoklu dönüş, `defer`.

```bash
go run 01_go_temelleri.go
```
> Bu klasördeki her `.go` dosyası kendi başına bir program (hepsinde `package main` ve `main()` var). Bu yüzden tek tek `go run <dosya>` ile çalıştır, `go build .` klasörde hata verir.

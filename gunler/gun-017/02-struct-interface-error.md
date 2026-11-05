# Struct, Metot, Interface ve Hata Değeri (error)

**Tanım:**
- **Struct:** Alanları olan veri tipi. Go'da **sınıf (class) yok**, onun yerine struct + metot var. Kalıtım (inheritance) da yok, yerine **gömme (embedding)** kullanılır.
- **Metot:** Bir tipe bağlı fonksiyon: `func (s Sunucu) Adres() string`. Parantezdeki `s`'ye **alıcı (receiver)** denir, Python'daki `self` gibi.
- **Pointer alıcı:** `func (s *Sunucu) Baslat()` struct'ı **yerinde değiştirir**. Değer alıcı (`s Sunucu`) kopya üzerinde çalışır, değişiklik dışarı yansımaz.
- **Pointer:** `&x` adresini alır, `*p` değerine gider. Aritmetik yok, C'deki kadar tehlikeli değil.
- **Interface:** Metot listesi. Bir tip o metotlara sahipse interface'i **kendiliğinden (implicitly)** uygular, `implements` yazılmaz. "Ördek gibi yürüyorsa ördektir" (duck typing), ama derleme zamanında kontrol edilir.
- **`error`:** Go'da istisna (exception) yok. Hata **sıradan bir dönüş değeri**: `sonuc, err := f()`, sonra `if err != nil { ... }`. Hata yok sayılamaz, gözünün önünde durur.
- **Hata sarmalama (wrapping):** `fmt.Errorf("config okunamadı: %w", err)` hataya bağlam ekler. `errors.Is(err, hedef)` zincirde belirli bir hatayı arar, `errors.As` belirli bir hata tipini arar.
- **`panic`:** Gerçekten kurtarılamayan durumlar için (programcı hatası). Normal hata akışında kullanılmaz.

**Neden önemli:** Kubernetes ve Terraform kaynak kodunu okuduğunda her yerde struct + interface + `if err != nil` göreceksin. Kubernetes nesneleri (`Pod`, `Deployment`) Go struct'larıdır, YAML'daki alanlar struct alanlarına karşılık gelir (`json:"name"` etiketleri). Interface'ler test yazmayı kolaylaştırır: gerçek AWS istemcisi yerine aynı interface'i uygulayan sahte (mock) bir istemci verirsin. Açık hata dönüşü sayesinde "hangi satır patlayabilir" sorusu kodun kendisinde görünür, bu da operasyonel araçlarda güvenilirlik sağlar.

## Python ile karşılaştırma
| | Python | Go |
|---|---|---|
| Veri tipi | `class` / `@dataclass` | `struct` |
| Metot | `def f(self)` | `func (s T) f()` |
| Kurucu | `__init__` | Gelenek: `func NewSunucu(...) *Sunucu` |
| Kalıtım | `class B(A)` | Gömme: `type B struct { A }` |
| Interface | `ABC` / `Protocol` | `interface`, kendiliğinden uygulanır |
| Hata | `raise` / `try/except` | `return err` / `if err != nil` |
| Yazdırma | `__str__` | `String() string` metodu (`fmt.Stringer`) |

## Hata yönetimi kalıbı
```go
cfg, err := ConfigOku("app.yaml")
if err != nil {
    return fmt.Errorf("başlatma başarısız: %w", err)  // bağlam ekle, yukarı ilet
}
// buradan sonra cfg güvenle kullanılır
```
Hata zinciri şöyle okunur: `başlatma başarısız: config okunamadı: open app.yaml: no such file or directory`

## JSON etiketleri (struct tags)
```go
type Sunucu struct {
    Ad    string `json:"ad"`
    CPU   int    `json:"cpu"`
    Notlar string `json:"notlar,omitempty"`  // boşsa JSON'a yazma
}
```
`encoding/json` bu etiketlere bakarak JSON'u struct'a çevirir. Kubernetes API tipleri tam olarak böyle tanımlanır.

## Örnek kod
`02_struct_interface.go`: struct, değer ve pointer alıcı, kurucu fonksiyon, gömme, interface, `Stringer`, özel hata tipi, `errors.Is/As`, JSON.

```bash
go run 02_struct_interface.go
```

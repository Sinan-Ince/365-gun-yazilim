// Gün 017: Struct, metot, interface ve error.
// Çalıştır: go run 02_struct_interface.go
package main

import (
	"encoding/json"
	"errors"
	"fmt"
)

// -------------------------------------------------------------------
// Struct + JSON etiketleri
type Sunucu struct {
	Ad        string `json:"ad"`
	IP        string `json:"ip"`
	Port      int    `json:"port"`
	Calisiyor bool   `json:"calisiyor"`
}

// Kurucu fonksiyon geleneği: NewX, pointer döndürür.
func NewSunucu(ad, ip string, port int) *Sunucu {
	return &Sunucu{Ad: ad, IP: ip, Port: port}
}

// Değer alıcı: sadece okur.
func (s Sunucu) Adres() string {
	return fmt.Sprintf("%s:%d", s.IP, s.Port)
}

// Pointer alıcı: struct'ı yerinde değiştirir.
func (s *Sunucu) Baslat() {
	s.Calisiyor = true
}

// Değer alıcı ile değiştirmeye çalışmak: kopya değişir, asıl struct değil.
func (s Sunucu) YanlisBaslat() {
	s.Calisiyor = true
}

// String() metodu fmt.Stringer interface'ini uygular, Println bunu kullanır.
func (s Sunucu) String() string {
	durum := "durdu"
	if s.Calisiyor {
		durum = "çalışıyor"
	}
	return fmt.Sprintf("[%s %s %s]", s.Ad, s.Adres(), durum)
}

// -------------------------------------------------------------------
// Gömme (embedding): kalıtım yerine. VeritabaniSunucusu, Sunucu'nun
// alanlarını ve metotlarını doğrudan kullanabilir.
type VeritabaniSunucusu struct {
	Sunucu // isimsiz alan = gömme
	Motor  string
}

// -------------------------------------------------------------------
// Interface: "Kontrol(...) error metodu olan her şey SaglikKontrolcu'dur".
type SaglikKontrolcu interface {
	Kontrol() error
}

func (s Sunucu) Kontrol() error {
	if !s.Calisiyor {
		return &DurumHatasi{Ad: s.Ad, Sebep: "servis çalışmıyor"}
	}
	return nil // nil = hata yok
}

// Başka bir tip, hiç ilişkisi olmadan aynı interface'i uygular.
type DiskKontrol struct {
	DolulukYuzde int
}

func (d DiskKontrol) Kontrol() error {
	if d.DolulukYuzde > 90 {
		return fmt.Errorf("disk %%%d dolu: %w", d.DolulukYuzde, ErrKritik)
	}
	return nil
}

// -------------------------------------------------------------------
// Hatalar
var ErrKritik = errors.New("kritik eşik aşıldı") // sabit "sentinel" hata

// Özel hata tipi: Error() string metodu olan her tip bir error'dur.
type DurumHatasi struct {
	Ad    string
	Sebep string
}

func (e *DurumHatasi) Error() string {
	return e.Ad + ": " + e.Sebep
}

func hepsiniKontrolEt(kontrolculer []SaglikKontrolcu) {
	for _, k := range kontrolculer {
		err := k.Kontrol()
		var durumHatasi *DurumHatasi
		switch {
		case err == nil:
			fmt.Printf("  ✅ %v\n", k)
		case errors.Is(err, ErrKritik): // zincirde ErrKritik var mı?
			fmt.Printf("  🔥 KRİTİK: %v\n", err)
		case errors.As(err, &durumHatasi): // zincirde DurumHatasi tipi var mı?
			fmt.Printf("  ⚠️  %s yeniden başlatılmalı (%s)\n", durumHatasi.Ad, durumHatasi.Sebep)
		default:
			fmt.Printf("  ❓ %v\n", err)
		}
	}
}

// -------------------------------------------------------------------
// Çoklu dönüş + error: Go'nun standart hata kalıbı.
func portBul(sunucular map[string]*Sunucu, ad string) (int, error) {
	s, ok := sunucular[ad]
	if !ok {
		return 0, fmt.Errorf("%q bulunamadı", ad)
	}
	return s.Port, nil
}

func baslik(metin string) { fmt.Printf("\n=== %s ===\n", metin) }

func main() {
	baslik("1) Struct ve metotlar")
	web := NewSunucu("web-1", "10.0.1.10", 80)
	fmt.Println(web) // String() metodu otomatik çağrılır
	web.YanlisBaslat()
	fmt.Println("değer alıcıdan sonra:", web.Calisiyor) // false
	web.Baslat()
	fmt.Println("pointer alıcıdan sonra:", web.Calisiyor) // true

	baslik("2) Pointer")
	port := 8080
	p := &port // p, port'un adresini tutar
	*p = 9090  // adres üzerinden değeri değiştir
	fmt.Println("port:", port)

	baslik("3) Gömme (embedding)")
	db := VeritabaniSunucusu{Sunucu: *NewSunucu("db-1", "10.0.2.20", 5432), Motor: "postgres"}
	fmt.Println(db.Ad, db.Adres(), db.Motor) // Sunucu'nun alan ve metotları doğrudan

	baslik("4) Interface ve hata türleri")
	kontrolculer := []SaglikKontrolcu{
		web,       // çalışıyor
		db.Sunucu, // çalışmıyor → DurumHatasi
		DiskKontrol{DolulukYuzde: 45},
		DiskKontrol{DolulukYuzde: 95}, // ErrKritik
	}
	hepsiniKontrolEt(kontrolculer)

	baslik("5) if err != nil kalıbı")
	envanter := map[string]*Sunucu{"web-1": web}
	for _, ad := range []string{"web-1", "cache-9"} {
		port, err := portBul(envanter, ad)
		if err != nil {
			fmt.Println("  hata:", err)
			continue
		}
		fmt.Println("  port:", port)
	}

	baslik("6) JSON")
	veri, err := json.MarshalIndent(web, "", "  ")
	if err != nil {
		panic(err) // burada olmamalı: programcı hatası
	}
	fmt.Println(string(veri))

	var okunan Sunucu
	girdi := `{"ad":"api-1","ip":"10.0.3.5","port":443,"calisiyor":true}`
	if err := json.Unmarshal([]byte(girdi), &okunan); err != nil {
		fmt.Println("JSON hatası:", err)
		return
	}
	fmt.Println("okunan:", okunan)

	bozuk := `{"ad": "x", "port": "yanlis-tip"}`
	if err := json.Unmarshal([]byte(bozuk), &okunan); err != nil {
		fmt.Println("bozuk JSON:", err) // tip uyuşmazlığı hata olarak döner
	}
}

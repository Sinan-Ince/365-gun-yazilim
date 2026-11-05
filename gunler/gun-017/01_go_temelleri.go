// Gün 017: Go temelleri.
// Çalıştır: go run 01_go_temelleri.go
// Binary yap: go build -o temeller 01_go_temelleri.go && ./temeller
package main // çalıştırılabilir programların paketi her zaman main

import (
	"fmt"
	"os"
	"sort"
	"strings"
)

// Fonksiyon dışında := kullanılamaz, var ya da const gerekir.
const varsayilanBolge = "eu-north-1"

func baslik(metin string) {
	fmt.Printf("\n=== %s ===\n", metin)
}

// Çoklu dönüş değeri: sonuç ve "bulundu mu" bilgisi birlikte döner.
func enYogun(cpu map[string]int) (string, int) {
	enAd, enDeger := "", -1
	for ad, deger := range cpu {
		if deger > enDeger {
			enAd, enDeger = ad, deger
		}
	}
	return enAd, enDeger
}

// Değişken sayıda parametre (variadic), Python'daki *args gibi.
func topla(sayilar ...int) int {
	toplam := 0
	for _, s := range sayilar { // _ : indeksi kullanmıyoruz
		toplam += s
	}
	return toplam
}

func main() {
	// -----------------------------------------------------------
	baslik("1) Değişkenler ve tipler")
	ad := "web-1" // tip çıkarımı: string
	var port int = 8080
	cpu := 72.5 // float64
	aktif := true
	fmt.Printf("%s:%d cpu=%.1f aktif=%t\n", ad, port, cpu, aktif)
	fmt.Printf("tipler: %T %T %T %T\n", ad, port, cpu, aktif)
	// ad = 5  → derleme hatası: string'e int atanamaz (Python'da çalışırdı)

	// Tip dönüşümü her zaman açıkça yapılır, örtük dönüşüm yok.
	yuzde := float64(port) / 100
	fmt.Println("açık dönüşüm:", yuzde)

	// -----------------------------------------------------------
	baslik("2) Sıfır değerler (zero value)")
	var (
		i int
		s string
		b bool
		m map[string]int
	)
	fmt.Printf("int=%d string=%q bool=%t map nil mi=%t\n", i, s, b, m == nil)

	// -----------------------------------------------------------
	baslik("3) Slice")
	sunucular := []string{"web-1", "web-2"}
	sunucular = append(sunucular, "db-1") // append yeni slice döndürür, geri ata
	fmt.Println(sunucular, "uzunluk:", len(sunucular))
	fmt.Println("ilk iki:", sunucular[:2]) // Python'daki dilimleme gibi
	for i, sunucu := range sunucular {
		fmt.Printf("  %d → %s\n", i, sunucu)
	}

	// -----------------------------------------------------------
	baslik("4) Map")
	cpuKullanimi := map[string]int{"web-1": 72, "web-2": 15, "db-1": 91}
	cpuKullanimi["cache-1"] = 40
	delete(cpuKullanimi, "web-2")

	// "virgül ok" kalıbı: anahtar var mı?
	if deger, ok := cpuKullanimi["web-2"]; ok {
		fmt.Println("web-2:", deger)
	} else {
		fmt.Println("web-2 yok (silindi)")
	}

	// Map'te sıra garanti değil. Sıralı yazdırmak için anahtarları sırala.
	anahtarlar := make([]string, 0, len(cpuKullanimi))
	for k := range cpuKullanimi {
		anahtarlar = append(anahtarlar, k)
	}
	sort.Strings(anahtarlar)
	for _, k := range anahtarlar {
		fmt.Printf("  %-8s %3d%%\n", k, cpuKullanimi[k])
	}
	enAd, enDeger := enYogun(cpuKullanimi)
	fmt.Printf("en yoğun: %s (%d%%)\n", enAd, enDeger)

	// -----------------------------------------------------------
	baslik("5) for: Go'daki tek döngü")
	for i := 0; i < 3; i++ { // klasik
		fmt.Print(i, " ")
	}
	n := 1
	for n < 100 { // while gibi
		n *= 3
	}
	fmt.Println("| 3'ün 100'ü geçen ilk kuvveti:", n)

	// -----------------------------------------------------------
	baslik("6) switch")
	for _, kod := range []int{200, 404, 503} {
		switch { // koşulsuz switch: if-else zinciri yerine
		case kod >= 500:
			fmt.Println(kod, "sunucu hatası")
		case kod >= 400:
			fmt.Println(kod, "istemci hatası")
		default:
			fmt.Println(kod, "başarılı")
		}
		// break yazmaya gerek yok, Go case'ler arasında kendiliğinden düşmez
	}

	// -----------------------------------------------------------
	baslik("7) Fonksiyonlar ve ortam değişkeni")
	fmt.Println("topla:", topla(1, 2, 3, 4))
	bolge := os.Getenv("AWS_REGION") // yoksa "" döner (sıfır değer)
	if bolge == "" {
		bolge = varsayilanBolge
	}
	fmt.Println("bölge:", bolge)
	fmt.Println(strings.ToUpper("go"), strings.Split("a,b,c", ","))

	// -----------------------------------------------------------
	baslik("8) defer")
	// defer: fonksiyon biterken çalışır, ters sırayla. Dosya kapatmak için birebir.
	defer fmt.Println("  (defer) en son ben çalışırım")
	defer fmt.Println("  (defer) benden sonra yukarıdaki")
	fmt.Println("main bitiyor...")
}

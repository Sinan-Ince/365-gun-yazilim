// Gün 017: Goroutine, channel ve eşzamanlılık.
// Çalıştır: go run 03_goroutine_channel.go
// Yarış dedektörüyle: go run -race 03_goroutine_channel.go
package main

import (
	"context"
	"errors"
	"fmt"
	"math/rand/v2"
	"sync"
	"time"
)

func baslik(metin string) { fmt.Printf("\n=== %s ===\n", metin) }

// Sahte sağlık kontrolü: rastgele 50-150 ms sürer. Gerçekte bir HTTP isteği olurdu.
func kontrolEt(sunucu string) string {
	sure := time.Duration(50+rand.IntN(100)) * time.Millisecond
	time.Sleep(sure)
	return fmt.Sprintf("%s OK (%v)", sunucu, sure.Round(time.Millisecond))
}

var sunucular = []string{"web-1", "web-2", "web-3", "db-1", "cache-1", "api-1"}

func main() {
	// -----------------------------------------------------------
	baslik("1) Sıralı")
	basla := time.Now()
	for _, s := range sunucular {
		kontrolEt(s)
	}
	fmt.Printf("sıralı süre: %v\n", time.Since(basla).Round(time.Millisecond))

	// -----------------------------------------------------------
	baslik("2) Goroutine + WaitGroup")
	basla = time.Now()
	var wg sync.WaitGroup
	for _, s := range sunucular {
		wg.Add(1)
		go func() { // Go 1.22+: döngü değişkeni s her turda yeni, güvenle kullanılır
			defer wg.Done()
			kontrolEt(s)
		}()
	}
	wg.Wait() // hepsi bitene kadar bekle
	fmt.Printf("paralel süre: %v (en yavaşı kadar)\n", time.Since(basla).Round(time.Millisecond))

	// -----------------------------------------------------------
	baslik("3) Channel ile sonuç toplama")
	sonuclar := make(chan string) // tamponsuz kanal
	for _, s := range sunucular {
		go func() { sonuclar <- kontrolEt(s) }()
	}
	for range sunucular { // tam olarak gönderilen sayı kadar oku
		fmt.Println(" ", <-sonuclar) // bitiş sırasına göre gelir
	}

	// -----------------------------------------------------------
	baslik("4) Worker pool (aynı anda en fazla 2 iş)")
	isler := make(chan string, len(sunucular))
	cikti := make(chan string, len(sunucular))
	var havuz sync.WaitGroup
	for w := 1; w <= 2; w++ {
		havuz.Add(1)
		go func() {
			defer havuz.Done()
			for s := range isler { // kanal kapanınca döngü biter
				cikti <- fmt.Sprintf("worker %d → %s", w, kontrolEt(s))
			}
		}()
	}
	for _, s := range sunucular {
		isler <- s
	}
	close(isler) // gönderen kapatır: "başka iş yok"
	go func() {
		havuz.Wait()
		close(cikti) // tüm worker'lar bitince sonuç kanalını kapat
	}()
	for satir := range cikti {
		fmt.Println(" ", satir)
	}

	// -----------------------------------------------------------
	baslik("5) select ile zaman aşımı")
	yavas := make(chan string, 1) // tamponlu: kimse okumasa da goroutine takılmaz
	go func() {
		time.Sleep(300 * time.Millisecond)
		yavas <- "yavaş servis cevap verdi"
	}()
	select {
	case cevap := <-yavas:
		fmt.Println(cevap)
	case <-time.After(100 * time.Millisecond):
		fmt.Println("zaman aşımı: 100 ms içinde cevap yok")
	}

	// -----------------------------------------------------------
	baslik("6) context ile iptal")
	ctx, iptal := context.WithTimeout(context.Background(), 120*time.Millisecond)
	defer iptal() // kaynakları serbest bırak, her zaman çağır
	err := uzunIs(ctx)
	fmt.Println("uzunIs sonucu:", err)
	fmt.Println("süre doldu mu:", errors.Is(err, context.DeadlineExceeded))

	// -----------------------------------------------------------
	baslik("7) Yarış durumu ve Mutex")
	sayac := 0
	var mu sync.Mutex
	var grup sync.WaitGroup
	for range 1000 {
		grup.Add(1)
		go func() {
			defer grup.Done()
			mu.Lock() // bunu kaldırırsan sonuç 1000'den küçük çıkabilir, -race uyarır
			sayac++
			mu.Unlock()
		}()
	}
	grup.Wait()
	fmt.Println("sayaç (1000 olmalı):", sayac)
}

// ctx iptal edilene kadar adım adım çalışır. Gerçek kodda HTTP isteği,
// veritabanı sorgusu gibi işler ctx'i kendileri dinler.
func uzunIs(ctx context.Context) error {
	for adim := 1; ; adim++ {
		select {
		case <-ctx.Done():
			return fmt.Errorf("%d. adımda durduruldu: %w", adim, ctx.Err())
		case <-time.After(50 * time.Millisecond):
			fmt.Printf("  adım %d tamam\n", adim)
		}
	}
}

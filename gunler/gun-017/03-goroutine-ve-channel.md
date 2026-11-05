# Goroutine, Channel ve Eşzamanlılık (concurrency)

**Tanım:**
- **Goroutine:** Go runtime'ının yönettiği çok hafif iş parçacığı. Başına `go` yazılan fonksiyon arka planda çalışır: `go kontrolEt(url)`. İşletim sistemi thread'i ~1 MB bellek ister, goroutine birkaç KB ile başlar. Aynı anda **yüz binlerce** goroutine çalışabilir.
- **Channel:** Goroutine'ler arasında veri taşıyan **tipli boru (typed pipe)**: `ch := make(chan int)`. Gönder `ch <- 5`, al `x := <-ch`. Tamponsuz (unbuffered) kanalda gönderen, alıcı gelene kadar bekler. Bu bekleme aynı zamanda senkronizasyon sağlar.
- **Tamponlu kanal (buffered):** `make(chan int, 10)`: 10 değer birikene kadar gönderen beklemez.
- **`sync.WaitGroup`:** "N tane goroutine bitene kadar bekle". `Add(1)` / `Done()` / `Wait()`. Go 1.25+ ile kısa yolu var: `wg.Go(func() { ... })`.
- **`select`:** Birden fazla kanalı aynı anda dinler, hangisi önce hazırsa onu alır. Zaman aşımı (timeout) için `time.After` ile birlikte kullanılır.
- **`context.Context`:** İptal (cancellation) ve süre sınırını (deadline) goroutine'lere yayar. `context.WithTimeout(ctx, 2*time.Second)`. Go'da ağ çağrısı yapan her fonksiyonun ilk parametresi gelenek olarak `ctx`.
- **Yarış durumu (race condition):** İki goroutine aynı değişkene aynı anda yazarsa sonuç bozulur. Çözüm: `sync.Mutex` ile kilit ya da veriyi channel üzerinden paylaşmak. `go run -race` bunu yakalar.
- **Felsefe:** *"Belleği paylaşarak iletişim kurma, iletişim kurarak belleği paylaş."* (Don't communicate by sharing memory; share memory by communicating.)

**Neden önemli:** Go'nun DevOps'ta bu kadar yaygın olmasının ana sebebi bu. Kubernetes controller'ları her kaynağı ayrı goroutine'lerde izler. Prometheus binlerce hedefi aynı anda kazır (scrape). Terraform kaynakları paralel oluşturur (`-parallelism=10`). Sen de 500 sunucuya aynı anda sağlık kontrolü yapan, S3'e paralel yükleme yapan araçları birkaç satırla yazabilirsin. Python'daki GIL sınırı Go'da yok: goroutine'ler tüm CPU çekirdeklerini kullanır.

## Node.js ile karşılaştırma (Gün 016)
| | Node.js | Go |
|---|---|---|
| Model | Tek thread + event loop | Birçok goroutine, birçok çekirdek |
| Arka planda çalıştır | `async` fonksiyon / Promise | `go f()` |
| Hepsini bekle | `await Promise.all([...])` | `sync.WaitGroup` |
| İlk biteni al | `Promise.race` | `select` |
| Zaman aşımı | `AbortSignal.timeout(2000)` | `context.WithTimeout` |
| CPU ağırlıklı iş | Event loop'u kilitler | Diğer çekirdeklerde paralel |

## Worker pool kalıbı
```
 işler kanalı ──┬──► worker 1 ──┐
 [j1 j2 j3 ...] ├──► worker 2 ──┼──► sonuçlar kanalı ──► main
                └──► worker 3 ──┘
```
Sabit sayıda worker, ortak bir kanaldan iş çeker. Böylece 10.000 iş olsa bile aynı anda en fazla N tanesi çalışır (API rate limit'lerini aşmamak için önemli).

## Sık yapılan hatalar
- `main` bitince bütün goroutine'ler ölür. Beklemezsen çıktı göremezsin.
- Kimsenin okumadığı kanala yazmak goroutine'i sonsuza kadar kilitler (goroutine leak). Hepsi kilitlenirse: `fatal error: all goroutines are asleep - deadlock!`
- Kanalı **gönderen** taraf kapatır (`close(ch)`), alan değil. Kapalı kanala yazmak `panic` verir.

## Örnek kod
`03_goroutine_channel.go`: sıralı ve paralel karşılaştırma, WaitGroup, channel, worker pool, `select` ile zaman aşımı, `context`, Mutex ve yarış durumu.

```bash
go run 03_goroutine_channel.go
go run -race 03_goroutine_channel.go   # yarış dedektörü açık
```

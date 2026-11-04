# Asenkron JavaScript (event loop, Promise, async/await)

**Tanım:**
- **Tek iş parçacığı (single thread):** JS kodun tek bir thread'de çalışır. Dosya okuma, ağ isteği gibi bekleme gerektiren işler **beklenirken thread bloklanmaz**: Node işi işletim sistemine (libuv) verir, sonuç gelince kodun devamını çalıştırır.
- **Olay döngüsü (event loop):** "Biten işlerin kuyruğuna bak, sıradaki callback'i çalıştır" döngüsü. nginx'in olay tabanlı modeliyle (Gün 015/01) aynı fikir: az thread, çok bağlantı.
- **Callback:** "İş bitince bunu çağır" diye verilen fonksiyon. İç içe geçince okunmaz hale gelir (callback hell).
- **Promise:** Gelecekte gelecek bir değerin temsili. Üç durumu var: `pending` (bekliyor), `fulfilled` (başarılı), `rejected` (hata).
- **`async` / `await`:** Promise'leri normal, sıralı kod gibi yazdırır. `await` sadece `async` fonksiyon içinde (ya da `.mjs` modülün en üst seviyesinde) kullanılır. Hatalar `try/catch` ile yakalanır.
- **Paralel çalıştırma:**
  - `Promise.all([...])`: hepsini aynı anda başlatır, biri patlarsa hepsi patlar.
  - `Promise.allSettled([...])`: hepsini bekler, hangisinin başarılı hangisinin hatalı olduğunu ayrı ayrı verir.
  - `Promise.race` / `Promise.any`: ilk biteni / ilk başarılıyı alır.

**Neden önemli:** Node'da ağ ve dosya ile ilgili neredeyse her API Promise döndürür. **AWS SDK v3** (`@aws-sdk/client-s3` vb.) tamamen `await client.send(komut)` şeklinde çalışır. **Lambda** handler'ı `export const handler = async (event) => {...}` diye yazılır. Burada `await`'i unutursan Lambda, iş bitmeden cevap döner ve iş yarım kalır. Sağlık kontrolü yapan betikler, deploy script'leri, webhook'lar: hepsinde "10 servise **paralel** istek at, zaman aşımı koy, hataları topla" kalıbını kullanırsın.

## Sıralı mı paralel mi?
```js
// SIRALI: toplam süre = 1 + 1 + 1 = 3 sn
for (const url of urller) {
    await fetch(url);
}

// PARALEL: toplam süre ≈ en yavaşı = 1 sn
await Promise.all(urller.map((url) => fetch(url)));
```
Birbirine bağımlı olmayan istekleri paralel at. Ama binlerce isteği aynı anda atma, karşı tarafı (ya da AWS API limitlerini, throttling) boğarsın. Gruplar halinde gönder.

## Sık yapılan hatalar
| Hata | Sonuç | Doğrusu |
|---|---|---|
| `await` unutmak: `const v = fetch(u)` | `v` bir Promise olur, veri değil | `const v = await fetch(u)` |
| `forEach` içinde `await` | `forEach` beklemez, döngü hemen biter | `for...of` (sıralı) ya da `Promise.all` (paralel) |
| `.catch` / `try` olmadan Promise | `UnhandledPromiseRejection`, Node process'i **çöker** | Her `await`'i bir `try/catch` kapsasın |
| Zaman aşımı yok | Cevap vermeyen servis betiği sonsuza dek bekletir | `fetch(u, { signal: AbortSignal.timeout(2000) })` |
| CPU'yu kilitleyen döngü | Event loop durur, sunucu kimseye cevap veremez | Ağır hesabı `worker_threads`'e ya da başka bir servise ver |

## Çalışma sırası
```js
console.log("1");
setTimeout(() => console.log("4: timer (macrotask)"), 0);
Promise.resolve().then(() => console.log("3: promise (microtask)"));
console.log("2");
// Çıktı: 1, 2, 3, 4. Önce senkron kod, sonra microtask'lar, sonra timer'lar.
```

## Örnek kod
`02_async_await.mjs`, `node:http` ile 3 sahte mikroservis açıyor (hızlı, yavaş, bozuk). Ardından sıralı ve paralel istek atıp süreleri karşılaştırıyor, `Promise.allSettled` ile hataları topluyor, zaman aşımı ve tekrar deneme (retry) gösteriyor. İnternet gerektirmez.

```bash
node 02_async_await.mjs
```

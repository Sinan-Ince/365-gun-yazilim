# JavaScript ve Node.js Temelleri (let/const, fonksiyon, nesne, modül)

**Tanım:**
- **JavaScript (JS):** Tarayıcının dili olarak doğdu, bugün sunucuda da çalışıyor. Dinamik tipli (dynamic typing): değişkenin tipi çalışırken belli olur (Python gibi, Gün 001).
- **Node.js:** JS'i tarayıcı dışında çalıştıran **çalışma ortamı (runtime)**. İçinde Chrome'un **V8** motoru var. Tarayıcıdaki `document`, `window` yok; onların yerine dosya (`node:fs`), ağ (`node:http`), process (`process.env`, `process.argv`) modülleri var.
- **npm:** Node'un paket yöneticisi (Python'daki `pip`). Projenin kimliği `package.json`, kesin sürümler `package-lock.json` dosyasında. Paketler `node_modules/` içine iner (`.gitignore`'a girer).
- **`let` / `const`:** Blok kapsamlı (block scope) değişken. Varsayılan `const`, değeri yeniden atanacaksa `let`. Eski `var` fonksiyon kapsamlı ve sürprizli, kullanma.
- **`===` (katı eşitlik):** Tip dönüşümü yapmadan karşılaştırır. `==` tipleri zorla eşitler (`"0" == 0` → `true`), hep `===` kullan.
- **Ok fonksiyonu (arrow function):** `const kare = x => x * x;` Kısa yazım. Callback'lerde (`map`, `filter`) çok kullanılır.
- **Modül (ES module):** `export` ile dışarı ver, `import` ile al. `.mjs` uzantısı ya da `package.json`'da `"type": "module"` ile açılır. Eski stil `require()` (CommonJS) hâlâ çok kodda var.

**Neden önemli:** DevOps'ta JS'e her yerde rastlarsın: **AWS Lambda**'nın en yaygın iki dilinden biri Node.js. **AWS CDK**'nin ana dili TypeScript (Gün 016/03). GitHub Actions'ın kendi action'ları Node ile yazılır. Frontend ekiplerinin `npm ci && npm run build` pipeline'larını CI/CD'de sen çalıştıracaksın. `package.json` okuyabilmek, `node_modules` ve lock dosyasını anlamak bu yüzden şart.

## Python ile karşılaştırma
| | Python | JavaScript |
|---|---|---|
| Değişken | `x = 5` | `const x = 5;` / `let x = 5;` |
| Yok değeri | `None` | `null` (bilerek boş) ve `undefined` (hiç atanmamış) |
| Liste / sözlük | `list`, `dict` | `Array`, `Object` (ya da `Map`) |
| f-string | `f"Merhaba {ad}"` | `` `Merhaba ${ad}` `` (template literal) |
| Lambda | `lambda x: x * 2` | `x => x * 2` |
| Liste üreteci | `[x*2 for x in l if x > 1]` | `l.filter(x => x > 1).map(x => x * 2)` |
| Açma (unpacking) | `a, b = l` | `const [a, b] = l;` (destructuring) |
| Paket | `pip` + `requirements.txt` | `npm` + `package.json` |
| Ortam değişkeni | `os.environ["PORT"]` | `process.env.PORT` |

## Doğru sayılan / yanlış sayılan (truthy / falsy)
`if (deger)` içinde **yanlış** sayılanlar: `false`, `0`, `""`, `null`, `undefined`, `NaN`. Geri kalan her şey doğru, **boş dizi `[]` ve boş nesne `{}` dahil** (Python'da boş liste yanlıştı, dikkat).

Bu yüzden varsayılan değer verirken `??` kullan:
```js
const port = process.env.PORT || 3000;   // PORT="0" ise de 3000 olur (yanlış)
const port2 = process.env.PORT ?? 3000;  // sadece null/undefined ise 3000
const sehir = kullanici?.adres?.sehir;   // ?. : adres yoksa hata yerine undefined
```

## package.json
```json
{
  "name": "ornek-servis",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "start": "node src/index.js",
    "test": "node --test"
  },
  "dependencies": { "express": "^5.1.0" },
  "devDependencies": { "typescript": "^5.9.0" }
}
```
- `npm install`: bağımlılıkları kur, lock dosyasını gerekirse güncelle (geliştirirken).
- `npm ci`: **sadece lock dosyasına göre** temiz kurulum. CI/CD'de ve Docker'da bunu kullan, tekrarlanabilir (reproducible) build verir.
- `npm run <script>`: `scripts` içindeki komutu çalıştırır. `^5.1.0` = 5.x.x içinde en yenisi (semver).

## Örnek kod
`01_javascript_temelleri.mjs`: değişkenler, tipler, fonksiyonlar, dizi metotları, nesneler, destructuring/spread, sınıf ve `process.env`.

```bash
node 01_javascript_temelleri.mjs
PORT=9090 node 01_javascript_temelleri.mjs   # ortam değişkeniyle
```

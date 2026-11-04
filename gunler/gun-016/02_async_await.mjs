// Gün 016: Asenkron JavaScript — event loop, Promise, async/await.
// Çalıştır: node 02_async_await.mjs
// Kendi içinde 3 sahte mikroservis açar (127.0.0.1, rastgele port), internet gerekmez.

import http from "node:http";
import { setTimeout as bekle } from "node:timers/promises";   // Promise döndüren setTimeout
import { readFile } from "node:fs/promises";
import { readFile as readFileCb } from "node:fs";              // callback stili, karşılaştırma için

const baslik = (metin) => console.log(`\n=== ${metin} ===`);
const sure = (t0) => `${((performance.now() - t0) / 1000).toFixed(2)} sn`;

// ---------------------------------------------------------------
baslik("1) Çalışma sırası: senkron → microtask → timer");
console.log("1: senkron");
setTimeout(() => console.log("4: setTimeout (timer kuyruğu)"), 0);
Promise.resolve().then(() => console.log("3: promise (microtask kuyruğu)"));
console.log("2: senkron");
await bekle(10);   // .mjs'te en üst seviyede await kullanılabilir (top-level await)

// ---------------------------------------------------------------
baslik("2) Callback → Promise → async/await (aynı iş, üç stil)");
// Eski stil: callback (Node'un ilk API'leri böyleydi)
readFileCb("/etc/hostname", "utf8", (hata, veri) => {
    console.log("callback :", hata ? hata.code : veri.trim());
});
// Promise zinciri
readFile("/etc/hostname", "utf8")
    .then((veri) => console.log("then     :", veri.trim()))
    .catch((hata) => console.log("then     :", hata.code));
// async/await: en okunaklısı
try {
    const veri = await readFile("/etc/hostname", "utf8");
    console.log("await    :", veri.trim());
} catch (hata) {
    console.log("await    :", hata.code);
}
try {
    await readFile("/yok/boyle/dosya");
} catch (hata) {
    console.log("hata yakalandı:", hata.code);   // ENOENT
}

// ---------------------------------------------------------------
// Sahte mikroservisler: gecikme ve davranış URL'den seçilir
const sunucu = http.createServer(async (istek, cevap) => {
    const yol = new URL(istek.url, "http://x").pathname;
    const ayarlar = {
        "/hizli": { ms: 300, kod: 200 },
        "/yavas": { ms: 1000, kod: 200 },
        "/bozuk": { ms: 200, kod: 500 },
        "/takili": { ms: 5000, kod: 200 },
    }[yol] ?? { ms: 0, kod: 404 };
    await bekle(ayarlar.ms);
    cevap.writeHead(ayarlar.kod, { "Content-Type": "application/json" });
    cevap.end(JSON.stringify({ servis: yol, ms: ayarlar.ms }));
});
await new Promise((tamam) => sunucu.listen(0, "127.0.0.1", tamam));   // callback'i Promise'e çevirme
const TABAN = `http://127.0.0.1:${sunucu.address().port}`;
console.log(`\n(sahte servisler ${TABAN} adresinde)`);

// fetch: Node 18+ içinde hazır. HTTP hata kodunda (500) reject ETMEZ, bunu kendimiz kontrol ederiz.
async function getir(yol, zamanAsimiMs = 2000) {
    const cevap = await fetch(TABAN + yol, { signal: AbortSignal.timeout(zamanAsimiMs) });
    if (!cevap.ok) throw new Error(`${yol} → HTTP ${cevap.status}`);
    return cevap.json();
}

// ---------------------------------------------------------------
baslik("3) Sıralı vs paralel");
const yollar = ["/hizli", "/yavas", "/hizli"];

let t0 = performance.now();
for (const yol of yollar) await getir(yol);           // biri bitmeden diğeri başlamaz
console.log("sıralı  :", sure(t0), "(300 + 1000 + 300 ms)");

t0 = performance.now();
await Promise.all(yollar.map((yol) => getir(yol)));    // hepsi aynı anda
console.log("paralel :", sure(t0), "(en yavaşı kadar)");

// ---------------------------------------------------------------
baslik("4) Promise.all vs Promise.allSettled");
const hepsi = ["/hizli", "/bozuk", "/yavas"];
try {
    await Promise.all(hepsi.map((y) => getir(y)));
} catch (hata) {
    console.log("all        : biri patladı, hepsi kayıp →", hata.message);
}
const sonuclar = await Promise.allSettled(hepsi.map((y) => getir(y)));
sonuclar.forEach((s, i) =>
    console.log(`allSettled : ${hepsi[i].padEnd(7)} ${s.status === "fulfilled" ? "✅" : "❌ " + s.reason.message}`),
);

// ---------------------------------------------------------------
baslik("5) Zaman aşımı (timeout)");
t0 = performance.now();
try {
    await getir("/takili", 1500);
} catch (hata) {
    console.log(`/takili 5 sn sürecekti, ${sure(t0)} sonra kesildi →`, hata.name);   // TimeoutError
}

// ---------------------------------------------------------------
baslik("6) Tekrar deneme (retry) + üstel bekleme (exponential backoff)");
// AWS SDK'nın da yaptığı şey: hata alınca bekle, her denemede bekleme süresini ikiye katla
async function tekrarDene(is, { deneme = 3, ilkBekleme = 200 } = {}) {
    for (let i = 1; i <= deneme; i++) {
        try {
            return await is();
        } catch (hata) {
            if (i === deneme) throw hata;
            const ms = ilkBekleme * 2 ** (i - 1);
            console.log(`  deneme ${i} başarısız (${hata.message}), ${ms} ms sonra tekrar`);
            await bekle(ms);
        }
    }
}
try {
    await tekrarDene(() => getir("/bozuk"));
} catch (hata) {
    console.log("3 denemeden sonra vazgeçildi:", hata.message);
}

// ---------------------------------------------------------------
baslik("7) Event loop'u kilitlemek (yapma)");
const zamanlayici = setTimeout(() => console.log("  timer çalıştı (gecikmeli!)"), 50);
t0 = performance.now();
while (performance.now() - t0 < 500) { /* 500 ms CPU meşgul: kimse cevap alamaz */ }
console.log("  500 ms'lik senkron döngü bitti, 50 ms'lik timer ancak şimdi çalışabilecek");
await bekle(10);
clearTimeout(zamanlayici);

sunucu.close();
console.log("\nbitti.");

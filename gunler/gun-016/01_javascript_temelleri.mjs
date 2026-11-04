// Gün 016: JavaScript ve Node.js temelleri.
// Çalıştır: node 01_javascript_temelleri.mjs
// .mjs uzantısı Node'a "bu bir ES modülü" der, import/export kullanılabilir.

import os from "node:os";
import { inspect } from "node:util";   // değeri okunur biçimde yazdırmak için

const baslik = (metin) => console.log(`\n=== ${metin} ===`);

// ---------------------------------------------------------------
baslik("1) let / const ve tipler");
const ad = "Sinan";          // yeniden atanamaz
let sayac = 0;               // yeniden atanabilir
sayac += 1;
console.log(typeof ad, typeof sayac, typeof true, typeof null, typeof undefined);
// typeof null === "object": dilin 1995'ten kalma bilinen hatası

console.log("0 == '0'  →", 0 == "0");    // true  (tip zorlaması)
console.log("0 === '0' →", 0 === "0");   // false (hep bunu kullan)
console.log("0.1 + 0.2 →", 0.1 + 0.2);   // 0.30000000000000004 (Python'da da aynı)

// ---------------------------------------------------------------
baslik("2) truthy / falsy, ?? ve ?.");
for (const deger of [0, "", null, undefined, NaN, [], {}, "0"]) {
    console.log(inspect(deger).padEnd(9), "→", deger ? "doğru" : "yanlış");
}
const port = process.env.PORT ?? 3000;   // ortamda yoksa 3000
console.log("port:", port);
const kullanici = { ad: "Ayşe" };
console.log("şehir:", kullanici.adres?.sehir);   // hata değil, undefined

// ---------------------------------------------------------------
baslik("3) Fonksiyonlar");
function selamla(isim, selam = "Merhaba") {   // varsayılan parametre
    return `${selam}, ${isim}!`;
}
const kare = (x) => x * x;                   // ok fonksiyonu, tek ifade = otomatik return
const topla = (...sayilar) => sayilar.reduce((a, b) => a + b, 0);  // rest parametre (*args)
console.log(selamla("Sinan"), kare(7), topla(1, 2, 3, 4));

// Closure: içteki fonksiyon dıştaki değişkeni hatırlar
function sayacYap() {
    let n = 0;
    return () => ++n;
}
const say = sayacYap();
say(); say();
console.log("closure sayacı:", say());   // 3

// ---------------------------------------------------------------
baslik("4) Dizi (Array) metotları");
const sunucular = [
    { ad: "web-1", cpu: 72, bolge: "eu-north-1" },
    { ad: "web-2", cpu: 15, bolge: "eu-north-1" },
    { ad: "db-1",  cpu: 91, bolge: "eu-central-1" },
];
const yogun = sunucular.filter((s) => s.cpu > 50).map((s) => s.ad);
const ortalama = sunucular.reduce((t, s) => t + s.cpu, 0) / sunucular.length;
console.log("CPU > 50:", yogun);
console.log("ortalama CPU:", ortalama.toFixed(1));
console.log("db var mı:", sunucular.some((s) => s.ad.startsWith("db")));
console.log("CPU'ya göre:", [...sunucular].sort((a, b) => b.cpu - a.cpu).map((s) => s.ad));
// [...dizi] kopya alır; sort() diziyi yerinde değiştirir

// ---------------------------------------------------------------
baslik("5) Nesne, destructuring, spread");
const config = { bolge: "eu-north-1", ortam: "dev", etiketler: { proje: "365" } };
const { bolge, ortam: ortamAdi } = config;            // nesneden çek, yeniden adlandır
const [ilk, ...kalanlar] = sunucular.map((s) => s.ad); // diziden çek
console.log(bolge, ortamAdi, ilk, kalanlar);

const prodConfig = { ...config, ortam: "prod" };       // kopyala + üzerine yaz
const derinKopya = structuredClone(config);            // derin kopya (iç nesneler de kopyalanır)
console.log("dev :", config.ortam, "| prod:", prodConfig.ortam);
// DİKKAT: spread sığ kopyadır (shallow copy), iç nesne ortak kalır
prodConfig.etiketler.proje = "değişti";
console.log("dev etiketi de değişti:", config.etiketler.proje, "| derin kopya etkilenmedi:", derinKopya.etiketler.proje);

for (const [anahtar, deger] of Object.entries({ cpu: 4, ram: "16GB" })) {
    console.log(` ${anahtar} = ${deger}`);
}

// JSON: API'ler ve config dosyaları
const json = JSON.stringify({ ad: "web-1", saglikli: true }, null, 2);
console.log(json);
console.log("geri çevrildi:", JSON.parse(json).ad);

// ---------------------------------------------------------------
baslik("6) Sınıf (class)");
class Sunucu {
    #sifre = "gizli";        // # = gerçekten private alan
    static sayi = 0;         // sınıfa ait (Gün 003 static)

    constructor(ad, cpu) {
        this.ad = ad;
        this.cpu = cpu;
        Sunucu.sayi++;
    }
    get durum() {            // getter: s.durum diye özellik gibi okunur
        return this.cpu > 80 ? "alarm" : "normal";
    }
    toString() {
        return `Sunucu(${this.ad}, cpu=${this.cpu}, ${this.durum})`;
    }
}
class GpuSunucu extends Sunucu {            // kalıtım
    constructor(ad, cpu, gpu) {
        super(ad, cpu);
        this.gpu = gpu;
    }
}
const s1 = new Sunucu("web-1", 90);
const s2 = new GpuSunucu("ml-1", 30, "RTX 3050");
console.log(String(s1), String(s2), "| toplam:", Sunucu.sayi);

// ---------------------------------------------------------------
baslik("7) Node'a özel: process ve os");
console.log("Node sürümü :", process.version);
console.log("argümanlar  :", process.argv.slice(2));   // node dosya.mjs a b → ['a','b']
console.log("platform    :", os.platform(), os.arch(), `${os.cpus().length} çekirdek`);
console.log("HOME        :", process.env.HOME);
process.exitCode = 0;   // 0 = başarılı (Bash'teki $? gibi, Gün 008)

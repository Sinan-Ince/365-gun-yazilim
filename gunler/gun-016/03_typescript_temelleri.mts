// Gün 016: TypeScript temelleri.
// Çalıştır (Node 23.6+, tipleri silip çalıştırır):  node 03_typescript_temelleri.mts
// Tip kontrolü (tipleri gerçekten denetler):        npx -p typescript tsc --noEmit --strict 03_typescript_temelleri.mts
//
// .mts = TypeScript ES modülü (top-level await ve import/export için).
// Not: Node sadece "silinebilir" (erasable) TS sözdizimini çalıştırır. enum, namespace
// ve constructor'da "public x" gibi JS'e karşılığı olan özellikler bu yüzden kullanılmadı.

const baslik = (metin: string): void => console.log(`\n=== ${metin} ===`);

// ---------------------------------------------------------------
baslik("1) Tip çıkarımı ve temel tipler");
const bolge = "eu-north-1";            // TS: tipi "eu-north-1" (literal), değişmez
let deneme = 3;                        // TS: number
const portlar: number[] = [80, 443];
const etiketler: Record<string, string> = { proje: "365", sahip: "sinan" };
console.log(bolge, deneme, portlar, etiketler);

// ---------------------------------------------------------------
baslik("2) interface, union ve isteğe bağlı alan");
type Ortam = "dev" | "staging" | "prod";

interface Sunucu {
    ad: string;
    cpu: number;
    ortam: Ortam;
    gpu?: string;                      // olmayabilir → tipi string | undefined
}

const sunucular: Sunucu[] = [
    { ad: "web-1", cpu: 92, ortam: "prod" },
    { ad: "web-2", cpu: 40, ortam: "prod" },
    { ad: "ml-1", cpu: 85, ortam: "dev", gpu: "RTX 3050" },
];

function alarmMi(s: Sunucu): boolean {
    return s.ortam === "prod" && s.cpu > 80;
}
for (const s of sunucular) {
    // s.gpu undefined olabilir; ?? ile varsayılan vermezsek TS bunu bize hatırlatır
    console.log(`${s.ad.padEnd(6)} ${s.ortam.padEnd(5)} gpu=${s.gpu ?? "-"} alarm=${alarmMi(s)}`);
}

// ---------------------------------------------------------------
baslik("3) Daraltma (narrowing) ve ayrık union (discriminated union)");
// Bir deploy işinin sonucu: "durum" alanına bakarak hangi alanların olduğunu TS bilir
type DeploySonucu =
    | { durum: "basarili"; surum: string; sureSn: number }
    | { durum: "hata"; hata: string }
    | { durum: "beklemede" };

function ozetle(s: DeploySonucu): string {
    switch (s.durum) {
        case "basarili":
            return `✅ ${s.surum} (${s.sureSn} sn)`;   // burada surum var
        case "hata":
            return `❌ ${s.hata}`;                       // burada hata var
        case "beklemede":
            return "⏳ sırada";
        default: {
            // Yeni bir durum eklenip burası unutulursa tsc burada hata verir
            const kontrol: never = s;
            return kontrol;
        }
    }
}
const deploylar: DeploySonucu[] = [
    { durum: "basarili", surum: "v1.4.2", sureSn: 48 },
    { durum: "hata", hata: "health check zaman aşımı" },
    { durum: "beklemede" },
];
deploylar.forEach((d) => console.log(ozetle(d)));

function idYaz(id: string | number): string {
    if (typeof id === "string") return id.toUpperCase();   // burada string
    return `#${id.toFixed(0)}`;                             // burada number
}
console.log(idYaz("i-0abc"), idYaz(42));

// ---------------------------------------------------------------
baslik("4) Generic");
function ilk<T>(dizi: readonly T[]): T | undefined {
    return dizi[0];
}
function grupla<T, K extends string>(dizi: readonly T[], anahtar: (x: T) => K): Record<K, T[]> {
    const sonuc = {} as Record<K, T[]>;
    for (const x of dizi) (sonuc[anahtar(x)] ??= []).push(x);
    return sonuc;
}
const ilkSunucu = ilk(sunucular);       // tipi: Sunucu | undefined
console.log("ilk:", ilkSunucu?.ad);
const ortamaGore = grupla(sunucular, (s) => s.ortam);
console.log("ortama göre:", Object.fromEntries(
    Object.entries(ortamaGore).map(([k, v]) => [k, (v as Sunucu[]).map((s) => s.ad)]),
));

// ---------------------------------------------------------------
baslik("5) unknown: dışarıdan gelen veriyi güvenle doğrulama");
// JSON.parse'ın sonucu aslında any'dir; ona körü körüne güvenme.
// Bir "type guard" fonksiyonu (x is Sunucu) ile kontrol edip tipi daraltıyoruz.
function sunucuMu(x: unknown): x is Sunucu {
    if (typeof x !== "object" || x === null) return false;
    const o = x as Record<string, unknown>;
    return typeof o.ad === "string"
        && typeof o.cpu === "number"
        && (o.ortam === "dev" || o.ortam === "staging" || o.ortam === "prod");
}
const gelenler = [
    '{"ad": "api-1", "cpu": 55, "ortam": "staging"}',
    '{"ad": "api-2", "cpu": "çok", "ortam": "prod"}',   // cpu yanlış tipte
    '{"ad": "api-3", "cpu": 10, "ortam": "test"}',      // ortam geçersiz
];
for (const metin of gelenler) {
    const veri: unknown = JSON.parse(metin);
    if (sunucuMu(veri)) {
        console.log("geçerli :", veri.ad, veri.cpu);   // burada veri: Sunucu
    } else {
        console.log("reddedildi:", metin);
    }
}

// ---------------------------------------------------------------
baslik("6) Sınıf + implements");
interface SaglikKontrolu {
    kontrolEt(): Promise<boolean>;
}
class PortKontrolu implements SaglikKontrolu {
    readonly hedef: string;
    #denemeSayisi = 0;
    constructor(hedef: string) {
        this.hedef = hedef;
    }
    async kontrolEt(): Promise<boolean> {
        this.#denemeSayisi++;
        return this.hedef.endsWith(":443");
    }
}
const kontroller: SaglikKontrolu[] = [new PortKontrolu("web-1:443"), new PortKontrolu("web-2:8080")];
const durumlar = await Promise.all(kontroller.map((k) => k.kontrolEt()));
console.log("sağlık:", durumlar);

// ---------------------------------------------------------------
// TİP HATALARI: Aşağıdaki satırların yorumunu kaldır.
// `node` yine de çalıştırır (tipleri sadece siler), ama `tsc --noEmit` hepsini yakalar.
//
// const hatali: Sunucu = { ad: "x", cpu: "yüksek", ortam: "prod" };  // cpu number olmalı
// const yanlisOrtam: Ortam = "production";                            // böyle bir değer yok
// sunucular[0].cpuu;                                                  // yazım hatası
// alarmMi({ ad: "y", cpu: 1 });                                       // ortam eksik

export {};   // dosyayı modül yapar (top-level await için)

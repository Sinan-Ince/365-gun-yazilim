# TypeScript Temelleri (tip, interface, union, generic)

**Tanım:**
- **TypeScript (TS):** JavaScript + **statik tipler (static typing)**. Microsoft yapımı. TS kodu derlenirken tipler kontrol edilir, sonra tipler silinip düz JS'e çevrilir. Tarayıcı ya da Node sonunda yine JS çalıştırır.
- **Tip kontrolü (type checking):** Hatayı **çalıştırmadan önce** yakalar. `sunucu.cpuu` gibi bir yazım hatası JS'te çalışırken `undefined` olarak sessizce geçer, TS'te derleme hatası verir.
- **`tsc`:** TypeScript derleyicisi. `tsc --noEmit` sadece tipleri kontrol eder, dosya üretmez (CI'da kullanılır). Ayarlar `tsconfig.json` dosyasında, `"strict": true` her zaman açık olsun.
- **Node ile doğrudan çalıştırma:** Node 23.6+ `.ts` dosyasını doğrudan çalıştırır (`node dosya.ts`), ama **sadece tipleri siler, kontrol etmez**. Tip hatası olan kod da çalışır. Kontrol için yine `tsc` lazım.
- **Tip çıkarımı (type inference):** `const x = 5` yazınca TS `x`'in `number` olduğunu kendisi anlar. Tipi sadece fonksiyon parametrelerine ve dışarıdan gelen veriye yazman yeterli.

**Neden önemli:** **AWS CDK**'de altyapıyı (VPC, EC2, Lambda) TypeScript koduyla tanımlarsın. Tip sistemi sayesinde editör her kaynağın alabileceği ayarları otomatik tamamlar, yanlış ayarı `cdk deploy`'dan önce yakalar. **Pulumi** de aynı şekilde çalışır. Büyük Node projelerinin, Lambda'ların ve AWS SDK v3'ün kendisi TS ile yazılmış. Ayrıca `tsc --noEmit`, CI pipeline'larında lint ve test adımlarının yanında standart bir kalite kapısı (quality gate) olarak durur.

## Temel tipler
| Yazım | Anlamı |
|---|---|
| `string`, `number`, `boolean` | Temel tipler |
| `string[]` ya da `Array<string>` | String dizisi |
| `{ ad: string; cpu?: number }` | Nesne; `?` = isteğe bağlı alan |
| `"dev" \| "prod"` | **Union** + **literal**: sadece bu iki değer olabilir |
| `Record<string, number>` | Anahtarı string, değeri number olan sözlük |
| `unknown` | "Ne olduğunu bilmiyorum, kullanmadan önce kontrol et" (güvenli) |
| `any` | Tip kontrolünü kapatır. **Kaçın**, TS kullanmanın anlamı kalmaz |
| `(x: number) => string` | Fonksiyon tipi |
| `readonly string[]` | Değiştirilemez dizi |

## `interface` ve `type`
```ts
interface Sunucu {                 // nesnenin şekli (shape)
    ad: string;
    cpu: number;
    ortam: "dev" | "prod";
    etiketler?: Record<string, string>;
}

type Durum = "calisiyor" | "durdu" | "hata";   // type: union ve takma ad için

function alarmMi(s: Sunucu): boolean {
    return s.ortam === "prod" && s.cpu > 80;
}
```
İkisi de çoğu yerde aynı işi görür. Nesne şekli için `interface`, union ve diğer her şey için `type` yaygın bir kural.

## Daraltma (narrowing)
Union tipte TS, `if` kontrolünden sonra hangi tip olduğunu anlar:
```ts
function yazdir(id: string | number) {
    if (typeof id === "string") return id.toUpperCase();   // burada string
    return id.toFixed(0);                                   // burada number
}
```

## Generic (tip parametresi)
"Her tiple çalışan ama tipi kaybetmeyen" fonksiyon:
```ts
function ilk<T>(dizi: T[]): T | undefined {
    return dizi[0];
}
const a = ilk([1, 2, 3]);        // number | undefined
const b = ilk(["x", "y"]);      // string | undefined
```

## Kurulum ve kullanım
```bash
npm install --save-dev typescript   # projeye ekle
npx tsc --init                      # tsconfig.json oluştur
npx tsc --noEmit                    # sadece tip kontrolü (CI adımı)
node 03_typescript_temelleri.mts     # Node 23.6+: tipleri silip çalıştırır
```

## Örnek kod
`03_typescript_temelleri.mts`: interface, union, narrowing, generic, `unknown` ile dışarıdan gelen JSON'u güvenli doğrulama. Sonunda yorum içinde bekleyen tip hataları var. Yorumu kaldırıp `npx tsc --noEmit` ile yakalanmasını izleyebilirsin.

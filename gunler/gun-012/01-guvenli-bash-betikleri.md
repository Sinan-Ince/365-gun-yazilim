# Bash: Güvenli Betik Pratikleri (`set -euo pipefail`, `trap`, `getopts`, `shellcheck`)

**Tanım:**
- **Sıkı mod (strict mode):** `set -euo pipefail`. Bash varsayılan olarak hatalara göz yumar: komut başarısız olsa da sonraki satıra geçer. Bu üç ayar onu "hata olunca dur" moduna alır.
  - `-e` (errexit): bir komut sıfırdan farklı exit kodu (Gün 008) dönerse betik durur.
  - `-u` (nounset): tanımsız değişken kullanılırsa hata verir (yazım hatası `$DOSYAA` sessizce boş string olmaz).
  - `-o pipefail`: pipe'ta (Gün 007) herhangi bir parça başarısız olursa pipe'ın kodu başarısız olur. Yoksa sadece son komuta bakılır.
- **`trap`:** Betik bir sinyal (Gün 009) aldığında veya çıkarken çalışacak komutu kaydeder. `trap temizle EXIT` = betik nasıl biterse bitsin (başarı, hata, Ctrl+C) `temizle` çalışır.
- **`getopts`:** Bash'in yerleşik seçenek ayrıştırıcısı (option parser). `-v`, `-n 5`, `-h` gibi kısa seçenekleri standart şekilde okur.
- **`shellcheck`:** Bash betiklerini çalıştırmadan inceleyen statik analiz aracı (linter). Tırnaksız değişken, yanlış `[ ]` kullanımı gibi yüzlerce hatayı yakalar.

**Neden önemli:** CI/CD hattında (GitHub Actions `run:`, GitLab CI, Jenkins), Dockerfile `RUN` satırlarında, EC2 **user data** betiklerinde ve deploy betiklerinde Bash her yerde. Sıkı mod olmadan `cd /yanlis/klasor` başarısız olur ve sonraki `rm -rf *` **yanlış klasörde** çalışır. `trap` ile geçici dosyalar, kilit dosyaları (`flock`, Gün 011) ve yarım kalan işler temizlenir. `shellcheck` birçok projede CI'da zorunlu adımdır; GitHub Actions'ın varsayılan bash'i bile `bash -e {0}` ile, yani `-e` açık çalışır.

## Sıkı mod: önce / sonra
```bash
#!/usr/bin/env bash
# set yok:
cd /olmayan/klasor      # hata verir ama devam eder
rm -rf ./*              # bulunduğun klasörü siler!
```
```bash
#!/usr/bin/env bash
set -euo pipefail
cd /olmayan/klasor      # burada durur, exit 1
rm -rf ./*              # hiç çalışmaz
```

| Ayar | Olmazsa | Olursa |
|---|---|---|
| `-e` | hata sonrası devam | ilk hatada çık |
| `-u` | `$YOK` → boş string | `YOK: unbound variable`, çık |
| `pipefail` | `false \| true` → 0 | `false \| true` → 1 |

## `-e`'nin bilinmesi gereken istisnaları
```bash
if grep -q hata log; then ...   # if/while koşulundaki hata betiği durdurmaz (zaten amacı bu)
komut || true                    # "başarısız olabilir, sorun değil" demenin yolu
komut && echo tamam              # && zincirinin sol tarafı durdurmaz
sayi=$(( 0 ))                    # dikkat: ((i++)) i=0 iken 1 döner ve -e ile betik ölür → i=$((i+1)) kullan
local x=$(komut)                 # local, komutun hatasını yutar → önce local x; sonra x=$(komut)
```

## `trap`: her durumda temizlik
```bash
gecici=$(mktemp -d)                         # güvenli geçici klasör (/tmp/tmp.XXXX)
temizle() { rm -rf "$gecici"; }
trap temizle EXIT                           # başarı, hata, exit: hepsinde çalışır
trap 'echo "Satır $LINENO hata verdi" >&2' ERR   # hangi satırda patladı
trap 'echo "iptal"; exit 130' INT TERM     # Ctrl+C ve kill (Gün 009)
```
> `kill -9` (SIGKILL) yakalanamaz, `trap` çalışmaz. Bu yüzden servisler önce SIGTERM alır.

## `getopts`: seçenek okuma
```bash
ayrintili=0; adet=1
while getopts ":vn:h" sec; do     # baştaki ":" = hataları kendim yöneteceğim; "n:" = -n değer alır
    case $sec in
        v) ayrintili=1 ;;
        n) adet=$OPTARG ;;
        h) kullanim; exit 0 ;;
        :) echo "-$OPTARG değer ister" >&2; exit 2 ;;
        \?) echo "Bilinmeyen seçenek: -$OPTARG" >&2; exit 2 ;;
    esac
done
shift $((OPTIND - 1))             # seçenekleri at, "$@" artık sadece kalan argümanlar
```
`getopts` sadece kısa seçenekleri (`-v`) bilir. `--verbose` gibi uzunlar için `while [[ $# -gt 0 ]]; case $1 in ...` döngüsü yazılır.

## Güvenli betik şablonu (kontrol listesi)
1. `#!/usr/bin/env bash` + `set -euo pipefail`
2. Değişkenleri hep tırnakla: `"$dosya"`, `"$@"` (boşluklu dosya adları)
3. Testlerde `[[ ]]` kullan, `[ ]` değil
4. Geçici dosya: `mktemp`, temizlik: `trap ... EXIT`
5. Zorunlu değişken: `: "${TOKEN:?gerekli}"` (Gün 011)
6. Hata mesajları stderr'e: `echo "hata" >&2`, anlamlı exit kodları (0 başarı, 1 hata, 2 kullanım hatası)
7. `rm -rf "$klasor/"*` yerine `rm -rf "${klasor:?}/"*`: değişken boşsa `/` silinmez
8. Çalıştırmadan önce: `shellcheck betik.sh`

## shellcheck
```bash
sudo pacman -S shellcheck        # Arch  (Ubuntu: apt install shellcheck)
shellcheck 01_guvenli_bash_betikleri.sh
```
```
In betik.sh line 3:
rm -rf $klasor/*
       ^-----^ SC2086: Double quote to prevent globbing and word splitting.
```
Her uyarının bir kodu var (SC2086). `shellcheck.net/wiki/SC2086` açıklamasını verir. Bilerek yapıyorsan satır üstüne `# shellcheck disable=SC2086`.

Kod: [`01_guvenli_bash_betikleri.sh`](01_guvenli_bash_betikleri.sh). `getopts` ile seçenek alır, `-e`/`-u`/`pipefail` farkını alt kabuklarda gösterir, `mktemp` + `trap` ile geçici klasörü her durumda temizler.

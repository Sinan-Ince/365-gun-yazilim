# Bash: Fonksiyon, Argümanlar ve Exit Kodları

**Tanım:**
- **Fonksiyon (function):** `ad() { ...; }` ile tanımlanır, `ad arg1 arg2` ile çağrılır. Argümanlar `$1 $2 ...` olarak gelir. Değer **döndürmez**, `echo` ile çıktı basar, `return` ile sadece durum kodu (0-255) verir.
- **Argümanlar (positional parameters):** Betiğe verilen parametreler: `$0` betik adı, `$1..$9`, `$#` sayısı, `"$@"` hepsi (ayrı ayrı).
- **Exit kodu (exit status):** Her komut bitince bir sayı bırakır, `$?` ile okunur. **0 = başarılı**, 0 dışı = hata. `exit N` betiği bu kodla bitirir.

**Neden önemli:** CI/CD sistemleri (GitHub Actions, Jenkins), Docker `HEALTHCHECK`, Kubernetes probe'ları, systemd ve cron bir adımın başarılı olup olmadığına **sadece exit koduna** bakar. Test betiğin hata verip `exit 0` ile biterse pipeline yeşil yanar ve bozuk kod production'a gider. Argüman alan fonksiyonlu betikler de tekrar kullanılabilir araçlar (`./deploy.sh prod v1.2`) yazmanı sağlar.

## Özel değişkenler
| Değişken | Anlamı |
|---|---|
| `$0` | Betiğin adı |
| `$1`, `$2`, ... | 1., 2. argüman (fonksiyon içinde: fonksiyonun argümanı) |
| `$#` | Argüman sayısı |
| `"$@"` | Tüm argümanlar, her biri ayrı kelime (**hep bunu kullan**) |
| `$*` | Tüm argümanlar tek metin |
| `$?` | Son komutun exit kodu |
| `$$` | Betiğin PID'i |
| `shift` | Argümanları bir sola kaydır (`$2` → `$1`) |

## Fonksiyon
```bash
selamla() {
    local ad="${1:?ad gerekli}"     # local: değişken fonksiyon dışına sızmaz
    local unvan="${2:-Mühendis}"    # 2. argüman yoksa varsayılan
    echo "Merhaba $unvan $ad"
}
selamla Sinan                       # Merhaba Mühendis Sinan
mesaj=$(selamla Ali DevOps)         # "dönüş değeri" = yakalanan stdout

port_acik_mi() {                    # return ile true/false
    (( $1 >= 1 && $1 <= 65535 ))    # son komutun kodu = fonksiyonun kodu
}
if port_acik_mi 8080; then echo "geçerli port"; fi
```

## Exit kodları
| Kod | Anlamı |
|---|---|
| `0` | Başarılı |
| `1` | Genel hata |
| `2` | Yanlış kullanım (eksik/yanlış argüman) |
| `126` | Çalıştırma izni yok (Gün 007: `chmod +x`) |
| `127` | Komut bulunamadı |
| `128+N` | N numaralı sinyalle öldü (`130` = Ctrl+C, `137` = `kill -9`, K8s'te OOMKilled) |

```bash
grep -q root /etc/passwd
echo $?                    # 0 (bulundu)
grep -q yokboyle /etc/passwd
echo $?                    # 1 (bulunamadı)
```

## Sağlam betik iskeleti (her betiğe bunu koy)
```bash
#!/usr/bin/env bash
set -euo pipefail          # -e: hata olursa dur, -u: tanımsız değişken hata, pipefail: pipe'ta hata yakala
trap 'echo "Hata: satır $LINENO" >&2' ERR

kullanim() { echo "Kullanım: $0 <ortam> [versiyon]" >&2; exit 2; }
(( $# >= 1 )) || kullanim

ortam="$1"; versiyon="${2:-latest}"
echo "Deploy: $ortam / $versiyon"
```

## Bayraklı argümanlar: `getopts`
```bash
while getopts "e:v" secenek; do      # e: değer alır, v: almaz
    case "$secenek" in
        e) ortam="$OPTARG" ;;
        v) ayrinti=1 ;;
        *) kullanim ;;
    esac
done
shift $(( OPTIND - 1 ))              # kalan argümanlar "$@" içinde
```

## Python karşılığı
| Bash | Python |
|---|---|
| `f() { echo "$1"; }` | `def f(x): print(x)` |
| `local x` | fonksiyon içi değişken (varsayılan) |
| `"$@"`, `$#` | `sys.argv[1:]`, `len(sys.argv) - 1` |
| `exit 2` | `sys.exit(2)` |
| `getopts` | `argparse` |

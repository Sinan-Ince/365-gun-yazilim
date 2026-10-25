# Bash: Değişken, Koşul ve Döngü

**Tanım:**
- **Değişken (variable):** `ad=deger` ile atanır (eşittir etrafında **boşluk yok**), `$ad` ya da `${ad}` ile okunur. Bash'te her şey varsayılan olarak metindir (string).
- **Koşul (conditional):** `if [[ ... ]]; then ... elif ...; else ...; fi`. `[[ ]]` bash'in test ifadesidir, karşılaştırma `true/false` değil **exit kodu** (0 = doğru) üretir.
- **Döngü (loop):** `for x in liste; do ... done`, `while kosul; do ... done`. Satır satır dosya okumak için `while read`.

**Neden önemli:** Gün 007'deki tek satırlık pipe'lar bir yere kadar yeter. Sunucu kurulum betikleri, deploy adımları, CI/CD job'ları (GitHub Actions `run:` blokları), EC2 **user data** ve Docker `ENTRYPOINT` betikleri hep bash'tir. "5 sunucuya bağlan, disk %90'ı geçtiyse uyar" gibi işler değişken + if + for ile yazılır.

## Değişkenler
```bash
ortam="prod"                 # boşluk YOK: ortam = "prod" hata verir
sayi=5
echo "Ortam: $ortam, ${ortam}-db"   # süslü parantez: ismi sınırla
dizin=$(pwd)                 # komut çıktısı (Gün 007)
(( sayi = sayi + 1 ))        # aritmetik: (( ))
echo $(( sayi * 2 ))         # 12
readonly BOLGE="eu-central-1"   # sabit
export AWS_REGION="$BOLGE"      # alt süreçlere (child process) aktar = ortam değişkeni
echo "${VERSIYON:-latest}"      # tanımsızsa varsayılan değer
```

| Yazım | Anlamı |
|---|---|
| `"$x"` | Çift tırnak: değişken açılır, **boşluklu değerleri korur** (her zaman tırnakla!) |
| `'$x'` | Tek tırnak: olduğu gibi yazılır, açılmaz |
| `${#x}` | Uzunluk |
| `${x:-v}` | `x` boşsa `v` kullan |
| `${dosya%.log}` | Sondan `.log` sil → `app.log` → `app` |
| `dizi=(a b c)`, `${dizi[@]}`, `${#dizi[@]}` | Dizi (array), tüm elemanlar, eleman sayısı |

## Koşullar: `[[ ]]` operatörleri
| Metin (string) | Sayı | Dosya |
|---|---|---|
| `==` eşit, `!=` farklı | `-eq` `-ne` | `-f` dosya var |
| `-z` boş, `-n` dolu | `-lt` `-le` (<, ≤) | `-d` dizin var |
| `=~` regex eşleşmesi | `-gt` `-ge` (>, ≥) | `-x` çalıştırılabilir |
| `&&` ve, `\|\|` veya, `!` değil | `(( a > b ))` alternatif | `-r` `-w` okunur/yazılır |

```bash
if [[ -f /etc/os-release ]]; then
    echo "Linux"
elif [[ "$OSTYPE" == darwin* ]]; then
    echo "macOS"
else
    echo "bilinmiyor"
fi

case "$ortam" in             # çok dallı seçim (Python match / switch)
    prod)      echo "dikkat!" ;;
    dev|test)  echo "rahat"   ;;
    *)         echo "?"       ;;
esac
```

> `[ ]` (tek köşeli) eski POSIX `test` komutudur. Bash'te `[[ ]]` kullan: tırnaksız boş değişkende patlamaz, `&&` ve `=~` destekler.

## Döngüler
```bash
for s in web1 web2 db1; do echo "ping $s"; done
for f in *.log; do echo "$f"; done          # glob ile dosyalar
for ((i=1; i<=3; i++)); do echo "$i"; done   # C stili
for i in {1..5}; do echo "$i"; done          # aralık (brace expansion)

while IFS= read -r satir; do                 # dosyayı satır satır oku
    echo ">> $satir"
done < sunucular.txt

sayac=0
while (( sayac < 3 )); do (( sayac++ )); done   # break / continue da var
```

## Python karşılığı
| Bash | Python |
|---|---|
| `x=5` | `x = 5` |
| `if [[ $x -gt 3 ]]; then ... fi` | `if x > 3:` |
| `for s in a b c; do ... done` | `for s in ["a","b","c"]:` |
| `while read -r l; do ...; done < f` | `for l in open(f):` |
| `case ... esac` | `match ...:` |

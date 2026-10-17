# Döngüler (for / while)

**Tanım:** Döngü, bir kod bloğunu birden çok kez çalıştırır.
- **for:** Bir koleksiyonun her elemanı için ya da belli bir sayıda çalışır.
- **while:** Koşul doğru olduğu sürece çalışır.

**Neden önemli:** 100 sunucuya aynı komutu göndermek, bir dosyayı satır satır okumak ya da servis ayağa kalkana kadar beklemek gibi işler hep döngüyle yapılır.

## Döngü kontrolü
| Komut | Ne yapar |
|---|---|
| `break` | Döngüden tamamen çıkar |
| `continue` | Bu turu atlar, sonraki tura geçer |

## Diğer dillerde
```java
// Java / C# / JS: klasik sayaçlı for
for (int i = 0; i < 5; i++) { System.out.println(i); }
```
```go
// Go'da while yoktur, her şey for ile yazılır
for i := 0; i < 5; i++ { fmt.Println(i) }
for sayac < 10 { sayac++ }   // while gibi çalışır
```
```bash
# Bash: birden çok sunucuya ping atmak
for sunucu in web1 web2 db1; do
    ping -c 1 "$sunucu" > /dev/null && echo "$sunucu ayakta"
done

# Servis cevap verene kadar beklemek (DevOps'ta çok yaygın)
until curl -s http://localhost:8080 > /dev/null; do
    echo "bekleniyor..."; sleep 2
done
```

> ⚠️ **Sonsuz döngü:** `while` koşulu hiç yanlış olmazsa program asla durmaz. Koşulu değiştiren bir satır olduğundan emin ol.

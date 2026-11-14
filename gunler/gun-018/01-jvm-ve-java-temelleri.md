# JVM ve Java Temelleri (bytecode, tipler, koleksiyonlar)

**Tanım:**
- **Java:** 1995'ten beri kullanılan, **statik tipli (static typing)** ve **nesne yönelimli (object-oriented)** bir dil. Go gibi derlenir, ama makine koduna değil **bytecode**'a derlenir.
- **JVM (Java Virtual Machine):** Bytecode'u çalıştıran sanal makine. "Bir kere yaz, her yerde çalıştır (write once, run anywhere)": aynı `.class`/`.jar` dosyası Linux, Windows ve macOS'ta çalışır, yeter ki JVM kurulu olsun.
- **JIT (Just-In-Time) derleyici:** JVM, sık çalışan kodu çalışma anında makine koduna çevirir. Bu yüzden Java uygulaması ilk saniyelerde yavaş, ısındıktan sonra (warm-up) çok hızlıdır.
- **JDK ve JRE:** JDK (Java Development Kit) = derleyici (`javac`) + araçlar + JVM. JRE (Java Runtime Environment) = sadece çalıştırmak için JVM. Sunucuda/konteynerde JRE yeterli.
- **`javac Dosya.java`** → `.class` (bytecode) üretir. **`java Sinif`** → çalıştırır. Java 11'den beri **`java Dosya.java`** ile derle + çalıştır tek adımda (tek dosyalık programlar için, `go run` gibi).
- **İlkel tipler (primitive types) ve referans tipleri (reference types):** `int`, `double`, `boolean`, `char`, `long` ilkel tiptir: değer doğrudan tutulur, `null` olamaz. `String`, `Integer`, `ArrayList` gibi diğer her şey nesnedir: değişken nesnenin adresini tutar, `null` olabilir.
- **Kutulama (boxing):** Koleksiyonlar ilkel tip tutamaz: `List<int>` yazılamaz, `List<Integer>` yazılır. Java `int` ↔ `Integer` dönüşümünü kendisi yapar (autoboxing).
- **`var` (Java 10+):** Yerel değişkende tip çıkarımı: `var liste = new ArrayList<String>();`. Go'daki `:=` gibi, tip yine statik.
- **Her şey bir sınıfın içinde:** Fonksiyon sınıfın dışında yazılamaz. Program `public static void main(String[] args)` metoduyla başlar.

**Neden önemli:** Kurumsal dünyanın büyük bölümü Java ile yazılmış: bankalar, e-ticaret, **Spring Boot** mikroservisleri. DevOps tarafında doğrudan karşına çıkan araçlar da Java: **Jenkins, Kafka, Elasticsearch, Gradle, SonarQube, Keycloak, Cassandra**. Bir DevOps mühendisi Java yazmasa bile şunları bilmeli: JAR nasıl çalıştırılır, JVM bellek ayarları (`-Xmx`, konteynerde `-XX:MaxRAMPercentage`), `OutOfMemoryError` ve GC (çöp toplayıcı, garbage collector) logları nasıl okunur, JDK ve JRE imajı farkı. AWS'de Java her yerde çalışır: Lambda (`java21` runtime, soğuk başlangıç için **SnapStart**), Elastic Beanstalk, ECS. AWS SDK'nın en olgun sürümlerinden biri Java SDK'dır.

## Derleme yolu: Go ve Java
```
Go:    kaynak.go  --go build-->  makine kodu (binary)  --> doğrudan çalışır
Java:  Kaynak.java --javac-->    Kaynak.class (bytecode) --> JVM (JIT) --> makine kodu
```
| | Go | Java |
|---|---|---|
| Derleme çıktısı | Platforma özel binary | Platformdan bağımsız bytecode |
| Çalıştırmak için | Hiçbir şey | JVM (JRE) |
| Açılış süresi | Milisaniyeler | Yüzlerce ms - saniyeler (JIT ısınması) |
| Uzun süreli performans | Çok iyi | Çok iyi (JIT optimizasyonu) |
| Bellek | Az | Fazla (JVM + heap) |
| Konteyner imajı | 5-20 MB | 100-300 MB (JRE dahil) |
| Hata yönetimi | `if err != nil` | `try/catch` (exception) |

## Python / Go / Java karşılaştırması
| | Python | Go | Java |
|---|---|---|---|
| Değişken | `x = 5` | `x := 5` | `int x = 5;` / `var x = 5;` |
| Sabit | `X = 5` (gelenek) | `const X = 5` | `final int X = 5;` |
| Liste | `list` | slice `[]int` | `ArrayList<Integer>` / dizi `int[]` |
| Sözlük | `dict` | `map[string]int` | `HashMap<String, Integer>` |
| Yok değeri | `None` | `nil` | `null` |
| Metin eşitliği | `a == b` | `a == b` | `a.equals(b)` (`==` adres karşılaştırır!) |
| Görünürlük | `_ad` (gelenek) | Büyük harf | `public` / `private` / `protected` |
| Paket aracı | `pip` | `go mod` | Maven / Gradle (03. kavram) |

## Sık yapılan hata: `==` ve `.equals()`
```java
String a = new String("web-1");
String b = new String("web-1");
a == b        // false: iki ayrı nesne, adresler farklı
a.equals(b)   // true: içerik aynı
```
`==` ilkel tiplerde değeri, nesnelerde **adresi** karşılaştırır. Metin ve nesne karşılaştırmasında her zaman `.equals()` kullan.

## Örnek kod
`01_java_temelleri.java`: tipler, `var`, String işlemleri, dizi, `ArrayList`, `HashMap`, döngüler, switch ifadesi, metotlar, `==`/`equals` tuzağı.

```bash
java 01_java_temelleri.java          # derle + çalıştır (tek adım)
# ya da klasik yol:
javac -d out 01_java_temelleri.java  # out/JavaTemelleri.class oluşur
java -cp out JavaTemelleri
```
> Sınıf adı rakamla başlayamadığı için dosya `01_...` ama sınıf `JavaTemelleri`. Sınıf `public` olmadığı için dosya adıyla aynı olmak zorunda değil.

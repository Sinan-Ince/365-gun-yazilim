# Maven ve Gradle (Java derleme araçları)

**Tanım:**
- **Derleme aracı (build tool):** Bağımlılıkları indirir, kodu derler, testleri çalıştırır ve çıktıyı paketler. Java'da bunun için `javac`'ı elle çağırmak yerine Maven ya da Gradle kullanılır. Python'daki `pip` + `pyproject.toml`, Node'daki `npm` + `package.json`, Go'daki `go mod` + `go build` karşılığı.
- **Maven:** XML tabanlı (`pom.xml`), "kural yapılandırmadan önce gelir (convention over configuration)" yaklaşımı. Klasör yapısı sabit, öğrenmesi kolay, kurumsal projelerde çok yaygın.
- **Gradle:** Groovy ya da Kotlin DSL ile yazılır (`build.gradle` / `build.gradle.kts`). Daha esnek ve hızlı (artımlı derleme, önbellek). Android projelerinin standart aracı.
- **Bağımlılık koordinatı:** Her kütüphane `groupId:artifactId:version` ile tanımlanır, ör. `software.amazon.awssdk:s3:2.29.0`. Kütüphaneler **Maven Central** deposundan iner ve `~/.m2/repository` altında önbelleğe alınır.
- **JAR (Java ARchive):** Derlenmiş `.class` dosyalarının zip'i. **Fat/uber JAR**, tüm bağımlılıkları da içerir: `java -jar uygulama.jar` ile tek başına çalışır (Spring Boot böyle paketler).
- **Wrapper (`mvnw`, `gradlew`):** Repoya eklenen küçük betik. Doğru Maven/Gradle sürümünü kendisi indirir, CI sunucusuna araç kurmak gerekmez.

**Neden önemli:** CI/CD pipeline'larında Java projesi gördüğünde adımlar hep aynıdır: `./mvnw verify` ya da `./gradlew build` → JAR çıkar → Docker imajına konur. Pipeline'ı hızlandırmanın en büyük yolu `~/.m2` ve `~/.gradle` klasörlerini **önbelleğe almaktır** (GitHub Actions `cache`, CodeBuild `cache` ayarı). Aksi halde her derlemede yüzlerce MB bağımlılık yeniden iner. Şirket içi kütüphaneler için **AWS CodeArtifact** ya da Nexus/Artifactory gibi özel depo kullanılır. Maven ayarına (`settings.xml`) bu deponun adresi ve token'ı yazılır.

## Standart proje yapısı (Maven ve Gradle aynı)
```
saglik/
├── pom.xml                 # (ya da build.gradle.kts)
├── mvnw                    # wrapper
└── src/
    ├── main/java/com/kiroschi/saglik/App.java    # uygulama kodu
    ├── main/resources/application.yml           # yapılandırma
    └── test/java/com/kiroschi/saglik/AppTest.java  # testler (JUnit)
target/                     # Maven çıktısı (Gradle'da build/) → .gitignore'a
```

## Minimum `pom.xml`
```xml
<project xmlns="http://maven.apache.org/POM/4.0.0">
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.kiroschi</groupId>
  <artifactId>saglik</artifactId>
  <version>1.0.0</version>

  <properties>
    <maven.compiler.release>21</maven.compiler.release>
  </properties>

  <dependencies>
    <dependency>
      <groupId>org.junit.jupiter</groupId>
      <artifactId>junit-jupiter</artifactId>
      <version>5.11.0</version>
      <scope>test</scope>   <!-- sadece testte, JAR'a girmez -->
    </dependency>
  </dependencies>
</project>
```

## Aynı şey Gradle'da (`build.gradle.kts`)
```kotlin
plugins { application }

java { toolchain { languageVersion = JavaLanguageVersion.of(21) } }
repositories { mavenCentral() }
dependencies { testImplementation("org.junit.jupiter:junit-jupiter:5.11.0") }
application { mainClass = "com.kiroschi.saglik.App" }
```

## Maven yaşam döngüsü (lifecycle)
Bir aşamayı çalıştırınca öncekiler de sırayla çalışır:
```
validate → compile → test → package → verify → install → deploy
```
| Komut | Ne yapar | Gradle karşılığı |
|---|---|---|
| `mvn compile` | Kodu derler | `gradle compileJava` |
| `mvn test` | Derler + testleri çalıştırır | `gradle test` |
| `mvn package` | + JAR üretir (`target/`) | `gradle jar` / `gradle build` |
| `mvn verify` | + entegrasyon testleri, kontroller (CI'da bunu kullan) | `gradle check` |
| `mvn install` | + JAR'ı yerel `~/.m2`'ye koyar | `gradle publishToMavenLocal` |
| `mvn dependency:tree` | Bağımlılık ağacı (çakışma ararken) | `gradle dependencies` |
| `mvn clean` | `target/` klasörünü siler | `gradle clean` |

## Diller arası paket araçları
| | Python | Node | Go | Java |
|---|---|---|---|---|
| Tanım dosyası | `pyproject.toml` | `package.json` | `go.mod` | `pom.xml` / `build.gradle.kts` |
| Kilit dosyası | `uv.lock` / `poetry.lock` | `package-lock.json` | `go.sum` | (Gradle: `gradle.lockfile`, isteğe bağlı) |
| Merkezi depo | PyPI | npm registry | proxy.golang.org | Maven Central |
| Yerel önbellek | `~/.cache/pip` | `~/.npm` | `~/go/pkg/mod` | `~/.m2`, `~/.gradle` |
| Çıktı | wheel | (kaynak) | binary | JAR |

## Java için çok aşamalı (multi-stage) Dockerfile
```dockerfile
# 1. aşama: JDK ile derle
FROM eclipse-temurin:21-jdk AS build
WORKDIR /app
COPY . .
RUN ./mvnw -q package -DskipTests

# 2. aşama: sadece JRE ile çalıştır (imaj ~200 MB küçülür)
FROM eclipse-temurin:21-jre
COPY --from=build /app/target/saglik-1.0.0.jar /app.jar
# Konteyner belleğinin %75'ini heap'e ver (-Xmx sabit yazmak yerine)
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75", "-jar", "/app.jar"]
```

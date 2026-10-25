# Modüller, Paketler ve venv/pip

**Tanım:**
- **Modül:** İçinde Python kodu olan tek bir `.py` dosyası. `import araclar` yazınca `araclar.py` dosyası çalıştırılır ve içindeki fonksiyon, sınıf ve değişkenler kullanılabilir hale gelir.
- **Paket:** Modüllerin bir klasörde toplanmış hali. Klasörde genelde bir `__init__.py` dosyası bulunur. Örnek: `requests`, `boto3` (AWS SDK).
- **pip:** Python'un paket yöneticisi. PyPI'dan (Python Package Index) paket indirip kurar.
- **venv (sanal ortam):** Projeye özel, ayrı bir Python kurulum klasörü. Kurduğun paketler sistemin geneline değil, sadece bu klasöre gider.

**Neden önemli:**
- **Düzen:** Bütün kodu tek dosyaya yazmak yerine işi parçalara bölersin. Her dosyanın tek bir işi olur.
- **Tekrar kullanım:** Bir kere yazdığın fonksiyonu başka dosyalardan da çağırabilirsin.
- **Sürüm çakışması:** A projesi `requests 2.28`, B projesi `requests 2.32` isteyebilir. Her projenin kendi venv'i olursa iki sürüm birbirini bozmaz.
- **Tekrarlanabilirlik:** `requirements.txt` dosyası sayesinde başka bir makinede (ya da Docker'da, CI'da) aynı ortam tek komutla kurulur. 4. ayda Dockerfile yazarken tam olarak bunu yapacağız.

## import yazımları
| Yazım | Anlamı |
|---|---|
| `import araclar` | Modülü al. Kullanırken başına adını yaz: `araclar.selamla()` |
| `from araclar import selamla` | Sadece fonksiyonu al: `selamla()` |
| `import araclar as ar` | Kısa takma ad ver: `ar.selamla()` |
| `from araclar import *` | Her şeyi al. **Kullanma**: hangi ismin nereden geldiği belirsizleşir |

## `if __name__ == "__main__":` ne işe yarar?
Bir dosya doğrudan çalıştırılınca (`python araclar.py`) Python o dosyanın `__name__` değişkenini `"__main__"` yapar. Aynı dosya başka bir dosyadan `import` edilince `__name__` değeri modülün adı olur (`"araclar"`).

Bu yüzden dosyanın sonundaki bu blok **sadece doğrudan çalıştırılınca** çalışır, import edilince çalışmaz. Deneme ve test kodu genelde buraya konur.

## venv ve pip akışı
```bash
python -m venv .venv               # 1. sanal ortamı oluştur (.venv zaten .gitignore'da)
source .venv/bin/activate          # 2. etkinleştir (Linux/macOS). Windows: .venv\Scripts\activate
pip install requests               # 3. paket kur (sadece .venv içine gider)
pip freeze > requirements.txt      # 4. kurulu paketleri ve sürümlerini dosyaya yaz
deactivate                         # 5. ortamdan çık

# Başka bir makinede ya da CI'da:
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt    # aynı sürümler kurulur
```

> `.venv/` klasörü Git'e **eklenmez**. Paylaşılan şey `requirements.txt` dosyasıdır, ortam her makinede ondan yeniden kurulur.

## Diğer dillerde
| Dil | Modül sistemi | Paket yöneticisi | Bağımlılık dosyası |
|---|---|---|---|
| Python | `import` | pip | `requirements.txt` / `pyproject.toml` |
| JS/TS | `import ... from` | npm | `package.json` (+ `node_modules/` git'e girmez) |
| Go | `import "fmt"` | `go get` | `go.mod` |
| Java | `import java.util.List;` | Maven / Gradle | `pom.xml` / `build.gradle` |
| C# | `using System;` | NuGet | `.csproj` |

```javascript
// JS: araclar.js
export function selamla(ad) { return `Merhaba ${ad}`; }
// main.js
import { selamla } from "./araclar.js";
```

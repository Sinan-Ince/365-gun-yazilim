# .gitignore

**Tanım:** Git'in takip etmemesi gereken dosya ve klasörlerin listesini tutan dosyadır. Reponun kök dizinine konur.

**Neden önemli:**
- **Güvenlik:** `.env`, şifre, API anahtarı ve AWS erişim anahtarı (access key) gibi bilgiler asla GitHub'a gitmemeli. GitHub'a sızan AWS anahtarları dakikalar içinde botlar tarafından bulunup kötüye kullanılıyor.
- **Temizlik:** `__pycache__/`, `node_modules/`, derleme çıktıları ve editör ayarları gibi otomatik üretilen dosyalar repoyu kirletir.
- **Çakışmayı önler:** Herkesin bilgisayarına özel dosyalar (ör. `.vscode/`, `.DS_Store`) ekipte gereksiz conflict çıkarır.

## Yazım kuralları
| Satır | Anlamı |
|---|---|
| `dosya.txt` | Bu isimdeki dosyayı her yerde yok say |
| `klasor/` | Bu klasörü ve içindekileri yok say |
| `*.log` | `.log` ile biten her dosya |
| `/build` | Sadece kök dizindeki `build` |
| `**/temp` | Her seviyedeki `temp` |
| `!onemli.log` | `!` istisnadır: yok sayma, bunu takip et |
| `# yorum` | Yorum satırı |

## Örnek (Python + DevOps projesi)
```gitignore
# Python
__pycache__/
*.pyc
.venv/
venv/

# Gizli bilgiler
.env
*.pem
*.key

# Terraform
.terraform/
*.tfstate
*.tfstate.backup

# Editör ve işletim sistemi
.vscode/
.idea/
.DS_Store
```

## Sık yapılan hata
`.gitignore`'a eklediğin dosya **daha önce commit'lendiyse** Git onu takip etmeye devam eder. Önce takipten çıkar:
```bash
git rm --cached .env           # dosyayı diskten silmez, sadece Git takibinden çıkarır
git commit -m "chore: .env takipten çıkarıldı"
```
> ⚠️ Gizli bir anahtar bir kez push'landıysa, sonradan silmek yetmez çünkü commit geçmişinde durur. Anahtarı **hemen iptal edip yenisini oluşturmak** gerekir.

## Faydalı komutlar
```bash
git check-ignore -v dosya.pyc   # bu dosya hangi kural yüzünden yok sayılıyor?
git status --ignored            # yok sayılan dosyaları da göster
```
Hazır şablonlar: https://github.com/github/gitignore

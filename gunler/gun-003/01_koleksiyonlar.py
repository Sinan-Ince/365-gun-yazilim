# Gün 003: Koleksiyonlar
# Çalıştırmak için: python 01_koleksiyonlar.py

# --- list: sıralı, değiştirilebilir ---
sunucular = ["web1", "web2", "db1"]
sunucular.append("cache1")         # sona ekle
sunucular.remove("web2")           # değere göre sil
print(sunucular, len(sunucular))
print(sunucular[0], sunucular[-1]) # ilk ve son eleman
print(sunucular[1:3])              # dilimleme (slice): 1 ve 2. indeks

# --- tuple: değiştirilemez ---
adres = ("localhost", 8080)
host, port = adres                 # açma (unpacking)
print(host, port)
# adres[1] = 9090  # TypeError: tuple değiştirilemez

# --- set: tekrar yok, sıra yok ---
ziyaretci_ipleri = ["10.0.0.1", "10.0.0.2", "10.0.0.1", "10.0.0.3"]
benzersiz = set(ziyaretci_ipleri)
print(benzersiz, len(benzersiz))   # 3 farklı IP

a = {"python", "bash", "go"}
b = {"go", "java", "python"}
print(a & b)   # kesişim: ikisinde de olan
print(a | b)   # birleşim
print(a - b)   # fark: a'da olup b'de olmayan

# --- dict: anahtar -> değer ---
kullanici = {"ad": "Sinan", "rol": "devops", "yas": 22}
kullanici["sehir"] = "İstanbul"           # ekle
print(kullanici["ad"])
print(kullanici.get("telefon", "yok"))    # anahtar yoksa hata vermez

for anahtar, deger in kullanici.items():
    print(f"{anahtar}: {deger}")

# --- İç içe yapı: JSON/YAML gibi ---
servis = {
    "isim": "api",
    "portlar": [80, 443],
    "ortam": {"DEBUG": False, "BOLGE": "eu-central-1"},
}
print(servis["ortam"]["BOLGE"])

# --- Comprehension: kısa yoldan koleksiyon üretmek ---
kareler = [x * x for x in range(1, 6)]
ciftler = [x for x in range(10) if x % 2 == 0]
uzunluklar = {s: len(s) for s in sunucular}
print(kareler, ciftler, uzunluklar)

# Alıştırma: bir metindeki kelimeleri say
metin = "git add git commit git push docker build docker run"
sayac = {}
for kelime in metin.split():
    sayac[kelime] = sayac.get(kelime, 0) + 1
print(sayac)   # {'git': 3, 'add': 1, ...}

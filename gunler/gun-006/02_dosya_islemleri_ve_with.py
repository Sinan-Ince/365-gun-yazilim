# Gün 006: Dosya işlemleri, with ve JSON
# Çalıştırmak için: python 02_dosya_islemleri_ve_with.py
# Oluşan dosyalar geçici bir klasöre yazılır ve sonda silinir.
import json
import tempfile
from pathlib import Path

klasor = Path(tempfile.mkdtemp(prefix="gun006_"))
print("Çalışma klasörü:", klasor)

# --- 1) Yazma ("w") ve ekleme ("a") ---
log = klasor / "uygulama.log"
with open(log, "w", encoding="utf-8") as f:
    f.write("INFO sunucu başladı\n")
    f.write("WARN disk %85 dolu\n")

with open(log, "a", encoding="utf-8") as f:       # sona ekle, silmeden
    f.write("ERROR veritabanına bağlanılamadı\n")
    f.write("INFO yeniden deneniyor\n")

print("with bitti, dosya kapalı mı?", f.closed)  # True

# --- 2) Satır satır okuma: büyük log dosyaları için doğru yöntem ---
sayac = {}
with open(log, encoding="utf-8") as f:
    for satir in f:
        seviye = satir.split()[0]
        sayac[seviye] = sayac.get(seviye, 0) + 1
        if seviye == "ERROR":
            print("Hata bulundu:", satir.strip())
print("Seviye sayıları:", sayac)                 # {'INFO': 2, 'WARN': 1, 'ERROR': 1}

# --- 3) JSON config yazma ve okuma ---
ayar = {
    "uygulama": "365-gun",
    "sunucular": [{"ad": "web1", "port": 80}, {"ad": "db1", "port": 5432}],
    "debug": False,
}
ayar_yolu = klasor / "ayar.json"
with open(ayar_yolu, "w", encoding="utf-8") as f:
    json.dump(ayar, f, indent=2, ensure_ascii=False)   # ensure_ascii=False: Türkçe karakter korunur

with open(ayar_yolu, encoding="utf-8") as f:
    okunan = json.load(f)
print("JSON'dan okunan portlar:", [s["port"] for s in okunan["sunucular"]])
print("Yazılan ile okunan aynı mı?", ayar == okunan)  # True

# --- 4) Olmayan dosya: hata yönetimi (Gün 003) ile birlikte ---
try:
    with open(klasor / "yok.txt", encoding="utf-8") as f:
        f.read()
except FileNotFoundError as e:
    print("Beklenen hata:", type(e).__name__)

# --- 5) pathlib kısayolları ---
not_dosyasi = klasor / "not.txt"
not_dosyasi.write_text("pathlib ile tek satırda yazıldı", encoding="utf-8")
print(not_dosyasi.read_text(encoding="utf-8"))
print("Klasördeki dosyalar:", sorted(p.name for p in klasor.iterdir()))

# --- 6) Kendi context manager'ımız: with bloğuna girişte ve çıkışta kod çalıştırmak ---
from contextlib import contextmanager
import time

@contextmanager
def sure_olc(isim):
    baslangic = time.perf_counter()
    try:
        yield                                     # with bloğunun içi burada çalışır
    finally:                                      # hata olsa bile çalışır
        print(f"{isim}: {time.perf_counter() - baslangic:.4f} sn")

with sure_olc("1 milyon toplama"):
    sum(range(1_000_000))

# --- Temizlik ---
for p in klasor.iterdir():
    p.unlink()
klasor.rmdir()
print("Geçici klasör silindi:", not klasor.exists())

# Gün 006: Modüller, paketler ve __name__
# Çalıştırmak için (bu klasörün içinden): python 01_moduller_ve_paketler.py
# Karşılaştır:                            python araclar.py

# --- 1) Kendi modülümüzü import etmek ---
import araclar                          # araclar.py burada bir kere çalışır
from araclar import selamla             # sadece bir fonksiyonu al
import araclar as ar                    # takma ad; modül tekrar YÜKLENMEZ, önbellekten gelir

print(araclar.adres("web1"))            # web1:80
print(selamla("Sinan"))                 # Merhaba Sinan
print(ar.adres("db1", 5432))            # db1:5432
print("ar ile araclar aynı nesne mi?", ar is araclar)   # True

# --- 2) Standart kütüphane: kurulum gerekmez ---
import os
import sys
import json
from pathlib import Path

print("Python sürümü:", sys.version.split()[0])
print("Bu dosyanın klasörü:", Path(__file__).parent.name)
print("HOME değişkeni:", os.environ.get("HOME"))
print("json ile:", json.dumps({"sunucu": "web1", "port": 80}))

# --- 3) Python modülleri nerede arar? ---
# Sırayla: çalışan dosyanın klasörü, PYTHONPATH, kurulu paketler (site-packages)
print("Arama yollarının ilki:", sys.path[0])

# --- 4) Dış paket: kurulu değilse hatayı yakala ---
try:
    import requests
    print("requests kurulu, sürüm:", requests.__version__)
except ModuleNotFoundError:
    print("requests kurulu değil. Kurmak için: python -m venv .venv && "
          "source .venv/bin/activate && pip install requests")

if __name__ == "__main__":
    print("Bu dosyanın __name__ değeri:", __name__)    # '__main__'

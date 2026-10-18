# Gün 003: Hata Yönetimi
# Çalıştırmak için: python 02_hata_yonetimi.py

# --- Temel try/except ---
def sayiya_cevir(metin):
    try:
        return int(metin)
    except ValueError:
        print(f"'{metin}' bir sayı değil")
        return None

print(sayiya_cevir("42"))
print(sayiya_cevir("kırk iki"))

# --- Birden fazla hata tipi, else ve finally ---
def bol(a, b):
    try:
        sonuc = a / b
    except ZeroDivisionError:
        print("Sıfıra bölünemez")
    except TypeError as e:
        print("Tip hatası:", e)
    else:
        print("Sonuç:", sonuc)    # sadece hata yoksa çalışır
    finally:
        print("bol() bitti")      # her durumda çalışır

bol(10, 2)
bol(10, 0)
bol(10, "x")

# --- Dosya okuma: en yaygın kullanım ---
try:
    with open("olmayan_ayar.conf") as f:   # with: dosyayı otomatik kapatır
        print(f.read())
except FileNotFoundError:
    print("Ayar dosyası yok, varsayılanlar kullanılıyor")

# --- raise: kendi hatanı fırlatmak ---
def port_kontrol(port):
    if not 1 <= port <= 65535:
        raise ValueError(f"Geçersiz port: {port}")
    return port

for p in (80, 70000):
    try:
        print("Port uygun:", port_kontrol(p))
    except ValueError as e:
        print("Hata:", e)

# --- Kendi hata sınıfın ---
class ServisHatasi(Exception):
    pass

# Alıştırma: yeniden deneme (retry). DevOps'ta çok yaygın bir kalıp
import random

def baglan():
    if random.random() < 0.7:          # %70 ihtimalle bağlantı başarısız
        raise ServisHatasi("bağlantı reddedildi")
    return "bağlandı"

for deneme in range(1, 6):
    try:
        print(f"{deneme}. deneme:", baglan())
        break
    except ServisHatasi as e:
        print(f"{deneme}. deneme başarısız: {e}")
else:
    print("5 denemede de bağlanılamadı")   # for-else: break olmazsa çalışır

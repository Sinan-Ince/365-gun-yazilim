# Gün 004: Sınıf ve Nesne
# Çalıştırmak için: python 01_sinif_ve_nesne.py

class Sunucu:
    adet = 0                                   # sınıf değişkeni: bütün nesneler için ortak

    def __init__(self, ad, ip, port=80):       # kurucu
        self.ad = ad                           # nesne değişkenleri
        self.ip = ip
        self.port = port
        self._calisiyor = False                # _ : iç kullanım
        Sunucu.adet += 1

    def baslat(self):                          # nesne metodu
        self._calisiyor = True
        print(f"{self.ad} başlatıldı")

    def durum(self):
        return "çalışıyor" if self._calisiyor else "durdu"

    def __str__(self):                         # print() çağrıldığında ne yazacağı
        return f"Sunucu({self.ad}, {self.ip}:{self.port})"

    @staticmethod
    def ip_gecerli_mi(ip):                     # nesneye ihtiyaç yok
        parcalar = ip.split(".")
        return len(parcalar) == 4 and all(p.isdigit() and 0 <= int(p) <= 255 for p in parcalar)

    @classmethod
    def metinden(cls, metin):                  # alternatif kurucu: "web1,10.0.0.5,443"
        ad, ip, port = metin.split(",")
        return cls(ad, ip, int(port))


web1 = Sunucu("web1", "10.0.0.5")
db1 = Sunucu.metinden("db1,10.0.0.9,5432")

print(web1)
print(db1)
web1.baslat()
print(web1.ad, web1.durum(), "|", db1.ad, db1.durum())

# static metot: nesne oluşturmadan çağrılır
print(Sunucu.ip_gecerli_mi("192.168.1.1"))
print(Sunucu.ip_gecerli_mi("300.1.1.1"))

# sınıf değişkeni ortak
print("Toplam sunucu:", Sunucu.adet)

# Her nesnenin kendi verisi vardır
print(web1.port, db1.port)

# Alıştırma: banka hesabı ve kapsülleme
class Hesap:
    def __init__(self, sahip):
        self.sahip = sahip
        self._bakiye = 0

    def yatir(self, miktar):
        if miktar <= 0:
            raise ValueError("Miktar pozitif olmalı")
        self._bakiye += miktar

    def cek(self, miktar):
        if miktar > self._bakiye:
            raise ValueError("Yetersiz bakiye")
        self._bakiye -= miktar

    @property                       # metodu değişken gibi okumayı sağlar: h.bakiye
    def bakiye(self):
        return self._bakiye

h = Hesap("Sinan")
h.yatir(500)
h.cek(120)
print(h.sahip, h.bakiye)
try:
    h.cek(1000)
except ValueError as e:
    print("Hata:", e)

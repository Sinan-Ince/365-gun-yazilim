# Gün 004: Kalıtım, Polimorfizm ve Interface
# Çalıştırmak için: python 02_kalitim_ve_interface.py
from abc import ABC, abstractmethod

# --- Kalıtım ve override ---
class Hayvan:
    def __init__(self, ad):
        self.ad = ad

    def ses_cikar(self):
        return "..."

    def tanit(self):
        return f"Ben {self.ad}, sesim: {self.ses_cikar()}"

class Kedi(Hayvan):
    def ses_cikar(self):            # override
        return "Miyav"

class Kopek(Hayvan):
    def __init__(self, ad, cins):
        super().__init__(ad)        # üst sınıfın kurucusunu çağır
        self.cins = cins

    def ses_cikar(self):
        return "Hav"

# Polimorfizm: hepsine aynı şekilde davranıyoruz
for h in [Kedi("Tekir"), Kopek("Karabaş", "kangal"), Hayvan("Bilinmeyen")]:
    print(h.tanit())

print(isinstance(Kedi("x"), Hayvan))   # True: Kedi bir Hayvan'dır

# --- Interface (abstract class) ---
class Depolama(ABC):
    @abstractmethod
    def kaydet(self, anahtar, veri): ...

    @abstractmethod
    def oku(self, anahtar): ...

class BellekDepolama(Depolama):
    def __init__(self):
        self._veri = {}

    def kaydet(self, anahtar, veri):
        self._veri[anahtar] = veri

    def oku(self, anahtar):
        return self._veri.get(anahtar)

class SahteS3Depolama(Depolama):
    """Gerçekte boto3 ile S3'e yükler. Burada sadece taklit ediyoruz."""
    def __init__(self, bucket):
        self.bucket = bucket
        self._nesneler = {}

    def kaydet(self, anahtar, veri):
        self._nesneler[anahtar] = veri
        print(f"s3://{self.bucket}/{anahtar} yüklendi")

    def oku(self, anahtar):
        return self._nesneler.get(anahtar)

# Bu fonksiyon hangi depolama olduğunu bilmiyor, sadece sözleşmeye güveniyor
def yedek_al(depo: Depolama):
    depo.kaydet("ayar.json", '{"debug": false}')
    print("Okunan:", depo.oku("ayar.json"))

yedek_al(BellekDepolama())
yedek_al(SahteS3Depolama("benim-bucket"))

# Soyut sınıftan doğrudan nesne üretilemez
try:
    Depolama()
except TypeError as e:
    print("Hata:", e)

# --- Composition: "sahip olma" ilişkisi ---
class Motor:
    def calistir(self):
        return "motor çalıştı"

class Araba:
    def __init__(self):
        self.motor = Motor()        # Araba bir Motor değildir, bir Motoru vardır

    def yola_cik(self):
        return f"{self.motor.calistir()}, yola çıkıldı"

print(Araba().yola_cik())

// Gün 018: Java'da sınıf, interface, record, enum, exception, generics, stream.
// Çalıştır: java 02_sinif_interface_exception.java
//
// Tek dosyalık çalıştırmada (java Dosya.java) dosyadaki İLK sınıf main olarak
// çalışır. Bu yüzden main'i içeren SinifOrnek en üstte.

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

class SinifOrnek {

    static void baslik(String metin) {
        System.out.printf("%n=== %s ===%n", metin);
    }

    // Checked exception fırlatabilen metot: imzada "throws" zorunlu
    static void kontrolEt(Sunucu s) throws SaglikHatasi {
        if (s.getDurum() != Durum.CALISIYOR) {
            throw new SaglikHatasi(s.getAd() + " yanıt vermiyor");
        }
        System.out.println(s.getAd() + " sağlıklı");
    }

    // Generic metot: her tip listeyle çalışır
    static <T> T ilkVeyaVarsayilan(List<T> liste, T varsayilan) {
        return liste.isEmpty() ? varsayilan : liste.get(0);
    }

    public static void main(String[] args) {
        // -----------------------------------------------------------
        baslik("1) Sınıf, kurucu, kapsülleme");
        Sunucu web = new Sunucu("web-1", 45);
        System.out.println(web);              // toString() çağrılır
        web.setCpu(88);
        System.out.println("yeni cpu: " + web.getCpu());
        try {
            web.setCpu(150);                  // geçersiz değer
        } catch (IllegalArgumentException e) { // unchecked exception
            System.out.println("reddedildi: " + e.getMessage());
        }
        // web.cpu = 150;  → derleme hatası: cpu private

        // -----------------------------------------------------------
        baslik("2) Kalıtım ve @Override");
        Sunucu ec2 = new Ec2Sunucu("api-1", 30, "t3.micro");
        System.out.println(ec2);              // Ec2Sunucu'nun toString'i çalışır
        System.out.println("aylık maliyet: $" + ec2.aylikMaliyet());

        // -----------------------------------------------------------
        baslik("3) Interface ve polimorfizm (polymorphism)");
        // Farklı sınıflar aynı interface tipiyle aynı listede durabilir
        List<SaglikKontrolu> kontroller = List.of(
                new HttpKontrol("https://ornek.com"),
                new DiskKontrol(91),
                web                            // Sunucu da SaglikKontrolu uyguluyor
        );
        for (SaglikKontrolu k : kontroller) {
            System.out.println(k.ozet());      // default metot, her biri kendi kontrolEt()'ini kullanır
        }

        // -----------------------------------------------------------
        baslik("4) Record ve enum");
        Olay o1 = new Olay("web-1", Seviye.UYARI, "cpu yüksek");
        Olay o2 = new Olay("web-1", Seviye.UYARI, "cpu yüksek");
        System.out.println(o1);                         // otomatik toString
        System.out.println("o1.equals(o2): " + o1.equals(o2)); // içerik karşılaştırması otomatik
        System.out.println("kaynak: " + o1.kaynak());   // getter: kaynak() (getKaynak değil)
        System.out.println("UYARI emoji: " + Seviye.UYARI.emoji);
        for (Seviye s : Seviye.values()) {
            System.out.print(s + "(" + s.ordinal() + ") ");
        }
        System.out.println();

        // -----------------------------------------------------------
        baslik("5) Checked exception ve özel exception");
        Sunucu db = new Sunucu("db-1", 10);
        db.setDurum(Durum.DURDU);
        for (Sunucu s : List.of(web, db)) {
            try {
                kontrolEt(s);
            } catch (SaglikHatasi e) {
                System.out.println("HATA: " + e.getMessage());
            } finally {
                // finally her durumda çalışır (hata olsa da olmasa da)
                System.out.println("  (kontrol bitti: " + s.getAd() + ")");
            }
        }

        // -----------------------------------------------------------
        baslik("6) try-with-resources");
        // Blok bitince close() otomatik çağrılır, hata fırlasa bile
        try (Baglanti b = new Baglanti("db-1")) {
            b.sorgu("SELECT 1");
            throw new IllegalStateException("sorgu sırasında hata");
        } catch (IllegalStateException e) {
            System.out.println("yakalandı: " + e.getMessage() + " (bağlantı zaten kapandı)");
        }

        // -----------------------------------------------------------
        baslik("7) Generics");
        List<String> bos = new ArrayList<>();
        System.out.println(ilkVeyaVarsayilan(List.of("eu-north-1", "us-east-1"), "yok"));
        System.out.println(ilkVeyaVarsayilan(bos, "yok"));
        System.out.println(ilkVeyaVarsayilan(List.of(80, 443), 0));

        // -----------------------------------------------------------
        baslik("8) Lambda ve Stream API");
        List<Sunucu> filo = List.of(
                new Sunucu("web-1", 88), new Sunucu("web-2", 35),
                new Sunucu("db-1", 92), new Ec2Sunucu("api-1", 60, "t3.small"));

        // 80 üstü CPU olanların adları (filter + map)
        List<String> yogunlar = filo.stream()
                .filter(s -> s.getCpu() > 80)   // lambda: s -> koşul
                .map(Sunucu::getAd)             // metot referansı = s -> s.getAd()
                .toList();
        System.out.println("yoğunlar: " + yogunlar);

        // Ortalama CPU
        double ort = filo.stream().mapToInt(Sunucu::getCpu).average().orElse(0);
        System.out.printf("ortalama cpu: %.1f%n", ort);

        // CPU'ya göre azalan sıralama
        filo.stream()
                .sorted(Comparator.comparingInt(Sunucu::getCpu).reversed())
                .forEach(s -> System.out.println("  " + s.getAd() + " " + s.getCpu()));

        // Ada göre gruplama: "web" → [...], "db" → [...]
        Map<String, List<String>> gruplar = filo.stream()
                .collect(Collectors.groupingBy(
                        s -> s.getAd().split("-")[0],
                        Collectors.mapping(Sunucu::getAd, Collectors.toList())));
        System.out.println("gruplar: " + gruplar);
    }
}

// =====================================================================
// Enum: alanı ve kurucusu olabilir
enum Seviye {
    BILGI("ℹ️"), UYARI("⚠️"), KRITIK("🔥");

    final String emoji;

    Seviye(String emoji) {
        this.emoji = emoji;
    }
}

enum Durum { CALISIYOR, DURDU }

// Record: kurucu, getter, equals, hashCode, toString otomatik
record Olay(String kaynak, Seviye seviye, String mesaj) {}

// Interface: sözleşme. default metot = gövdesi olan interface metodu (Java 8+)
interface SaglikKontrolu {
    String ad();
    boolean saglikli();

    default String ozet() {
        return (saglikli() ? "✅ " : "❌ ") + ad();
    }
}

// Sınıf: private alanlar + public metotlar (kapsülleme)
class Sunucu implements SaglikKontrolu {
    private final String ad;   // final: kurucuda bir kere atanır, sonra değişmez
    private int cpu;
    private Durum durum = Durum.CALISIYOR;

    // Kurucu (constructor): sınıfla aynı isim, dönüş tipi yok
    Sunucu(String ad, int cpu) {
        this.ad = ad;          // this.ad = alan, ad = parametre
        setCpu(cpu);
    }

    String getAd() { return ad; }
    int getCpu() { return cpu; }
    Durum getDurum() { return durum; }
    void setDurum(Durum durum) { this.durum = durum; }

    // Setter içinde doğrulama: kapsüllemenin asıl faydası
    void setCpu(int cpu) {
        if (cpu < 0 || cpu > 100) {
            throw new IllegalArgumentException("cpu 0-100 arası olmalı: " + cpu);
        }
        this.cpu = cpu;
    }

    double aylikMaliyet() { return 20.0; }

    // SaglikKontrolu interface'inin metotları
    @Override public String ad() { return ad; }
    @Override public boolean saglikli() { return durum == Durum.CALISIYOR && cpu < 90; }

    @Override
    public String toString() {
        return "Sunucu[" + ad + ", cpu=" + cpu + ", " + durum + "]";
    }
}

// Kalıtım: Ec2Sunucu, Sunucu'nun her şeyini alır, bazılarını değiştirir
class Ec2Sunucu extends Sunucu {
    private final String tip;

    Ec2Sunucu(String ad, int cpu, String tip) {
        super(ad, cpu);        // üst sınıfın kurucusu, ilk satırda
        this.tip = tip;
    }

    @Override
    double aylikMaliyet() {
        return switch (tip) {
            case "t3.micro" -> 7.5;
            case "t3.small" -> 15.0;
            default -> super.aylikMaliyet(); // üst sınıfın metodunu çağır
        };
    }

    @Override
    public String toString() {
        return "Ec2" + super.toString() + " tip=" + tip;
    }
}

class HttpKontrol implements SaglikKontrolu {
    private final String url;
    HttpKontrol(String url) { this.url = url; }
    @Override public String ad() { return "HTTP " + url; }
    @Override public boolean saglikli() { return true; } // gerçekte HTTP isteği atılırdı
}

class DiskKontrol implements SaglikKontrolu {
    private final int dolulukYuzde;
    DiskKontrol(int dolulukYuzde) { this.dolulukYuzde = dolulukYuzde; }
    @Override public String ad() { return "Disk %" + dolulukYuzde; }
    @Override public boolean saglikli() { return dolulukYuzde < 85; }
}

// Özel checked exception: Exception'dan türer (RuntimeException'dan değil)
class SaglikHatasi extends Exception {
    SaglikHatasi(String mesaj) { super(mesaj); }
}

// AutoCloseable uygulayan sınıf try-with-resources ile kullanılabilir
class Baglanti implements AutoCloseable {
    private final String hedef;

    Baglanti(String hedef) {
        this.hedef = hedef;
        System.out.println("bağlantı açıldı: " + hedef);
    }

    void sorgu(String sql) { System.out.println("sorgu: " + sql); }

    @Override
    public void close() { System.out.println("bağlantı kapandı: " + hedef); }
}

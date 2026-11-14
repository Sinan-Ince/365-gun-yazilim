// Gün 018: Java temelleri.
// Çalıştır (derle + çalıştır tek adım): java 01_java_temelleri.java
// Klasik yol: javac -d out 01_java_temelleri.java && java -cp out JavaTemelleri

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

// Java'da her kod bir sınıfın içinde olmak zorunda.
class JavaTemelleri {

    // static final = sınıfa ait sabit (Go'daki const gibi)
    static final String VARSAYILAN_BOLGE = "eu-north-1";

    static void baslik(String metin) {
        System.out.printf("%n=== %s ===%n", metin);
    }

    // Aşırı yükleme (overloading): aynı isim, farklı parametreler.
    // Go'da yok, Java derleyicisi parametre tiplerine bakıp doğru metodu seçer.
    static int topla(int a, int b) {
        return a + b;
    }

    static double topla(double a, double b) {
        return a + b;
    }

    // Değişken sayıda parametre (varargs), Go'daki ...int gibi
    static int topla(int... sayilar) {
        int toplam = 0;
        for (int s : sayilar) {
            toplam += s;
        }
        return toplam;
    }

    // Switch ifadesi (Java 14+): değer döndürür, break gerekmez
    static String durumAciklama(int kod) {
        return switch (kod) {
            case 200, 201 -> "başarılı";
            case 404 -> "bulunamadı";
            case 500, 502, 503 -> "sunucu hatası";
            default -> "bilinmiyor";
        };
    }

    public static void main(String[] args) {
        // -----------------------------------------------------------
        baslik("1) İlkel tipler ve referans tipleri");
        int port = 8080;            // ilkel: değer doğrudan tutulur
        double cpu = 72.5;
        boolean aktif = true;
        long bayt = 5_000_000_000L; // int sınırı ~2.1 milyar, büyük sayı için long
        String ad = "web-1";        // referans: nesnenin adresi tutulur
        System.out.printf("%s:%d cpu=%.1f aktif=%b bayt=%d%n", ad, port, cpu, aktif, bayt);
        // ad = 5;  → derleme hatası: String'e int atanamaz

        var bolge = VARSAYILAN_BOLGE; // var: tip çıkarımı (String), yine statik tip
        System.out.println("bölge: " + bolge);

        // Tip dönüşümü: genişletme otomatik, daraltma açıkça (cast)
        double d = port;           // int → double otomatik
        int yuzde = (int) cpu;     // double → int, ondalık kısmı atılır
        System.out.println("d=" + d + " yuzde=" + yuzde);

        // -----------------------------------------------------------
        baslik("2) String işlemleri");
        String log = "  ERROR disk dolu: /var/log  ";
        System.out.println("trim:       '" + log.trim() + "'");
        System.out.println("küçük harf: " + log.trim().toLowerCase());
        System.out.println("içeriyor:   " + log.contains("ERROR"));
        System.out.println("parçala:    " + List.of(log.trim().split(" ")));
        // Text block (Java 15+): çok satırlı metin, YAML/JSON yazarken işe yarar
        String yaml = """
                server:
                  port: %d
                  region: %s
                """.formatted(port, bolge);
        System.out.print(yaml);

        // -----------------------------------------------------------
        baslik("3) == ve equals tuzağı");
        String a = new String("web-1");
        String b = new String("web-1");
        System.out.println("a == b      : " + (a == b));      // false: farklı nesneler
        System.out.println("a.equals(b) : " + a.equals(b));   // true: içerik aynı
        Integer x = 1000, y = 1000;                           // kutulanmış Integer
        System.out.println("Integer 1000 == 1000 : " + (x == y));     // false!
        System.out.println("x.equals(y)          : " + x.equals(y));  // true

        // -----------------------------------------------------------
        baslik("4) Dizi (array): sabit boyutlu");
        int[] cpular = {45, 91, 30, 78};
        int enYuksek = cpular[0];
        for (int c : cpular) {         // gelişmiş for (enhanced for), Python'daki for x in liste
            if (c > enYuksek) enYuksek = c;
        }
        System.out.println("uzunluk=" + cpular.length + " en yüksek=" + enYuksek);

        // -----------------------------------------------------------
        baslik("5) ArrayList: büyüyebilen liste (Go'daki slice)");
        List<String> sunucular = new ArrayList<>(); // <> içi tip çıkarımı (diamond)
        sunucular.add("web-1");
        sunucular.add("web-2");
        sunucular.add("db-1");
        sunucular.remove("web-2");
        System.out.println(sunucular + " boyut=" + sunucular.size());
        // List<int> yazılamaz: koleksiyonlar nesne tutar, Integer kullanılır
        List<Integer> portlar = new ArrayList<>(List.of(80, 443));
        portlar.add(8080); // int otomatik Integer'a kutulanır (autoboxing)
        System.out.println("portlar: " + portlar);

        // Klasik for döngüsü (indeksli)
        for (int i = 0; i < sunucular.size(); i++) {
            System.out.println(i + ": " + sunucular.get(i));
        }

        // -----------------------------------------------------------
        baslik("6) HashMap: sözlük (Go'daki map)");
        Map<String, Integer> cpuMap = new HashMap<>();
        cpuMap.put("web-1", 45);
        cpuMap.put("web-2", 91);
        cpuMap.put("db-1", 78);
        System.out.println("web-2: " + cpuMap.get("web-2"));
        System.out.println("yok-1: " + cpuMap.get("yok-1"));                // null döner
        System.out.println("varsayılan: " + cpuMap.getOrDefault("yok-1", 0));
        System.out.println("var mı: " + cpuMap.containsKey("db-1"));
        for (Map.Entry<String, Integer> e : cpuMap.entrySet()) {   // sıra garanti değil
            String uyari = e.getValue() > 80 ? " ⚠️" : "";           // üçlü operatör
            System.out.println(e.getKey() + " -> " + e.getValue() + uyari);
        }

        // -----------------------------------------------------------
        baslik("7) Metotlar: aşırı yükleme ve varargs");
        System.out.println("topla(2, 3)       = " + topla(2, 3));
        System.out.println("topla(2.5, 3.5)   = " + topla(2.5, 3.5));
        System.out.println("topla(1, 2, 3, 4) = " + topla(1, 2, 3, 4));

        // -----------------------------------------------------------
        baslik("8) Switch ifadesi ve while");
        for (int kod : new int[]{200, 404, 503, 418}) {
            System.out.println(kod + " -> " + durumAciklama(kod));
        }
        int deneme = 0;
        while (deneme < 3) {
            deneme++;
            System.out.println("bağlantı denemesi " + deneme);
        }

        // -----------------------------------------------------------
        baslik("9) Komut satırı argümanları");
        // java 01_java_temelleri.java a b c  → args = [a, b, c]
        System.out.println("argüman sayısı: " + args.length + " " + List.of(args));
    }
}

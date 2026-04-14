# E-ticaret Fiyat Hesaplayici — Blueprint

## Amac
E-ticaret saticilarinin urun fiyatlandirmasini optimize etmesini saglayan hesaplayici. Maliyet, kargo, komisyon ve hedef kar marjindan satis fiyati hesaplar. "Rakip Fiyat Ara" butonu Apify uzerinden Google Shopping'den gercek rakip fiyatlarini ceker ve karsilastirma tablosu gosterir.

## Teknik Gereksinimler
- Tek dosya: `index.html` (inline CSS + JS)
- Tema: Koyu (#0a0a0a arka plan), aksent renk #10b981 (yesil)
- Font: DM Sans (Google Fonts)
- Dil: Turkce
- Framework yok, sadece vanilla HTML/CSS/JS
- localStorage ile hesaplama gecmisi

## API Anahtari Kurulumu

```js
// index.html icerisinde <script> blogunun en basinda:
// =============================================
// AYAR: Asagidaki degeri kendi Apify anahtarinla degistir
// Anahtar almak icin: https://console.apify.com/account#/integrations
// =============================================
const APIFY_TOKEN = 'YOUR_APIFY_TOKEN_HERE';
```

### .env.example
```
APIFY_TOKEN=apify_api_xxxxxxxxxxxxxxxxxxxx
```

## Apify Entegrasyonu

### Endpoint
```
POST https://api.apify.com/v2/acts/apify~google-shopping-scraper/run-sync-get-dataset-items?token=${APIFY_TOKEN}
```

### Headers
```js
{
  "Content-Type": "application/json"
}
```

### Request Body
```js
{
  "queries": productName,      // Kullanicinin girdigi urun adi
  "countryCode": "TR",
  "languageCode": "tr",
  "maxItems": 5
}
```

### Response Format (Apify Google Shopping Scraper)
```json
[
  {
    "title": "iPhone 15 Pro Kilif Silikon",
    "price": "₺249,90",
    "extractedPrice": 249.90,
    "currency": "TRY",
    "seller": "Trendyol",
    "link": "https://...",
    "thumbnail": "https://...",
    "rating": 4.5,
    "reviewsCount": 128
  }
]
```

### Hata Yonetimi & Fallback
- API hatasi veya token girilmemisse: mock veri goster + uyari notu
- Mock veri: kullanicinin girdigi fiyata gore +/- %10-30 araliginda 5 sahte rakip fiyati olustur
- Timeout: 30 saniye, asarsa fallback'e dusur
- Fallback verisi icin sahte magazalar: "MagazaA", "MagazaB", "OnlineShop", "TechStore", "BudgetMart"
- Mock durumunda tablo ustunde kuçuk uyari: "Gercek veriler yuklenemedi, ornek veriler gosteriliyor"

## Hesaplama Mantigi

### Girdi Alanlari
```js
{
  productName: string,        // "iPhone 15 Pro Kilif"
  productCost: number,        // Urun maliyeti (TL)
  shippingCost: number,       // Kargo maliyeti (TL)
  packagingCost: number,      // Paketleme maliyeti (TL)
  platformCommission: number, // Platform komisyonu (%)
  taxRate: number,            // KDV orani (%) - varsayilan 20
  targetMargin: number,       // Hedef kar marji (%)
  additionalCosts: number     // Diger giderler (TL) - opsiyonel
}
```

### Platform Komisyon Onayarlari
```js
const PLATFORM_PRESETS = [
  { name: "Trendyol", commission: 17.5, icon: "T" },
  { name: "Hepsiburada", commission: 15.0, icon: "H" },
  { name: "N11", commission: 14.0, icon: "N" },
  { name: "Amazon TR", commission: 15.0, icon: "A" },
  { name: "Etsy", commission: 6.5, icon: "E" },
  { name: "Ciceksepeti", commission: 20.0, icon: "C" },
  { name: "Ozel", commission: 0, icon: "?" }
];
```
Platform secildiginde komisyon otomatik dolsun. "Ozel" secildiginde manuel giris.

### Hesaplama Formuleri
```js
totalCost = productCost + shippingCost + packagingCost + additionalCosts;
commissionAmount = sellingPrice * (platformCommission / 100);
taxAmount = sellingPrice * (taxRate / 100 / (1 + taxRate / 100)); // KDV dahil fiyattan
netRevenue = sellingPrice - commissionAmount - taxAmount;
profit = netRevenue - totalCost;
actualMargin = (profit / sellingPrice) * 100;

// Hedef marjdan fiyat hesaplama (ters hesap):
suggestedPrice = totalCost / (1 - (targetMargin / 100) - (platformCommission / 100) - (taxRate / 100 / (1 + taxRate / 100)));
```

### Karlilik Analizi Ciktisi
```js
{
  suggestedPrice: number,       // Onerilen satis fiyati
  totalCost: number,            // Toplam maliyet
  commissionAmount: number,     // Komisyon tutari
  taxAmount: number,            // KDV tutari
  netRevenue: number,           // Net gelir
  profitPerUnit: number,        // Birim kar
  actualMargin: number,         // Gercek kar marji %
  breakEvenPrice: number,       // Basabas noktasi (0 kar fiyati)
  monthlyProfit10: number,      // Ayda 10 satis ile kar
  monthlyProfit50: number,      // Ayda 50 satis ile kar
  monthlyProfit100: number      // Ayda 100 satis ile kar
}
```

## UI Spesifikasyonu

### Layout
```
+--------------------------------------------------+
|  HEADER: "Fiyat Hesaplayici" + kisa aciklama      |
+--------------------------------------------------+
|                                                    |
|  SOL: Girdi Formu          |  SAG: Sonuc Paneli   |
|  - Urun Adi               |  - Onerilen Fiyat     |
|  - Platform secimi         |    (buyuk, vurgulu)   |
|  - Maliyet alanlari       |  - Kar/Maliyet dagil. |
|  - Komisyon & KDV         |  - Aylik kar tahmini  |
|  - Hedef marj slider      |  - Basabas noktasi    |
|  [Hesapla]                |                        |
|                            +------------------------+
|                            |  RAKIP FIYATLARI       |
|  [Rakip Fiyat Ara]        |  (Apify tablosu)       |
+--------------------------------------------------+
|  GECMIS HESAPLAMALAR                               |
+--------------------------------------------------+
```

### Sol Panel — Girdi Formu

**Urun Adi**
- Text input, placeholder: "ornek: iPhone 15 Pro Kilif"
- Hem hesaplama hem rakip arama icin kullanilir

**Platform Secimi**
- Yatay buton grubu (pill seklinde)
- Her buton: platform icon harfi + adi
- Secili olan: yesil arka plan
- Secim yapilinca komisyon otomatik dolsun

**Maliyet Alanlari**
- Urun Maliyeti (₺): number input, step 0.01
- Kargo Maliyeti (₺): number input, varsayilan 25
- Paketleme (₺): number input, varsayilan 5
- Diger Giderler (₺): number input, varsayilan 0
- Her inputun sol icerisinde ₺ ikonu

**Komisyon & Vergi**
- Platform Komisyonu (%): number input, platforma gore otomatik
- KDV Orani (%): number input, varsayilan 20
- Her inputun sag icerisinde % ikonu

**Hedef Kar Marji**
- Range slider + sayi gostergesi
- Min: 5%, Max: 80%, Varsayilan: 30%
- Slider rengi: yesil gradient
- Sag tarafta buyuk font ile "%30" gibi gosterge
- Slider hareket ettikce anlik hesaplama (debounced, 150ms)

**Hesapla Butonu**
- Tam genislik, yesil (#10b981), buyuk
- Butona basmaya gerek yok aslinda — tum inputlar degistikce anlik hesaplama yapilsin
- Buton daha cok gorsel vurgu icin

**Rakip Fiyat Ara Butonu**
- Outline stil, beyaz border
- Iceride arama ikonu (SVG magnifying glass)
- Tiklaninca Apify'a istek at
- Loading durumunda spinner goster
- APIFY_TOKEN girilmemisse: butonu aktifte birak ama tiklaninca mock veri goster

### Sag Panel — Sonuc

**Onerilen Fiyat (Hero)**
- Cok buyuk font (48px), yesil renk
- "₺349,90" formati
- Altinda kucuk: "Onerilen Satis Fiyati"

**Kar Dagilimi Gorsel**
- Yatay stacked bar: Maliyet | Komisyon | KDV | Kar
- Her dilim farkli renk, ustunde TL degeri
- Altinda legend

**Detay Karti**
Grid halinde (2x4):
| Toplam Maliyet | ₺115,00 |
| Komisyon Tutari | ₺61,23 |
| KDV Tutari | ₺58,32 |
| Net Gelir | ₺234,67 |
| Birim Kar | ₺119,67 |
| Gercek Marj | %34.2 |
| Basabas Fiyati | ₺195,00 |
| ROI | %104.1 |

**Aylik Kar Tahmini**
3 kart yan yana:
- "10 Satis/Ay" -> ₺1.196,70
- "50 Satis/Ay" -> ₺5.983,50
- "100 Satis/Ay" -> ₺11.967,00

### Rakip Fiyat Tablosu
- Urun adi arandiktan sonra gorunur
- Basligi: "Rakip Fiyatlari — Google Shopping"
- Tablo sutunlari: Urun | Magaza | Fiyat | Degerlendirme | Fark
- "Fark" sutunu: senin onerilen fiyatinla aradaki fark (₺ ve %)
  - Senin fiyatin dusukse: yesil, "₺23 daha uygun"
  - Senin fiyatin yuksekse: kirmizi, "₺15 daha pahali"
- Tablonun altinda ozet: "Ortalama rakip fiyati: ₺285,40 | Senin fiyatin: ₺349,90"

### Alt Kisim — Gecmis
- "Son Hesaplamalar" basligi
- Yatay scroll kartlar
- Her kart: urun adi, platform, onerilen fiyat, kar marji, tarih
- Maksimum 15 kayit

### Responsive
- 768px alti: tek kolon layout
- Aylik kar kartlari: yatay scroll
- Rakip tablosu: yatay scroll

### Animasyonlar
- Input degistikce sonuc paneli yumusak gecis (opacity + transform)
- Onerilen fiyat degistikce sayi animasyonu (eski -> yeni)
- Stacked bar animasyonlu genislesin
- Rakip tablosu satirlari staggered fade-in
- Slider hareket ettikce fiyat anlik degissin (smooth)

### Renk Paleti
```css
--bg-primary: #0a0a0a;
--bg-secondary: #111111;
--bg-card: #1a1a1a;
--border: #2a2a2a;
--text-primary: #f5f5f5;
--text-secondary: #a0a0a0;
--accent: #10b981;
--accent-hover: #059669;
--accent-light: #d1fae5;
--cost-color: #ef4444;
--commission-color: #f59e0b;
--tax-color: #8b5cf6;
--profit-color: #22c55e;
```

## localStorage Yapisi

```js
// Key: 'fiyat-hesaplayici-gecmis'
// Value: JSON array
[
  {
    id: "fh_1695000000000",
    productName: string,
    platform: string,
    input: { productCost, shippingCost, packagingCost, platformCommission, taxRate, targetMargin, additionalCosts },
    output: { suggestedPrice, totalCost, profitPerUnit, actualMargin },
    competitors: [...] | null,
    createdAt: timestamp
  }
]
```

## Onemli Notlar
- Tum hesaplamalar anlik (real-time), butona basmayi beklemesin
- Fiyat formatlama: Turkce locale, ₺ simgesi, 2 ondalik basamak
- Negatif kar durumunda: fiyat kirmizi goster, uyari ikonu ekle
- Basabas noktasinin altinda fiyat girilirse: uyari mesaji
- Apify API cagrisinin gercek bir API oldugunu kullanici bilmek zorunda degil — dogal bir ozellik gibi hissettir
- Slider debounce: 150ms, gereksiz yeniden hesaplama onle
- Rakip fiyat arandi mi bilgisini de gecmise kaydet

# CrossRoads — Kurulum Rehberi

## Gereksinimler (Bir kez yap)

### 1. Flutter Kur (Mac'e)
```bash
# Homebrew yoksa önce bunu çalıştır:
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Flutter'ı kur:
brew install --cask flutter

# Kurulumu doğrula:
flutter doctor
```

### 2. Git Kur (Windows için)
```
https://git-scm.com/download/win adresinden indir ve kur
```

---

## ADIM 1 — Supabase Kurulumu (5 dakika)

1. **supabase.com** adresine git → "Start your project" → GitHub ile giriş
2. "New Project" → İsim: `crossroads` → Şifre seç (kaydet!) → Bölge: `eu-central-1 (Frankfurt)`
3. Proje oluşturulurken bekle (~2 dk)
4. Sol menü → **SQL Editor** → "New query" → 
   `d:\Masaüstü\.yen\crossroads\supabase\schema.sql` dosyasının içeriğini yapıştır → **Run**
5. Sol menü → **Authentication** → **Providers**:
   - Google: Aç → Client ID ve Secret gir (console.cloud.google.com'dan)
   - Apple: Aç → Apple Developer hesabın yoksa şimdilik kapat
6. Sol menü → **Project Settings** → **API**:
   - `URL` → kopyala
   - `anon public` key → kopyala  
   - `service_role` key → kopyala
   - `JWT Secret` → kopyala

---

## ADIM 2 — Backend'i Railway'e Deploy Et (5 dakika)

1. **railway.app** adresine git → GitHub ile giriş
2. "New Project" → "Deploy from GitHub repo" 
3. GitHub'da yeni repo oluştur: `crossroads-backend`
4. `d:\Masaüstü\.yen\crossroads\backend` klasörünü bu repoya yükle
5. Railway'de Environment Variables ekle:
   ```
   SUPABASE_URL=https://xxx.supabase.co
   SUPABASE_ANON_KEY=eyJ...
   SUPABASE_SERVICE_ROLE_KEY=eyJ...
   JWT_SECRET=supabase-jwt-secret
   ```
6. Deploy sonrası Railway sana bir URL verecek: `https://crossroads-xxx.up.railway.app`
7. Bu URL'yi not al → Flutter'da kullanacağız

---

## ADIM 3 — Flutter Uygulamasını Kur (Mac'te)

```bash
# Proje klasörüne git
cd /path/to/crossroads/mobile

# Bağımlılıkları yükle
flutter pub get

# iOS klasörünü hazırla
cd ios && pod install && cd ..

# Info.plist'e konum izinlerini ekle
# ios/Runner/Info.plist dosyasını aç
# ios/Runner/Info.plist.additions.txt içindeki satırları <dict> içine ekle

# Telefonu USB ile bağla, güven onayı ver
# Sonra çalıştır:
flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co \
            --dart-define=SUPABASE_ANON_KEY=eyJ...
```

---

## ADIM 4 — Google Auth Ayarı

### Google Console:
1. console.cloud.google.com → Yeni Proje → "CrossRoads"
2. APIs & Services → OAuth 2.0 → Create Credentials
3. Application type: **iOS**
4. Bundle ID: `io.crossroads.app`
5. Client ID'yi kopyala → Supabase'deki Google provider'a yapıştır
6. Redirect URI olarak şunu ekle: `https://xxx.supabase.co/auth/v1/callback`

---

## Proje Yapısı

```
crossroads/
├── backend/              ← FastAPI Python backend
│   ├── main.py           ← Ana uygulama
│   ├── app/
│   │   ├── routes/       ← API endpoint'leri
│   │   ├── models.py     ← Pydantic modeller
│   │   ├── database.py   ← Supabase bağlantısı
│   │   └── config.py     ← Ortam değişkenleri
│   ├── requirements.txt  ← Python bağımlılıkları
│   └── railway.toml      ← Railway deploy config
│
├── mobile/               ← Flutter iOS/Android uygulaması
│   ├── lib/
│   │   ├── main.dart     ← Giriş noktası
│   │   ├── router.dart   ← Sayfa yönlendirme
│   │   ├── screens/      ← Ekranlar
│   │   ├── services/     ← API servisleri
│   │   ├── models/       ← Veri modelleri
│   │   └── theme/        ← Renk ve stil
│   └── pubspec.yaml      ← Flutter bağımlılıkları
│
└── supabase/
    └── schema.sql        ← Veritabanı şeması
```

---

## API Endpoint'leri

| Method | URL | Açıklama |
|--------|-----|----------|
| GET | /api/v1/capsules/nearby?lat=&lon= | Yakındaki kapsüller |
| POST | /api/v1/capsules | Yeni kapsül bırak |
| POST | /api/v1/capsules/unlock | Kapsül aç / cevap ver |
| GET | /api/v1/capsules/my | Kendi kapsüllerin |
| GET | /api/v1/users/me | Kendi profil |
| PUT | /api/v1/users/me | Profil güncelle |
| GET | /api/v1/matches | Eşleşmeler |
| GET | /api/v1/matches/{id}/messages | Mesajlar |
| POST | /api/v1/matches/{id}/messages | Mesaj gönder |

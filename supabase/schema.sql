-- CrossRoads - Supabase Schema
-- Supabase SQL Editor'a yapıştır ve çalıştır

-- PostGIS eklentisini aktif et
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================
-- USERS tablosu (auth.users ile senkron)
-- =============================================
CREATE TABLE public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username VARCHAR(50) UNIQUE NOT NULL,
    display_name VARCHAR(100),
    gender VARCHAR(10) CHECK (gender IN ('male', 'female', 'other')),
    bio TEXT,
    avatar_url TEXT,
    birth_year INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- CAPSULES tablosu (kapsüller)
-- =============================================
CREATE TABLE public.capsules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    location GEOMETRY(Point, 4326) NOT NULL,
    is_indoor BOOLEAN DEFAULT FALSE,
    content_text TEXT NOT NULL CHECK (char_length(content_text) <= 300),
    song_name VARCHAR(100),
    artist_name VARCHAR(100),
    mood VARCHAR(30) CHECK (mood IN ('happy','sad','excited','calm','nostalgic','romantic','curious')),
    unlock_count INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '7 days'),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Konum araması için spatial index (hız kritik)
CREATE INDEX capsules_location_idx ON public.capsules USING GIST (location);
CREATE INDEX capsules_user_id_idx ON public.capsules (user_id);
CREATE INDEX capsules_expires_at_idx ON public.capsules (expires_at);

-- =============================================
-- CAPSULE_UNLOCKS tablosu (kim hangi kapsülü açtı)
-- =============================================
CREATE TABLE public.capsule_unlocks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    capsule_id UUID NOT NULL REFERENCES public.capsules(id) ON DELETE CASCADE,
    opener_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    reply_text TEXT CHECK (char_length(reply_text) <= 300),
    unlocked_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(capsule_id, opener_id)
);

-- =============================================
-- MATCHES tablosu (eşleşmeler)
-- =============================================
CREATE TABLE public.matches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user1_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    user2_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    capsule_id UUID REFERENCES public.capsules(id) ON DELETE SET NULL,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active','blocked','ended')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user1_id, user2_id)
);

-- =============================================
-- MESSAGES tablosu (chat mesajları)
-- =============================================
CREATE TABLE public.messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    match_id UUID NOT NULL REFERENCES public.matches(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL CHECK (char_length(content) <= 1000),
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX messages_match_id_idx ON public.messages (match_id, created_at DESC);

-- =============================================
-- FONKSIYONLAR
-- =============================================

-- Yakındaki kapsülleri getir (soft radius algoritması)
CREATE OR REPLACE FUNCTION get_nearby_capsules(
    user_lat DOUBLE PRECISION,
    user_lon DOUBLE PRECISION,
    limit_count INTEGER DEFAULT 50
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    content_text TEXT,
    song_name VARCHAR,
    artist_name VARCHAR,
    mood VARCHAR,
    is_indoor BOOLEAN,
    unlock_count INTEGER,
    distance_meters DOUBLE PRECISION,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id,
        c.user_id,
        c.content_text,
        c.song_name,
        c.artist_name,
        c.mood,
        c.is_indoor,
        c.unlock_count,
        ST_Distance(
            c.location::geography,
            ST_SetSRID(ST_MakePoint(user_lon, user_lat), 4326)::geography
        ) AS distance_meters,
        c.created_at
    FROM public.capsules c
    WHERE
        c.is_active = TRUE
        AND c.expires_at > NOW()
        AND ST_DWithin(
            c.location::geography,
            ST_SetSRID(ST_MakePoint(user_lon, user_lat), 4326)::geography,
            CASE WHEN c.is_indoor = TRUE THEN 30 ELSE 5 END
        )
    ORDER BY distance_meters ASC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- Kapsül açıldığında unlock_count güncelle
CREATE OR REPLACE FUNCTION increment_unlock_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.capsules
    SET unlock_count = unlock_count + 1
    WHERE id = NEW.capsule_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_capsule_unlock
    AFTER INSERT ON public.capsule_unlocks
    FOR EACH ROW EXECUTE FUNCTION increment_unlock_count();

-- Karşılıklı cevap verilince eşleştir
CREATE OR REPLACE FUNCTION check_and_create_match()
RETURNS TRIGGER AS $$
DECLARE
    capsule_owner UUID;
    already_replied BOOLEAN;
BEGIN
    -- Kapsül sahibini bul
    SELECT user_id INTO capsule_owner FROM public.capsules WHERE id = NEW.capsule_id;

    -- Kapsül sahibi cevap verdiyse eşleştir
    SELECT EXISTS(
        SELECT 1 FROM public.capsule_unlocks
        WHERE capsule_id = NEW.capsule_id
        AND opener_id = capsule_owner
        AND reply_text IS NOT NULL
    ) INTO already_replied;

    IF already_replied AND NEW.reply_text IS NOT NULL THEN
        INSERT INTO public.matches (user1_id, user2_id, capsule_id)
        VALUES (
            LEAST(capsule_owner, NEW.opener_id),
            GREATEST(capsule_owner, NEW.opener_id),
            NEW.capsule_id
        )
        ON CONFLICT (user1_id, user2_id) DO NOTHING;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_capsule_reply
    AFTER INSERT OR UPDATE ON public.capsule_unlocks
    FOR EACH ROW EXECUTE FUNCTION check_and_create_match();

-- =============================================
-- ROW LEVEL SECURITY (RLS)
-- =============================================
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.capsules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.capsule_unlocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Users: herkes okuyabilir, sadece kendisi yazabilir
CREATE POLICY "Users are viewable by everyone" ON public.users FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON public.users FOR INSERT WITH CHECK (auth.uid() = id);

-- Capsules: herkes okuyabilir, sadece sahibi yazabilir
CREATE POLICY "Capsules are viewable by everyone" ON public.capsules FOR SELECT USING (is_active = true);
CREATE POLICY "Users can insert own capsules" ON public.capsules FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own capsules" ON public.capsules FOR UPDATE USING (auth.uid() = user_id);

-- Unlocks: kendi açtıklarını görebilir
CREATE POLICY "Users can view own unlocks" ON public.capsule_unlocks FOR SELECT USING (auth.uid() = opener_id);
CREATE POLICY "Users can create unlocks" ON public.capsule_unlocks FOR INSERT WITH CHECK (auth.uid() = opener_id);

-- Matches: kendi eşleşmelerini görebilir
CREATE POLICY "Users can view own matches" ON public.matches FOR SELECT USING (auth.uid() = user1_id OR auth.uid() = user2_id);

-- Messages: eşleşmesindeki mesajları görebilir
CREATE POLICY "Users can view match messages" ON public.messages FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.matches
        WHERE id = match_id AND (user1_id = auth.uid() OR user2_id = auth.uid())
    )
);
CREATE POLICY "Users can send messages" ON public.messages FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- =============================================
-- YENİ KULLANICI OTOMATİK PROFIL OLUŞTUR
-- =============================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, username, display_name, avatar_url)
    VALUES (
        NEW.id,
        LOWER(REPLACE(COALESCE(NEW.raw_user_meta_data->>'full_name', SPLIT_PART(NEW.email, '@', 1)), ' ', '_')) || '_' || FLOOR(RANDOM() * 9999)::TEXT,
        COALESCE(NEW.raw_user_meta_data->>'full_name', SPLIT_PART(NEW.email, '@', 1)),
        NEW.raw_user_meta_data->>'avatar_url'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

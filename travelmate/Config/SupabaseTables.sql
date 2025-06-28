-- Configuration des tables Supabase pour TravelMate

-- Table des favoris
CREATE TABLE IF NOT EXISTS favorites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    destination_id UUID NOT NULL REFERENCES destinations(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, destination_id)
);

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_favorites_user_id ON favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_favorites_destination_id ON favorites(destination_id);

-- Table des réservations
CREATE TABLE IF NOT EXISTS reservations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    destination_id UUID NOT NULL REFERENCES destinations(id) ON DELETE CASCADE,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    number_of_people INTEGER NOT NULL CHECK (number_of_people > 0),
    total_price DECIMAL(10,2) NOT NULL CHECK (total_price > 0),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'cancelled', 'completed')),
    stripe_payment_intent_id VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_reservations_user_id ON reservations(user_id);
CREATE INDEX IF NOT EXISTS idx_reservations_destination_id ON reservations(destination_id);
CREATE INDEX IF NOT EXISTS idx_reservations_status ON reservations(status);
CREATE INDEX IF NOT EXISTS idx_reservations_dates ON reservations(start_date, end_date);

-- Trigger pour mettre à jour updated_at automatiquement
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_reservations_updated_at 
    BEFORE UPDATE ON reservations 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Politiques de sécurité RLS (Row Level Security)

-- Activer RLS sur les tables
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE reservations ENABLE ROW LEVEL SECURITY;

-- Politiques pour les favoris
CREATE POLICY "Users can view their own favorites" ON favorites
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own favorites" ON favorites
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own favorites" ON favorites
    FOR DELETE USING (auth.uid() = user_id);

-- Politiques pour les réservations
CREATE POLICY "Users can view their own reservations" ON reservations
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own reservations" ON reservations
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own reservations" ON reservations
    FOR UPDATE USING (auth.uid() = user_id);

-- Fonction pour obtenir les réservations avec les détails des destinations
CREATE OR REPLACE FUNCTION get_user_reservations_with_details(user_uuid UUID)
RETURNS TABLE (
    reservation_id UUID,
    destination_id UUID,
    destination_title TEXT,
    destination_image_url TEXT,
    start_date TIMESTAMP WITH TIME ZONE,
    end_date TIMESTAMP WITH TIME ZONE,
    number_of_people INTEGER,
    total_price DECIMAL(10,2),
    status VARCHAR(20),
    stripe_payment_intent_id VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.id,
        r.destination_id,
        d.title,
        d.image_url,
        r.start_date,
        r.end_date,
        r.number_of_people,
        r.total_price,
        r.status,
        r.stripe_payment_intent_id,
        r.created_at
    FROM reservations r
    JOIN destinations d ON r.destination_id = d.id
    WHERE r.user_id = user_uuid
    ORDER BY r.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour obtenir les favoris avec les détails des destinations
CREATE OR REPLACE FUNCTION get_user_favorites_with_details(user_uuid UUID)
RETURNS TABLE (
    favorite_id UUID,
    destination_id UUID,
    destination_title TEXT,
    destination_description TEXT,
    destination_type TEXT,
    destination_location TEXT,
    destination_image_url TEXT,
    destination_rating DECIMAL(3,2),
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        f.id,
        f.destination_id,
        d.title,
        d.description,
        d.type,
        d.location,
        d.image_url,
        d.rating,
        f.created_at
    FROM favorites f
    JOIN destinations d ON f.destination_id = d.id
    WHERE f.user_id = user_uuid
    ORDER BY f.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER; 
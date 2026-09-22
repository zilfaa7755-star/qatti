-- ============================================
-- قاعدة بيانات تطبيق قاتي - Qaati Database
-- PostgreSQL + PostGIS
-- ============================================

-- تفعيل PostGIS
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. الجداول الأساسية
-- ============================================

-- المستخدمون
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(255),
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(100) NOT NULL,
    avatar_url TEXT,
    type VARCHAR(20) NOT NULL CHECK (type IN ('buyer', 'seller', 'driver', 'admin', 'support')),
    wallet_balance DECIMAL(12,2) DEFAULT 0,
    trust_level VARCHAR(20) DEFAULT 'bronze' CHECK (trust_level IN ('bronze', 'silver', 'gold')),
    trust_score INTEGER DEFAULT 0,
    is_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    fcm_token TEXT,
    last_location GEOGRAPHY(POINT, 4326),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- الأسواق
CREATE TABLE markets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    name_en VARCHAR(100),
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    address TEXT NOT NULL,
    city VARCHAR(50) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    opening_time TIME,
    closing_time TIME,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- المتاجر
CREATE TABLE shops (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    market_id UUID REFERENCES markets(id) ON DELETE SET NULL,
    seller_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    location GEOGRAPHY(POINT, 4326),
    address TEXT,
    cover_image TEXT,
    logo_image TEXT,
    bank_account JSONB,
    e_wallets JSONB,
    rating DECIMAL(2,1) DEFAULT 0,
    total_reviews INTEGER DEFAULT 0,
    total_orders INTEGER DEFAULT 0,
    is_verified BOOLEAN DEFAULT FALSE,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'suspended', 'closed', 'rejected')),
    auto_stock_update BOOLEAN DEFAULT TRUE,
    last_stock_update TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- أنواع القات
CREATE TABLE khat_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    name_en VARCHAR(100),
    origin VARCHAR(100),
    description TEXT,
    image_url TEXT,
    characteristics JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- درجات جودة القات
CREATE TABLE khat_grades (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type_id UUID REFERENCES khat_types(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL,
    quality_score INTEGER CHECK (quality_score BETWEEN 1 AND 100),
    price_min DECIMAL(10,2),
    price_max DECIMAL(10,2),
    characteristics TEXT,
    reference_images TEXT[],
    color_code VARCHAR(7),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- المنتجات
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
    type_id UUID REFERENCES khat_types(id),
    grade_id UUID REFERENCES khat_grades(id),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price_type VARCHAR(20) NOT NULL CHECK (price_type IN ('fixed', 'range', 'inquiry', 'auction')),
    fixed_price DECIMAL(10,2),
    min_price DECIMAL(10,2),
    max_price DECIMAL(10,2),
    auction_start_price DECIMAL(10,2),
    auction_end_time TIMESTAMP WITH TIME ZONE,
    current_bid DECIMAL(10,2),
    current_bidder_id UUID REFERENCES users(id),
    stock_quantity DECIMAL(8,2) NOT NULL DEFAULT 0,
    unit VARCHAR(20) DEFAULT 'bundle',
    weight_per_unit DECIMAL(6,2),
    images TEXT[],
    is_live BOOLEAN DEFAULT FALSE,
    live_url TEXT,
    live_started_at TIMESTAMP WITH TIME ZONE,
    is_featured BOOLEAN DEFAULT FALSE,
    view_count INTEGER DEFAULT 0,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'out_of_stock', 'hidden', 'deleted')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- الطلبات
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_number VARCHAR(20) UNIQUE NOT NULL,
    buyer_id UUID REFERENCES users(id),
    shop_id UUID REFERENCES shops(id),
    status VARCHAR(30) DEFAULT 'pending' CHECK (status IN (
        'pending', 'confirmed', 'preparing', 'ready_for_pickup', 
        'picked_up', 'in_transit', 'delivered', 'cancelled', 'refunded', 'failed'
    )),
    subtotal DECIMAL(12,2) NOT NULL,
    delivery_fee DECIMAL(10,2) DEFAULT 0,
    app_fee DECIMAL(10,2) DEFAULT 0,
    discount_amount DECIMAL(10,2) DEFAULT 0,
    total_amount DECIMAL(12,2) NOT NULL,
    payment_type VARCHAR(20) NOT NULL CHECK (payment_type IN ('wallet', 'card', 'cash', 'postpaid')),
    payment_status VARCHAR(20) DEFAULT 'pending' CHECK (payment_status IN ('pending', 'held', 'completed', 'failed', 'refunded')),
    payment_method VARCHAR(50),
    transaction_id VARCHAR(100),
    delivery_address TEXT NOT NULL,
    delivery_location GEOGRAPHY(POINT, 4326),
    delivery_notes TEXT,
    estimated_delivery TIMESTAMP WITH TIME ZONE,
    actual_delivery TIMESTAMP WITH TIME ZONE,
    cancellation_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- عناصر الطلب
CREATE TABLE order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id),
    quantity DECIMAL(8,2) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    negotiated_price DECIMAL(10,2),
    final_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(12,2) NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- الموصلون / السائقون
CREATE TABLE drivers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    vehicle_type VARCHAR(50),
    vehicle_plate VARCHAR(20),
    license_number VARCHAR(50),
    id_card_image TEXT,
    license_image TEXT,
    current_location GEOGRAPHY(POINT, 4326),
    status VARCHAR(20) DEFAULT 'offline' CHECK (status IN ('offline', 'available', 'busy', 'on_break')),
    max_orders INTEGER DEFAULT 3,
    active_orders INTEGER DEFAULT 0,
    total_deliveries INTEGER DEFAULT 0,
    rating DECIMAL(2,1) DEFAULT 0,
    total_reviews INTEGER DEFAULT 0,
    last_assignment TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- شركات التوصيل
CREATE TABLE delivery_companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    owner_id UUID REFERENCES users(id),
    license_number VARCHAR(50),
    contact_phone VARCHAR(20),
    contact_email VARCHAR(255),
    coverage_area GEOGRAPHY(POLYGON, 4326),
    base_rate DECIMAL(10,2),
    per_km_rate DECIMAL(10,2),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- عمليات التوصيل
CREATE TABLE deliveries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    driver_id UUID REFERENCES drivers(id),
    company_id UUID REFERENCES delivery_companies(id),
    status VARCHAR(30) DEFAULT 'pending' CHECK (status IN (
        'pending', 'assigned', 'accepted', 'pickup', 'in_transit', 
        'near_destination', 'delivered', 'failed', 'returned'
    )),
    pickup_location GEOGRAPHY(POINT, 4326) NOT NULL,
    drop_location GEOGRAPHY(POINT, 4326) NOT NULL,
    distance_km DECIMAL(6,2),
    fee DECIMAL(10,2) NOT NULL,
    label_url TEXT,
    barcode VARCHAR(50),
    qr_code TEXT,
    gps_tracking JSONB,
    pickup_time TIMESTAMP WITH TIME ZONE,
    delivery_time TIMESTAMP WITH TIME ZONE,
    delivery_proof_image TEXT,
    delivery_proof_signature TEXT,
    recipient_name VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- المحادثات / التفاوض
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID REFERENCES orders(id),
    product_id UUID REFERENCES products(id),
    buyer_id UUID NOT NULL REFERENCES users(id),
    seller_id UUID NOT NULL REFERENCES users(id),
    type VARCHAR(20) DEFAULT 'negotiation' CHECK (type IN ('negotiation', 'support', 'general')),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'closed', 'blocked')),
    last_message TEXT,
    last_message_at TIMESTAMP WITH TIME ZONE,
    unread_count_buyer INTEGER DEFAULT 0,
    unread_count_seller INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- الرسائل
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(id),
    content TEXT NOT NULL,
    type VARCHAR(20) DEFAULT 'text' CHECK (type IN ('text', 'image', 'voice', 'location', 'price_offer', 'system')),
    metadata JSONB,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- التقييمات
CREATE TABLE reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reviewer_id UUID NOT NULL REFERENCES users(id),
    target_id UUID NOT NULL,
    target_type VARCHAR(20) NOT NULL CHECK (target_type IN ('shop', 'driver', 'product', 'order')),
    order_id UUID REFERENCES orders(id),
    rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    images TEXT[],
    is_verified BOOLEAN DEFAULT FALSE,
    helpful_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- الإشعارات
CREATE TABLE IF NOT EXISTS review_helpful_votes (
    review_id UUID NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    PRIMARY KEY (review_id, user_id)
);

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,
    title VARCHAR(200) NOT NULL,
    body TEXT NOT NULL,
    data JSONB,
    is_read BOOLEAN DEFAULT FALSE,
    sent_via VARCHAR(20) DEFAULT 'push' CHECK (sent_via IN ('push', 'sms', 'email', 'in_app')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- سجل المحفظة
CREATE TABLE wallet_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id),
    type VARCHAR(20) NOT NULL CHECK (type IN ('deposit', 'withdrawal', 'payment', 'refund', 'fee', 'commission', 'delivery_fee', 'reversal')),
    amount DECIMAL(12,2) NOT NULL,
    balance_after DECIMAL(12,2) NOT NULL,
    reference_type VARCHAR(50),
    reference_id UUID,
    description TEXT,
    status VARCHAR(20) DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'failed', 'reversed', 'cancelled')),
    metadata JSONB,
    idempotency_key VARCHAR(160),
    provider_transaction_code VARCHAR(160),
    approved_at TIMESTAMP,
    rejection_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- سلة المفاوضات
CREATE TABLE negotiation_carts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    buyer_id UUID REFERENCES users(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id),
    shop_id UUID REFERENCES shops(id),
    offered_price DECIMAL(10,2),
    requested_quantity DECIMAL(8,2),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'expired')),
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- الوكلاء
CREATE TABLE shop_agents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shop_id UUID REFERENCES shops(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id),
    permissions JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- البث المباشر
CREATE TABLE live_streams (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shop_id UUID NOT NULL REFERENCES shops(id),
    product_id UUID REFERENCES products(id),
    streamer_id UUID NOT NULL REFERENCES users(id),
    title VARCHAR(200),
    stream_url TEXT,
    thumbnail_url TEXT,
    viewer_count INTEGER DEFAULT 0,
    max_viewers INTEGER DEFAULT 0,
    status VARCHAR(20) DEFAULT 'live' CHECK (status IN ('scheduled', 'live', 'ended', 'cancelled')),
    started_at TIMESTAMP WITH TIME ZONE,
    ended_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- الإعدادات العامة
CREATE INDEX idx_live_streams_streamer ON live_streams(streamer_id);

CREATE TABLE app_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key VARCHAR(100) UNIQUE NOT NULL,
    value JSONB NOT NULL,
    description TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 1.1 حقول المجال الموحّدة مع طبقة TypeORM
-- هذه الإضافات تجعل 01_database.sql قاعدة قابلة للتشغيل مع الـ entities
-- مع الحفاظ على الحقول التاريخية التي تستخدمها التقارير/الاستيراد.
-- ============================================

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS preferred_language VARCHAR(10) DEFAULT 'ar',
  ADD COLUMN IF NOT EXISTS location JSONB,
  ADD COLUMN IF NOT EXISTS shop_id UUID REFERENCES shops(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS phone_verified BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS otp_code VARCHAR(255),
  ADD COLUMN IF NOT EXISTS otp_expires_at TIMESTAMP,
  ADD COLUMN IF NOT EXISTS otp_attempts INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS otp_last_sent_at TIMESTAMPTZ NULL,
  ADD COLUMN IF NOT EXISTS suspension_reason TEXT,
  ADD COLUMN IF NOT EXISTS suspension_expires_at TIMESTAMP;

ALTER TABLE shops
  ADD COLUMN IF NOT EXISTS rejection_reason TEXT,
  ADD COLUMN IF NOT EXISTS suspension_reason TEXT,
  ADD COLUMN IF NOT EXISTS approved_at TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS phone VARCHAR(30);

ALTER TABLE orders
  ADD COLUMN IF NOT EXISTS reservation_expires_at TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS ready_at TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE deliveries
  ADD COLUMN IF NOT EXISTS estimated_pickup_time TIMESTAMP WITH TIME ZONE;

ALTER TABLE wallet_transactions
  ADD COLUMN IF NOT EXISTS metadata JSONB,
  ADD COLUMN IF NOT EXISTS approved_at TIMESTAMP,
  ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

-- ============================================
-- 1.2 Canonical database invariants
-- ============================================
ALTER TABLE users
  ADD CONSTRAINT users_wallet_balance_nonnegative CHECK (wallet_balance >= 0),
  ADD CONSTRAINT users_trust_score_nonnegative CHECK (trust_score >= 0);

ALTER TABLE products
  ADD CONSTRAINT products_stock_nonnegative CHECK (stock_quantity >= 0),
  ADD CONSTRAINT products_price_bounds CHECK (
    (fixed_price IS NULL OR fixed_price >= 0) AND
    (min_price IS NULL OR min_price >= 0) AND
    (max_price IS NULL OR max_price >= 0) AND
    (auction_start_price IS NULL OR auction_start_price >= 0) AND
    (current_bid IS NULL OR current_bid >= 0) AND
    (min_price IS NULL OR max_price IS NULL OR min_price <= max_price)
  );

ALTER TABLE orders
  ADD CONSTRAINT orders_amounts_nonnegative CHECK (
    subtotal >= 0 AND delivery_fee >= 0 AND app_fee >= 0 AND
    discount_amount >= 0 AND total_amount >= 0
  );

ALTER TABLE order_items
  ADD CONSTRAINT order_items_amounts_nonnegative CHECK (
    quantity > 0 AND unit_price >= 0 AND
    (negotiated_price IS NULL OR negotiated_price >= 0) AND
    final_price >= 0 AND total_price >= 0
  );

ALTER TABLE wallet_transactions
  ADD CONSTRAINT wallet_balance_after_nonnegative CHECK (balance_after >= 0);

ALTER TABLE reviews
  ADD CONSTRAINT reviews_rating_range CHECK (rating BETWEEN 1 AND 5);

ALTER TABLE drivers
  ADD CONSTRAINT drivers_capacity_nonnegative CHECK (
    max_orders >= 0 AND active_orders >= 0 AND total_deliveries >= 0
  );

-- Phase 4 commerce integrity invariants
ALTER TABLE products
  ADD CONSTRAINT products_fixed_price_required CHECK (
    price_type <> 'fixed' OR fixed_price IS NOT NULL
  ),
  ADD CONSTRAINT products_range_price_complete CHECK (
    price_type <> 'range' OR (
      min_price IS NOT NULL AND max_price IS NOT NULL AND min_price <= max_price
    )
  ),
  ADD CONSTRAINT products_auction_price_complete CHECK (
    price_type <> 'auction' OR (
      auction_start_price IS NOT NULL AND auction_end_time IS NOT NULL
    )
  );

ALTER TABLE order_items
  ADD CONSTRAINT order_items_quantity_integer CHECK (quantity = trunc(quantity)),
  ADD CONSTRAINT order_items_total_matches_final_price CHECK (
    total_price = round(quantity * final_price, 2)
  );

ALTER TABLE orders
  ADD CONSTRAINT orders_discount_not_above_subtotal CHECK (discount_amount <= subtotal),
  ADD CONSTRAINT orders_total_matches_components CHECK (
    total_amount = round(subtotal + delivery_fee + app_fee - discount_amount, 2)
  );

CREATE UNIQUE INDEX idx_deliveries_order_unique
  ON deliveries(order_id) WHERE order_id IS NOT NULL;
CREATE UNIQUE INDEX idx_wallet_idempotency_unique
  ON wallet_transactions(idempotency_key) WHERE idempotency_key IS NOT NULL;
CREATE UNIQUE INDEX idx_wallet_provider_tx_unique
  ON wallet_transactions(provider_transaction_code) WHERE provider_transaction_code IS NOT NULL;

-- ============================================
-- 2. الفهارس Indexes
-- ============================================

CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_type ON users(type);
CREATE INDEX idx_users_location ON users USING GIST(last_location);

CREATE INDEX idx_shops_market ON shops(market_id);
CREATE INDEX idx_shops_seller ON shops(seller_id);
CREATE INDEX idx_shops_status ON shops(status);
CREATE INDEX idx_shops_location ON shops USING GIST(location);

CREATE INDEX idx_products_shop ON products(shop_id);
CREATE INDEX idx_products_type ON products(type_id);
CREATE INDEX idx_products_grade ON products(grade_id);
CREATE INDEX idx_products_price_type ON products(price_type);
CREATE INDEX idx_products_status ON products(status);

CREATE INDEX idx_orders_buyer ON orders(buyer_id);
CREATE INDEX idx_orders_shop ON orders(shop_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_number ON orders(order_number);

CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);

CREATE INDEX idx_deliveries_order ON deliveries(order_id);
CREATE INDEX idx_deliveries_driver ON deliveries(driver_id);
CREATE INDEX idx_deliveries_status ON deliveries(status);

CREATE INDEX idx_conversations_buyer ON conversations(buyer_id);
CREATE INDEX idx_conversations_seller ON conversations(seller_id);
CREATE INDEX idx_conversations_order ON conversations(order_id);

CREATE INDEX idx_messages_conversation ON messages(conversation_id);
CREATE INDEX idx_messages_created ON messages(created_at);
CREATE INDEX idx_messages_sender ON messages(sender_id);

CREATE INDEX idx_reviews_target ON reviews(target_id, target_type);
CREATE INDEX idx_reviews_order ON reviews(order_id);
CREATE INDEX idx_reviews_reviewer ON reviews(reviewer_id);
CREATE UNIQUE INDEX idx_reviews_reviewer_target_order ON reviews(reviewer_id, target_id, target_type, order_id) WHERE order_id IS NOT NULL;
CREATE INDEX idx_orders_reservation_expiry ON orders(reservation_expires_at) WHERE payment_status = 'pending';

CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_unread ON notifications(user_id, is_read);
CREATE INDEX idx_notifications_user_created ON notifications(user_id, created_at DESC);

CREATE INDEX idx_wallet_user ON wallet_transactions(user_id);
CREATE INDEX idx_wallet_reference ON wallet_transactions(reference_type, reference_id);
CREATE INDEX idx_platform_ledger_order_created ON platform_ledger_entries(order_id, created_at DESC);

-- ============================================
-- 3. الدوال والمحفزات Functions & Triggers
-- ============================================

-- تحديث updated_at تلقائياً
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_shops_updated_at BEFORE UPDATE ON shops
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_deliveries_updated_at BEFORE UPDATE ON deliveries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_drivers_updated_at BEFORE UPDATE ON drivers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- توليد رقم الطلب
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TRIGGER AS $$
BEGIN
    NEW.order_number = 'QAT-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(FLOOR(RANDOM() * 9999)::TEXT, 4, '0');
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER set_order_number BEFORE INSERT ON orders
    FOR EACH ROW EXECUTE FUNCTION generate_order_number();

-- تحديث التقييم التلقائي للمتجر
CREATE OR REPLACE FUNCTION update_shop_rating()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE shops 
    SET rating = (
        SELECT ROUND(AVG(rating)::numeric, 1) 
        FROM reviews 
        WHERE target_id = NEW.target_id AND target_type = 'shop'
    ),
    total_reviews = (
        SELECT COUNT(*) 
        FROM reviews 
        WHERE target_id = NEW.target_id AND target_type = 'shop'
    )
    WHERE id = NEW.target_id;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_shop_rating_trigger 
    AFTER INSERT OR UPDATE ON reviews
    FOR EACH ROW 
    WHEN (NEW.target_type = 'shop')
    EXECUTE FUNCTION update_shop_rating();

-- ============================================
-- 4. البيانات الأولية Seed Data
-- ============================================

-- أنواع القات
INSERT INTO khat_types (name, name_en, origin, description, characteristics) VALUES
('الحمراء', 'Al-Hamra', 'اليمن - إب', 'أشهر أنواع القات اليمني، أوراق حمراء غامقة', '{"color": "dark_red", "taste": "bitter_sweet", "strength": "high"}'),
('الخضراء', 'Al-Khadra', 'اليمن - تعز', 'أوراق خضراء زاهية، طعم منعش', '{"color": "bright_green", "taste": "fresh", "strength": "medium"}'),
('البيضاء', 'Al-Bayda', 'اليمن - صنعاء', 'أوراق فاتحة اللون، ناعمة الملمس', '{"color": "light_green", "taste": "mild", "strength": "low"}'),
('الأبيض الجبلي', 'Mountain White', 'اليمن - الجوف', 'أجود أنواع القات، نادر ومميز', '{"color": "white_green", "taste": "premium", "strength": "very_high"}'),
('الأحمر الكيني', 'Kenyan Red', 'كينيا', 'قات كيني مستورد، جودة عالية', '{"color": "red", "taste": "strong", "strength": "high", "imported": true}');

-- درجات الجودة
INSERT INTO khat_grades (type_id, name, quality_score, price_min, price_max, characteristics, color_code) 
SELECT id, 'درجة أولى (A)', 95, 1000, 2000, 'أوراق كاملة، خالية من العيوب، طازجة', '#22c55e'
FROM khat_types WHERE name = 'الحمراء';

INSERT INTO khat_grades (type_id, name, quality_score, price_min, price_max, characteristics, color_code)
SELECT id, 'درجة ثانية (B)', 75, 600, 1000, 'أوراق جيدة، بعض العيوب البسيطة', '#eab308'
FROM khat_types WHERE name = 'الحمراء';

INSERT INTO khat_grades (type_id, name, quality_score, price_min, price_max, characteristics, color_code)
SELECT id, 'درجة ثالثة (C)', 55, 300, 600, 'أوراق متوسطة، بعض الأوراق المتساقطة', '#f97316'
FROM khat_types WHERE name = 'الحمراء';

INSERT INTO khat_grades (type_id, name, quality_score, price_min, price_max, characteristics, color_code)
SELECT id, 'درجة رابعة (D)', 35, 100, 300, 'أوراق عادية، مناسبة للاستخدام اليومي', '#ef4444'
FROM khat_types WHERE name = 'الحمراء';

-- إعدادات التطبيق
INSERT INTO app_settings (key, value, description) VALUES
('delivery_base_rate', '{"amount": 50, "currency": "YER"}', 'سعر التوصيل الأساسي لكل كم'),
('app_commission_fixed', '{"amount": 10, "currency": "YER"}', 'العمولة الثابتة للتطبيق'),
('app_commission_percent', '{"percent": 1}', 'العمولة النسبية للتطبيق'),
('trust_levels', '{
    "bronze": {"limit": 5000, "max_orders": 3, "min_completed": 0},
    "silver": {"limit": 15000, "max_orders": 10, "min_completed": 5},
    "gold": {"limit": 50000, "max_orders": 999, "min_completed": 20, "min_rating": 4.5}
}', 'مستويات نظام الثقة'),
('stock_update_interval', '{"minutes": 30}', 'فترة تحديث المخزون بالدقائق'),
('auction_duration', '{"minutes": 15}', 'مدة المزاد اللحظي بالدقائق'),
('multi_order_time_window', '{"minutes": 5}', 'نافذة قبول الطلبات المتعددة');

-- ============================================
-- 5. Views للتقارير
-- ============================================

CREATE VIEW shop_performance AS
SELECT 
    s.id AS shop_id,
    s.name AS shop_name,
    COUNT(DISTINCT o.id) AS total_orders,
    COALESCE(SUM(o.total_amount), 0) AS total_revenue,
    s.rating,
    s.total_reviews,
    COUNT(DISTINCT CASE WHEN o.status = 'delivered' THEN o.id END) AS completed_orders,
    COUNT(DISTINCT CASE WHEN o.status = 'cancelled' THEN o.id END) AS cancelled_orders
FROM shops s
LEFT JOIN orders o ON s.id = o.shop_id
GROUP BY s.id, s.name, s.rating, s.total_reviews;

CREATE VIEW daily_sales AS
SELECT 
    DATE(o.created_at) AS sale_date,
    COUNT(*) AS order_count,
    SUM(o.total_amount) AS total_sales,
    SUM(o.app_fee) AS total_commission,
    SUM(o.delivery_fee) AS total_delivery_fees
FROM orders o
WHERE o.status = 'delivered'
GROUP BY DATE(o.created_at)
ORDER BY sale_date DESC;

-- Phase 5: financial-system hardening
CREATE TABLE IF NOT EXISTS payment_webhook_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_event_id VARCHAR(255) NOT NULL UNIQUE,
  provider VARCHAR(50) NOT NULL,
  event_type VARCHAR(120) NOT NULL,
  processed BOOLEAN NOT NULL DEFAULT FALSE,
  payload_hash VARCHAR(128),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_payment_webhook_provider_created ON payment_webhook_events(provider, created_at DESC);
CREATE UNIQUE INDEX IF NOT EXISTS idx_orders_transaction_id_unique ON orders(transaction_id) WHERE transaction_id IS NOT NULL;
ALTER TABLE wallet_transactions DROP CONSTRAINT IF EXISTS wallet_transaction_amount_sign_check;
ALTER TABLE wallet_transactions ADD CONSTRAINT wallet_transaction_amount_sign_check CHECK (
  (type IN ('deposit','refund','commission','fee','delivery_fee') AND amount >= 0)
  OR (type IN ('payment','withdrawal') AND amount <= 0)
  OR (type = 'reversal')
);


-- Platform revenue ledger. app_fee is charged to the buyer and recorded here so
-- seller settlement + driver settlement + platform revenue reconcile to the order total.
CREATE TABLE platform_ledger_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE RESTRICT,
  entry_type VARCHAR(30) NOT NULL CHECK (entry_type IN ('fee','reversal')),
  amount DECIMAL(12,2) NOT NULL,
  idempotency_key VARCHAR(160) NOT NULL UNIQUE,
  description TEXT NOT NULL,
  metadata JSONB NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT platform_ledger_entry_amount_check CHECK (
    (entry_type = 'fee' AND amount >= 0)
    OR (entry_type = 'reversal' AND amount <= 0)
  )
);


-- Refresh tokens for session rotation/revocation (see
-- backend/src/database/migrations/1700000008000-RefreshTokens.ts, kept in
-- sync here per the schema-source discipline in docs/SCHEMA_RECONCILIATION.md).
CREATE TABLE IF NOT EXISTS refresh_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash VARCHAR(64) NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  revoked_at TIMESTAMPTZ,
  replaced_by_token_hash VARCHAR(64),
  user_agent TEXT,
  ip_address VARCHAR(64),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_refresh_tokens_hash_unique ON refresh_tokens(token_hash);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_expiry_sweep ON refresh_tokens(expires_at) WHERE revoked_at IS NULL;

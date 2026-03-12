-- 1. Create Categories Table
CREATE TABLE categories (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  name text NOT NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now())
);

-- 2. Create Products Table
CREATE TABLE products (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  category_id uuid REFERENCES categories(id) ON DELETE CASCADE,
  name text NOT NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now())
);

-- 3. Modify Request Items Table to support linked products and categories
ALTER TABLE request_items ADD COLUMN category_id uuid REFERENCES categories(id) ON DELETE SET NULL;
ALTER TABLE request_items ADD COLUMN product_id uuid REFERENCES products(id) ON DELETE SET NULL;

-- 4. Enable RLS
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies for Categories
CREATE POLICY "Everyone can view categories" ON categories FOR SELECT USING (true);
CREATE POLICY "Only admins can manage categories" ON categories FOR ALL 
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- 6. RLS Policies for Products
CREATE POLICY "Everyone can view products" ON products FOR SELECT USING (true);
CREATE POLICY "Only admins can manage products" ON products FOR ALL 
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

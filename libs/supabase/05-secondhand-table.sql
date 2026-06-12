-- =============================================
-- 珈邻小程序 - 闲置商品表
-- 执行顺序: 5
-- 功能: 创建闲置商品表、收藏表、图片存储
-- 依赖: 01-users-table.sql
-- =============================================

-- 1. 创建闲置商品表
CREATE TABLE IF NOT EXISTS public.secondhand_items (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES public.users(id),
  title VARCHAR(100) NOT NULL,
  description TEXT DEFAULT '',
  images TEXT[] DEFAULT '{}',
  category VARCHAR(50) DEFAULT '其他',
  price DECIMAL(10,2) NOT NULL,
  original_price DECIMAL(10,2) DEFAULT 0,
  phone VARCHAR(20) DEFAULT '',
  view_count INT DEFAULT 0,
  favorite_count INT DEFAULT 0,
  status VARCHAR(20) DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. 创建收藏表
CREATE TABLE IF NOT EXISTS public.secondhand_favorites (
  id BIGSERIAL PRIMARY KEY,
  item_id BIGINT NOT NULL REFERENCES public.secondhand_items(id) ON DELETE CASCADE,
  user_id BIGINT NOT NULL REFERENCES public.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(item_id, user_id)
);

-- 3. 创建索引
CREATE INDEX IF NOT EXISTS idx_secondhand_items_user_id ON public.secondhand_items(user_id);
CREATE INDEX IF NOT EXISTS idx_secondhand_items_category ON public.secondhand_items(category);
CREATE INDEX IF NOT EXISTS idx_secondhand_items_status ON public.secondhand_items(status);
CREATE INDEX IF NOT EXISTS idx_secondhand_items_created_at ON public.secondhand_items(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_secondhand_favorites_item_id ON public.secondhand_favorites(item_id);
CREATE INDEX IF NOT EXISTS idx_secondhand_favorites_user_id ON public.secondhand_favorites(user_id);

-- 4. 启用 RLS
ALTER TABLE public.secondhand_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.secondhand_favorites ENABLE ROW LEVEL SECURITY;

-- 5. RLS 策略 - secondhand_items
DROP POLICY IF EXISTS "允许查询闲置" ON public.secondhand_items;
DROP POLICY IF EXISTS "允许插入闲置" ON public.secondhand_items;
DROP POLICY IF EXISTS "允许更新闲置" ON public.secondhand_items;
DROP POLICY IF EXISTS "允许删除闲置" ON public.secondhand_items;

CREATE POLICY "允许查询闲置" ON public.secondhand_items FOR SELECT USING (true);
CREATE POLICY "允许插入闲置" ON public.secondhand_items FOR INSERT WITH CHECK (true);
CREATE POLICY "允许更新闲置" ON public.secondhand_items FOR UPDATE USING (true);
CREATE POLICY "允许删除闲置" ON public.secondhand_items FOR DELETE USING (true);

-- 6. RLS 策略 - secondhand_favorites
DROP POLICY IF EXISTS "允许查询收藏" ON public.secondhand_favorites;
DROP POLICY IF EXISTS "允许插入收藏" ON public.secondhand_favorites;
DROP POLICY IF EXISTS "允许删除收藏" ON public.secondhand_favorites;

CREATE POLICY "允许查询收藏" ON public.secondhand_favorites FOR SELECT USING (true);
CREATE POLICY "允许插入收藏" ON public.secondhand_favorites FOR INSERT WITH CHECK (true);
CREATE POLICY "允许删除收藏" ON public.secondhand_favorites FOR DELETE USING (true);

-- 7. 更新时间触发器
DROP TRIGGER IF EXISTS secondhand_items_updated_at ON public.secondhand_items;
CREATE TRIGGER secondhand_items_updated_at
  BEFORE UPDATE ON public.secondhand_items
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- 8. 授权
GRANT SELECT, INSERT, UPDATE, DELETE ON public.secondhand_items TO anon;
GRANT USAGE, SELECT ON SEQUENCE public.secondhand_items_id_seq TO anon;
GRANT SELECT, INSERT, DELETE ON public.secondhand_favorites TO anon;
GRANT USAGE, SELECT ON SEQUENCE public.secondhand_favorites_id_seq TO anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.secondhand_items TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE public.secondhand_items_id_seq TO authenticated;
GRANT SELECT, INSERT, DELETE ON public.secondhand_favorites TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE public.secondhand_favorites_id_seq TO authenticated;

-- 9. 创建 secondhand bucket 用于存储闲置图片
INSERT INTO storage.buckets (id, name, public)
VALUES ('secondhand', 'secondhand', true)
ON CONFLICT (id) DO NOTHING;

-- 10. Storage 策略 - secondhand bucket
DROP POLICY IF EXISTS "允许上传闲置图片" ON storage.objects;
DROP POLICY IF EXISTS "允许更新闲置图片" ON storage.objects;
DROP POLICY IF EXISTS "允许公开访问闲置图片" ON storage.objects;

CREATE POLICY "允许上传闲置图片" ON storage.objects
FOR INSERT TO anon
WITH CHECK (bucket_id = 'secondhand');

CREATE POLICY "允许更新闲置图片" ON storage.objects
FOR UPDATE TO anon
USING (bucket_id = 'secondhand');

CREATE POLICY "允许公开访问闲置图片" ON storage.objects
FOR SELECT TO anon
USING (bucket_id = 'secondhand');


-- 11. 发布闲置 RPC 函数
CREATE OR REPLACE FUNCTION public.create_secondhand_item(
  p_user_id BIGINT,
  p_title VARCHAR,
  p_description TEXT DEFAULT '',
  p_images TEXT[] DEFAULT '{}',
  p_category VARCHAR DEFAULT '其他',
  p_price DECIMAL DEFAULT 0,
  p_original_price DECIMAL DEFAULT 0,
  p_phone VARCHAR DEFAULT ''
)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_item secondhand_items;
BEGIN
  INSERT INTO secondhand_items (user_id, title, description, images, category, price, original_price, phone)
  VALUES (p_user_id, p_title, p_description, p_images, p_category, p_price, p_original_price, p_phone)
  RETURNING * INTO v_item;
  
  RETURN json_build_object(
    'success', true,
    'message', '发布成功',
    'item', row_to_json(v_item)
  );
END;
$$;

-- 12. 查询闲置列表 RPC 函数
CREATE OR REPLACE FUNCTION public.get_secondhand_items(
  p_user_id BIGINT DEFAULT NULL,
  p_category VARCHAR DEFAULT NULL,
  p_keyword VARCHAR DEFAULT NULL,
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result JSON;
BEGIN
  SELECT json_agg(row_to_json(t)) INTO v_result
  FROM (
    SELECT
      s.id, s.title, s.description, s.images, s.category,
      s.price, s.original_price, s.view_count, s.favorite_count, s.created_at,
      u.id as user_id, u.nickname, u.avatar_url, u.building,
      CASE WHEN p_user_id IS NOT NULL THEN
        EXISTS(SELECT 1 FROM secondhand_favorites WHERE item_id = s.id AND user_id = p_user_id)
      ELSE false END as favorited
    FROM secondhand_items s
    JOIN users u ON s.user_id = u.id
    WHERE s.status = 'active'
      AND (p_category IS NULL OR p_category = '全部' OR s.category = p_category)
      AND (p_keyword IS NULL OR s.title ILIKE '%' || p_keyword || '%')
    ORDER BY s.created_at DESC
    LIMIT p_limit OFFSET p_offset
  ) t;
  
  RETURN COALESCE(v_result, '[]'::json);
END;
$$;

-- 13. 查询闲置详情 RPC 函数
CREATE OR REPLACE FUNCTION public.get_secondhand_detail(
  p_item_id BIGINT,
  p_user_id BIGINT DEFAULT NULL
)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result JSON;
BEGIN
  -- 增加浏览量
  UPDATE secondhand_items SET view_count = view_count + 1 WHERE id = p_item_id;
  
  SELECT row_to_json(t) INTO v_result
  FROM (
    SELECT
      s.id, s.title, s.description, s.images, s.category,
      s.price, s.original_price, s.phone, s.view_count, s.favorite_count, s.created_at,
      u.id as user_id, u.nickname, u.avatar_url, u.building,
      CASE WHEN p_user_id IS NOT NULL THEN
        EXISTS(SELECT 1 FROM secondhand_favorites WHERE item_id = s.id AND user_id = p_user_id)
      ELSE false END as favorited
    FROM secondhand_items s
    JOIN users u ON s.user_id = u.id
    WHERE s.id = p_item_id
  ) t;
  
  RETURN v_result;
END;
$$;

-- 14. 收藏/取消收藏 RPC 函数
CREATE OR REPLACE FUNCTION public.toggle_favorite(
  p_item_id BIGINT,
  p_user_id BIGINT
)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_exists BOOLEAN;
  v_favorite_count INT;
BEGIN
  SELECT EXISTS(SELECT 1 FROM secondhand_favorites WHERE item_id = p_item_id AND user_id = p_user_id) INTO v_exists;
  
  IF v_exists THEN
    DELETE FROM secondhand_favorites WHERE item_id = p_item_id AND user_id = p_user_id;
    UPDATE secondhand_items SET favorite_count = favorite_count - 1 WHERE id = p_item_id;
  ELSE
    INSERT INTO secondhand_favorites (item_id, user_id) VALUES (p_item_id, p_user_id);
    UPDATE secondhand_items SET favorite_count = favorite_count + 1 WHERE id = p_item_id;
  END IF;
  
  SELECT favorite_count INTO v_favorite_count FROM secondhand_items WHERE id = p_item_id;
  
  RETURN json_build_object(
    'success', true,
    'favorited', NOT v_exists,
    'favorite_count', v_favorite_count
  );
END;
$$;

-- 15. 授权 RPC 函数
GRANT EXECUTE ON FUNCTION public.create_secondhand_item(BIGINT, VARCHAR, TEXT, TEXT[], VARCHAR, DECIMAL, DECIMAL, VARCHAR) TO anon;
GRANT EXECUTE ON FUNCTION public.create_secondhand_item(BIGINT, VARCHAR, TEXT, TEXT[], VARCHAR, DECIMAL, DECIMAL, VARCHAR) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_secondhand_items(BIGINT, VARCHAR, VARCHAR, INT, INT) TO anon;
GRANT EXECUTE ON FUNCTION public.get_secondhand_items(BIGINT, VARCHAR, VARCHAR, INT, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_secondhand_detail(BIGINT, BIGINT) TO anon;
GRANT EXECUTE ON FUNCTION public.get_secondhand_detail(BIGINT, BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.toggle_favorite(BIGINT, BIGINT) TO anon;
GRANT EXECUTE ON FUNCTION public.toggle_favorite(BIGINT, BIGINT) TO authenticated;

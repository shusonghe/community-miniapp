-- =============================================
-- 珈邻小程序 - 动态表
-- 执行顺序: 4
-- 功能: 创建动态表、点赞表、评论表、图片存储
-- 依赖: 01-users-table.sql
-- =============================================

-- 1. 创建动态表
CREATE TABLE IF NOT EXISTS public.posts (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES public.users(id),
  content TEXT NOT NULL,
  images TEXT[] DEFAULT '{}',
  location VARCHAR(100) DEFAULT '',
  topic VARCHAR(50) DEFAULT '',
  like_count INT DEFAULT 0,
  comment_count INT DEFAULT 0,
  status VARCHAR(20) DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. 创建点赞表
CREATE TABLE IF NOT EXISTS public.post_likes (
  id BIGSERIAL PRIMARY KEY,
  post_id BIGINT NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  user_id BIGINT NOT NULL REFERENCES public.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

-- 3. 创建评论表
CREATE TABLE IF NOT EXISTS public.post_comments (
  id BIGSERIAL PRIMARY KEY,
  post_id BIGINT NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  user_id BIGINT NOT NULL REFERENCES public.users(id),
  content TEXT NOT NULL,
  parent_id BIGINT DEFAULT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. 创建索引
CREATE INDEX IF NOT EXISTS idx_posts_user_id ON public.posts(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON public.posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_posts_status ON public.posts(status);
CREATE INDEX IF NOT EXISTS idx_post_likes_post_id ON public.post_likes(post_id);
CREATE INDEX IF NOT EXISTS idx_post_likes_user_id ON public.post_likes(user_id);
CREATE INDEX IF NOT EXISTS idx_post_comments_post_id ON public.post_comments(post_id);

-- 5. 启用 RLS
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_comments ENABLE ROW LEVEL SECURITY;

-- 6. RLS 策略 - posts
DROP POLICY IF EXISTS "允许查询动态" ON public.posts;
DROP POLICY IF EXISTS "允许插入动态" ON public.posts;
DROP POLICY IF EXISTS "允许更新动态" ON public.posts;
DROP POLICY IF EXISTS "允许删除动态" ON public.posts;

CREATE POLICY "允许查询动态" ON public.posts FOR SELECT USING (true);
CREATE POLICY "允许插入动态" ON public.posts FOR INSERT WITH CHECK (true);
CREATE POLICY "允许更新动态" ON public.posts FOR UPDATE USING (true);
CREATE POLICY "允许删除动态" ON public.posts FOR DELETE USING (true);

-- 7. RLS 策略 - post_likes
DROP POLICY IF EXISTS "允许查询点赞" ON public.post_likes;
DROP POLICY IF EXISTS "允许插入点赞" ON public.post_likes;
DROP POLICY IF EXISTS "允许删除点赞" ON public.post_likes;

CREATE POLICY "允许查询点赞" ON public.post_likes FOR SELECT USING (true);
CREATE POLICY "允许插入点赞" ON public.post_likes FOR INSERT WITH CHECK (true);
CREATE POLICY "允许删除点赞" ON public.post_likes FOR DELETE USING (true);

-- 8. RLS 策略 - post_comments
DROP POLICY IF EXISTS "允许查询评论" ON public.post_comments;
DROP POLICY IF EXISTS "允许插入评论" ON public.post_comments;
DROP POLICY IF EXISTS "允许删除评论" ON public.post_comments;

CREATE POLICY "允许查询评论" ON public.post_comments FOR SELECT USING (true);
CREATE POLICY "允许插入评论" ON public.post_comments FOR INSERT WITH CHECK (true);
CREATE POLICY "允许删除评论" ON public.post_comments FOR DELETE USING (true);

-- 9. 更新时间触发器
DROP TRIGGER IF EXISTS posts_updated_at ON public.posts;
CREATE TRIGGER posts_updated_at
  BEFORE UPDATE ON public.posts
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- 10. 授权
GRANT SELECT, INSERT, UPDATE, DELETE ON public.posts TO anon;
GRANT USAGE, SELECT ON SEQUENCE public.posts_id_seq TO anon;
GRANT SELECT, INSERT, DELETE ON public.post_likes TO anon;
GRANT USAGE, SELECT ON SEQUENCE public.post_likes_id_seq TO anon;
GRANT SELECT, INSERT, DELETE ON public.post_comments TO anon;
GRANT USAGE, SELECT ON SEQUENCE public.post_comments_id_seq TO anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.posts TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE public.posts_id_seq TO authenticated;
GRANT SELECT, INSERT, DELETE ON public.post_likes TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE public.post_likes_id_seq TO authenticated;
GRANT SELECT, INSERT, DELETE ON public.post_comments TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE public.post_comments_id_seq TO authenticated;

-- 11. 创建 posts bucket 用于存储动态图片
INSERT INTO storage.buckets (id, name, public)
VALUES ('posts', 'posts', true)
ON CONFLICT (id) DO NOTHING;


-- 12. Storage 策略 - posts bucket
DROP POLICY IF EXISTS "允许上传动态图片" ON storage.objects;
DROP POLICY IF EXISTS "允许更新动态图片" ON storage.objects;
DROP POLICY IF EXISTS "允许公开访问动态图片" ON storage.objects;

CREATE POLICY "允许上传动态图片" ON storage.objects
FOR INSERT TO anon
WITH CHECK (bucket_id = 'posts');

CREATE POLICY "允许更新动态图片" ON storage.objects
FOR UPDATE TO anon
USING (bucket_id = 'posts');

CREATE POLICY "允许公开访问动态图片" ON storage.objects
FOR SELECT TO anon
USING (bucket_id = 'posts');

-- 13. 发布动态 RPC 函数
CREATE OR REPLACE FUNCTION public.create_post(
  p_user_id BIGINT,
  p_content TEXT,
  p_images TEXT[] DEFAULT '{}',
  p_location VARCHAR DEFAULT '',
  p_topic VARCHAR DEFAULT ''
)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_post posts;
BEGIN
  INSERT INTO posts (user_id, content, images, location, topic)
  VALUES (p_user_id, p_content, p_images, p_location, p_topic)
  RETURNING * INTO v_post;
  
  RETURN json_build_object(
    'success', true,
    'message', '发布成功',
    'post', row_to_json(v_post)
  );
END;
$$;

-- 14. 点赞/取消点赞 RPC 函数
CREATE OR REPLACE FUNCTION public.toggle_like(
  p_post_id BIGINT,
  p_user_id BIGINT
)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_exists BOOLEAN;
  v_like_count INT;
BEGIN
  SELECT EXISTS(SELECT 1 FROM post_likes WHERE post_id = p_post_id AND user_id = p_user_id) INTO v_exists;
  
  IF v_exists THEN
    DELETE FROM post_likes WHERE post_id = p_post_id AND user_id = p_user_id;
    UPDATE posts SET like_count = like_count - 1 WHERE id = p_post_id;
  ELSE
    INSERT INTO post_likes (post_id, user_id) VALUES (p_post_id, p_user_id);
    UPDATE posts SET like_count = like_count + 1 WHERE id = p_post_id;
  END IF;
  
  SELECT like_count INTO v_like_count FROM posts WHERE id = p_post_id;
  
  RETURN json_build_object(
    'success', true,
    'liked', NOT v_exists,
    'like_count', v_like_count
  );
END;
$$;

-- 15. 添加评论 RPC 函数
CREATE OR REPLACE FUNCTION public.add_comment(
  p_post_id BIGINT,
  p_user_id BIGINT,
  p_content TEXT,
  p_parent_id BIGINT DEFAULT NULL
)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_comment post_comments;
  v_comment_count INT;
BEGIN
  INSERT INTO post_comments (post_id, user_id, content, parent_id)
  VALUES (p_post_id, p_user_id, p_content, p_parent_id)
  RETURNING * INTO v_comment;
  
  UPDATE posts SET comment_count = comment_count + 1 WHERE id = p_post_id;
  SELECT comment_count INTO v_comment_count FROM posts WHERE id = p_post_id;
  
  RETURN json_build_object(
    'success', true,
    'message', '评论成功',
    'comment', row_to_json(v_comment),
    'comment_count', v_comment_count
  );
END;
$$;

-- 16. 查询动态列表 RPC 函数（带用户信息、点赞状态、关键词搜索）
CREATE OR REPLACE FUNCTION public.get_posts(
  p_user_id BIGINT DEFAULT NULL,
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0,
  p_keyword VARCHAR DEFAULT NULL,
  p_order_by VARCHAR DEFAULT 'latest'
)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result JSON;
BEGIN
  IF p_order_by = 'hot' THEN
    SELECT json_agg(row_to_json(t)) INTO v_result
    FROM (
      SELECT
        p.id, p.content, p.images, p.location, p.topic,
        p.like_count, p.comment_count, p.created_at,
        u.id as user_id, u.nickname, u.avatar_url, u.building,
        CASE WHEN p_user_id IS NOT NULL THEN
          EXISTS(SELECT 1 FROM post_likes WHERE post_id = p.id AND user_id = p_user_id)
        ELSE false END as liked
      FROM posts p
      JOIN users u ON p.user_id = u.id
      WHERE p.status = 'active'
        AND (p_keyword IS NULL OR p.content ILIKE '%' || p_keyword || '%')
      ORDER BY p.like_count DESC, p.created_at DESC
      LIMIT p_limit OFFSET p_offset
    ) t;
  ELSE
    SELECT json_agg(row_to_json(t)) INTO v_result
    FROM (
      SELECT
        p.id, p.content, p.images, p.location, p.topic,
        p.like_count, p.comment_count, p.created_at,
        u.id as user_id, u.nickname, u.avatar_url, u.building,
        CASE WHEN p_user_id IS NOT NULL THEN
          EXISTS(SELECT 1 FROM post_likes WHERE post_id = p.id AND user_id = p_user_id)
        ELSE false END as liked
      FROM posts p
      JOIN users u ON p.user_id = u.id
      WHERE p.status = 'active'
        AND (p_keyword IS NULL OR p.content ILIKE '%' || p_keyword || '%')
      ORDER BY p.created_at DESC
      LIMIT p_limit OFFSET p_offset
    ) t;
  END IF;
  
  RETURN COALESCE(v_result, '[]'::json);
END;
$$;

-- 17. 查询评论列表 RPC 函数
CREATE OR REPLACE FUNCTION public.get_comments(
  p_post_id BIGINT,
  p_limit INT DEFAULT 50
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
      c.id, c.content, c.parent_id, c.created_at,
      u.id as user_id, u.nickname, u.avatar_url
    FROM post_comments c
    JOIN users u ON c.user_id = u.id
    WHERE c.post_id = p_post_id
    ORDER BY c.created_at ASC
    LIMIT p_limit
  ) t;
  
  RETURN COALESCE(v_result, '[]'::json);
END;
$$;

-- 18. 授权 RPC 函数
GRANT EXECUTE ON FUNCTION public.create_post(BIGINT, TEXT, TEXT[], VARCHAR, VARCHAR) TO anon;
GRANT EXECUTE ON FUNCTION public.create_post(BIGINT, TEXT, TEXT[], VARCHAR, VARCHAR) TO authenticated;
GRANT EXECUTE ON FUNCTION public.toggle_like(BIGINT, BIGINT) TO anon;
GRANT EXECUTE ON FUNCTION public.toggle_like(BIGINT, BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.add_comment(BIGINT, BIGINT, TEXT, BIGINT) TO anon;
GRANT EXECUTE ON FUNCTION public.add_comment(BIGINT, BIGINT, TEXT, BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_posts(BIGINT, INT, INT, VARCHAR, VARCHAR) TO anon;
GRANT EXECUTE ON FUNCTION public.get_posts(BIGINT, INT, INT, VARCHAR, VARCHAR) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_comments(BIGINT, INT) TO anon;
GRANT EXECUTE ON FUNCTION public.get_comments(BIGINT, INT) TO authenticated;

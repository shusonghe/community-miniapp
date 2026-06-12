-- =============================================
-- 珈邻小程序 - 我的内容管理RPC
-- 执行顺序: 6
-- 功能: 查询/删除我的动态、我的闲置
-- 依赖: 04-posts-table.sql, 05-secondhand-table.sql
-- =============================================

-- 1. 查询我的动态
CREATE OR REPLACE FUNCTION public.get_my_posts(
  p_user_id BIGINT,
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
      p.id, p.content, p.images, p.location, p.topic,
      p.like_count, p.comment_count, p.created_at,
      u.id as user_id, u.nickname, u.avatar_url, u.building
    FROM posts p
    JOIN users u ON p.user_id = u.id
    WHERE p.user_id = p_user_id AND p.status = 'active'
    ORDER BY p.created_at DESC
    LIMIT p_limit OFFSET p_offset
  ) t;
  
  RETURN COALESCE(v_result, '[]'::json);
END;
$$;

-- 2. 删除动态
CREATE OR REPLACE FUNCTION public.delete_post(
  p_post_id BIGINT,
  p_user_id BIGINT
)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_owner_id BIGINT;
BEGIN
  SELECT user_id INTO v_owner_id FROM posts WHERE id = p_post_id;
  
  IF v_owner_id IS NULL THEN
    RETURN json_build_object('success', false, 'message', '动态不存在');
  END IF;
  
  IF v_owner_id != p_user_id THEN
    RETURN json_build_object('success', false, 'message', '无权删除');
  END IF;
  
  UPDATE posts SET status = 'deleted' WHERE id = p_post_id;
  
  RETURN json_build_object('success', true, 'message', '删除成功');
END;
$$;

-- 3. 查询我的闲置
CREATE OR REPLACE FUNCTION public.get_my_secondhand(
  p_user_id BIGINT,
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
      s.price, s.original_price, s.phone, s.view_count,
      s.favorite_count, s.status, s.created_at,
      u.id as user_id, u.nickname, u.avatar_url, u.building
    FROM secondhand_items s
    JOIN users u ON s.user_id = u.id
    WHERE s.user_id = p_user_id AND s.status IN ('active', 'sold')
    ORDER BY s.created_at DESC
    LIMIT p_limit OFFSET p_offset
  ) t;
  
  RETURN COALESCE(v_result, '[]'::json);
END;
$$;

-- 4. 删除闲置
CREATE OR REPLACE FUNCTION public.delete_secondhand(
  p_item_id BIGINT,
  p_user_id BIGINT
)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_owner_id BIGINT;
BEGIN
  SELECT user_id INTO v_owner_id FROM secondhand_items WHERE id = p_item_id;
  
  IF v_owner_id IS NULL THEN
    RETURN json_build_object('success', false, 'message', '商品不存在');
  END IF;
  
  IF v_owner_id != p_user_id THEN
    RETURN json_build_object('success', false, 'message', '无权删除');
  END IF;
  
  UPDATE secondhand_items SET status = 'deleted' WHERE id = p_item_id;
  
  RETURN json_build_object('success', true, 'message', '删除成功');
END;
$$;

-- 5. 更新闲置状态（已售出）
CREATE OR REPLACE FUNCTION public.update_secondhand_status(
  p_item_id BIGINT,
  p_user_id BIGINT,
  p_status VARCHAR
)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_owner_id BIGINT;
BEGIN
  SELECT user_id INTO v_owner_id FROM secondhand_items WHERE id = p_item_id;
  
  IF v_owner_id IS NULL THEN
    RETURN json_build_object('success', false, 'message', '商品不存在');
  END IF;
  
  IF v_owner_id != p_user_id THEN
    RETURN json_build_object('success', false, 'message', '无权操作');
  END IF;
  
  UPDATE secondhand_items SET status = p_status WHERE id = p_item_id;
  
  RETURN json_build_object('success', true, 'message', '更新成功');
END;
$$;

-- 6. 授权
GRANT EXECUTE ON FUNCTION public.get_my_posts(BIGINT, INT, INT) TO anon;
GRANT EXECUTE ON FUNCTION public.get_my_posts(BIGINT, INT, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_post(BIGINT, BIGINT) TO anon;
GRANT EXECUTE ON FUNCTION public.delete_post(BIGINT, BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_secondhand(BIGINT, INT, INT) TO anon;
GRANT EXECUTE ON FUNCTION public.get_my_secondhand(BIGINT, INT, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_secondhand(BIGINT, BIGINT) TO anon;
GRANT EXECUTE ON FUNCTION public.delete_secondhand(BIGINT, BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_secondhand_status(BIGINT, BIGINT, VARCHAR) TO anon;
GRANT EXECUTE ON FUNCTION public.update_secondhand_status(BIGINT, BIGINT, VARCHAR) TO authenticated;

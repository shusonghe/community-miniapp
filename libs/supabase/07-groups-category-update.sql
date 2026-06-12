-- =============================================
-- 珈邻小程序 - 组团表更新（添加类型字段）
-- 执行顺序: 7.2
-- 功能: 添加组团类型字段，更新相关RPC函数
-- 依赖: 07-groups-table.sql
-- =============================================

-- 1. 添加类型字段到 groups 表
ALTER TABLE public.groups ADD COLUMN IF NOT EXISTS category VARCHAR(20) DEFAULT 'activity';

-- 2. 创建索引
CREATE INDEX IF NOT EXISTS idx_groups_category ON public.groups(category);

-- 3. 更新发起组团 RPC（添加类型参数）
CREATE OR REPLACE FUNCTION public.create_group(
  p_user_id BIGINT,
  p_title VARCHAR,
  p_description TEXT DEFAULT '',
  p_images TEXT[] DEFAULT '{}',
  p_target_count INT DEFAULT 0,
  p_price DECIMAL DEFAULT 0,
  p_end_time TIMESTAMPTZ DEFAULT NULL,
  p_location VARCHAR DEFAULT '',
  p_contact VARCHAR DEFAULT '',
  p_category VARCHAR DEFAULT 'activity'
)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_group groups;
BEGIN
  INSERT INTO groups (user_id, title, description, images, target_count, price, end_time, location, contact, category)
  VALUES (p_user_id, p_title, p_description, p_images, p_target_count, p_price, p_end_time, p_location, p_contact, p_category)
  RETURNING * INTO v_group;
  
  RETURN json_build_object('success', true, 'message', '发起成功', 'group', row_to_json(v_group));
END;
$$;

-- 4. 更新查询组团列表 RPC（添加类型筛选）
CREATE OR REPLACE FUNCTION public.get_groups(
  p_user_id BIGINT DEFAULT NULL,
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0,
  p_category VARCHAR DEFAULT NULL
)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result JSON;
BEGIN
  SELECT json_agg(row_to_json(t)) INTO v_result
  FROM (
    SELECT g.id, g.title, g.description, g.images, g.target_count, g.current_count,
           g.price, g.end_time, g.location, g.contact, g.status, g.created_at, g.category,
           u.id as user_id, u.nickname, u.avatar_url, u.building,
           CASE WHEN p_user_id IS NOT NULL THEN
             EXISTS(SELECT 1 FROM group_members WHERE group_id = g.id AND user_id = p_user_id)
           ELSE false END as joined
    FROM groups g
    JOIN users u ON g.user_id = u.id
    WHERE g.status = 'active'
      AND (p_category IS NULL OR g.category = p_category)
    ORDER BY g.created_at DESC
    LIMIT p_limit OFFSET p_offset
  ) t;
  RETURN COALESCE(v_result, '[]'::json);
END;
$$;

-- 5. 更新查询组团详情 RPC（返回类型字段）
CREATE OR REPLACE FUNCTION public.get_group_detail(
  p_group_id BIGINT,
  p_user_id BIGINT DEFAULT NULL
)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result JSON;
BEGIN
  SELECT row_to_json(t) INTO v_result
  FROM (
    SELECT g.id, g.title, g.description, g.images, g.target_count, g.current_count,
           g.price, g.end_time, g.location, g.contact, g.status, g.created_at, g.category,
           u.id as user_id, u.nickname, u.avatar_url, u.building, u.phone,
           CASE WHEN p_user_id IS NOT NULL THEN
             EXISTS(SELECT 1 FROM group_members WHERE group_id = g.id AND user_id = p_user_id)
           ELSE false END as joined,
           g.user_id = p_user_id as is_owner
    FROM groups g
    JOIN users u ON g.user_id = u.id
    WHERE g.id = p_group_id
  ) t;
  RETURN v_result;
END;
$$;

-- 6. 重新授权 RPC 函数
GRANT EXECUTE ON FUNCTION public.create_group(BIGINT, VARCHAR, TEXT, TEXT[], INT, DECIMAL, TIMESTAMPTZ, VARCHAR, VARCHAR, VARCHAR) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_groups(BIGINT, INT, INT, VARCHAR) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_group_detail(BIGINT, BIGINT) TO anon, authenticated;

-- =============================================
-- 珈邻小程序 - 组团表更新（添加电话字段返回）
-- 执行顺序: 7.1
-- 功能: 更新 get_group_detail 和 get_group_members 函数，返回用户电话
-- 依赖: 07-groups-table.sql
-- =============================================

-- 1. 更新查询组团详情 RPC（添加发起人电话）
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
           g.price, g.end_time, g.location, g.contact, g.status, g.created_at,
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

-- 2. 更新查询参团成员 RPC（添加成员电话和楼栋）
CREATE OR REPLACE FUNCTION public.get_group_members(
  p_group_id BIGINT
)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result JSON;
BEGIN
  SELECT json_agg(row_to_json(t)) INTO v_result
  FROM (
    SELECT m.id, m.quantity, m.remark, m.created_at,
           u.id as user_id, u.nickname, u.avatar_url, u.phone, u.building
    FROM group_members m
    JOIN users u ON m.user_id = u.id
    WHERE m.group_id = p_group_id
    ORDER BY m.created_at ASC
  ) t;
  RETURN COALESCE(v_result, '[]'::json);
END;
$$;

-- 3. 重新授权 RPC 函数
GRANT EXECUTE ON FUNCTION public.get_group_detail(BIGINT, BIGINT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_group_members(BIGINT) TO anon, authenticated;

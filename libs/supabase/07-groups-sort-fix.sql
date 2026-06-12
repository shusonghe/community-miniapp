-- =============================================
-- 珈邻小程序 - 组团排序修复
-- 执行顺序: 07-groups-sort-fix
-- 功能: 修复热门活动排序，进行中的活动排在前面
-- 依赖: 07-groups-table.sql
-- =============================================

-- 更新查询组团列表 RPC，按状态和发布时间排序
-- 排序规则：进行中的活动排在前面，已结束的排在后面，同状态内按发布时间倒序
CREATE OR REPLACE FUNCTION public.get_groups(
  p_user_id BIGINT DEFAULT NULL,
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
    SELECT g.id, g.title, g.description, g.images, g.target_count, g.current_count,
           g.price, g.end_time, g.location, g.contact, g.status, g.created_at,
           u.id as user_id, u.nickname, u.avatar_url, u.building,
           CASE WHEN p_user_id IS NOT NULL THEN
             EXISTS(SELECT 1 FROM group_members WHERE group_id = g.id AND user_id = p_user_id)
           ELSE false END as joined,
           CASE WHEN g.end_time IS NULL OR g.end_time > NOW() THEN 0 ELSE 1 END as is_expired
    FROM groups g
    JOIN users u ON g.user_id = u.id
    WHERE g.status = 'active'
    ORDER BY is_expired ASC, g.created_at DESC
    LIMIT p_limit OFFSET p_offset
  ) t;
  RETURN COALESCE(v_result, '[]'::json);
END;
$$;

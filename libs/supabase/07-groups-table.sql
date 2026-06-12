-- =============================================
-- 珈邻小程序 - 组团表
-- 执行顺序: 7
-- 功能: 创建组团表、参团表、RPC函数
-- 依赖: 01-users-table.sql
-- =============================================

-- 1. 创建组团表
CREATE TABLE IF NOT EXISTS public.groups (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES public.users(id),
  title VARCHAR(100) NOT NULL,
  description TEXT DEFAULT '',
  images TEXT[] DEFAULT '{}',
  target_count INT DEFAULT 0,
  current_count INT DEFAULT 0,
  price DECIMAL(10,2) DEFAULT 0,
  end_time TIMESTAMPTZ,
  location VARCHAR(100) DEFAULT '',
  contact VARCHAR(50) DEFAULT '',
  status VARCHAR(20) DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. 创建参团表
CREATE TABLE IF NOT EXISTS public.group_members (
  id BIGSERIAL PRIMARY KEY,
  group_id BIGINT NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  user_id BIGINT NOT NULL REFERENCES public.users(id),
  quantity INT DEFAULT 1,
  remark TEXT DEFAULT '',
  status VARCHAR(20) DEFAULT 'joined',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(group_id, user_id)
);

-- 3. 创建索引
CREATE INDEX IF NOT EXISTS idx_groups_user_id ON public.groups(user_id);
CREATE INDEX IF NOT EXISTS idx_groups_status ON public.groups(status);
CREATE INDEX IF NOT EXISTS idx_groups_created_at ON public.groups(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_group_members_group_id ON public.group_members(group_id);
CREATE INDEX IF NOT EXISTS idx_group_members_user_id ON public.group_members(user_id);

-- 4. 启用 RLS
ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;

-- 5. RLS 策略 - groups
DROP POLICY IF EXISTS "允许查询组团" ON public.groups;
DROP POLICY IF EXISTS "允许插入组团" ON public.groups;
DROP POLICY IF EXISTS "允许更新组团" ON public.groups;
DROP POLICY IF EXISTS "允许删除组团" ON public.groups;

CREATE POLICY "允许查询组团" ON public.groups FOR SELECT USING (true);
CREATE POLICY "允许插入组团" ON public.groups FOR INSERT WITH CHECK (true);
CREATE POLICY "允许更新组团" ON public.groups FOR UPDATE USING (true);
CREATE POLICY "允许删除组团" ON public.groups FOR DELETE USING (true);

-- 6. RLS 策略 - group_members
DROP POLICY IF EXISTS "允许查询参团" ON public.group_members;
DROP POLICY IF EXISTS "允许插入参团" ON public.group_members;
DROP POLICY IF EXISTS "允许删除参团" ON public.group_members;

CREATE POLICY "允许查询参团" ON public.group_members FOR SELECT USING (true);
CREATE POLICY "允许插入参团" ON public.group_members FOR INSERT WITH CHECK (true);
CREATE POLICY "允许删除参团" ON public.group_members FOR DELETE USING (true);

-- 7. 更新时间触发器
DROP TRIGGER IF EXISTS groups_updated_at ON public.groups;
CREATE TRIGGER groups_updated_at
  BEFORE UPDATE ON public.groups
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- 8. 授权表
GRANT SELECT, INSERT, UPDATE, DELETE ON public.groups TO anon;
GRANT USAGE, SELECT ON SEQUENCE public.groups_id_seq TO anon;
GRANT SELECT, INSERT, DELETE ON public.group_members TO anon;
GRANT USAGE, SELECT ON SEQUENCE public.group_members_id_seq TO anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.groups TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE public.groups_id_seq TO authenticated;
GRANT SELECT, INSERT, DELETE ON public.group_members TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE public.group_members_id_seq TO authenticated;

-- 9. 创建 groups bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('groups', 'groups', true)
ON CONFLICT (id) DO NOTHING;

-- 10. Storage 策略
DROP POLICY IF EXISTS "允许上传组团图片" ON storage.objects;
DROP POLICY IF EXISTS "允许更新组团图片" ON storage.objects;
DROP POLICY IF EXISTS "允许公开访问组团图片" ON storage.objects;

CREATE POLICY "允许上传组团图片" ON storage.objects
FOR INSERT TO anon WITH CHECK (bucket_id = 'groups');

CREATE POLICY "允许更新组团图片" ON storage.objects
FOR UPDATE TO anon USING (bucket_id = 'groups');

CREATE POLICY "允许公开访问组团图片" ON storage.objects
FOR SELECT TO anon USING (bucket_id = 'groups');


-- 11. 发起组团 RPC
CREATE OR REPLACE FUNCTION public.create_group(
  p_user_id BIGINT,
  p_title VARCHAR,
  p_description TEXT DEFAULT '',
  p_images TEXT[] DEFAULT '{}',
  p_target_count INT DEFAULT 0,
  p_price DECIMAL DEFAULT 0,
  p_end_time TIMESTAMPTZ DEFAULT NULL,
  p_location VARCHAR DEFAULT '',
  p_contact VARCHAR DEFAULT ''
)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_group groups;
BEGIN
  INSERT INTO groups (user_id, title, description, images, target_count, price, end_time, location, contact)
  VALUES (p_user_id, p_title, p_description, p_images, p_target_count, p_price, p_end_time, p_location, p_contact)
  RETURNING * INTO v_group;
  
  RETURN json_build_object('success', true, 'message', '发起成功', 'group', row_to_json(v_group));
END;
$$;

-- 12. 查询组团列表 RPC
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
           ELSE false END as joined
    FROM groups g
    JOIN users u ON g.user_id = u.id
    WHERE g.status = 'active'
    ORDER BY g.created_at DESC
    LIMIT p_limit OFFSET p_offset
  ) t;
  RETURN COALESCE(v_result, '[]'::json);
END;
$$;

-- 13. 查询组团详情 RPC
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
           u.id as user_id, u.nickname, u.avatar_url, u.building,
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

-- 14. 参加组团 RPC
CREATE OR REPLACE FUNCTION public.join_group(
  p_group_id BIGINT,
  p_user_id BIGINT,
  p_quantity INT DEFAULT 1,
  p_remark TEXT DEFAULT ''
)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_group groups;
  v_exists BOOLEAN;
BEGIN
  SELECT * INTO v_group FROM groups WHERE id = p_group_id;
  IF v_group IS NULL THEN
    RETURN json_build_object('success', false, 'message', '组团不存在');
  END IF;
  IF v_group.status != 'active' THEN
    RETURN json_build_object('success', false, 'message', '组团已结束');
  END IF;
  SELECT EXISTS(SELECT 1 FROM group_members WHERE group_id = p_group_id AND user_id = p_user_id) INTO v_exists;
  IF v_exists THEN
    RETURN json_build_object('success', false, 'message', '您已参加此组团');
  END IF;
  INSERT INTO group_members (group_id, user_id, quantity, remark) VALUES (p_group_id, p_user_id, p_quantity, p_remark);
  UPDATE groups SET current_count = current_count + p_quantity WHERE id = p_group_id;
  RETURN json_build_object('success', true, 'message', '参团成功');
END;
$$;

-- 15. 退出组团 RPC
CREATE OR REPLACE FUNCTION public.leave_group(
  p_group_id BIGINT,
  p_user_id BIGINT
)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_member group_members;
BEGIN
  SELECT * INTO v_member FROM group_members WHERE group_id = p_group_id AND user_id = p_user_id;
  IF v_member IS NULL THEN
    RETURN json_build_object('success', false, 'message', '您未参加此组团');
  END IF;
  DELETE FROM group_members WHERE group_id = p_group_id AND user_id = p_user_id;
  UPDATE groups SET current_count = current_count - v_member.quantity WHERE id = p_group_id;
  RETURN json_build_object('success', true, 'message', '已退出组团');
END;
$$;


-- 16. 查询我的组团 RPC
CREATE OR REPLACE FUNCTION public.get_my_groups(
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
    SELECT g.id, g.title, g.description, g.images, g.target_count, g.current_count,
           g.price, g.end_time, g.location, g.contact, g.status, g.created_at,
           u.id as user_id, u.nickname, u.avatar_url, u.building
    FROM groups g
    JOIN users u ON g.user_id = u.id
    WHERE g.user_id = p_user_id AND g.status IN ('active', 'completed', 'closed')
    ORDER BY g.created_at DESC
    LIMIT p_limit OFFSET p_offset
  ) t;
  RETURN COALESCE(v_result, '[]'::json);
END;
$$;

-- 17. 删除组团 RPC
CREATE OR REPLACE FUNCTION public.delete_group(
  p_group_id BIGINT,
  p_user_id BIGINT
)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_owner_id BIGINT;
BEGIN
  SELECT user_id INTO v_owner_id FROM groups WHERE id = p_group_id;
  IF v_owner_id IS NULL THEN
    RETURN json_build_object('success', false, 'message', '组团不存在');
  END IF;
  IF v_owner_id != p_user_id THEN
    RETURN json_build_object('success', false, 'message', '无权删除');
  END IF;
  UPDATE groups SET status = 'deleted' WHERE id = p_group_id;
  RETURN json_build_object('success', true, 'message', '删除成功');
END;
$$;

-- 18. 更新组团状态 RPC
CREATE OR REPLACE FUNCTION public.update_group_status(
  p_group_id BIGINT,
  p_user_id BIGINT,
  p_status VARCHAR
)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_owner_id BIGINT;
BEGIN
  SELECT user_id INTO v_owner_id FROM groups WHERE id = p_group_id;
  IF v_owner_id IS NULL THEN
    RETURN json_build_object('success', false, 'message', '组团不存在');
  END IF;
  IF v_owner_id != p_user_id THEN
    RETURN json_build_object('success', false, 'message', '无权操作');
  END IF;
  UPDATE groups SET status = p_status WHERE id = p_group_id;
  RETURN json_build_object('success', true, 'message', '更新成功');
END;
$$;

-- 19. 查询参团成员 RPC
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
           u.id as user_id, u.nickname, u.avatar_url
    FROM group_members m
    JOIN users u ON m.user_id = u.id
    WHERE m.group_id = p_group_id
    ORDER BY m.created_at ASC
  ) t;
  RETURN COALESCE(v_result, '[]'::json);
END;
$$;

-- 20. 授权 RPC 函数
GRANT EXECUTE ON FUNCTION public.create_group(BIGINT, VARCHAR, TEXT, TEXT[], INT, DECIMAL, TIMESTAMPTZ, VARCHAR, VARCHAR) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_groups(BIGINT, INT, INT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_group_detail(BIGINT, BIGINT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.join_group(BIGINT, BIGINT, INT, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.leave_group(BIGINT, BIGINT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_groups(BIGINT, INT, INT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.delete_group(BIGINT, BIGINT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.update_group_status(BIGINT, BIGINT, VARCHAR) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_group_members(BIGINT) TO anon, authenticated;

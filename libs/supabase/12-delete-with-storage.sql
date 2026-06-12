-- =============================================
-- 珈邻小程序 - Storage 删除功能
-- 执行顺序: 12
-- 功能: 
--   1. 为所有 bucket 添加删除权限策略（RLS Policy）
--   2. 提供硬删除函数（可选）
-- 
-- 重要说明:
--   - 此SQL可以安全地重复执行（使用 DROP POLICY IF EXISTS）
--   - 执行后，前端删除记录时可以同步删除Storage图片
--   - 如果图片仍无法删除，请检查 bucket 是否存在
-- =============================================

-- =============================================
-- 第一部分：Storage 删除权限策略
-- 原有的 Storage 策略只有 INSERT/UPDATE/SELECT，缺少 DELETE
-- 必须添加 DELETE 策略才能通过 API 删除文件
-- =============================================

-- 1. posts bucket 删除权限（动态图片）
DROP POLICY IF EXISTS "允许删除动态图片" ON storage.objects;
CREATE POLICY "允许删除动态图片" ON storage.objects
FOR DELETE TO anon
USING (bucket_id = 'posts');

DROP POLICY IF EXISTS "允许删除动态图片_authenticated" ON storage.objects;
CREATE POLICY "允许删除动态图片_authenticated" ON storage.objects
FOR DELETE TO authenticated
USING (bucket_id = 'posts');

-- 2. secondhand bucket 删除权限（闲置图片）
DROP POLICY IF EXISTS "允许删除闲置图片" ON storage.objects;
CREATE POLICY "允许删除闲置图片" ON storage.objects
FOR DELETE TO anon
USING (bucket_id = 'secondhand');

DROP POLICY IF EXISTS "允许删除闲置图片_authenticated" ON storage.objects;
CREATE POLICY "允许删除闲置图片_authenticated" ON storage.objects
FOR DELETE TO authenticated
USING (bucket_id = 'secondhand');

-- 3. groups bucket 删除权限（组团图片）
DROP POLICY IF EXISTS "允许删除组团图片" ON storage.objects;
CREATE POLICY "允许删除组团图片" ON storage.objects
FOR DELETE TO anon
USING (bucket_id = 'groups');

DROP POLICY IF EXISTS "允许删除组团图片_authenticated" ON storage.objects;
CREATE POLICY "允许删除组团图片_authenticated" ON storage.objects
FOR DELETE TO authenticated
USING (bucket_id = 'groups');

-- 4. avatars bucket 删除权限（头像）
DROP POLICY IF EXISTS "允许删除头像" ON storage.objects;
CREATE POLICY "允许删除头像" ON storage.objects
FOR DELETE TO anon
USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "允许删除头像_authenticated" ON storage.objects;
CREATE POLICY "允许删除头像_authenticated" ON storage.objects
FOR DELETE TO authenticated
USING (bucket_id = 'avatars');

-- =============================================
-- 第二部分：验证 bucket 是否存在
-- 如果 bucket 不存在，需要先创建
-- =============================================

-- 检查并创建 posts bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('posts', 'posts', true)
ON CONFLICT (id) DO NOTHING;

-- 检查并创建 secondhand bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('secondhand', 'secondhand', true)
ON CONFLICT (id) DO NOTHING;

-- 检查并创建 groups bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('groups', 'groups', true)
ON CONFLICT (id) DO NOTHING;

-- 检查并创建 avatars bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- =============================================
-- 第三部分：硬删除函数（可选）
-- 如果需要真正删除数据库记录而非软删除，可以使用这些函数
-- =============================================

-- 1. 硬删除动态（真正删除数据库记录）
CREATE OR REPLACE FUNCTION public.hard_delete_post(
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
  
  -- 真正删除记录
  DELETE FROM posts WHERE id = p_post_id;
  
  RETURN json_build_object('success', true, 'message', '删除成功');
END;
$$;

-- 2. 硬删除闲置（真正删除数据库记录）
CREATE OR REPLACE FUNCTION public.hard_delete_secondhand(
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
  
  -- 真正删除记录
  DELETE FROM secondhand_items WHERE id = p_item_id;
  
  RETURN json_build_object('success', true, 'message', '删除成功');
END;
$$;

-- 3. 硬删除组团（真正删除数据库记录）
CREATE OR REPLACE FUNCTION public.hard_delete_group(
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
  
  -- 先删除参团记录
  DELETE FROM group_members WHERE group_id = p_group_id;
  
  -- 再删除组团记录
  DELETE FROM groups WHERE id = p_group_id;
  
  RETURN json_build_object('success', true, 'message', '删除成功');
END;
$$;

-- 4. 授权硬删除函数
GRANT EXECUTE ON FUNCTION public.hard_delete_post(BIGINT, BIGINT) TO anon;
GRANT EXECUTE ON FUNCTION public.hard_delete_post(BIGINT, BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.hard_delete_secondhand(BIGINT, BIGINT) TO anon;
GRANT EXECUTE ON FUNCTION public.hard_delete_secondhand(BIGINT, BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.hard_delete_group(BIGINT, BIGINT) TO anon;
GRANT EXECUTE ON FUNCTION public.hard_delete_group(BIGINT, BIGINT) TO authenticated;

-- =============================================
-- 使用说明：
-- 
-- 1. 在 Supabase SQL Editor 中执行此文件
-- 
-- 2. 前端删除流程（已实现）：
--    a. 用户点击删除按钮
--    b. 前端调用 storage.deleteImages(item.images) 删除Storage图片
--    c. 前端调用 delete_post/delete_secondhand/delete_group RPC 删除数据库记录
--
-- 3. 如需硬删除（真正删除数据库记录），使用：
--    hard_delete_post / hard_delete_secondhand / hard_delete_group
--
-- 4. 验证删除权限是否生效：
--    SELECT * FROM pg_policies WHERE tablename = 'objects' AND policyname LIKE '%删除%';
--
-- 5. 如果仍无法删除图片，检查：
--    - bucket 是否存在: SELECT * FROM storage.buckets;
--    - 文件是否存在: SELECT * FROM storage.objects WHERE bucket_id = 'posts';
--    - RLS 是否启用: SELECT relrowsecurity FROM pg_class WHERE relname = 'objects';
-- =============================================

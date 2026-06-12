-- =============================================
-- 珈邻小程序 - 删除组团相关所有内容
-- 先执行此脚本，再执行 07-groups-table.sql
-- =============================================

-- 1. 删除 RPC 函数
DROP FUNCTION IF EXISTS public.create_group(BIGINT, VARCHAR, TEXT, TEXT[], VARCHAR, INT, DECIMAL, TIMESTAMPTZ, VARCHAR, VARCHAR);
DROP FUNCTION IF EXISTS public.create_group(BIGINT, VARCHAR, TEXT, TEXT[], INT, DECIMAL, TIMESTAMPTZ, VARCHAR, VARCHAR);
DROP FUNCTION IF EXISTS public.get_groups(BIGINT, VARCHAR, INT, INT);
DROP FUNCTION IF EXISTS public.get_groups(BIGINT, INT, INT);
DROP FUNCTION IF EXISTS public.get_group_detail(BIGINT, BIGINT);
DROP FUNCTION IF EXISTS public.join_group(BIGINT, BIGINT, INT, TEXT);
DROP FUNCTION IF EXISTS public.leave_group(BIGINT, BIGINT);
DROP FUNCTION IF EXISTS public.get_my_groups(BIGINT, INT, INT);
DROP FUNCTION IF EXISTS public.delete_group(BIGINT, BIGINT);
DROP FUNCTION IF EXISTS public.update_group_status(BIGINT, BIGINT, VARCHAR);
DROP FUNCTION IF EXISTS public.get_group_members(BIGINT);

-- 2. 删除表（CASCADE 会自动删除触发器、索引、RLS 策略）
DROP TABLE IF EXISTS public.group_members CASCADE;
DROP TABLE IF EXISTS public.groups CASCADE;

-- 3. 删除 Storage 策略（groups bucket 相关）
DO $$
BEGIN
  DROP POLICY IF EXISTS "允许上传组团图片" ON storage.objects;
  DROP POLICY IF EXISTS "允许更新组团图片" ON storage.objects;
  DROP POLICY IF EXISTS "允许公开访问组团图片" ON storage.objects;
EXCEPTION WHEN OTHERS THEN
  NULL;
END;
$$;

-- 4. 先删除 bucket 中的所有文件，再删除 bucket
DELETE FROM storage.objects WHERE bucket_id = 'groups';
DELETE FROM storage.buckets WHERE id = 'groups';

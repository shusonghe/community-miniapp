-- =============================================
-- 珈邻小程序 - 头像存储
-- 执行顺序: 3
-- 功能: 创建avatars bucket、配置访问策略
-- =============================================

-- 1. 创建 avatars bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Storage 策略 - 允许上传头像
DROP POLICY IF EXISTS "允许上传头像" ON storage.objects;
CREATE POLICY "允许上传头像" ON storage.objects
FOR INSERT TO anon
WITH CHECK (bucket_id = 'avatars');

-- 3. Storage 策略 - 允许更新头像
DROP POLICY IF EXISTS "允许更新头像" ON storage.objects;
CREATE POLICY "允许更新头像" ON storage.objects
FOR UPDATE TO anon
USING (bucket_id = 'avatars');

-- 4. Storage 策略 - 允许公开访问头像
DROP POLICY IF EXISTS "允许公开访问头像" ON storage.objects;
CREATE POLICY "允许公开访问头像" ON storage.objects
FOR SELECT TO anon
USING (bucket_id = 'avatars');

-- 5. 授权给认证用户
DROP POLICY IF EXISTS "认证用户上传头像" ON storage.objects;
CREATE POLICY "认证用户上传头像" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'avatars');

DROP POLICY IF EXISTS "认证用户更新头像" ON storage.objects;
CREATE POLICY "认证用户更新头像" ON storage.objects
FOR UPDATE TO authenticated
USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "认证用户访问头像" ON storage.objects;
CREATE POLICY "认证用户访问头像" ON storage.objects
FOR SELECT TO authenticated
USING (bucket_id = 'avatars');

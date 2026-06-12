-- =============================================
-- 珈邻小程序 - 用户表
-- 执行顺序: 1
-- 功能: 创建用户表、索引、RLS策略、触发器
-- =============================================

-- 1. 删除旧表（如果存在）
DROP TABLE IF EXISTS public.users CASCADE;

-- 2. 创建用户表
CREATE TABLE public.users (
  id BIGSERIAL PRIMARY KEY,
  phone VARCHAR(11) UNIQUE NOT NULL,
  password VARCHAR(100) NOT NULL,
  nickname VARCHAR(50) DEFAULT '珈邻用户',
  avatar_url TEXT,
  gender VARCHAR(10) DEFAULT '',
  building VARCHAR(50) DEFAULT '',
  user_type VARCHAR(20) DEFAULT 'owner',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. 创建索引
CREATE INDEX idx_users_phone ON public.users(phone);

-- 4. 启用 RLS（行级安全）
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 5. 创建 RLS 策略 - 允许匿名访问（小程序场景需要）
DROP POLICY IF EXISTS "允许查询用户" ON public.users;
DROP POLICY IF EXISTS "允许插入用户" ON public.users;
DROP POLICY IF EXISTS "允许更新用户" ON public.users;

CREATE POLICY "允许查询用户" ON public.users FOR SELECT USING (true);
CREATE POLICY "允许插入用户" ON public.users FOR INSERT WITH CHECK (true);
CREATE POLICY "允许更新用户" ON public.users FOR UPDATE USING (true);

-- 6. 更新时间触发器
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS users_updated_at ON public.users;
CREATE TRIGGER users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- 7. 授权给匿名用户
GRANT SELECT, INSERT, UPDATE ON public.users TO anon;
GRANT USAGE, SELECT ON SEQUENCE public.users_id_seq TO anon;

-- 8. 授权给认证用户
GRANT SELECT, INSERT, UPDATE ON public.users TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE public.users_id_seq TO authenticated;

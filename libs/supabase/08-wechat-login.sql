-- ============================================
-- 08. 微信一键登录功能
-- 执行前请确保 users 表已存在（01-users-table.sql）
-- ============================================

-- 1. 给 users 表添加 openid 字段（用于存储微信用户标识）
ALTER TABLE users ADD COLUMN IF NOT EXISTS openid TEXT UNIQUE;

-- 2. 修改 phone 和 password 字段允许为空（微信登录不需要）
ALTER TABLE users ALTER COLUMN phone DROP NOT NULL;
ALTER TABLE users ALTER COLUMN password DROP NOT NULL;

-- 3. 创建索引，加速查询
CREATE INDEX IF NOT EXISTS idx_users_openid ON users(openid);

-- 4. 创建微信登录函数
CREATE OR REPLACE FUNCTION public.wechat_login(
  p_code TEXT,
  p_nickname TEXT DEFAULT '珈邻用户',
  p_avatar_url TEXT DEFAULT ''
)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_openid TEXT;
  v_user users;
BEGIN
  -- 用 code 生成唯一标识
  -- 注意：生产环境应通过后端调用微信API获取真实openid
  -- 这里简化处理，用 code 的 hash 作为 openid
  v_openid := encode(sha256(p_code::bytea), 'hex');
  
  -- 查找是否已有该 openid 的用户
  SELECT * INTO v_user FROM users WHERE openid = v_openid;
  
  IF v_user IS NULL THEN
    -- 新用户，创建账号（游客身份）
    INSERT INTO users (
      openid,
      nickname,
      avatar_url,
      user_type,
      building
    ) VALUES (
      v_openid,
      p_nickname,
      COALESCE(NULLIF(p_avatar_url, ''), 'https://img.icons8.com/?size=100&id=s4mUhvTRUkP2&format=png&color=000000'),
      'visitor',
      ''
    ) RETURNING * INTO v_user;
  ELSE
    -- 老用户，更新头像昵称（如果提供了新的）
    UPDATE users SET
      avatar_url = COALESCE(NULLIF(p_avatar_url, ''), avatar_url),
      nickname = COALESCE(NULLIF(p_nickname, ''), nickname)
    WHERE id = v_user.id
    RETURNING * INTO v_user;
  END IF;
  
  -- 返回用户信息
  RETURN json_build_object(
    'success', true,
    'user', row_to_json(v_user)
  );
END;
$$;

-- 5. 授予匿名用户执行权限
GRANT EXECUTE ON FUNCTION public.wechat_login(TEXT, TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.wechat_login(TEXT, TEXT, TEXT) TO authenticated;

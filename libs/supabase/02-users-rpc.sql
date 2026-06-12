-- =============================================
-- 珈邻小程序 - 用户RPC函数
-- 执行顺序: 2
-- 功能: 重置密码、更新用户资料
-- 依赖: 01-users-table.sql
-- =============================================

-- 1. 重置密码函数
CREATE OR REPLACE FUNCTION public.reset_password(p_phone VARCHAR, p_new_password VARCHAR)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id BIGINT;
BEGIN
  SELECT id INTO v_user_id FROM users WHERE phone = p_phone;
  
  IF v_user_id IS NULL THEN
    RETURN json_build_object('success', false, 'message', '该手机号未注册');
  END IF;
  
  UPDATE users SET password = p_new_password WHERE id = v_user_id;
  
  RETURN json_build_object('success', true, 'message', '密码重置成功');
END;
$$;

GRANT EXECUTE ON FUNCTION public.reset_password(VARCHAR, VARCHAR) TO anon;
GRANT EXECUTE ON FUNCTION public.reset_password(VARCHAR, VARCHAR) TO authenticated;

-- 2. 更新用户资料函数
CREATE OR REPLACE FUNCTION public.update_user_profile(
  p_user_id BIGINT,
  p_nickname VARCHAR DEFAULT NULL,
  p_gender VARCHAR DEFAULT NULL,
  p_building VARCHAR DEFAULT NULL,
  p_avatar_url TEXT DEFAULT NULL
)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user users;
BEGIN
  SELECT * INTO v_user FROM users WHERE id = p_user_id;
  
  IF v_user IS NULL THEN
    RETURN json_build_object('success', false, 'message', '用户不存在');
  END IF;
  
  UPDATE users SET
    nickname = COALESCE(p_nickname, nickname),
    gender = COALESCE(p_gender, gender),
    building = COALESCE(p_building, building),
    avatar_url = COALESCE(p_avatar_url, avatar_url),
    updated_at = NOW()
  WHERE id = p_user_id;
  
  SELECT * INTO v_user FROM users WHERE id = p_user_id;
  
  RETURN json_build_object(
    'success', true,
    'message', '更新成功',
    'user', row_to_json(v_user)
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.update_user_profile(BIGINT, VARCHAR, VARCHAR, VARCHAR, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.update_user_profile(BIGINT, VARCHAR, VARCHAR, VARCHAR, TEXT) TO authenticated;

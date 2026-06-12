-- =============================================
-- Tabbar 动态配置表
-- 用于控制小程序底部导航栏的显示/隐藏
-- =============================================

-- 创建 tabbar_config 表
CREATE TABLE IF NOT EXISTS public.tabbar_config (
    id SERIAL PRIMARY KEY,
    tab_key VARCHAR(50) NOT NULL UNIQUE,      -- 标识符: home, secondhand, community, group, profile
    tab_name VARCHAR(50) NOT NULL,             -- 显示名称
    icon VARCHAR(100) NOT NULL,                -- 默认图标
    selected_icon VARCHAR(100) NOT NULL,       -- 选中图标
    path VARCHAR(200) NOT NULL,                -- 页面路径
    sort_order INT NOT NULL DEFAULT 0,         -- 排序顺序
    is_visible BOOLEAN NOT NULL DEFAULT true,  -- 是否显示
    is_center BOOLEAN NOT NULL DEFAULT false,  -- 是否为中间凸起按钮
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 添加注释
COMMENT ON TABLE public.tabbar_config IS 'Tabbar动态配置表，控制底部导航栏显示';
COMMENT ON COLUMN public.tabbar_config.tab_key IS '唯一标识符';
COMMENT ON COLUMN public.tabbar_config.is_visible IS '是否显示该tab，false则隐藏';
COMMENT ON COLUMN public.tabbar_config.is_center IS '是否为中间凸起样式的按钮';

-- 插入默认数据
INSERT INTO public.tabbar_config (tab_key, tab_name, icon, selected_icon, path, sort_order, is_visible, is_center) VALUES
    ('home', '首页', 'tn-icon-home', 'tn-icon-home-fill', '/pages/index/index', 1, true, false),
    ('secondhand', '闲置', 'tn-icon-shopbag', 'tn-icon-shopbag-fill', '/pages/secondhand/secondhand', 2, true, false),
    ('community', '社区', 'tn-icon-team', 'tn-icon-team-fill', '/pages/community/community', 3, true, true),
    ('group', '组团', 'tn-icon-shop', 'tn-icon-shop-fill', '/pages/group/group', 4, true, false),
    ('profile', '我的', 'tn-icon-my', 'tn-icon-my-fill', '/pages/profile/profile', 5, true, false)
ON CONFLICT (tab_key) DO NOTHING;

-- 创建更新时间触发器
CREATE OR REPLACE FUNCTION public.update_tabbar_config_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_tabbar_config_updated_at ON public.tabbar_config;
CREATE TRIGGER trigger_tabbar_config_updated_at
    BEFORE UPDATE ON public.tabbar_config
    FOR EACH ROW
    EXECUTE FUNCTION public.update_tabbar_config_updated_at();

-- 创建获取可见tabbar配置的RPC函数
CREATE OR REPLACE FUNCTION public.get_tabbar_config()
RETURNS TABLE (
    tab_key VARCHAR(50),
    tab_name VARCHAR(50),
    icon VARCHAR(100),
    selected_icon VARCHAR(100),
    path VARCHAR(200),
    sort_order INT,
    is_center BOOLEAN
)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        t.tab_key,
        t.tab_name,
        t.icon,
        t.selected_icon,
        t.path,
        t.sort_order,
        t.is_center
    FROM tabbar_config t
    WHERE t.is_visible = true
    ORDER BY t.sort_order ASC;
END;
$$;

-- 设置RLS策略
ALTER TABLE public.tabbar_config ENABLE ROW LEVEL SECURITY;

-- 允许所有人读取
DROP POLICY IF EXISTS "Allow public read tabbar_config" ON public.tabbar_config;
CREATE POLICY "Allow public read tabbar_config" ON public.tabbar_config
    FOR SELECT USING (true);

-- 只允许管理员修改（可根据需要调整）
-- CREATE POLICY "Allow admin update tabbar_config" ON public.tabbar_config
--     FOR UPDATE USING (auth.role() = 'authenticated');

-- 授权
GRANT SELECT ON public.tabbar_config TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_tabbar_config() TO anon, authenticated;

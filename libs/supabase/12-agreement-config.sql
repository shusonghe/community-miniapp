-- =============================================
-- 用户协议与隐私政策动态配置表
-- 用于在 Supabase 后台管理协议内容
-- =============================================

-- 创建 agreement_config 表
CREATE TABLE IF NOT EXISTS public.agreement_config (
    id SERIAL PRIMARY KEY,
    agreement_type VARCHAR(20) NOT NULL UNIQUE,   -- 类型: user(用户协议), privacy(隐私政策)
    title VARCHAR(100) NOT NULL,                   -- 标题
    update_date VARCHAR(50) NOT NULL,              -- 更新日期
    content TEXT NOT NULL,                         -- 协议内容（JSON格式，包含多个章节）
    is_active BOOLEAN NOT NULL DEFAULT true,       -- 是否启用
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 添加注释
COMMENT ON TABLE public.agreement_config IS '用户协议与隐私政策配置表';
COMMENT ON COLUMN public.agreement_config.agreement_type IS '协议类型：user-用户协议，privacy-隐私政策';
COMMENT ON COLUMN public.agreement_config.title IS '协议标题';
COMMENT ON COLUMN public.agreement_config.update_date IS '协议更新日期';
COMMENT ON COLUMN public.agreement_config.content IS '协议内容，JSON格式存储章节数组';
COMMENT ON COLUMN public.agreement_config.is_active IS '是否启用该协议';

-- 插入默认用户协议
INSERT INTO public.agreement_config (agreement_type, title, update_date, content) VALUES
(
    'user',
    '珈邻用户服务协议',
    '2026年1月1日',
    '[
        {"title": "嗨，欢迎加入珈邻大家庭！", "text": "珈邻是一个温暖的邻里社区平台，我们希望每位邻居都能在这里找到归属感。在开始之前，请花几分钟了解一下我们的约定，这能帮助我们一起维护这个美好的社区。"},
        {"title": "一、我们能为您做什么", "text": "在珈邻，您可以：\n• 分享生活点滴，记录邻里温情\n• 获取社区资讯，不错过身边的精彩\n我们会不断优化服务，让您的邻里生活更便捷。"},
        {"title": "二、关于您的账号", "text": "• 请使用真实信息注册，这样邻居们才能更好地认识您\n• 妥善保管您的密码，账号安全很重要哦\n• 账号仅限本人使用，不要借给他人"},
        {"title": "三、做一个好邻居", "text": "好的社区需要大家共同维护，请您：\n• 友善交流，尊重每一位邻居\n• 发布真实、有价值的内容\n• 不发布违法、虚假或伤害他人的信息\n• 交易时诚信为本，互相体谅\n如果有人违反约定，我们可能会采取提醒、限制功能等措施，希望您理解。"},
        {"title": "四、关于内容版权", "text": "您在珈邻发布的内容，版权归您所有。同时，您授权我们在平台内展示和推广这些内容，让更多邻居看到。珈邻的品牌、设计等知识产权归我们所有。"},
        {"title": "五、温馨提示", "text": "• 邻居间的交易由双方自行协商，请注意交易安全\n• 如遇网络故障等不可抗力，服务可能暂时中断\n• 我们会尽力审核内容，但无法保证所有信息的准确性，请您自行判断"},
        {"title": "六、协议更新", "text": "随着社区发展，我们可能会更新本协议。届时会在平台公布，继续使用即表示您同意新的约定。"},
        {"title": "七、联系我们", "text": "有任何问题或建议，欢迎通过\"我的-意见反馈\"告诉我们，我们很乐意倾听您的声音！"}
    ]'
)
ON CONFLICT (agreement_type) DO UPDATE SET
    title = EXCLUDED.title,
    update_date = EXCLUDED.update_date,
    content = EXCLUDED.content,
    updated_at = NOW();

-- 插入默认隐私政策
INSERT INTO public.agreement_config (agreement_type, title, update_date, content) VALUES
(
    'privacy',
    '珈邻隐私政策',
    '2026年1月1日',
    '[
        {"title": "您的隐私，我们用心守护", "text": "珈邻深知隐私对您的重要性。这份政策将帮助您了解我们如何收集、使用和保护您的信息。请放心，我们会像保护自己的隐私一样保护您的信息。"},
        {"title": "一、我们收集哪些信息", "text": "为了给您提供更好的服务，我们会收集：\n• 注册信息：手机号、昵称、头像（用于识别您的身份）\n• 设备信息：设备型号、系统版本（用于优化使用体验）\n• 使用记录：浏览和发布的内容（用于个性化推荐）\n我们只收集必要的信息，绝不过度索取。"},
        {"title": "二、信息用途", "text": "您的信息将用于：\n• 提供和改进我们的服务\n• 验证身份，保障账号安全\n• 推送您可能感兴趣的社区动态\n未经您同意，我们不会将信息用于其他目的。"},
        {"title": "三、信息共享", "text": "我们承诺：\n• 绝不出售您的个人信息\n• 仅在您明确同意、法律要求或保护公众权益时才会共享\n• 如需共享，会提前告知您"},
        {"title": "四、信息安全", "text": "我们采取多重措施保护您的信息：\n• 数据存储在中国境内的安全服务器\n• 使用加密技术传输和存储敏感信息\n• 严格限制员工访问权限\n如果您注销账号，我们会删除或匿名化处理您的信息。"},
        {"title": "五、您的权利", "text": "您随时可以：\n• 查看和修改您的个人资料\n• 删除您发布的内容\n• 注销账号并清除数据\n• 撤回之前的授权\n这些操作可在\"后台-设置\"中完成。"},
        {"title": "六、未成年人保护", "text": "我们特别关注未成年人的隐私保护。如果您未满14周岁，请在家长陪同下使用珈邻。"},
        {"title": "七、政策更新", "text": "我们可能会更新本政策。如有重大变更，会通过弹窗等方式通知您，请留意。"},
        {"title": "八、联系我们", "text": "如果您对隐私有任何疑问，欢迎通过\"我的-意见反馈\"联系我们，我们会尽快回复！"}
    ]'
)
ON CONFLICT (agreement_type) DO UPDATE SET
    title = EXCLUDED.title,
    update_date = EXCLUDED.update_date,
    content = EXCLUDED.content,
    updated_at = NOW();

-- 创建更新时间触发器
CREATE OR REPLACE FUNCTION public.update_agreement_config_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_agreement_config_updated_at ON public.agreement_config;
CREATE TRIGGER trigger_agreement_config_updated_at
    BEFORE UPDATE ON public.agreement_config
    FOR EACH ROW
    EXECUTE FUNCTION public.update_agreement_config_updated_at();

-- 创建获取协议配置的RPC函数
CREATE OR REPLACE FUNCTION public.get_agreement_config(p_type VARCHAR(20))
RETURNS TABLE (
    agreement_type VARCHAR(20),
    title VARCHAR(100),
    update_date VARCHAR(50),
    content TEXT
)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        a.agreement_type,
        a.title,
        a.update_date,
        a.content
    FROM agreement_config a
    WHERE a.agreement_type = p_type
    AND a.is_active = true;
END;
$$;

-- 设置RLS策略
ALTER TABLE public.agreement_config ENABLE ROW LEVEL SECURITY;

-- 允许所有人读取
DROP POLICY IF EXISTS "Allow public read agreement_config" ON public.agreement_config;
CREATE POLICY "Allow public read agreement_config" ON public.agreement_config
    FOR SELECT USING (true);

-- 授权
GRANT SELECT ON public.agreement_config TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_agreement_config(VARCHAR) TO anon, authenticated;

-- =============================================
-- 珈邻小程序 - 公告表
-- 执行顺序: 11
-- 功能: 创建公告表，用于小程序审核期间展示
-- =============================================

-- 1. 创建公告表
CREATE TABLE IF NOT EXISTS public.notices (
  id BIGSERIAL PRIMARY KEY,
  title VARCHAR(200) NOT NULL,
  content TEXT NOT NULL,
  tag VARCHAR(50) DEFAULT '公告',
  status VARCHAR(20) DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. 创建索引
CREATE INDEX IF NOT EXISTS idx_notices_status ON public.notices(status);
CREATE INDEX IF NOT EXISTS idx_notices_created_at ON public.notices(created_at DESC);

-- 3. 启用 RLS
ALTER TABLE public.notices ENABLE ROW LEVEL SECURITY;

-- 4. RLS 策略
DROP POLICY IF EXISTS "允许查询公告" ON public.notices;
CREATE POLICY "允许查询公告" ON public.notices FOR SELECT USING (true);

-- 5. 更新时间触发器
DROP TRIGGER IF EXISTS notices_updated_at ON public.notices;
CREATE TRIGGER notices_updated_at
  BEFORE UPDATE ON public.notices
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- 6. 授权
GRANT SELECT ON public.notices TO anon;
GRANT SELECT ON public.notices TO authenticated;

-- 7. 插入默认公告数据
INSERT INTO public.notices (title, content, tag) VALUES
  ('关于小区电梯维护保养的通知', '尊敬的业主：为保障电梯安全运行，物业将于本周六（1月25日）上午9:00-12:00对1-3号楼电梯进行例行维护保养。届时电梯将暂停使用，请各位业主提前做好出行安排，如有不便敬请谅解。如遇紧急情况，请联系物业服务中心：400-XXX-XXXX。', '物业通知'),
  ('春节期间垃圾分类投放时间调整', '各位业主：春节期间（1月28日-2月4日），小区垃圾分类投放时间调整为每日上午7:00-9:00、下午17:00-19:00。请大家按时投放，共同维护小区环境卫生。厨余垃圾请使用专用垃圾袋，可回收物请清洗干净后投放。祝大家新春快乐！', '温馨提示'),
  ('小区停车场收费标准公示', '根据物价部门批复，现将小区停车场收费标准公示如下：地下车位月租300元/月，地上临时停车2元/小时（首小时免费）。业主车辆请办理停车卡，访客车辆请在门岗登记。为保障消防通道畅通，请勿在消防通道及绿化带停放车辆，违规停放将予以锁车处理。', '收费公示')
ON CONFLICT DO NOTHING;

-- 8. 在tabbar_config中添加公告菜单
INSERT INTO public.tabbar_config (tab_key, tab_name, icon, selected_icon, path, sort_order, is_visible, is_center) VALUES
  ('notice', '公告', 'tn-icon-notice', 'tn-icon-notice-fill', '/pages/notice/notice', 6, true, false)
ON CONFLICT (tab_key) DO UPDATE SET
  tab_name = EXCLUDED.tab_name,
  icon = EXCLUDED.icon,
  selected_icon = EXCLUDED.selected_icon,
  path = EXCLUDED.path,
  sort_order = EXCLUDED.sort_order,
  is_visible = EXCLUDED.is_visible;

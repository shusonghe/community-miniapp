-- =============================================
-- 珈邻小程序 - 修复 RLS 策略
-- 收紧策略：禁止直接表操作，只允许通过 RPC 函数
-- 执行时机：在所有表创建完成后执行
-- =============================================

-- ========== posts 表 ==========
DROP POLICY IF EXISTS "允许更新动态" ON public.posts;
DROP POLICY IF EXISTS "允许删除动态" ON public.posts;
-- 禁止直接更新/删除，必须通过 RPC
CREATE POLICY "禁止直接更新动态" ON public.posts FOR UPDATE USING (false);
CREATE POLICY "禁止直接删除动态" ON public.posts FOR DELETE USING (false);

-- ========== post_likes 表 ==========
DROP POLICY IF EXISTS "允许插入点赞" ON public.post_likes;
DROP POLICY IF EXISTS "允许删除点赞" ON public.post_likes;
-- 禁止直接操作，必须通过 toggle_like RPC
CREATE POLICY "禁止直接插入点赞" ON public.post_likes FOR INSERT WITH CHECK (false);
CREATE POLICY "禁止直接删除点赞" ON public.post_likes FOR DELETE USING (false);

-- ========== post_comments 表 ==========
DROP POLICY IF EXISTS "允许插入评论" ON public.post_comments;
DROP POLICY IF EXISTS "允许删除评论" ON public.post_comments;
-- 禁止直接操作，必须通过 add_comment RPC
CREATE POLICY "禁止直接插入评论" ON public.post_comments FOR INSERT WITH CHECK (false);
CREATE POLICY "禁止直接删除评论" ON public.post_comments FOR DELETE USING (false);

-- ========== secondhand_items 表 ==========
DROP POLICY IF EXISTS "允许更新闲置" ON public.secondhand_items;
DROP POLICY IF EXISTS "允许删除闲置" ON public.secondhand_items;
-- 禁止直接更新/删除
CREATE POLICY "禁止直接更新闲置" ON public.secondhand_items FOR UPDATE USING (false);
CREATE POLICY "禁止直接删除闲置" ON public.secondhand_items FOR DELETE USING (false);

-- ========== secondhand_favorites 表 ==========
DROP POLICY IF EXISTS "允许插入收藏" ON public.secondhand_favorites;
DROP POLICY IF EXISTS "允许删除收藏" ON public.secondhand_favorites;
-- 禁止直接操作，必须通过 toggle_favorite RPC
CREATE POLICY "禁止直接插入收藏" ON public.secondhand_favorites FOR INSERT WITH CHECK (false);
CREATE POLICY "禁止直接删除收藏" ON public.secondhand_favorites FOR DELETE USING (false);

-- ========== groups 表 ==========
DROP POLICY IF EXISTS "允许更新组团" ON public.groups;
DROP POLICY IF EXISTS "允许删除组团" ON public.groups;
-- 禁止直接更新/删除，必须通过 RPC
CREATE POLICY "禁止直接更新组团" ON public.groups FOR UPDATE USING (false);
CREATE POLICY "禁止直接删除组团" ON public.groups FOR DELETE USING (false);

-- ========== group_members 表 ==========
DROP POLICY IF EXISTS "允许插入参团" ON public.group_members;
DROP POLICY IF EXISTS "允许删除参团" ON public.group_members;
-- 禁止直接操作，必须通过 join_group/leave_group RPC
CREATE POLICY "禁止直接插入参团" ON public.group_members FOR INSERT WITH CHECK (false);
CREATE POLICY "禁止直接删除参团" ON public.group_members FOR DELETE USING (false);

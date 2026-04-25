-- Cho phép role admin (không chỉ super_admin) cập nhật system_settings — Web Admin dashboard dùng anon key + session admin.
-- Super_admin vẫn toàn quyền (policy OR).

DROP POLICY IF EXISTS system_settings_super_write ON public.system_settings;
CREATE POLICY system_settings_admin_update ON public.system_settings
  FOR UPDATE
  USING (public.is_admin() OR public.is_super_admin())
  WITH CHECK (public.is_admin() OR public.is_super_admin());

DROP POLICY IF EXISTS system_settings_super_insert ON public.system_settings;
CREATE POLICY system_settings_admin_insert ON public.system_settings
  FOR INSERT
  WITH CHECK (public.is_admin() OR public.is_super_admin());

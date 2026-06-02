-- Add missing columns and optimize RLS performance using Custom JWT Claims
-- Generated on 2026-06-02

-- =============================================================================
-- PART 1: ADD MISSING COLUMNS
-- =============================================================================

-- 1. Thêm các cột thiếu vào bảng user_scan_events
ALTER TABLE public.user_scan_events 
ADD COLUMN IF NOT EXISTS image_url text,
ADD COLUMN IF NOT EXISTS weight_grams integer DEFAULT 0,
ADD COLUMN IF NOT EXISTS co2_saved_grams numeric(10,2) DEFAULT 0.00;

-- 2. Thêm cột thiếu vào bảng collection_points
ALTER TABLE public.collection_points
ADD COLUMN IF NOT EXISTS image_url text;

-- Cập nhật comment giải thích
COMMENT ON COLUMN public.user_scan_events.image_url IS 'Đường dẫn công khai của ảnh rác đã quét lưu trên Storage.';
COMMENT ON COLUMN public.user_scan_events.weight_grams IS 'Khối lượng ước tính của vật thể quét (mặc định 100g).';
COMMENT ON COLUMN public.user_scan_events.co2_saved_grams IS 'Lượng khí CO₂ giảm thiểu nhờ phân loại rác đúng cách.';
COMMENT ON COLUMN public.collection_points.image_url IS 'Hình ảnh thực tế của điểm thu gom rác đóng góp bởi cộng đồng.';


-- =============================================================================
-- PART 2: OPTIMIZE RLS PERFORMANCE USING CUSTOM JWT CLAIMS
-- =============================================================================

-- 1. Hàm tự động đồng bộ role từ profiles vào metadata của auth.users
CREATE OR REPLACE FUNCTION public.sync_user_role_to_auth()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  UPDATE auth.users
  SET raw_app_meta_data = COALESCE(raw_app_meta_data, '{}'::jsonb) || jsonb_build_object('role', NEW.role::text)
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$;

-- Tạo trigger kích hoạt khi chèn hoặc cập nhật quyền hạn trong profiles
DROP TRIGGER IF EXISTS tr_sync_user_role ON public.profiles;
CREATE TRIGGER tr_sync_user_role
  AFTER INSERT OR UPDATE OF role ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.sync_user_role_to_auth();

-- 2. Đồng bộ hóa dữ liệu hiện tại cho tất cả user hiện có
UPDATE auth.users u
SET raw_app_meta_data = COALESCE(u.raw_app_meta_data, '{}'::jsonb) || jsonb_build_object('role', p.role::text)
FROM public.profiles p
WHERE u.id = p.id;

-- 3. Viết lại hàm current_profile_role() tối ưu hóa đọc từ JWT Claim
CREATE OR REPLACE FUNCTION public.current_profile_role()
RETURNS public.app_role
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  raw_role text;
BEGIN
  -- Đọc trực tiếp từ JWT Claim trong RAM
  raw_role := nullif(current_setting('request.jwt.claims', true), '')::jsonb -> 'app_metadata' ->> 'role';
  
  -- Fallback đọc từ DB nếu chạy trực tiếp trên Console (không qua API/JWT)
  IF raw_role IS NULL THEN
    SELECT role::text INTO raw_role FROM public.profiles WHERE id = auth.uid();
  END IF;
  
  RETURN COALESCE(raw_role, 'user')::public.app_role;
END;
$$;

-- 4. Viết lại hàm is_admin() tối ưu hóa
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.current_profile_role() IN ('admin', 'super_admin');
$$;

-- 5. Viết lại hàm is_super_admin()
CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.current_profile_role() = 'super_admin';
$$;

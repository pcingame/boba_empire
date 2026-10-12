-- Gộp dữ liệu của tài khoản CŨ (thường là tài khoản ẩn danh, đang giữ Hội/ví/BXH…) sang tài khoản
-- MỚI đăng ký bằng email. Lý do: liên kết email tạo user_id mới, nên mọi thứ gắn với user_id cũ
-- (thành viên Hội, ví Xu Chợ/Xu Hội, phụ kiện, tin đăng, dòng BXH…) ở lại tài khoản cũ.
--
-- CÁCH DÙNG (Supabase → SQL Editor, chạy bằng quyền admin):
--  1. Sửa v_old, v_email bên dưới. Giữ v_dry = true và chạy: câu lệnh luôn kết thúc bằng lỗi
--     "DRY RUN" kèm BÁO CÁO các bảng sẽ đổi — đó là bình thường, KHÔNG có gì bị thay đổi.
--  2. Xem báo cáo; nếu ổn, đổi v_dry := false rồi chạy lại để áp thật (một transaction: lỗi giữa
--     chừng thì không đổi gì).
--
-- Quy tắc xung đột (cả hai tài khoản đã có dòng cùng khóa, ví dụ cả hai đều có cloud save/BXH):
-- xử lý TỪNG DÒNG — dòng không trùng thì chuyển sang tài khoản mới; dòng trùng thì GIỮ dòng của tài
-- khoản MỚI, bỏ dòng cũ. Báo cáo ghi rõ bảng nào có dòng bị bỏ.
-- Tài khoản cũ KHÔNG bị xoá (xoá tay ở Authentication → Users nếu muốn).
do $$
declare
  v_old   uuid    := 'e47787f4-8597-4f56-bf6d-49f71b6fb7d1';
  v_email text    := 'bryn.neronesky@gmail.com';
  v_dry   boolean := true;
  v_new   uuid;
  r       record;
  n       bigint;
  rep     text := '';
  pkcmp   text;
  incl    boolean;
begin
  select id into v_new from auth.users where lower(email) = lower(v_email);
  if v_new is null then
    raise exception 'Chưa có tài khoản nào với email % — người chơi phải liên kết email trong app trước.', v_email;
  end if;
  if v_new = v_old then raise exception 'Hai user_id trùng nhau, không có gì để gộp.'; end if;
  if not exists (select 1 from auth.users where id = v_old) then
    raise exception 'Không tìm thấy tài khoản cũ %', v_old;
  end if;

  -- Mọi cột (một cột) trỏ tới auth.users(id) trong schema public + vài cột uuid không có khóa ngoại.
  for r in
    select * from (
      select c.conrelid::regclass::text as tbl, a.attname::text as col
        from pg_constraint c
        join pg_attribute a on a.attrelid = c.conrelid and a.attnum = c.conkey[1]
       where c.contype = 'f' and c.confrelid = 'auth.users'::regclass
         and c.connamespace = 'public'::regnamespace and array_length(c.conkey, 1) = 1
      union all values
        ('public.guilds', 'owner_id'), ('public.guild_messages', 'user_id'),
        ('public.guild_message_reports', 'reporter_id'), ('public.guild_message_reactions', 'user_id')
    ) x
    where to_regclass(x.tbl) is not null   -- bảng chưa tạo (SQL mới chưa chạy) thì bỏ qua
    order by 1, 2
  loop
    begin
      -- Khóa chính của bảng (nếu cột đang đổi nằm trong đó): chuyển TỪNG DÒNG không trùng với dòng
      -- sẵn có của tài khoản mới; dòng trùng thì giữ dòng MỚI, bỏ dòng cũ.
      select string_agg(format('t2.%1$I is not distinct from t.%1$I', a.attname), ' and ')
        into pkcmp
        from pg_index i
        join pg_attribute a on a.attrelid = i.indrelid and a.attnum = any (i.indkey)
       where i.indrelid = r.tbl::regclass and i.indisprimary and a.attname <> r.col;
      incl := exists (select 1 from pg_index i join pg_attribute a on a.attrelid = i.indrelid and a.attnum = any (i.indkey)
                       where i.indrelid = r.tbl::regclass and i.indisprimary and a.attname = r.col);
      if incl then
        execute format('update %1$s t set %2$I = $1 where t.%2$I = $2 and not exists (select 1 from %1$s t2 where t2.%2$I = $1%3$s)',
                       r.tbl, r.col, coalesce(' and ' || pkcmp, '')) using v_new, v_old;
        get diagnostics n = row_count;
        if n > 0 then rep := rep || format(E'\n  đổi %s dòng: %s.%s', n, r.tbl, r.col); end if;
        execute format('delete from %s where %I = $1', r.tbl, r.col) using v_old;
        get diagnostics n = row_count;
        if n > 0 then rep := rep || format(E'\n  TRÙNG, giữ dòng tài khoản MỚI, bỏ %s dòng cũ: %s.%s', n, r.tbl, r.col); end if;
      else
        execute format('update %s set %I = $1 where %I = $2', r.tbl, r.col, r.col) using v_new, v_old;
        get diagnostics n = row_count;
        if n > 0 then rep := rep || format(E'\n  đổi %s dòng: %s.%s', n, r.tbl, r.col); end if;
      end if;
    exception when unique_violation then
      -- Ràng buộc duy nhất khác khóa chính (vd tên thành viên trong hội): giữ nguyên dòng cũ, báo để xử lý tay.
      rep := rep || format(E'\n  KHÔNG CHUYỂN ĐƯỢC (vướng ràng buộc duy nhất, dòng cũ giữ nguyên): %s.%s', r.tbl, r.col);
    end;
  end loop;

  if v_dry then
    raise exception E'DRY RUN (không thay đổi gì). % -> %\nBÁO CÁO:%', v_old, v_new,
      coalesce(nullif(rep, ''), E'\n  (không có dữ liệu nào để chuyển)');
  end if;
end $$;

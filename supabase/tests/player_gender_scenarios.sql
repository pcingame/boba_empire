-- Giới tính hồ sơ: chọn/đổi/bỏ, whitelist, chặn ẩn danh/khách, tra theo tên. Chạy bằng scripts/test_lb_rewards_sql.sh.
\set ON_ERROR_STOP on
select as_u(1);
select set_player_gender('female');
select chk('chọn xong tra theo tên (không phân biệt hoa thường)', player_gender('a') = 'female');
select chk('giá trị lạ bị chặn', err_of($$select set_player_gender('x')$$) like '%invalid gender%');
select set_player_gender('other');
select chk('đổi giới tính', player_gender('A') = 'other');
select as_u(0);
select chk('khách xem được', player_gender('A') = 'other');
select chk('khách không đặt được', err_of($$select set_player_gender('male')$$) like '%permission denied%');
select chk('tên không ai dùng → rỗng', player_gender('Nobody') = '');
select chk('không đọc thẳng bảng', err_of('select * from player_genders') like '%permission denied%');
select as_u(7);
select chk('tài khoản ẩn danh bị chặn', err_of($$select set_player_gender('male')$$) like '%not linked%');
select as_u(1);
select set_player_gender('');
select chk('bỏ → rỗng', player_gender('A') = '');
\echo PLAYER GENDER OK

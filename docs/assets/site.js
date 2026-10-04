/* Landing page Boba Empire: i18n (tải từng ngôn ngữ), bảng xếp hạng, lịch sự kiện, hiệu ứng.
   Chạy `defer`. Head của index.html đã chọn ngôn ngữ (window.__LANG) và bắt đầu tải
   assets/i18n/<lang>.js từ sớm (window.__I18N_EL). Xem WEBSITE.md. */
(function () {
  'use strict';
  var NAMES = { vi: 'Tiếng Việt', en: 'English', es: 'Español', id: 'Bahasa Indonesia', pt: 'Português', th: 'ไทย', ko: '한국어' };
  var LANGS = Object.keys(NAMES);
  var API = 'https://orphyhtnaaqfglytffkn.supabase.co/rest/v1/';
  // Publishable key: công khai theo thiết kế (đã nhúng sẵn trong app), chỉ đọc qua RLS/RPC công khai.
  var KEY = 'sb_publishable_1mFXwBKzUaLm36h4WMLFuQ_3oqju0RV';
  var REDUCED = window.matchMedia && matchMedia('(prefers-reduced-motion: reduce)').matches;
  var root = document.documentElement;

  // Lịch khớp `festivals` trong lib/core/accessories.dart (UTC, [start, end)).
  var EVENTS = [
    { id: 'halloween',  em: '🦇🎃👻🧙', s: [2026, 10, 24], e: [2026, 11, 3] },
    { id: 'christmas',  em: '⛄🎄🦌🎅', s: [2026, 12, 18], e: [2026, 12, 28] },
    { id: 'new_year',   em: '🥂🎉🎆🎇', s: [2026, 12, 28], e: [2027, 1, 4] },
    { id: 'tet',        em: '🧨🧧🌼🐐', s: [2027, 1, 30],  e: [2027, 2, 10] },
    { id: 'valentine',  em: '💌🌹🍫💘', s: [2027, 2, 10],  e: [2027, 2, 16] },
    { id: 'womens_day', em: '🌷💐💄👸', s: [2027, 3, 4],   e: [2027, 3, 10] },
    { id: 'mid_autumn', em: '🥮🐇🌕🦁', s: [2027, 9, 8],   e: [2027, 9, 18] }
  ];

  // Cùng quy ước số lớn như game (lib/core/format.dart).
  var SUF = ['', 'K', 'M', 'B', 'T', 'aa', 'bb', 'cc', 'dd', 'ee', 'ff', 'gg', 'hh', 'ii', 'jj',
             'kk', 'll', 'mm', 'nn', 'oo', 'pp', 'qq', 'rr', 'ss', 'tt', 'uu', 'vv', 'ww', 'xx', 'yy', 'zz'];
  function big(n) {
    n = Number(n);
    if (!isFinite(n) || n <= 0) return '0';
    if (n < 1000) return String(Math.round(n));
    var tier = 0;
    while (n >= 1000 && tier < SUF.length - 1) { n /= 1000; tier++; }
    return n.toFixed(2) + SUF[tier];
  }
  function dur(sec) {
    var d = Math.floor(sec / 86400), h = Math.floor(sec % 86400 / 3600), m = Math.floor(sec % 3600 / 60), s = sec % 60;
    if (d) return d + 'd ' + h + 'h';
    if (h) return h + 'h ' + m + 'm';
    if (m) return m + 'm ' + s + 's';
    return s + 's';
  }
  function tpl(str, n) { return str.replace('{n}', n); }
  window.__big = big; window.__dur = dur;   // dùng lại ở extras.js
  function $(id) { return document.getElementById(id); }

  var T = window.I18N = window.I18N || {};
  var lang = window.__LANG && NAMES[window.__LANG] ? window.__LANG : 'vi';

  /* ---------- tải ngôn ngữ ---------- */
  function ready(l, cb) {
    if (T[l]) return cb();
    var el = (l === window.__LANG && window.__I18N_EL) || null;
    if (!el) { el = document.createElement('script'); el.src = 'assets/i18n/' + l + '.js'; el.async = true; document.head.appendChild(el); }
    el.addEventListener('load', function () { cb(); });
    el.addEventListener('error', function () { if (l !== 'vi') { lang = 'vi'; ready('vi', cb); } });
  }

  /* ---------- sự kiện lễ ---------- */
  function utc(a) { return Date.UTC(a[0], a[1] - 1, a[2]); }
  function fmtDate(a, last) {
    var d = new Date(utc(a) - (last ? 86400000 : 0));
    try {
      return d.toLocaleDateString(lang === 'vi' ? 'vi-VN' : lang, { day: 'numeric', month: lang === 'vi' ? 'numeric' : 'short', year: last ? 'numeric' : undefined, timeZone: 'UTC' });
    } catch (e) { return d.toISOString().slice(0, 10); }
  }
  function renderEvents() {
    var t = T[lang], now = Date.now(), nextSet = false, box = $('eventList');
    box.textContent = '';
    EVENTS.forEach(function (ev, i) {
      var cls = 'event reveal', tag = '';
      if (now >= utc(ev.s) && now < utc(ev.e)) { cls += ' live'; tag = t.live; }
      else if (now < utc(ev.s) && !nextSet) { cls += ' next'; tag = t.next; nextSet = true; }
      var d = document.createElement('div'); d.className = cls; d.style.setProperty('--d', (i % 4) * 0.07 + 's');
      var tg = document.createElement('span'); tg.className = 'tag'; tg.textContent = tag;
      var em = document.createElement('div'); em.className = 'em'; em.setAttribute('aria-hidden', 'true'); em.textContent = ev.em;
      var h = document.createElement('h3'); h.textContent = t.ev[ev.id];
      var tm = document.createElement('time'); tm.textContent = fmtDate(ev.s, false) + ' – ' + fmtDate(ev.e, true);
      d.appendChild(tg); d.appendChild(em); d.appendChild(h); d.appendChild(tm);
      box.appendChild(d); watch(d);
    });
  }


  /* ---------- đếm ngược sự kiện + hiệu ứng mùa ---------- */
  // ?event=halloween ép sự kiện đó "đang diễn ra" (để xem thử/chụp ảnh); không ảnh hưởng người dùng thường.
  var FORCE = (function () { try { return new URLSearchParams(location.search).get('event') || ''; } catch (e) { return ''; } })();
  function nowMs() { return Date.now(); }
  function pickEvent() {
    var now = nowMs(), i, ev;
    if (FORCE) for (i = 0; i < EVENTS.length; i++) if (EVENTS[i].id === FORCE) return { ev: EVENTS[i], live: true, end: nowMs() + 6 * 86400000 };
    for (i = 0; i < EVENTS.length; i++) { ev = EVENTS[i]; if (now >= utc(ev.s) && now < utc(ev.e)) return { ev: ev, live: true, end: utc(ev.e) }; }
    for (i = 0; i < EVENTS.length; i++) { ev = EVENTS[i]; if (now < utc(ev.s)) return { ev: ev, live: false, end: utc(ev.s) }; }
    return null;
  }
  function span(ms) {
    var s = Math.max(0, Math.floor(ms / 1000)), d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60);
    if (d) return d + 'd ' + h + 'h';
    if (h) return h + 'h ' + m + 'm';
    return m + 'm ' + (s % 60) + 's';
  }
  var cdTimer = null, seasonFor = '';
  function renderCountdown() {
    var el = $('countdown'), t = T[lang], pk = pickEvent();
    if (cdTimer) { clearInterval(cdTimer); cdTimer = null; }
    if (!pk) { el.hidden = true; return; }
    function tick() {
      var left = pk.end - nowMs();
      var text = (pk.live ? t.cdLive : t.cdNext).replace('{name}', t.ev[pk.ev.id]).replace('{t}', span(left));
      el.textContent = Array.from(pk.ev.em)[0] + '  ' + text;
    }
    tick(); el.hidden = false;
    cdTimer = setInterval(tick, 1000);
    // Sự kiện đang diễn ra: thả emoji của bộ phụ kiện rơi nhẹ ở hero.
    var box = $('season'), want = pk.live ? pk.ev.id : '';
    if (want !== seasonFor) {
      seasonFor = want; box.textContent = '';
      if (want && !REDUCED) {
        var em = Array.from(pk.ev.em);
        for (var i = 0; i < 14; i++) {
          var sp = document.createElement('span');
          sp.textContent = em[i % em.length];
          sp.style.left = (4 + (i * 7.1) % 92) + '%';
          sp.style.fontSize = (18 + (i * 5) % 14) + 'px';
          sp.style.animationDuration = (11 + (i * 3) % 8) + 's';
          sp.style.animationDelay = '-' + ((i * 2.3) % 14) + 's';
          box.appendChild(sp);
        }
      }
    }
  }

  /* ---------- bảng xếp hạng ---------- */
  function H() { return { apikey: KEY, Authorization: 'Bearer ' + KEY }; }
  function rpc(name) {
    return fetch(API + 'rpc/' + name, { method: 'POST', headers: Object.assign({ 'Content-Type': 'application/json' }, H()), body: JSON.stringify({ p_limit: 20 }) });
  }
  var BOARDS = [
    { id: 'income', tab: 'lbTabIncome', col: 'lbIncome',
      get: function () { return fetch(API + 'leaderboard_entries?select=nickname,lifetime_earnings,stage&order=lifetime_earnings.desc&limit=20', { headers: H() }); },
      val: function (r) { return big(r.lifetime_earnings); }, sub: function (r, t) { return tpl(t.lbStage, r.stage); } },
    { id: 'pearls', tab: 'lbTabPearls', col: 'lbPearls',
      get: function () { return rpc('m3_leaderboard_top'); },
      val: function (r) { return r.stars + ' ⭐'; }, sub: function (r, t) { return tpl(t.lbLevels, r.levels_cleared); } },
    { id: 'collection', tab: 'lbTabCollection', col: 'lbCollection',
      get: function () { return rpc('accessory_leaderboard_top'); },
      val: function (r) { return r.owned_count; }, sub: null },
    { id: 'speed', tab: 'lbTabSpeed', col: 'lbSpeed',
      get: function () { return rpc('story_speedrun_top'); },
      val: function (r) { return dur(r.complete_seconds); }, sub: null }
  ];
  var cache = {}, current = BOARDS[0].id, boardStarted = false, reqId = 0;

  function renderTabs() {
    var t = T[lang], box = $('boardTabs');
    box.textContent = '';
    BOARDS.forEach(function (b) {
      var btn = document.createElement('button');
      btn.type = 'button'; btn.className = 'tab'; btn.setAttribute('role', 'tab');
      btn.setAttribute('aria-selected', b.id === current ? 'true' : 'false');
      btn.textContent = t[b.tab];
      btn.addEventListener('click', function () { current = b.id; renderTabs(); loadBoard(); });
      box.appendChild(btn);
    });
  }
  function msg(text) {
    var box = $('boardBox'); box.textContent = '';
    var d = document.createElement('div'); d.className = 'board-msg'; d.textContent = text; box.appendChild(d);
  }
  function skeleton() {
    var box = $('boardBox'); box.textContent = '';
    for (var i = 0; i < 8; i++) { var d = document.createElement('div'); d.className = 'sk'; d.style.opacity = String(1 - i * 0.09); box.appendChild(d); }
  }
  function renderBoard(b, rows) {
    var t = T[lang], box = $('boardBox');
    if (!rows.length) return msg(t.lbEmpty);
    var table = document.createElement('table'), head = document.createElement('tr');
    [[t.lbRank, ''], [t.lbPlayer, ''], [t[b.col], 'val']].forEach(function (c) {
      var th = document.createElement('th'); th.textContent = c[0]; if (c[1]) th.className = c[1]; head.appendChild(th);
    });
    var thead = document.createElement('thead'); thead.appendChild(head); table.appendChild(thead);
    var tb = document.createElement('tbody'), medals = ['🥇', '🥈', '🥉'];
    rows.forEach(function (r, i) {
      var tr = document.createElement('tr'); tr.style.setProperty('--i', i);
      var tdR = document.createElement('td'); tdR.className = 'rank'; tdR.textContent = medals[i] || ('#' + (i + 1));
      var tdW = document.createElement('td'); tdW.className = 'who'; tdW.textContent = r.nickname || '—';
      var tdV = document.createElement('td'); tdV.className = 'val'; tdV.textContent = b.val(r);
      if (b.sub) { var s = document.createElement('span'); s.className = 'sub'; s.textContent = b.sub(r, t); tdV.appendChild(s); }
      tr.appendChild(tdR); tr.appendChild(tdW); tr.appendChild(tdV); tb.appendChild(tr);
    });
    table.appendChild(tb); box.textContent = ''; box.appendChild(table);
  }
  function loadBoard() {
    var b = BOARDS.filter(function (x) { return x.id === current; })[0], id = ++reqId;
    var c = cache[b.id];
    if (c && Date.now() - c.at < 60000) return renderBoard(b, c.rows);
    skeleton();
    b.get().then(function (res) {
      if (!res.ok) throw new Error(res.status);
      return res.json();
    }).then(function (rows) {
      cache[b.id] = { at: Date.now(), rows: rows };
      if (id === reqId) renderBoard(b, rows);   // bỏ kết quả của tab cũ nếu đã chuyển tab
    }).catch(function () { if (id === reqId) msg(T[lang].lbError); });
  }

  /* ---------- áp dụng ngôn ngữ ---------- */
  function apply() {
    var t = T[lang];
    root.lang = lang;
    document.title = t.metaTitle;
    var md = document.querySelector('meta[name="description"]'); if (md) md.setAttribute('content', t.metaDesc);
    document.querySelectorAll('[data-i18n]').forEach(function (el) {
      var v = t[el.getAttribute('data-i18n')];
      if (v == null) return;
      // figcaption có <span> con: chỉ thay nút văn bản đầu, giữ span.
      if (el.tagName === 'FIGCAPTION') el.firstChild.nodeValue = v; else el.textContent = v;
    });
    var shotLang = lang === 'ko' ? 'en' : lang;   // chưa có ảnh store tiếng Hàn
    document.querySelectorAll('img[data-shot]').forEach(function (img) {
      var src = 'assets/' + shotLang + '/' + img.getAttribute('data-shot') + '.webp';
      if (img.getAttribute('src') !== src) img.src = src;
    });
    var hv = $('heroVideo');   // vi có video giao diện tiếng Việt; các ngôn ngữ khác dùng bản tiếng Anh
    if (hv) {
      var suf = lang === 'vi' ? '-vi' : '', want = 'assets/video/gameplay' + suf + '.mp4';
      if (hv.getAttribute('src') !== want) { hv.poster = 'assets/video/poster' + suf + '.webp'; hv.src = want; hv.load(); if (hv.autoplay) hv.play().catch(function () {}); }
    }
    $('langSel').value = lang;
    renderEvents(); renderTabs(); renderCountdown();
    window.__LANG_CUR = lang; document.dispatchEvent(new CustomEvent('langchange'));
    if (boardStarted) loadBoard();
    root.className = root.className.replace(' i18n-pending', '');
  }

  /* ---------- hiệu ứng ---------- */
  var io = null;
  function watch(el) {
    if (!el.classList.contains('reveal')) return;
    if (!io) { el.classList.add('in'); return; }
    io.observe(el);
  }
  function setupReveal() {
    if (REDUCED || !('IntersectionObserver' in window)) { document.querySelectorAll('.reveal').forEach(function (e) { e.classList.add('in'); }); return; }
    io = new IntersectionObserver(function (es) {
      es.forEach(function (e) { if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); } });
    }, { rootMargin: '0px 0px -8% 0px', threshold: 0.08 });
    document.querySelectorAll('.reveal').forEach(function (e) { io.observe(e); });
  }
  function countUp(el) {
    var to = +el.getAttribute('data-count'), suf = el.getAttribute('data-suffix') || '';
    if (REDUCED || !to) return;
    var t0 = performance.now(), dur = 1100;
    (function tick(now) {
      var p = Math.min(1, (now - t0) / dur), e = 1 - Math.pow(1 - p, 3);
      el.textContent = Math.round(to * e) + (p === 1 ? suf : '');
      if (p < 1) requestAnimationFrame(tick);
    })(t0);
  }
  function setupCounters() {
    var els = document.querySelectorAll('[data-count]');
    if (REDUCED || !('IntersectionObserver' in window)) return;
    var o = new IntersectionObserver(function (es) {
      es.forEach(function (e) { if (e.isIntersecting) { countUp(e.target); o.unobserve(e.target); } });
    }, { threshold: 0.6 });
    els.forEach(function (e) { o.observe(e); });
  }
  function setupNav() {
    var nav = document.querySelector('nav'), on = false;
    window.addEventListener('scroll', function () {
      var s = window.scrollY > 8;
      if (s !== on) { on = s; nav.classList.toggle('scrolled', s); }
    }, { passive: true });
  }

  /* ---------- khởi động ---------- */
  var sel = $('langSel');
  LANGS.forEach(function (l) { var o = document.createElement('option'); o.value = l; o.textContent = NAMES[l]; sel.appendChild(o); });
  sel.addEventListener('change', function () {
    var l = sel.value;
    try { localStorage.setItem('lang', l); } catch (e) {}
    ready(l, function () { lang = l; apply(); });
  });

  // Chỉ gọi API khi người dùng cuộn gần tới mục xếp hạng.
  var boardEl = $('board');
  function start() { if (!boardStarted) { boardStarted = true; loadBoard(); } }
  if ('IntersectionObserver' in window) {
    new IntersectionObserver(function (es, o) { if (es[0].isIntersecting) { start(); o.disconnect(); } }, { rootMargin: '300px' }).observe(boardEl);
  } else { start(); }

  setupReveal(); setupCounters(); setupNav();
  ready(lang, function () { apply(); });
})();

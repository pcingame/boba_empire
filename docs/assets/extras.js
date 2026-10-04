/* Phần "vui" của landing page: mini-game chạm thử, tour cuộn, hiệu ứng khi bấm nút tải, trứng phục sinh.
   Chạy `defer` sau site.js; lấy chuỗi theo ngôn ngữ qua window.I18N[window.__LANG_CUR] và sự kiện
   'langchange'. Mọi hiệu ứng tắt khi người dùng bật "giảm chuyển động". Xem WEBSITE.md. */
(function () {
  'use strict';
  var REDUCED = window.matchMedia && matchMedia('(prefers-reduced-motion: reduce)').matches;
  var $ = function (id) { return document.getElementById(id); };
  function T() { return (window.I18N && window.I18N[window.__LANG_CUR]) || (window.I18N && window.I18N.vi) || {}; }
  function big(n) { return window.__big ? window.__big(n) : String(Math.floor(n)); }

  /* ================= mini-game chạm thử ================= */
  (function play() {
    var cup = $('pCup'); if (!cup) return;
    var coinsEl = $('pCoins'), rateEl = $('pRate'), shop = $('pShop'), floats = $('pFloats'), hint = $('pHint'), cta = $('pCta');
    // Ba nâng cấp: [giá gốc, hệ số giá, +chạm, +/giây]
    var UP = [{ base: 15, g: 1.18, tap: 1, sec: 0, key: 'playU1' },
              { base: 60, g: 1.17, tap: 0, sec: 1, key: 'playU2' },
              { base: 350, g: 1.2, tap: 0, sec: 8, key: 'playU3' }];
    var coins = 0, earned = 0, tapValue = 1, rate = 0, lv = [0, 0, 0], playedMs = 0, shown = false, running = false, last = 0;

    function cost(i) { return Math.ceil(UP[i].base * Math.pow(UP[i].g, lv[i])); }
    function buildShop() {
      var t = T(); shop.textContent = '';
      UP.forEach(function (u, i) {
        var b = document.createElement('button'); b.type = 'button'; b.className = 'up off'; b.dataset.i = i;
        var left = document.createElement('span');
        var name = document.createElement('b'); name.textContent = t[u.key] || u.key;
        var sm = document.createElement('small');
        sm.textContent = u.tap ? '+' + u.tap + ' 👆' : '+' + u.sec + (t.playPerSec || '/s');
        left.appendChild(name); left.appendChild(sm);
        var right = document.createElement('span'); right.className = 'cost';
        b.appendChild(left); b.appendChild(right); shop.appendChild(b);
      });
      paint();
    }
    function paint() {
      coinsEl.textContent = big(coins);
      rateEl.textContent = rate ? '+' + big(rate) + (T().playPerSec || '/s') : '';
      var bs = shop.children;
      for (var i = 0; i < bs.length; i++) {
        var c = cost(i), b = bs[i];
        b.querySelector('.cost').textContent = 'Lv.' + lv[i] + ' · ' + big(c);
        var off = coins < c; b.classList.toggle('off', off); b.setAttribute('aria-disabled', off ? 'true' : 'false');
      }
    }
    function float(text, x, y) {
      var f = document.createElement('span'); f.className = 'f'; f.textContent = text;
      f.style.left = x + 'px'; f.style.top = y + 'px'; floats.appendChild(f);
      setTimeout(function () { f.remove(); }, 950);
    }
    function maybeCta() {
      if (shown || (earned < 250 && playedMs < 25000)) return;
      shown = true; cta.hidden = false;
    }
    function tap(e) {
      coins += tapValue; earned += tapValue;
      var r = cup.parentNode.getBoundingClientRect(), cx = e && e.clientX ? e.clientX : r.left + r.width / 2, cy = e && e.clientY ? e.clientY : r.top + r.height / 2;
      if (!REDUCED) {
        float('+' + big(tapValue), cx - r.left + (Math.random() * 40 - 20), cy - r.top - 10);
        cup.classList.remove('pop'); void cup.offsetWidth; cup.classList.add('pop');
      }
      cup.classList.add('used'); hint.classList.add('gone');
      paint(); maybeCta();
    }
    cup.addEventListener('pointerdown', function (e) { if (e.pointerType === 'mouse' && e.button !== 0) return; tap(e); e.preventDefault(); });
    cup.addEventListener('keydown', function (e) { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); if (!e.repeat) tap(null); } });
    shop.addEventListener('click', function (e) {
      var b = e.target.closest('.up'); if (!b) return;
      var i = +b.dataset.i, c = cost(i); if (coins < c) return;
      coins -= c; lv[i]++; tapValue += UP[i].tap; rate += UP[i].sec; paint();
    });

    function frame(now) {
      if (!running) return;
      var dt = Math.min(250, now - last); last = now;
      if (rate) { var add = rate * dt / 1000; coins += add; earned += add; }
      playedMs += dt; paint(); maybeCta();
      requestAnimationFrame(frame);
    }
    function start() { if (running || document.hidden) return; running = true; last = performance.now(); requestAnimationFrame(frame); }
    function stop() { running = false; }
    // Chỉ chạy vòng lặp khi mục đang nhìn thấy và tab đang mở (tiết kiệm pin).
    if ('IntersectionObserver' in window) {
      new IntersectionObserver(function (es) { es[0].isIntersecting ? start() : stop(); }).observe($('play'));
    } else { start(); }
    document.addEventListener('visibilitychange', function () { document.hidden ? stop() : start(); });
    document.addEventListener('langchange', buildShop);
    if (window.__LANG_CUR) buildShop();
  })();

  /* ================= tour cuộn: ảnh đổi theo bước ================= */
  (function tour() {
    var steps = document.querySelectorAll('.step'), imgs = document.querySelectorAll('.tour-img');
    if (!steps.length || !('IntersectionObserver' in window)) return;
    function set(i) {
      steps.forEach(function (s, k) { s.classList.toggle('active', k === i); });
      imgs.forEach(function (m, k) { m.classList.toggle('on', k === i); });
    }
    // Bước nào đi qua "vạch giữa màn hình" thì thành bước đang xem.
    var io = new IntersectionObserver(function (es) {
      es.forEach(function (e) { if (e.isIntersecting) set(+e.target.dataset.i); });
    }, { rootMargin: '-45% 0px -45% 0px', threshold: 0 });
    steps.forEach(function (s) { io.observe(s); });
  })();

  /* ================= hạt trân châu khi bấm nút tải ================= */
  function pearlBurst(x, y) {
    for (var i = 0; i < 16; i++) {
      var p = document.createElement('span'); p.className = 'burst';
      p.style.left = (x - 6) + 'px'; p.style.top = (y - 6) + 'px'; document.body.appendChild(p);
      var a = (Math.PI * 2 * i) / 16 + Math.random() * 0.4, d = 60 + Math.random() * 70;
      var an = p.animate([{ transform: 'translate(0,0) scale(1)', opacity: 1 },
                          { transform: 'translate(' + Math.cos(a) * d + 'px,' + (Math.sin(a) * d + 40) + 'px) scale(.4)', opacity: 0 }],
                         { duration: 620 + Math.random() * 200, easing: 'cubic-bezier(.2,.7,.2,1)' });
      an.onfinish = function (el) { return function () { el.remove(); }; }(p);
    }
  }
  document.addEventListener('click', function (e) {
    var a = e.target.closest && e.target.closest('a.btn.primary[href*="apps.apple.com"]');
    if (!a || REDUCED) return;
    if (e.defaultPrevented || e.button !== 0 || e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;  // giữ hành vi mở tab mới
    e.preventDefault();
    pearlBurst(e.clientX, e.clientY);
    var href = a.href;
    setTimeout(function () { window.location.href = href; }, 380);
  });


  /* ================= video hero: chỉ chạy khi nhìn thấy; tôn trọng giảm chuyển động / tiết kiệm dữ liệu ================= */
  (function heroVideo() {
    var v = $('heroVideo'); if (!v) return;
    var saver = navigator.connection && navigator.connection.saveData;
    if (REDUCED || saver) { v.autoplay = false; v.removeAttribute('autoplay'); v.preload = 'none'; v.pause(); return; }   // chỉ hiện ảnh poster
    if (!('IntersectionObserver' in window)) return;
    new IntersectionObserver(function (es) {
      if (es[0].isIntersecting) { v.play().catch(function () {}); } else { v.pause(); }
    }, { threshold: 0.2 }).observe(v);
  })();

  /* ================= trứng phục sinh: bấm 5 lần vào logo ================= */
  (function egg() {
    var n = 0, timer = null, busy = false;
    function rain() {
      if (busy) return; busy = true;
      var list = ['🧋', '🧋', '⚫', '🧋'], done = 0, total = REDUCED ? 0 : 46;
      if (!total) { busy = false; return; }
      for (var i = 0; i < total; i++) {
        var el = document.createElement('span'); el.className = 'rain'; el.textContent = list[i % list.length];
        el.style.left = Math.random() * 100 + 'vw'; el.style.fontSize = (18 + Math.random() * 22) + 'px'; document.body.appendChild(el);
        var an = el.animate([{ transform: 'translateY(0) rotate(0)', opacity: 1 },
                             { transform: 'translateY(' + (innerHeight + 80) + 'px) rotate(' + (Math.random() * 540 - 270) + 'deg)', opacity: .9 }],
                            { duration: 1800 + Math.random() * 1800, delay: Math.random() * 1400, easing: 'cubic-bezier(.4,.1,.8,.6)', fill: 'both' });
        an.onfinish = function (e2) { return function () { e2.remove(); if (++done === total) busy = false; }; }(el);
      }
    }
    function hit(e) {
      if (e.target.closest('a')) { /* logo trong nav là link #top — vẫn đếm nhưng không chặn */ }
      n++; clearTimeout(timer); timer = setTimeout(function () { n = 0; }, 2500);
      if (n >= 5) { n = 0; rain(); }
    }
    var targets = document.querySelectorAll('.brand, .hero .icon');
    for (var i = 0; i < targets.length; i++) targets[i].addEventListener('click', hit);
  })();
})();

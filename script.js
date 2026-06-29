/* =========================================================
   アップルスタジオ 公式サイト  共通スクリプト
   - 年号の自動表示
   - モバイルナビの開閉
   - スクロール表示アニメーション
   - ギャラリーのライトボックス
   ========================================================= */

document.addEventListener("DOMContentLoaded", function () {
  // ----- フッターの年号 -----
  var yearEl = document.getElementById("year");
  if (yearEl) yearEl.textContent = new Date().getFullYear();

  // ----- モバイルナビの開閉 -----
  var toggle = document.querySelector(".nav-toggle");
  var links = document.querySelector(".nav-links");
  if (toggle && links) {
    toggle.addEventListener("click", function () {
      var open = links.classList.toggle("is-open");
      toggle.classList.toggle("is-open", open);
      toggle.setAttribute("aria-expanded", open ? "true" : "false");
    });
    // リンクを押したら閉じる
    links.querySelectorAll("a").forEach(function (a) {
      a.addEventListener("click", function () {
        links.classList.remove("is-open");
        toggle.classList.remove("is-open");
        toggle.setAttribute("aria-expanded", "false");
      });
    });
  }

  // ----- スクロール表示アニメーション -----
  var revealEls = document.querySelectorAll(".reveal");
  if ("IntersectionObserver" in window && revealEls.length) {
    var io = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          if (entry.isIntersecting) {
            entry.target.classList.add("is-visible");
            io.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.12 }
    );
    revealEls.forEach(function (el) {
      io.observe(el);
    });
  } else {
    // 非対応環境では全表示
    revealEls.forEach(function (el) {
      el.classList.add("is-visible");
    });
  }

  // ----- ギャラリーのライトボックス -----
  var gallery = document.querySelector(".gallery-grid");
  var lightbox = document.querySelector(".lightbox");
  if (gallery && lightbox) {
    var lbImg = lightbox.querySelector("img");
    var lbClose = lightbox.querySelector(".lightbox-close");

    function openLightbox(src, alt) {
      lbImg.src = src;
      lbImg.alt = alt || "";
      lightbox.classList.add("is-open");
    }
    function closeLightbox() {
      lightbox.classList.remove("is-open");
      lbImg.src = "";
    }

    gallery.addEventListener("click", function (e) {
      var item = e.target.closest(".gallery-item");
      if (!item) return;
      var img = item.querySelector("img");
      if (img) openLightbox(img.src, img.alt);
    });
    lbClose.addEventListener("click", closeLightbox);
    lightbox.addEventListener("click", function (e) {
      if (e.target === lightbox) closeLightbox();
    });
    document.addEventListener("keydown", function (e) {
      if (e.key === "Escape") closeLightbox();
    });
  }

  // ----- ロゴアニメーション -----
  // 透過アニメーションWebP(images/logo-animation.webp)を、訪問時と
  // クリック時に再生する。<img> を作り直すことで先頭から再生し、
  // 2回目以降（クリック）はネット環境のみクエリを変えて確実に再生し直す。
  var logoWrap = document.querySelector("[data-logo-anim]");
  if (logoWrap) {
    var logoImg = logoWrap.querySelector("img");
    var animSrc = logoWrap.getAttribute("data-anim");
    var stillSrc = logoWrap.getAttribute("data-still") ||
      logoImg.getAttribute("src"); // 失敗時に戻す静止ロゴ
    var reduceMotion =
      window.matchMedia &&
      window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    var isFile = location.protocol === "file:";
    var played = false;     // 一度でもアニメを読み込んだか

    // <img> を作り直してアニメを先頭から再生。失敗したら静止ロゴに戻す
    // （= ロゴが消えて alt テキストになるのを防ぐ安全網）
    function swapToAnim(src) {
      var fresh = logoImg.cloneNode(false);
      fresh.onerror = function () {
        fresh.onerror = null;
        fresh.src = stillSrc; // 読み込み失敗 → 静止ロゴ
      };
      fresh.src = src;
      logoImg.parentNode.replaceChild(fresh, logoImg);
      logoImg = fresh;
    }

    function playLogo() {
      if (reduceMotion || !animSrc) return;
      // クリックの手応え（ぽよん）。アニメ完了が分かりにくくても反応が伝わる
      logoWrap.classList.remove("is-pop");
      void logoWrap.offsetWidth; // リフローしてアニメを必ずやり直す
      logoWrap.classList.add("is-pop");

      // 初回はキャッシュ済みの素のURLで（再ダウンロードなし・描画も確実）。
      // 2回目以降はネット環境のみクエリを変えて先頭から再生し直す
      // （file:// はクエリ付きだとファイルを見つけられないので付けない）。
      var src = animSrc;
      if (played && !isFile) {
        src = animSrc + (animSrc.indexOf("?") < 0 ? "?" : "&") + "t=" + Date.now();
      }
      played = true;
      swapToAnim(src);
    }

    if (!reduceMotion && animSrc) {
      playLogo(); // 訪問時に再生
    }
    logoWrap.addEventListener("click", playLogo); // クリックで再生
  }

  // ----- メンバーの流れる表示（Top） -----
  // index.html に直接置いたカードを、ループ用にもう1セット複製する
  // （translateX(-50%) で途切れず無限スクロール）。fetch不要なので
  // ファイルを直接開いても（file://）動作する。
  var marquee = document.querySelector("[data-member-marquee]");
  if (marquee && marquee.children.length) {
    var originals = Array.prototype.slice.call(marquee.children);
    originals.forEach(function (card) {
      var clone = card.cloneNode(true);
      clone.setAttribute("aria-hidden", "true");
      marquee.appendChild(clone);
    });
    // カードをクリックしたら、メンバーページでその人の詳細を開いた状態へ移動
    marquee.addEventListener("click", function (e) {
      var card = e.target.closest(".member-card");
      if (!card) return;
      var n = card.querySelector(".member-name");
      if (n) location.href = "members.html?m=" + encodeURIComponent(n.textContent.trim());
    });
  }

  // ----- メンバー詳細（カードクリックで、行の下に枠を挟んで展開） -----
  // 画面は暗くせず、左:カード / 右:動画(X投稿) をインラインで表示する。
  var memberGrid = document.querySelector(".member-grid");
  if (memberGrid) {
    var detail = null;       // 展開中のパネル
    var currentCard = null;  // 展開中のカード

    function xUrl(s) {
      // x.com / twitter.com どちらでも、/video/1 等が付いていてもOK
      var u = s.trim().split("?")[0];
      var m = u.match(/(?:twitter\.com|x\.com)\/(\w+)\/status\/(\d+)/);
      return m ? "https://twitter.com/" + m[1] + "/status/" + m[2] : u;
    }
    // クリックされたカードの行情報（先頭/末尾カード・最下行かどうか）
    function rowInfo(card) {
      var cards = memberGrid.querySelectorAll(".member-card");
      var top = card.offsetTop;
      var maxTop = 0;
      cards.forEach(function (c) { if (c.offsetTop > maxTop) maxTop = c.offsetTop; });
      var inRow = [];
      cards.forEach(function (c) { if (Math.abs(c.offsetTop - top) < 4) inRow.push(c); });
      return {
        first: inRow[0],
        last: inRow[inRow.length - 1],
        isLastRow: Math.abs(top - maxTop) < 4
      };
    }
    function buildDetail(card) {
      var el = document.createElement("div");
      el.className = "member-detail";

      var close = document.createElement("button");
      close.className = "member-detail-close";
      close.setAttribute("aria-label", "閉じる");
      close.textContent = "×";
      close.addEventListener("click", function (e) { e.stopPropagation(); closeDetail(); });
      el.appendChild(close);

      // 左：カード（一言は消して写真＋名前のみ）
      var left = document.createElement("div");
      left.className = "member-detail-card";
      var clone = card.cloneNode(true);
      clone.classList.remove("reveal");
      var cmClone = clone.querySelector(".member-comment"); if (cmClone) cmClone.remove();
      var ntClone = clone.querySelector(".member-note"); if (ntClone) ntClone.remove();
      left.appendChild(clone);
      el.appendChild(left);

      // 右：一言（動画の上）＋ 枠で囲んだ動画
      var right = document.createElement("div");
      right.className = "member-detail-video";

      var bEl = card.querySelector(".member-comment");
      var aEl = card.querySelector(".member-note");
      var words = document.createElement("div");
      words.className = "detail-words";
      function oneLine(node) { return node ? node.innerHTML.replace(/<br\s*\/?>/gi, " ") : ""; }
      if (aEl) words.innerHTML += '<p class="detail-a">' + oneLine(aEl) + "</p>";
      if (bEl) words.innerHTML += '<p class="detail-b">' + oneLine(bEl) + "</p>";
      right.appendChild(words);

      var frame = document.createElement("div");
      frame.className = "detail-video-frame";
      var xv = card.getAttribute("data-x");
      if (xv) {
        frame.innerHTML =
          '<div class="x-embed"><blockquote class="twitter-tweet" data-media-max-width="560">' +
          '<a href="' + xUrl(xv) + '"></a></blockquote></div>';
      } else {
        frame.innerHTML = '<p class="video-soon">🎬 紹介動画は準備中です</p>';
      }
      right.appendChild(frame);
      el.appendChild(right);
      return el;
    }
    function closeDetail() {
      if (detail) { detail.remove(); detail = null; }
      currentCard = null;
    }
    function openDetail(card) {
      closeDetail();
      detail = buildDetail(card);
      currentCard = card;
      var r = rowInfo(card);
      if (r.isLastRow) {
        r.first.insertAdjacentElement("beforebegin", detail); // 最下行は上側に表示
      } else {
        r.last.insertAdjacentElement("afterend", detail);     // それ以外は行の下に表示
      }
      if (card.getAttribute("data-x") && window.twttr && window.twttr.widgets) {
        window.twttr.widgets.load(detail);
      }
      detail.scrollIntoView({ behavior: "smooth", block: "center" });
    }

    memberGrid.addEventListener("click", function (e) {
      if (e.target.closest(".member-detail")) return; // パネル内のクリックは無視
      var card = e.target.closest(".member-card");
      if (!card) return;
      if (card === currentCard) { closeDetail(); return; } // 同じカードで閉じる
      openDetail(card);
    });
    document.addEventListener("keydown", function (e) {
      if (e.key === "Escape") closeDetail();
    });

    // URLに ?m=名前 があれば、その人の詳細を開いた状態で表示（Topからの遷移用）
    var want = new URLSearchParams(location.search).get("m");
    if (want) {
      var target = Array.prototype.slice
        .call(memberGrid.querySelectorAll(".member-card"))
        .filter(function (c) {
          var n = c.querySelector(".member-name");
          return n && n.textContent.trim() === want;
        })[0];
      if (target) {
        setTimeout(function () { openDetail(target); }, 200);
      }
    }
  }
});

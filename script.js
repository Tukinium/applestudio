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
  // クリック時に再生する。クエリを変えて読み込み直すことで毎回先頭から再生。
  var logoWrap = document.querySelector("[data-logo-anim]");
  if (logoWrap) {
    var logoImg = logoWrap.querySelector("img");
    var animSrc = logoWrap.getAttribute("data-anim");
    var reduceMotion =
      window.matchMedia &&
      window.matchMedia("(prefers-reduced-motion: reduce)").matches;

    function playLogo() {
      if (reduceMotion || !animSrc) return;
      // <img> を作り直すと、キャッシュ済みの WebP を先頭から再生できる
      // （クエリ付与での再ダウンロードを避けるため同じURLを使う）
      var fresh = logoImg.cloneNode(false);
      fresh.src = animSrc;
      logoImg.parentNode.replaceChild(fresh, logoImg);
      logoImg = fresh;
    }

    if (!reduceMotion && animSrc) {
      playLogo(); // 訪問時に再生
    }
    logoWrap.addEventListener("click", playLogo); // クリックで再生
  }
});

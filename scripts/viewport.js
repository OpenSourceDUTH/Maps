(function setupVisualViewportCSSVars() {
  const root = document.documentElement;
  const vv = window.visualViewport;

  if (!vv) return;

  const update = () => {
    // Approximate keyboard overlap at the bottom of the layout viewport. Basically handle the keyboard so the website feels more like a native app and not something that drags the entire website upwards to make space and hides half of it.
    const keyboardInset = Math.max(0, window.innerHeight - vv.height - vv.offsetTop);
    root.style.setProperty("--keyboard-inset", `${keyboardInset}px`);
    root.style.setProperty("--vv-height", `${vv.height}px`);
  };

  vv.addEventListener("resize", update, { passive: true });
  vv.addEventListener("scroll", update, { passive: true });

  // Focus changes often trigger keyboard animations; nudge an update.
  window.addEventListener(
    "focusin",
    () => {
      update();
      setTimeout(update, 50);
      setTimeout(update, 250);
    },
    { passive: true }
  );
  window.addEventListener(
    "focusout",
    () => {
      update();
      setTimeout(update, 50);
      setTimeout(update, 250);
    },
    { passive: true }
  );

  update();
})();

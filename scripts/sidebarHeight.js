// Keep MapLibre controls aligned with the actual sidebar height (no guesswork).
(function setupSidebarHeightCSSVar() {
  const root = document.documentElement;
  const sidebar = document.getElementById("sidebar");
  if (!sidebar || !window.ResizeObserver) return;

  const update = () => {
    const rect = sidebar.getBoundingClientRect();
    root.style.setProperty("--sidebar-height", `${Math.max(0, rect.height)}px`);
  };

  const ro = new ResizeObserver(() => update());
  ro.observe(sidebar);
  update();
})();

// Mobile bottom-sheet resize (drag the handle). CSS `resize` is not reliable on mobile.
(function setupBottomSheetResize() {
  const sidebar = document.getElementById("sidebar");
  const handle = document.querySelector("#sidebar .sheet-handle");
  if (!sidebar || !handle) return;

  const isBottomSheetMode = () => window.matchMedia("(max-width: 800px)").matches;
  const getVVHeight = () => (window.visualViewport ? window.visualViewport.height : window.innerHeight);

  const clamp = (value, min, max) => Math.max(min, Math.min(max, value));

  // Snap points (edit these to taste)
  const SNAP_POINTS = (vvHeight) => {
    const min = 160;
    const points = [
      min,
      Math.round(vvHeight * 0.45),
      Math.round(vvHeight * 0.8),
      Math.round(vvHeight - 16)
    ];
    // remove duplicates and sort
    return Array.from(new Set(points)).sort((a, b) => a - b);
  };

  const snapToNearest = (heightPx) => {
    const vvHeight = getVVHeight();

    // Respect the actual CSS max-height so we don't pick unreachable snaps
    const cssMax = parseFloat(getComputedStyle(sidebar).getPropertyValue("max-height")) || (vvHeight - 16);
    const maxClamp = Math.max(120, Math.round(cssMax)); // final allowed max in px

    // Build usable points and clamp them into the allowed range
    let points = SNAP_POINTS(vvHeight).map(p => clamp(Math.round(p), 120, maxClamp));
    points = Array.from(new Set(points)).sort((a,b) => a - b);

    // Pick nearest as before
    let best = points[0];
    let bestDist = Math.abs(heightPx - best);
    for (const p of points) {
      const d = Math.abs(heightPx - p);
      if (d < bestDist) {
        bestDist = d;
        best = p;
      }
    }

    return clamp(best, 120, maxClamp);
  };

  let startY = 0;
  let startHeight = 0;
  let dragging = false;
  let moved = false;

  const onPointerMove = (e) => {
    if (!dragging) return;

    const dy = startY - e.clientY; // drag up => positive
    const vvHeight = getVVHeight();
    console.log('SNAP_POINTS', vvHeight, SNAP_POINTS(vvHeight));
    const minHeight = 120;
    const maxHeight = Math.max(minHeight, vvHeight - 16);
    const nextHeight = clamp(startHeight + dy, minHeight, maxHeight);

    moved = true;
    document.documentElement.style.setProperty("--mobile-sidebar-height", `${Math.round(nextHeight)}px`);
    e.preventDefault();
  };

  const endDrag = (e) => {
    if (!dragging) return;

    dragging = false;

    try {
      handle.releasePointerCapture(e.pointerId);
    } catch {}

    window.removeEventListener("pointermove", onPointerMove);
    window.removeEventListener("pointerup", endDrag);
    window.removeEventListener("pointercancel", endDrag);

    if (isBottomSheetMode() && moved) {
      const current = sidebar.getBoundingClientRect().height;
      const snapped = snapToNearest(current);

      // Small snap animation
      sidebar.style.transition = "height 160ms ease";
      document.documentElement.style.setProperty("--mobile-sidebar-height", `${Math.round(snapped)}px`);
      window.setTimeout(() => {
        sidebar.style.transition = "";
      }, 180);
    }
  };

  handle.addEventListener("pointerdown", (e) => {
    if (!isBottomSheetMode()) return;

    dragging = true;
    moved = false;
    startY = e.clientY;
    startHeight = sidebar.getBoundingClientRect().height;

    handle.setPointerCapture(e.pointerId);

    window.addEventListener("pointermove", onPointerMove, { passive: false });
    window.addEventListener("pointerup", endDrag, { passive: true });
    window.addEventListener("pointercancel", endDrag, { passive: true });

    e.preventDefault();
  });
})();

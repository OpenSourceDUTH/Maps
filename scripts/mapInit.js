(function initMap() {
  // Helper to reset sidebar state
  function resetSidebar() {
    const sidebar = document.getElementById("sidebar");
    const sidebarContent = document.getElementById("sidebar-content");

    sidebar.classList.remove("sidebar-expanded");
    sidebar.classList.remove("sidebar-expanded-mobile");
    sidebarContent.innerHTML = "";

    // Reset mobile height to default (revert to CSS)
    document.documentElement.style.removeProperty("--mobile-sidebar-height");
  }

  // Helper to expand sidebar
  function expandSidebar() {
    if (window.matchMedia("(max-width: 800px)").matches) {
      const sidebar = document.getElementById("sidebar");
      sidebar.classList.add("sidebar-expanded-mobile");
      const getVVHeight = () =>
        window.visualViewport
          ? window.visualViewport.height
          : window.innerHeight;
      const vvHeight = getVVHeight();
      // Second snap point logic
      const targetHeight = Math.round(vvHeight * 0.45);

      sidebar.style.transition = "height 250ms ease";
      document.documentElement.style.setProperty(
        "--mobile-sidebar-height",
        `${targetHeight}px`
      );

      setTimeout(() => {
        sidebar.style.transition = "";
      }, 280);
    } else {
      const sidebar = document.getElementById("sidebar");
      sidebar.classList.add("sidebar-expanded");
    }
  }

  // Setup close button listener
  const closeBtn = document.getElementById("sidebar-close-btn");
  if (closeBtn) {
    closeBtn.addEventListener("click", (e) => {
      e.stopPropagation(); // Prevent map click if button is over map
      resetSidebar();
    });
  }

  fetch("map4.json")
    .then((response) => response.json())
    .then((styleJSON) => {
      const map = new maplibregl.Map({
        container: "map",
        style: styleJSON,
        attributionControl: {
          compact: false,
          customAttribution:
            '<a href="https://opensource.cs.duth.gr" target="_blank" rel="noopener noreferrer">OpenSourceDUTH</a> | Attributions  |  Privacy',
        },
        center: [24.3457, 40.9799],
        zoom: 13,
        maxBounds: [24.374317, 40.927197, 24.383887, 40.931469],
      });

      // map.addControl(
      //   new maplibregl.NavigationControl({
      //     showCompass: false,
      //   })
      // );

      map.addControl(
        new maplibregl.GeolocateControl({
          positionOptions: {
            enableHighAccuracy: true,
          },
          trackUserLocation: true,
        })
      );

      map.on("load", () => {
        map.addSource("points", {
          type: "geojson",
          data: "points.geojson",
        });

        map.addLayer({
          id: "points-layer",
          type: "circle",
          source: "points",
          paint: {
            "circle-radius": 8,
            "circle-color": "#007cbf",
            "circle-stroke-width": 2,
            // "circle-stroke-color": "#ffffff",
          },
        });

        map.on("mouseenter", "points-layer", () => {
          map.getCanvas().style.cursor = "pointer";
        });

        map.on("mouseleave", "points-layer", () => {
          map.getCanvas().style.cursor = "";
        });

        // Handle clicks on the map
        map.on("click", (e) => {
          const features = map.queryRenderedFeatures(e.point, {
            layers: ["points-layer"],
          });

          if (features.length > 0) {
            // Clicked on a point
            const feature = features[0];
            // Keeping this here so we can possibly add a share function without sharing the URL (To keep the URL clean)
            const coordinates = feature.geometry.coordinates.slice();
            console.log(coordinates);
            const properties = feature.properties || {};

            // Build content for sidebar
            let content = "";

            if (properties.name) {
              content += `<a href="https:google.com" class="hover-underline-animation"><h1>${properties.name}</h1></a>`;
            }
            //properties.other_tags

            // Update sidebar content
            const sidebarContent = document.getElementById("sidebar-content");
            if (sidebarContent) {
              sidebarContent.innerHTML = content;
              expandSidebar();
              // Scroll to top of sidebar content
              sidebarContent.scrollTop = 0;
            }
          } else {
            resetSidebar();
          }
        });
      });
    });
})();

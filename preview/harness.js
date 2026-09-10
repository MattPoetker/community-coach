/* Shared preview harness: theme switching, mode, and the Layer 0 brand editor.
   Both preview pages load this so the switcher cannot drift between them. */
(function () {
  "use strict";

  var root = document.documentElement;

  var PRESETS = {
    /* Kiln and its two variations. */
    kiln:     { accent: [0.46, 0.098, 156], neutral: [74, 0.016],  radius: 1.5,  density: 1.08, ratio: 1.22, display: "Bricolage Grotesque", body: "Karla",             mode: "light" },
    hearth:   { accent: [0.47, 0.086, 28],  neutral: [58, 0.021],  radius: 1.0,  density: 1.12, ratio: 1.30, display: "Newsreader",          body: "Karla",             mode: "light" },
    grove:    { accent: [0.44, 0.090, 182], neutral: [95, 0.009],  radius: 0.9,  density: 1.0,  ratio: 1.24, display: "Epilogue",            body: "Figtree",           mode: "light" },
    /* The other three directions, kept for reference. */
    meridian: { accent: [0.66, 0.145, 32],  neutral: [205, 0.038], radius: 0.75, density: 1.0,  ratio: 1.28, display: "Instrument Serif",    body: "Hanken Grotesk",    mode: "dark"  },
    signal:   { accent: [0.55, 0.20, 252],  neutral: [254, 0.008], radius: 0.5,  density: 1.0,  ratio: 1.25, display: "Archivo",             body: "Schibsted Grotesk", mode: "light" },
    ledger:   { accent: [0.44, 0.135, 22],  neutral: [248, 0.005], radius: 0.25, density: 0.88, ratio: 1.18, display: "IBM Plex Sans",       body: "IBM Plex Sans",     mode: "light" }
  };

  var FONTS = {
    "Archivo": "sans-serif",
    "Bricolage Grotesque": "sans-serif",
    "Epilogue": "sans-serif",
    "Figtree": "sans-serif",
    "Hanken Grotesk": "sans-serif",
    "IBM Plex Sans": "sans-serif",
    "Instrument Serif": "serif",
    "Karla": "sans-serif",
    "Newsreader": "serif",
    "Big Shoulders Display": "sans-serif",
    "Bodoni Moda": "serif",
    "JetBrains Mono": "monospace",
    "Public Sans": "sans-serif",
    "Spectral": "serif",
    "Schibsted Grotesk": "sans-serif"
  };

  var OVERRIDES = [
    "--brand-accent-l", "--brand-accent-c", "--brand-accent-h",
    "--brand-neutral-h", "--brand-neutral-c",
    "--brand-radius-scale", "--brand-density", "--brand-type-ratio",
    "--brand-font-display", "--brand-font-body"
  ];

  var FIELDS = [
    { input: "f-hue",     out: "o-hue",     prop: "--brand-accent-h",     key: 2, from: "accent",  fmt: function (v) { return Math.round(v) + "°"; } },
    { input: "f-chroma",  out: "o-chroma",  prop: "--brand-accent-c",     key: 1, from: "accent",  fmt: function (v) { return Number(v).toFixed(3); } },
    { input: "f-light",   out: "o-light",   prop: "--brand-accent-l",     key: 0, from: "accent",  fmt: function (v) { return Number(v).toFixed(2); } },
    { input: "f-nhue",    out: "o-nhue",    prop: "--brand-neutral-h",    key: 0, from: "neutral", fmt: function (v) { return Math.round(v) + "°"; } },
    { input: "f-nchroma", out: "o-nchroma", prop: "--brand-neutral-c",    key: 1, from: "neutral", fmt: function (v) { return Number(v).toFixed(3); } },
    { input: "f-radius",  out: "o-radius",  prop: "--brand-radius-scale", from: "radius",  fmt: function (v) { return Number(v).toFixed(2) + "×"; } },
    { input: "f-density", out: "o-density", prop: "--brand-density",      from: "density", fmt: function (v) { return Number(v).toFixed(2) + "×"; } },
    { input: "f-ratio",   out: "o-ratio",   prop: "--brand-type-ratio",   from: "ratio",   fmt: function (v) { return Number(v).toFixed(2); } }
  ];

  /* Remembering the pick across the two preview pages is the whole point of the
     harness — you should be able to jump from the app to the landing page and
     still be looking at the same theme. */
  var STORE = "cc-preview-theme";
  var current = "kiln";
  try {
    var saved = localStorage.getItem(STORE);
    if (saved && PRESETS[saved]) current = saved;
  } catch (e) { /* private window, or site data blocked — the default is fine */ }


  /* The harness renders its own chrome. Both preview pages carry a single
     <div id="harness" data-page="…"> placeholder, so the switcher, the mode
     toggle and the brand editor cannot drift apart between them. */
  var PAGES = [
    { key: "index", label: "All directions", href: "index.html" },
    { key: "app", label: "Kiln · app", href: "themes.html" },
    { key: "landing", label: "Kiln · landing", href: "landing.html" },
    { key: "broadsheet", label: "Broadsheet", href: "broadsheet.html" },
    { key: "console", label: "Console", href: "console.html" },
    { key: "studio", label: "Studio", href: "studio.html" }
  ];

  var GROUPS = [
    { label: "Kiln family", keys: ["kiln", "hearth", "grove"] },
    { label: "Other directions", keys: ["meridian", "signal", "ledger"] }
  ];

  var LABELS = {
    kiln:     ["Kiln", "Control"],
    hearth:   ["Hearth", "More literary"],
    grove:    ["Grove", "More assured"],
    meridian: ["Meridian", "High-ticket"],
    signal:   ["Signal", "Performance"],
    ledger:   ["Ledger", "Practice"]
  };

  var SLIDERS = [
    ["f-hue", "o-hue", "Accent hue", 0, 360, 1],
    ["f-chroma", "o-chroma", "Accent chroma", 0, 0.28, 0.005],
    ["f-light", "o-light", "Accent lightness", 0.25, 0.85, 0.01],
    ["f-nhue", "o-nhue", "Neutral hue", 0, 360, 1],
    ["f-nchroma", "o-nchroma", "Neutral chroma", 0, 0.045, 0.001],
    ["f-radius", "o-radius", "Radius scale", 0, 2.5, 0.05],
    ["f-density", "o-density", "Density", 0.8, 1.4, 0.02],
    ["f-ratio", "o-ratio", "Type scale ratio", 1.08, 1.42, 0.01]
  ];

  function esc(value) {
    return String(value).replace(/[&<>"]/g, function (c) {
      return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c];
    });
  }

  function render() {
    var mount = document.getElementById("harness");
    if (!mount) return;
    var page = mount.dataset.page;

    /* Direction pages carry their own design language, so the theme chips do not
       apply to them — but the brand editor still does, which is the point. */
    var showChips = mount.dataset.chips !== "false";

    var groups = !showChips ? "" : GROUPS.map(function (group) {
      var chips = group.keys.map(function (key) {
        var label = LABELS[key];
        return '<button class="hz-chip" data-theme-btn="' + key + '"' +
          (key === "kiln" ? ' data-control="true"' : "") +
          ' aria-pressed="false">' + esc(label[0]) +
          "<small>" + esc(label[1]) + "</small></button>";
      }).join("");
      return '<div class="hz-group"><span class="hz-group__label">' +
        esc(group.label) + "</span>" + chips + "</div>";
    }).join('<div class="hz-divider"></div>');
    if (!showChips) groups = '<span class="hz-group__label">Direction · own layout, still brandable</span>';

    var pages = PAGES.map(function (p) {
      return '<a class="hz-btn" href="' + p.href + '"' +
        (p.key === page ? ' aria-current="page"' : "") + ">" + esc(p.label) + "</a>";
    }).join("");

    var fields = SLIDERS.map(function (s) {
      return '<div class="hz-field"><label for="' + s[0] + '">' + esc(s[2]) + "</label>" +
        '<input type="range" id="' + s[0] + '" min="' + s[3] + '" max="' + s[4] + '" step="' + s[5] + '">' +
        '<output for="' + s[0] + '" id="' + s[1] + '"></output></div>';
    }).join("");

    mount.outerHTML =
      '<header class="hz-bar">' +
        '<div class="hz-bar__brand">Theme Evaluation <span>· Community Coach</span></div>' +
        groups +
        '<div class="hz-spacer"></div>' +
        pages +
        '<button class="hz-btn" id="mode-toggle" aria-pressed="false">Dark mode</button>' +
        '<button class="hz-btn" id="editor-toggle" aria-pressed="false" aria-controls="brand-editor">Brand editor</button>' +
      "</header>" +
      '<section class="hz-editor" id="brand-editor" hidden aria-label="Brand editor">' +
        '<div class="hz-editor__grid">' + fields +
          '<div class="hz-field"><label for="f-display">Display face</label><select id="f-display"></select></div>' +
          '<div class="hz-field"><label for="f-body">Body face</label><select id="f-body"></select></div>' +
          '<div class="hz-field" style="justify-content:flex-end"><button class="hz-btn" id="reset-brand">Reset to preset</button></div>' +
        "</div>" +
        '<p class="hz-editor__note">These are the fourteen brand inputs stored in ' +
        "<code>communities.branding</code>. Everything below is derived from them. In production " +
        "the same values compile to a <code>&lt;style&gt;</code> block via " +
        "<code>Branding::TokenCompiler</code> — no rebuild, no deploy.</p>" +
      "</section>";
  }

  render();

  function presetValue(field) {
    var preset = PRESETS[current];
    var source = preset[field.from];
    return Array.isArray(source) ? source[field.key] : source;
  }

  function clearOverrides() {
    OVERRIDES.forEach(function (name) { root.style.removeProperty(name); });
  }

  function syncControls() {
    if (!document.getElementById("f-hue")) return;
    FIELDS.forEach(function (field) {
      var input = document.getElementById(field.input);
      input.value = presetValue(field);
      document.getElementById(field.out).textContent = field.fmt(input.value);
    });
    document.getElementById("f-display").value = PRESETS[current].display;
    document.getElementById("f-body").value = PRESETS[current].body;
  }

  function setMode(mode) {
    root.dataset.mode = mode;
    var btn = document.getElementById("mode-toggle");
    if (!btn) return;
    btn.setAttribute("aria-pressed", String(mode === "dark"));
    btn.textContent = mode === "dark" ? "Light mode" : "Dark mode";
  }

  function setTheme(key) {
    current = key;
    root.dataset.theme = key;
    try { localStorage.setItem(STORE, key); } catch (e) { /* non-fatal */ }
    document.querySelectorAll("[data-theme-btn]").forEach(function (btn) {
      btn.setAttribute("aria-pressed", String(btn.dataset.themeBtn === key));
    });
    clearOverrides();
    setMode(PRESETS[key].mode);
    syncControls();
  }

  document.querySelectorAll("[data-theme-btn]").forEach(function (btn) {
    btn.addEventListener("click", function () { setTheme(btn.dataset.themeBtn); });
  });

  var modeBtn = document.getElementById("mode-toggle");
  if (modeBtn) {
    modeBtn.addEventListener("click", function () {
      setMode(root.dataset.mode === "dark" ? "light" : "dark");
    });
  }

  var editor = document.getElementById("brand-editor");
  var editorBtn = document.getElementById("editor-toggle");
  if (editor && editorBtn) {
    editorBtn.addEventListener("click", function () {
      var open = editor.hidden;
      editor.hidden = !open;
      this.setAttribute("aria-pressed", String(open));
    });

    ["f-display", "f-body"].forEach(function (id) {
      var select = document.getElementById(id);
      Object.keys(FONTS).forEach(function (family) {
        var option = document.createElement("option");
        option.value = family;
        option.textContent = family;
        select.appendChild(option);
      });
    });

    FIELDS.forEach(function (field) {
      document.getElementById(field.input).addEventListener("input", function () {
        root.style.setProperty(field.prop, this.value);
        document.getElementById(field.out).textContent = field.fmt(this.value);
      });
    });

    function applyFont(role, family) {
      root.style.setProperty("--brand-font-" + role, '"' + family + '", ' + FONTS[family]);
    }
    document.getElementById("f-display").addEventListener("change", function () { applyFont("display", this.value); });
    document.getElementById("f-body").addEventListener("change", function () { applyFont("body", this.value); });

    document.getElementById("reset-brand").addEventListener("click", function () {
      clearOverrides();
      syncControls();
    });
  }

  var mountEl = document.querySelector("[data-chips]");
  if (document.getElementById("mode-toggle") && root.dataset.direction) {
    /* A direction owns its default mode; the harness only reflects and toggles it. */
    setMode(root.dataset.mode || "light");
    syncControls();
  } else {
    setTheme(current);
  }
})();

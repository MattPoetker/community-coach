"use client";

import { useEffect, useState, useTransition } from "react";
import { updateBranding } from "@/lib/actions";

/**
 * The whitelabel surface: fourteen values that compile to the whole interface.
 *
 * Changes preview live by writing the Layer 0 custom properties straight onto the document,
 * because the ramps derive in CSS — the browser does the work, so there is no round trip
 * between moving a slider and seeing the result. Saving persists the same values, which
 * Branding::TokenCompiler then validates, contrast-checks and emits on the next load.
 */

type Branding = Record<string, unknown>;

const PRESETS = [
  { key: "kiln", name: "Kiln", hint: "Warm and relational", accent: "oklch(0.46 0.098 156)" },
  { key: "hearth", name: "Hearth", hint: "Literary and calm", accent: "oklch(0.47 0.086 28)" },
  { key: "grove", name: "Grove", hint: "Assured and contemporary", accent: "oklch(0.44 0.09 182)" },
  { key: "meridian", name: "Meridian", hint: "High-ticket", accent: "oklch(0.52 0.155 32)" },
  { key: "signal", name: "Signal", hint: "Performance", accent: "oklch(0.55 0.2 252)" },
  { key: "ledger", name: "Ledger", hint: "Professional practice", accent: "oklch(0.44 0.135 22)" },
];

const SLIDERS = [
  { key: "accentHue", prop: "--brand-accent-h", label: "Accent hue", min: 0, max: 360, step: 1, unit: "°" },
  { key: "accentChroma", prop: "--brand-accent-c", label: "Accent intensity", min: 0, max: 0.28, step: 0.005, unit: "" },
  { key: "accentLightness", prop: "--brand-accent-l", label: "Accent lightness", min: 0.25, max: 0.85, step: 0.01, unit: "" },
  { key: "radiusScale", prop: "--brand-radius-scale", label: "Corner roundness", min: 0, max: 2.5, step: 0.05, unit: "×" },
  { key: "density", prop: "--brand-density", label: "Spacing", min: 0.8, max: 1.4, step: 0.02, unit: "×" },
] as const;

const DEFAULTS: Record<string, number> = {
  accentHue: 156,
  accentChroma: 0.098,
  accentLightness: 0.46,
  radiusScale: 1.5,
  density: 1.08,
};

export function BrandingEditor({ branding }: { branding: Branding }) {
  const [preset, setPreset] = useState(String(branding.preset ?? "kiln"));
  const [values, setValues] = useState<Record<string, number>>(() => readInitial(branding));
  const [saved, setSaved] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [pending, startTransition] = useTransition();

  // Live preview. Inline properties on <html> beat the stylesheet, which is the same
  // precedence the compiled <style> block relies on in production.
  useEffect(() => {
    const root = document.documentElement;
    SLIDERS.forEach((slider) => root.style.setProperty(slider.prop, String(values[slider.key])));
    return () => SLIDERS.forEach((slider) => root.style.removeProperty(slider.prop));
  }, [values]);

  function save() {
    setError(null);
    setSaved(false);
    startTransition(async () => {
      const result = await updateBranding({
        preset,
        accent: {
          l: values.accentLightness,
          c: values.accentChroma,
          h: values.accentHue,
        },
        structure: { radiusScale: values.radiusScale, density: values.density },
      });
      if (result.ok) setSaved(true);
      else setError(result.error);
    });
  }

  return (
    <section className="card stack">
      <div>
        <div className="u-label">Branding</div>
        <p className="u-secondary" style={{ fontSize: "var(--text-sm)", marginTop: "var(--space-2)" }}>
          Changes preview here immediately. Save to make them live for everyone.
        </p>
      </div>

      {error && <p className="form-error" role="alert">{error}</p>}

      <div className="field">
        <label htmlFor="preset">Starting point</label>
        <div className="swatch-row" role="group" aria-label="Preset">
          {PRESETS.map((option) => (
            <button
              key={option.key}
              type="button"
              className="swatch"
              title={`${option.name} — ${option.hint}`}
              aria-label={`${option.name}, ${option.hint}`}
              aria-pressed={preset === option.key}
              style={{ background: option.accent }}
              onClick={() => setPreset(option.key)}
            />
          ))}
        </div>
        <span className="u-meta">
          {PRESETS.find((option) => option.key === preset)?.name} ·{" "}
          {PRESETS.find((option) => option.key === preset)?.hint}
        </span>
      </div>

      {SLIDERS.map((slider) => (
        <div className="field" key={slider.key}>
          <div className="row row--between">
            <label htmlFor={slider.key}>{slider.label}</label>
            <span className="u-meta">
              {format(values[slider.key], slider.step)}{slider.unit}
            </span>
          </div>
          <input
            id={slider.key}
            type="range"
            min={slider.min}
            max={slider.max}
            step={slider.step}
            value={values[slider.key]}
            onChange={(event) =>
              setValues((current) => ({ ...current, [slider.key]: Number(event.target.value) }))
            }
          />
        </div>
      ))}

      <div className="row row--between">
        <button className="btn btn--ghost" type="button"
                onClick={() => setValues({ ...DEFAULTS })} disabled={pending}>
          Reset
        </button>
        <div className="row" style={{ gap: "var(--space-3)" }}>
          {saved && <span className="u-meta" role="status">Saved and live.</span>}
          <button className="btn btn--primary" type="button" onClick={save} disabled={pending}>
            {pending ? "Saving…" : "Save branding"}
          </button>
        </div>
      </div>

      <p className="u-meta">
        Contrast is checked when this saves. If an accent cannot carry legible text, it is
        nudged until it can and you are told — the hue you picked is kept.
      </p>
    </section>
  );
}

function readInitial(branding: Branding): Record<string, number> {
  const accent = (branding.accent ?? {}) as Record<string, number>;
  const structure = (branding.structure ?? {}) as Record<string, number>;
  return {
    accentHue: accent.h ?? DEFAULTS.accentHue,
    accentChroma: accent.c ?? DEFAULTS.accentChroma,
    accentLightness: accent.l ?? DEFAULTS.accentLightness,
    radiusScale: structure.radiusScale ?? DEFAULTS.radiusScale,
    density: structure.density ?? DEFAULTS.density,
  };
}

function format(value: number, step: number) {
  return step >= 1 ? Math.round(value) : value.toFixed(step < 0.01 ? 3 : 2);
}

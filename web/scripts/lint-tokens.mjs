#!/usr/bin/env node
/**
 * Fails if a component stylesheet reaches past the token contract.
 *
 * The whole whitelabel guarantee rests on components consuming Layer 2/3 tokens only.
 * That is easy to state and easy to forget at 6pm, so it is checked here instead.
 */
import { readFileSync, readdirSync, statSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { join } from "node:path";

const STYLE_DIR = fileURLToPath(new URL("../styles/", import.meta.url));

/** Files that are allowed to contain literals — they *define* the contract. */
const CONTRACT_FILES = new Set([
  "tokens.css",
  "themes.css",
  // Directions set their own Layer 0 defaults and their own component anatomy, so they
  // are allowed the same literals themes.css is. They still may not hardcode colour.
  "directions/broadsheet.css",
  "directions/console.css",
  "directions/studio.css",
]);

const RULES = [
  { name: "raw hex colour", re: /#[0-9a-fA-F]{3,8}\b/ },
  { name: "raw rgb()/hsl() colour", re: /\b(?:rgba?|hsla?)\s*\(/ },
  { name: "raw oklch() colour", re: /\boklch\s*\(/ },
  { name: "hardcoded px radius", re: /border-radius:\s*[^;]*\d+px/ },
  { name: "Layer 0 token in a component", re: /var\(\s*--brand-(?!font)/ },
  { name: "Layer 1 ramp in a component", re: /var\(\s*--[an]-\d/ },
];

/** Exemptions. Empty, and worth keeping that way — every case so far was a missing
 *  Layer 3 token rather than a genuine exception. */
const EXEMPT = [];

let failures = 0;

function cssFiles(dir, prefix = "") {
  return readdirSync(dir).flatMap((entry) => {
    const full = join(dir, entry);
    if (statSync(full).isDirectory()) return cssFiles(full, prefix + entry + "/");
    return entry.endsWith(".css") ? [{ name: prefix + entry, path: full }] : [];
  });
}

for (const { name: file, path: fullPath } of cssFiles(STYLE_DIR)) {
  if (CONTRACT_FILES.has(file)) continue;

  const lines = readFileSync(fullPath, "utf8").split("\n");
  let inComment = false;

  lines.forEach((line, i) => {
    const trimmed = line.trim();
    if (inComment) {
      if (trimmed.includes("*/")) inComment = false;
      return;
    }
    if (trimmed.startsWith("/*")) {
      if (!trimmed.includes("*/")) inComment = true;
      return;
    }

    const fontValue = /font-family:\s*([^;]+)/.exec(line);
    if (fontValue && !fontValue[1].trim().startsWith("var(")) {
      failures++;
      console.error(`${file}:${i + 1}  hardcoded font family: ${fontValue[1].trim()}\n    ${trimmed}\n    -> use var(--font-display|body|mono) or a Layer 3 font token.`);
    }

    for (const rule of RULES) {
      const hit = rule.re.exec(line);
      if (!hit) continue;

      const exempt = EXEMPT.some(
        (e) => e.file === file && e.rule === rule.name && line.includes(e.match)
      );
      if (exempt) continue;

      failures++;
      console.error(
        `${file}:${i + 1}  ${rule.name}: ${hit[0].trim()}\n` +
          `    ${trimmed}\n` +
          `    -> use a Layer 2 or Layer 3 token. See docs/DESIGN_SYSTEM.md.`
      );
    }
  });
}

if (failures > 0) {
  console.error(`\n${failures} token-contract violation${failures === 1 ? "" : "s"}.`);
  process.exit(1);
}
console.log("Token contract clean.");

// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Allen Sanborn
// Runs sync-plugin-version.mjs against a throwaway repo. `npm test` (node --test).

import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdirSync, mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const script = join(dirname(fileURLToPath(import.meta.url)), "sync-plugin-version.mjs");

function repo(pkgVersion, pluginSource) {
  const dir = mkdtempSync(join(tmpdir(), "sync-version-"));
  mkdirSync(join(dir, ".claude-plugin"));
  writeFileSync(join(dir, "package.json"), JSON.stringify({ version: pkgVersion }));
  writeFileSync(join(dir, ".claude-plugin", "plugin.json"), pluginSource);
  const run = (...args) =>
    spawnSync(process.execPath, [script, ...args], { cwd: dir, encoding: "utf8" });
  const plugin = () => readFileSync(join(dir, ".claude-plugin", "plugin.json"), "utf8");
  return { run, plugin };
}

const plugin = (v) => `{\n  "name": "x",\n  "version": "${v}",\n  "skills": ["./a"]\n}\n`;

test("in sync: exits 0 and changes nothing", () => {
  const r = repo("1.2.3", plugin("1.2.3"));
  assert.equal(r.run().status, 0);
  assert.equal(r.run("--check").status, 0);
  assert.equal(r.plugin(), plugin("1.2.3"));
});

test("--check on a mismatch: exits 1 and changes nothing", () => {
  const r = repo("1.3.0", plugin("1.2.3"));
  const out = r.run("--check");
  assert.equal(out.status, 1);
  assert.match(out.stderr, /plugin\.json version is 1\.2\.3, package\.json is 1\.3\.0/);
  assert.equal(r.plugin(), plugin("1.2.3"));
});

test("sync on a mismatch: rewrites only the version, keeping the formatting", () => {
  const r = repo("1.3.0", plugin("1.2.3"));
  assert.equal(r.run().status, 0);
  assert.equal(r.plugin(), plugin("1.3.0"));
});

test("no version field to replace: exits 1 and changes nothing", () => {
  const source = `{ "name": "x" }\n`;
  const r = repo("1.3.0", source);
  const out = r.run();
  assert.equal(out.status, 1);
  assert.match(out.stderr, /Could not find a version field/);
  assert.equal(r.plugin(), source);
});

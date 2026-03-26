#!/usr/bin/env bun
/**
 * Bun entrypoint for interactive setup — runs scripts/setup.sh with inherited stdio
 * so prompts (hidden API key) work as in a normal terminal.
 *
 *   bun run setup
 *   bun scripts/setup.ts
 */

import { spawnSync } from "node:child_process";
import { join } from "node:path";

const repoRoot = join(import.meta.dir, "..");
const setupSh = join(repoRoot, "scripts", "setup.sh");

const result = spawnSync("bash", [setupSh], {
    cwd: repoRoot,
    stdio: "inherit",
    env: process.env,
});

process.exit(result.status ?? 1);

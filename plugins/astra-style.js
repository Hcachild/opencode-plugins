import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const STYLE_MARKER = "## Progress narration (Astra-like)";

const CONFLICT_PATTERNS = [
  /IMPORTANT: You should minimize output tokens as much as possible[\s\S]*?(?=\r?\n\r?\n|$)/g,
  /IMPORTANT: You should NOT answer with unnecessary preamble or postamble[\s\S]*?(?=\r?\n\r?\n|$)/g,
  /IMPORTANT: Keep your responses short[\s\S]*?(?=\r?\n\r?\n|$)/g,
  /\s*After working on a file, just stop, rather than providing an explanation of what you did\./g,
];

const STYLE = `## Progress narration (Astra-like)
These rules override the global instructions to minimize output tokens, avoid preamble or postamble, answer in 1-3 lines, or stay silent until the final answer. They apply to progress updates only; final answers stay concise.

- If the task requires tools, start with one short line before the first tool call: what you will do and why.
- After each tool result, add one short line: what you learned and what you will do next.
- Do not make more than one tool call without a progress line. For long steps, narrate at phase boundaries: inspect, change, verify.
- Keep each line to one or two sentences and under 30 words. Use plain prose, with no headings, bullet lists, or restating the request.
- Mention concrete targets: file, symbol, command, or skill.
- A progress line may include a non-blocking question, but state your assumption and continue unless the answer is required.
- Keep the final answer separate and self-contained; do not rely on earlier progress lines.

## Using skills
Before the first tool call, scan the available skills once.
- If a skill clearly matches, load it with the skill tool before other work and say: Using <skill-id>: <one-line reason>.
- If several skills could match, load the most specific one; load a second only if the first explicitly points to it.
- Do not load a skill based only on keywords or superficial relevance.
- If none match, say nothing about skills and continue.
- The user's instructions take precedence over a skill's instructions. If a skill would make you pause, name its SKILL.md, quote the conflicting instruction, and explain briefly.

## Follow-through
Treat "can you", "I want", and "help me" as requests to act. Complete the work end-to-end, including verification, before asking questions. Ask for approval only after preparing a concrete, reviewable result. Stop early only for destructive or irreversible actions, or missing information that would change the result.`;

function transform(system) {
  let out = system;
  const removed = [];
  for (const pattern of CONFLICT_PATTERNS) {
    out = out.replace(pattern, (match) => {
      removed.push(match);
      return "";
    });
  }
  out = out.replace(/(?:\r?\n){3,}/g, "\n\n").trimEnd();
  if (!out.includes(STYLE_MARKER)) out += `\n\n${STYLE}`;
  return { text: out, removed };
}

function debug(line) {
  if (process.env.OPENCODE_ASTRA_STYLE_DEBUG !== "1") return;
  const message = `[astra-style] ${line}`;
  console.error(message);
  try {
    fs.appendFileSync(
      path.join(os.tmpdir(), "opencode-astra-style-debug.log"),
      `${new Date().toISOString()} ${message}\n`,
    );
  } catch {}
}

export const AstraStylePlugin = async () => ({
  "experimental.chat.system.transform": async (input, output) => {
    const system = output?.system;
    if (!Array.isArray(system)) return;

    const model = `${input?.model?.providerID ?? ""}/${input?.model?.id ?? ""}`.toLowerCase();
    if (!model.includes("deepseek")) {
      debug(`skip model=${model}`);
      return;
    }

    const index = system.findIndex(
      (entry) =>
        typeof entry === "string" &&
        (entry.includes("You are opencode") || entry.includes("# Tone and style")),
    );
    if (index === -1) {
      debug(`model=${model} no base prompt found, skip`);
      return;
    }

    const before = system[index];
    const { text, removed } = transform(before);
    system[index] = text;

    const remaining = [
      "IMPORTANT: You should minimize output tokens",
      "IMPORTANT: You should NOT answer with unnecessary preamble",
      "IMPORTANT: Keep your responses short",
      "After working on a file, just stop",
    ].filter((marker) => text.includes(marker));
    const removedSummary = removed
      .map((match) => `${match.slice(0, 60).replace(/\s+/g, " ")}...(${match.length})`)
      .join(" || ");

    debug(
      `model=${model} before=${before.length} after=${text.length} removed=${removedSummary || "none"} remaining=${remaining.join("|") || "none"}`,
    );
  },
});

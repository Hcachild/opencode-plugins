const DEFAULT_TIMEOUT = 60_000;

export const BashTimeoutPlugin = async () => ({
  "tool.execute.before": async (input, output) => {
    if (input.tool !== "bash") return;
    if (typeof output?.args?.timeout !== "number") {
      output.args.timeout = DEFAULT_TIMEOUT;
    }
  },
});

const PREFIX =
  "[Console]::OutputEncoding=[System.Text.Encoding]::UTF8; $OutputEncoding=[System.Text.Encoding]::UTF8;\n";

export const Utf8WindowsPlugin = async () => ({
  "shell.env": async (input, output) => {
    output.env.PYTHONIOENCODING = "utf-8";
  },
  "tool.execute.before": async (input, output) => {
    if (process.platform !== "win32" || input.tool !== "bash") return;
    const command = output?.args?.command;
    if (typeof command !== "string") return;
    if (command.includes("[Console]::OutputEncoding")) return;
    output.args.command = PREFIX + command;
  },
});

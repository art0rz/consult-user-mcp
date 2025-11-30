import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { SwiftDialogProvider } from "./providers/swift.js";
import type { DialogPosition } from "./types.js";

const server = new McpServer({ name: "speak-mcp-server", version: "1.0.0" });
const provider = new SwiftDialogProvider();
const pos = z.enum(["left", "right", "center"]).default("left");

server.registerTool("ask_confirmation", {
  description: "Yes/No dialog. Returns {confirmed, cancelled, response}. 10 min timeout.",
  inputSchema: z.object({
    message: z.string().min(1).max(500),
    title: z.string().max(100).default("Confirmation"),
    confirm_label: z.string().max(20).default("Yes"),
    cancel_label: z.string().max(20).default("No"),
    position: pos,
  }),
}, async (p) => {
  provider.pulse();
  const r = await provider.confirm({
    message: p.message, title: p.title ?? "Confirmation",
    confirmLabel: p.confirm_label ?? "Yes", cancelLabel: p.cancel_label ?? "No",
    position: (p.position ?? "left") as DialogPosition,
  });
  return { content: [{ type: "text", text: JSON.stringify(r) }] };
});

server.registerTool("ask_multiple_choice", {
  description: "List picker dialog. Returns {selected, cancelled, description}. 10 min timeout.",
  inputSchema: z.object({
    prompt: z.string().min(1).max(500),
    choices: z.array(z.string().min(1).max(100)).min(2).max(20),
    descriptions: z.array(z.string().max(200)).optional(),
    allow_multiple: z.boolean().default(true),
    default_selection: z.string().optional(),
    position: pos,
  }),
}, async (p) => {
  provider.pulse();
  const r = await provider.choose({
    prompt: p.prompt, choices: p.choices, descriptions: p.descriptions,
    allowMultiple: p.allow_multiple ?? true, defaultSelection: p.default_selection,
    position: (p.position ?? "left") as DialogPosition,
  });
  return { content: [{ type: "text", text: JSON.stringify(r) }] };
});

server.registerTool("ask_text_input", {
  description: "Text input dialog. Returns {text, cancelled}. Supports hidden input. 10 min timeout.",
  inputSchema: z.object({
    prompt: z.string().min(1).max(500),
    title: z.string().max(100).default("Input"),
    default_value: z.string().max(1000).default(""),
    hidden: z.boolean().default(false),
    position: pos,
  }),
}, async (p) => {
  provider.pulse();
  const r = await provider.textInput({
    prompt: p.prompt, title: p.title ?? "Input",
    defaultValue: p.default_value ?? "", hidden: p.hidden ?? false,
    position: (p.position ?? "left") as DialogPosition,
  });
  return { content: [{ type: "text", text: JSON.stringify(r) }] };
});

server.registerTool("notify_user", {
  description: "Show macOS notification banner. Non-blocking, no user response needed. Returns {success}.",
  inputSchema: z.object({
    message: z.string().min(1).max(500),
    title: z.string().max(100).default("Notice"),
    subtitle: z.string().max(200).optional(),
    sound: z.boolean().default(true),
  }),
}, async (p) => {
  provider.pulse();
  const r = await provider.notify({
    message: p.message, title: p.title ?? "Notice",
    subtitle: p.subtitle, sound: p.sound ?? true,
  });
  return { content: [{ type: "text", text: JSON.stringify(r) }] };
});

async function main(): Promise<void> {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  provider.setClientName(server.server.getClientVersion()?.name ?? "MCP");
  console.error("Speak MCP Server running on stdio");
}

main().catch((e) => { console.error("Server error:", e); process.exit(1); });

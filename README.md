# Speak MCP

Native macOS dialog system for MCP (Model Context Protocol) servers.

## Install

1. Download **Speak MCP.app.zip** from [Releases](../../releases)
2. Unzip and drag to `/Applications`
3. Launch it - a menu bar icon appears
4. Add the MCP server to Claude Code:

```json
{
  "mcpServers": {
    "speak": {
      "command": "node",
      "args": ["/Applications/Speak MCP.app/Contents/Resources/mcp-server/dist/index.js"]
    }
  }
}
```

## Build from Source

```bash
pnpm install
pnpm build
```

Creates `Speak MCP.app` in project root.

## Structure

```
speak/
├── dialog-cli/          # Native Swift CLI for dialogs
├── mcp-server/          # MCP server (TypeScript)
├── macos-app/           # SwiftUI menu bar app source
└── Speak MCP.app        # Built app bundle
```

## MCP Tools

- `ask_confirmation` - Yes/No dialog
- `ask_multiple_choice` - List picker
- `ask_text_input` - Text input
- `notify_user` - System notification
- `speak_text` - Text-to-speech

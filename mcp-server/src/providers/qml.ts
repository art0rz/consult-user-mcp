import { execFile } from "child_process";
import { promisify } from "util";
import { fileURLToPath } from "url";
import { dirname, join } from "path";
import { existsSync } from "fs";
import type { DialogProvider } from "./interface.js";
import type {
  ConfirmOptions,
  ConfirmResult,
  ChooseOptions,
  ChoiceResult,
  TextInputOptions,
  TextInputResult,
  NotifyOptions,
  NotifyResult,
  TtsOptions,
  TtsResult,
  QuestionsOptions,
  QuestionsResult,
} from "../types.js";

const execFileAsync = promisify(execFile);

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

function findDialogCli(): string {
  const execDir = dirname(process.execPath);

  const candidates = [
    // Packaged bun binary inside AppImage/tarball: <binary>/dialog-cli-qt/bin/consult-user-dialog
    join(execDir, "dialog-cli-qt", "bin", "consult-user-dialog"),
    // Packaged in Resources (mirroring macOS layout for consistency)
    join(execDir, "..", "Resources", "dialog-cli-qt", "bin", "consult-user-dialog"),
    // Node/bun dist -> app bundle style: dist/providers -> ../dialog-cli-qt/bin/consult-user-dialog
    join(__dirname, "..", "..", "dialog-cli-qt", "bin", "consult-user-dialog"),
    // Dev: dist/providers -> ../../../dialog-cli-qt/bin/consult-user-dialog
    join(__dirname, "..", "..", "..", "dialog-cli-qt", "bin", "consult-user-dialog"),
  ];

  for (const candidate of candidates) {
    if (existsSync(candidate)) return candidate;
  }

  return candidates[candidates.length - 1]; // fallback to dev path
}

const CLI_PATH = findDialogCli();

/**
 * QML-based native dialog provider for Linux.
 * Uses a Qt Quick CLI that mirrors the Swift command surface.
 */
export class QmlDialogProvider implements DialogProvider {
  private clientName = "MCP";

  setClientName(name: string): void {
    this.clientName = name;
  }

  private async runCli<T>(command: string, args: object): Promise<T> {
    if (!existsSync(CLI_PATH)) {
      throw new Error(`QML dialog CLI not found at ${CLI_PATH}`);
    }
    const jsonArg = JSON.stringify(args);
    const { stdout } = await execFileAsync(CLI_PATH, [command, jsonArg], {
      env: { ...process.env, MCP_CLIENT_NAME: this.clientName },
    });
    return JSON.parse(stdout.trim()) as T;
  }

  async confirm(opts: ConfirmOptions): Promise<ConfirmResult> {
    return this.runCli<ConfirmResult>("confirm", {
      message: opts.message,
      title: opts.title,
      confirmLabel: opts.confirmLabel,
      cancelLabel: opts.cancelLabel,
      position: opts.position,
    });
  }

  async choose(opts: ChooseOptions): Promise<ChoiceResult> {
    return this.runCli<ChoiceResult>("choose", {
      prompt: opts.prompt,
      choices: opts.choices,
      descriptions: opts.descriptions,
      allowMultiple: opts.allowMultiple,
      defaultSelection: opts.defaultSelection,
      position: opts.position,
    });
  }

  async textInput(opts: TextInputOptions): Promise<TextInputResult> {
    return this.runCli<TextInputResult>("textInput", {
      prompt: opts.prompt,
      title: opts.title,
      defaultValue: opts.defaultValue,
      hidden: opts.hidden,
      position: opts.position,
    });
  }

  async notify(opts: NotifyOptions): Promise<NotifyResult> {
    return this.runCli<NotifyResult>("notify", {
      message: opts.message,
      title: opts.title,
      subtitle: opts.subtitle,
      sound: opts.sound,
    });
  }

  async tts(opts: TtsOptions): Promise<TtsResult> {
    return this.runCli<TtsResult>("tts", {
      text: opts.text,
      voice: opts.voice,
      rate: opts.rate,
    });
  }

  async questions(opts: QuestionsOptions): Promise<QuestionsResult> {
    return this.runCli<QuestionsResult>("questions", {
      questions: opts.questions,
      mode: opts.mode,
      position: opts.position,
    });
  }

  async pulse(): Promise<void> {
    // Fire and forget - don't wait for completion
    execFileAsync(CLI_PATH, ["pulse"]).catch(() => {});
  }
}

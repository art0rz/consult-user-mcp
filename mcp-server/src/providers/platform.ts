import type { DialogProvider } from "./interface.js";
import { SwiftDialogProvider } from "./swift.js";
import { QmlDialogProvider } from "./qml.js";
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

class NotImplementedProvider implements DialogProvider {
  private clientName = "MCP";
  private readonly reason: string;

  constructor(reason: string) {
    this.reason = reason;
  }

  setClientName(name: string): void {
    this.clientName = name;
  }

  pulse(): void {
    // no-op
  }

  private fail(method: string): Error {
    return new Error(`${method} is not available on ${this.reason}`);
  }

  confirm(_opts: ConfirmOptions): Promise<ConfirmResult> {
    return Promise.reject(this.fail("confirm"));
  }

  choose(_opts: ChooseOptions): Promise<ChoiceResult> {
    return Promise.reject(this.fail("choose"));
  }

  textInput(_opts: TextInputOptions): Promise<TextInputResult> {
    return Promise.reject(this.fail("textInput"));
  }

  notify(_opts: NotifyOptions): Promise<NotifyResult> {
    return Promise.reject(this.fail("notify"));
  }

  tts(_opts: TtsOptions): Promise<TtsResult> {
    return Promise.reject(this.fail("tts"));
  }

  questions(_opts: QuestionsOptions): Promise<QuestionsResult> {
    return Promise.reject(this.fail("questions"));
  }
}

class PowerShellDialogProvider extends NotImplementedProvider {
  constructor() {
    super("Windows (PowerShell provider not implemented yet)");
  }
}

export function createDialogProvider(): DialogProvider {
  switch (process.platform) {
    case "darwin":
      return new SwiftDialogProvider();
    case "win32":
      return new PowerShellDialogProvider();
    case "linux":
      return new QmlDialogProvider();
    default:
      return new NotImplementedProvider(`unsupported platform: ${process.platform}`);
  }
}

// The Nook plugin for OpenCode
// Bridges OpenCode events to the The Nook app via Unix socket or TCP.
// Wire contract: NDJSON envelopes over ~/.nook/run/nook.sock
// (env override NOOK_SOCKET), or NOOK_HOST (host:port), or
// NOOK_PORTS (comma list fanned out to 127.0.0.1 + host.docker.internal
// + default gateway). Any transport failure fails open: the agent continues
// normally, no noisy logs.
//
// One file serves both plugin APIs: opencode 1.x calls `server(config)`
// (object entrypoints work there from 1.18.29) and drives the V1 event
// names below; opencode 2.x calls `setup(ctx)` and drives the V2 event
// names in the second half of this file. Both emit the same envelopes.
import { Socket } from "net";
import { homedir, hostname as osHostname } from "os";
import { randomUUID } from "crypto";
import { execSync } from "child_process";
import { readFileSync } from "fs";
import { lookup } from "dns/promises";

const SOURCE = "opencode";
const SESSION_PREFIX = "opencode";
const DEFAULT_SERVER_URL = "http://127.0.0.1:4096";
const SOCKET_PATH =
  process.env.NOOK_SOCKET ||
  `${process.env.HOME || homedir()}/.nook/run/nook.sock`;

// App-level yolo override: `~/.nook/yolo.json` (NOOK_YOLO_FILE
// relocates it). "yolo" auto-approves permission requests; "verify"/"auto"
// keep the island gate for requests opencode actually asks about.
function yoloOverrideActive() {
  if (process.env.NOOK_YOLO === "1") return true;
  const path =
    process.env.NOOK_YOLO_FILE ||
    `${process.env.HOME || homedir()}/.nook/yolo.json`;
  try {
    const parsed = JSON.parse(readFileSync(path, "utf8"));
    return parsed && parsed.mode === "yolo";
  } catch {
    return false;
  }
}

const _SERVER_USERNAME = process.env.OPENCODE_SERVER_USERNAME || "opencode";
const _SERVER_PASSWORD = process.env.OPENCODE_SERVER_PASSWORD;
const _AUTH_HEADER = _SERVER_PASSWORD
  ? "Basic " +
    Buffer.from(`${_SERVER_USERNAME}:${_SERVER_PASSWORD}`).toString("base64")
  : null;

function prefixedSessionId(raw) {
  if (!raw || typeof raw !== "string") return raw;
  return raw.startsWith(`${SESSION_PREFIX}-`)
    ? raw
    : `${SESSION_PREFIX}-${raw}`;
}

// Terminal capture per wire contract: env vars -> terminal{} keys.
// Falls back to `_AN_*` prefixed copies set by a parent shell.env hook so
// sessions started before The Nook can still resolve their terminal.
function terminalFields() {
  const env = process.env;
  const get = (key) => env[key] ?? env["_AN_" + key];
  const t = {};
  // Multiplexers (tmux, herdr) override TERM_PROGRAM with their own name;
  // the emulator's distinctive env vars survive, so prefer them.
  if (get("GHOSTTY_RESOURCES_DIR")) t.term_program = "ghostty";
  else if (get("KITTY_WINDOW_ID")) t.term_program = "kitty";
  else if (get("ITERM_SESSION_ID")) t.term_program = "iTerm.app";
  else if (get("TERM_SESSION_ID")) t.term_program = "Apple_Terminal";
  else if (get("WEZTERM_EXECUTABLE")) t.term_program = "WezTerm";
  else if (get("TERM_PROGRAM")) t.term_program = get("TERM_PROGRAM");
  if (get("TERM_SESSION_ID")) t.term_session_id = get("TERM_SESSION_ID");
  if (get("ITERM_SESSION_ID")) t.iterm_session_id = get("ITERM_SESSION_ID");
  if (get("TMUX_PANE")) t.tmux_pane = get("TMUX_PANE");
  if (get("KITTY_WINDOW_ID")) t.kitty_window_id = get("KITTY_WINDOW_ID");
  if (get("__CFBundleIdentifier")) t.bundle_id = get("__CFBundleIdentifier");
  if (get("SSH_TTY")) t.ssh_tty = get("SSH_TTY");
  // The client end of the hop: the pane worth focusing lives on the box
  // that opened the connection, and this is the only thing naming it.
  if (get("SSH_CLIENT")) t.ssh_client = get("SSH_CLIENT");
  if (get("HERDR_SOCKET_PATH")) t.herdr_socket_path = get("HERDR_SOCKET_PATH");
  if (get("HERDR_WORKSPACE_ID"))
    t.herdr_workspace_id = get("HERDR_WORKSPACE_ID");
  if (get("HERDR_TAB_ID")) t.herdr_tab_id = get("HERDR_TAB_ID");
  if (get("HERDR_PANE_ID")) t.herdr_pane_id = get("HERDR_PANE_ID");
  return Object.keys(t).length > 0 ? t : undefined;
}

function connectTarget(target, timeoutMs) {
  return new Promise((resolve) => {
    let settled = false;
    const done = (sock) => {
      if (settled) return;
      settled = true;
      resolve(sock);
    };
    let sock;
    try {
      sock = new Socket();
    } catch {
      done(null);
      return;
    }
    sock.on("connect", () => {
      sock.setTimeout(0);
      done(sock);
    });
    sock.on("error", () => {
      sock.destroy();
      done(null);
    });
    sock.setTimeout(timeoutMs, () => {
      sock.destroy();
      done(null);
    });
    try {
      if (target.kind === "unix") sock.connect({ path: target.path });
      else sock.connect({ host: target.host, port: target.port });
    } catch {
      sock.destroy();
      done(null);
    }
  });
}

let gatewayCache = null;
let gatewayChecked = false;
function defaultGateway() {
  if (gatewayChecked) return gatewayCache;
  gatewayChecked = true;
  try {
    const out = execSync(
      "route -n get default 2>/dev/null || ip route 2>/dev/null || true",
      { timeout: 1000, stdio: ["ignore", "pipe", "ignore"] },
    ).toString();
    let m = out.match(/(?:^|\s)gateway\s*:\s*([0-9.]+)/m);
    if (!m) m = out.match(/default via ([0-9.]+)/);
    gatewayCache = m ? m[1] : null;
  } catch {
    gatewayCache = null;
  }
  return gatewayCache;
}

let dockerResolvableCache = null;
function hostDockerResolvable() {
  if (dockerResolvableCache === null) {
    dockerResolvableCache = lookup("host.docker.internal")
      .then(() => true)
      .catch(() => false);
  }
  return dockerResolvableCache;
}

// Endpoint baked by `nook-hook --setup --host` on remote hosts.
function endpointFile() {
  try {
    return readFileSync(`${process.env.HOME || homedir()}/.nook/endpoint`, "utf8").trim();
  } catch {
    return "";
  }
}
// Connect per the wire contract priority: Unix socket first (3 s connect
// timeout), else NOOK_HOST (host:port), else NOOK_PORTS fan-out
// to 127.0.0.1 + host.docker.internal (if resolvable) + default gateway.
async function openConnection() {
  const candidates = [{ kind: "unix", path: SOCKET_PATH }];
  const host = process.env.NOOK_HOST || endpointFile();
  if (host) {
    const idx = host.lastIndexOf(":");
    if (idx > 0) {
      const h = host.slice(0, idx);
      const p = parseInt(host.slice(idx + 1), 10);
      if (h && Number.isFinite(p))
        candidates.push({ kind: "tcp", host: h, port: p });
    }
  }
  const ports = (process.env.NOOK_PORTS || "")
    .split(",")
    .map((s) => parseInt(s.trim(), 10))
    .filter((n) => Number.isFinite(n) && n > 0);
  if (ports.length > 0) {
    const hosts = ["127.0.0.1"];
    if (await hostDockerResolvable()) hosts.push("host.docker.internal");
    const gw = defaultGateway();
    if (gw) hosts.push(gw);
    for (const port of ports) {
      for (const h of hosts) candidates.push({ kind: "tcp", host: h, port });
    }
  }
  for (const candidate of candidates) {
    const sock = await connectTarget(
      candidate,
      candidate.kind === "unix" ? 3000 : 1500,
    );
    if (sock) return sock;
  }
  return null;
}

// Fire-and-forget: one envelope line, then close.
function sendEnvelope(envelope) {
  return new Promise((resolve) => {
    let settled = false;
    const done = (ok) => {
      if (settled) return;
      settled = true;
      resolve(ok);
    };
    (async () => {
      const sock = await openConnection();
      if (!sock) {
        console.debug("[nook] app unreachable; continuing without bridge");
        done(false);
        return;
      }
      let wrote = false;
      sock.on("error", () => {});
      sock.on("close", () => done(wrote));
      sock.setTimeout(3000, () => sock.destroy());
      try {
        sock.write(JSON.stringify({ type: "event", event: envelope }) + "\n");
        wrote = true;
        sock.end();
      } catch {
        sock.destroy();
        done(false);
      }
    })();
  });
}

// Awaited event: hold the connection, read exactly one response line, apply
// the directive. Any failure resolves null (fail open).
function requestDirective(envelope, timeoutMs = 300000) {
  return new Promise((resolve) => {
    let settled = false;
    const done = (directive) => {
      if (settled) return;
      settled = true;
      resolve(directive);
    };
    (async () => {
      const sock = await openConnection();
      if (!sock) {
        console.debug("[nook] app unreachable; failing open");
        done(null);
        return;
      }
      let buf = "";
      sock.on("data", (chunk) => {
        buf += chunk.toString();
        const nl = buf.indexOf("\n");
        if (nl === -1) return;
        const line = buf.slice(0, nl).trim();
        sock.destroy();
        try {
          const msg = JSON.parse(line);
          if (
            msg &&
            msg.type === "response" &&
            msg.in_reply_to === envelope.event_id &&
            msg.directive
          ) {
            done(msg.directive);
          } else {
            done(null);
          }
        } catch {
          done(null);
        }
      });
      sock.on("error", () => done(null));
      sock.on("close", () => done(null));
      sock.setTimeout(timeoutMs, () => {
        sock.destroy();
        done(null);
      });
      try {
        sock.write(JSON.stringify({ type: "event", event: envelope }) + "\n");
      } catch {
        sock.destroy();
        done(null);
      }
    })();
  });
}

// ── Small shared helpers ──────────────────────────────────────────────────

// Terminal env vars copied (prefixed `_AN_`) into every shell the agent
// spawns, so sessions started before The Nook can still resolve their
// terminal — see terminalFields().
const SHELL_ENV_KEYS = [
  "TERM_PROGRAM",
  "ITERM_SESSION_ID",
  "TERM_SESSION_ID",
  "TMUX",
  "TMUX_PANE",
  "KITTY_WINDOW_ID",
  "GHOSTTY_RESOURCES_DIR",
  "WEZTERM_EXECUTABLE",
  "__CFBundleIdentifier",
  "SSH_TTY",
  "HERDR_SOCKET_PATH",
  "HERDR_WORKSPACE_ID",
  "HERDR_TAB_ID",
  "HERDR_PANE_ID",
];

// First non-empty value in a `||`-style fallback chain (order matters).
function firstDefined(...values) {
  for (const v of values) {
    if (v !== undefined && v !== null && v !== "") return v;
  }
  return "";
}

// Evict the oldest key once a Map outgrows `max` (bounded session state).
function boundedMap(map, max) {
  if (map.size > max) map.delete(map.keys().next().value);
}

// Option display label from either a string option or a {label|text|value|name}.
function optionLabel(option) {
  if (typeof option === "string") return option;
  return option && (option.label || option.text || option.value || option.name);
}

// One handler method per event type; mapEvent is a table lookup so every
// new opencode event type is one table entry + one small method instead of
// another branch in a growing dispatch chain.
const EVENT_HANDLERS = {
  "session.created": "handleSessionCreated",
  "session.deleted": "handleSessionDeleted",
  "session.updated": "handleSessionUpdated",
  "session.status": "handleSessionStatus",
  "session.idle": "handleSessionStatus",
  "session.error": "handleSessionError",
  "message.updated": "handleMessageUpdated",
  "message.part.updated": "handleMessagePartUpdated",
  "message.part.delta": "handleMessagePartDelta",
  "permission.asked": "handlePermissionAsked",
  "permission.replied": "handlePermissionReplied",
  "question.asked": "handleQuestionAsked",
  "question.replied": "handleQuestionReplied",
  "question.rejected": "handleQuestionReplied",
};

class OpenCodeBridge {
  constructor({ client, serverUrl, directory }) {
    this.serverOrigin = (serverUrl && serverUrl.origin) || DEFAULT_SERVER_URL;
    this.serverPort = parseInt(serverUrl && serverUrl.port) || 4096;
    this.client = client;
    this.directory = directory;
    this.msgRoles = new Map();
    this.sessions = new Map();
    this.knownSessions = new Set();
    this.partBuffers = new Map();
    this.partTypes = new Map();
    this.lastTokenSent = new Map();
    this.pendingPartsByMessage = new Map();
    this.recentStops = new Map();
    this.seenEvents = new Map();
    this.sessionCwd = new Map();
    this.replyTargets = new Map();
  }

  buildHeaders(cwd) {
    const headers = { "Content-Type": "application/json" };
    if (_AUTH_HEADER) headers.Authorization = _AUTH_HEADER;
    const dir = cwd || this.directory;
    if (dir) headers["x-opencode-directory"] = encodeURIComponent(dir);
    return headers;
  }

  async postReply(path, body, cwd) {
    try {
      const response = await fetch(`${this.serverOrigin}${path}`, {
        method: "POST",
        headers: this.buildHeaders(cwd),
        body: JSON.stringify(body),
      });
      if (response && response.ok) return response;
    } catch {}
    const shouldUseClientFallback = !_AUTH_HEADER && this.serverPort === 4096;
    if (!shouldUseClientFallback) return null;
    try {
      const rawClient = this.client && this.client._client;
      if (!rawClient || typeof rawClient.post !== "function") return null;
      return await rawClient.post({
        url: path,
        headers: this.buildHeaders(cwd),
        body,
      });
    } catch {
      return null;
    }
  }

  getSession(sid) {
    if (!this.sessions.has(sid))
      this.sessions.set(sid, { lastUserText: "", lastAssistantText: "" });
    return this.sessions.get(sid);
  }

  cleanupSeen(now) {
    if (this.seenEvents.size <= 500) return;
    const cutoff = now - 10 * 60 * 1000;
    for (const [key, ts] of this.seenEvents) {
      if (ts < cutoff || this.seenEvents.size > 800)
        this.seenEvents.delete(key);
      if (this.seenEvents.size <= 500) break;
    }
  }

  eventKey(ev) {
    if (ev && ev.id) return `id:${ev.id}`;
    const p = (ev && ev.properties) || {};
    const part = p.part || {};
    const status =
      (p.status && p.status.type) || (part.state && part.state.status) || "";
    const sessionID = firstDefined(
      p.sessionID,
      p.info && p.info.sessionID,
      part.sessionID,
      p.info && p.info.id,
    );
    const messageID = firstDefined(
      p.messageID,
      p.info && p.info.id,
      part.messageID,
    );
    const partID = firstDefined(p.partID, part.id, p.id);
    return [
      "fallback",
      ev && ev.type ? ev.type : "",
      sessionID,
      messageID,
      partID,
      status,
    ].join(":");
  }

  shouldProcessEvent(ev) {
    const key = this.eventKey(ev);
    if (!key) return true;
    if (this.seenEvents.has(key)) return false;
    const now = Date.now();
    this.seenEvents.set(key, now);
    this.cleanupSeen(now);
    return true;
  }

  rememberPendingPart(part) {
    if (!part || !part.messageID) return;
    const list = this.pendingPartsByMessage.get(part.messageID) || [];
    list.push(part);
    this.pendingPartsByMessage.set(part.messageID, list.slice(-20));
    boundedMap(this.pendingPartsByMessage, 200);
  }

  markSessionStarted(sessionId, cwd) {
    if (!sessionId) return null;
    const effectiveCwd = cwd || this.directory || undefined;
    if (effectiveCwd) this.sessionCwd.set(sessionId, effectiveCwd);
    if (this.knownSessions.has(sessionId)) return null;
    this.knownSessions.add(sessionId);
    return this.envelope("SessionStart", sessionId, { cwd: effectiveCwd });
  }

  markSessionStopped(sessionId, additional = {}) {
    if (!sessionId) return null;
    const now = Date.now();
    const last = this.recentStops.get(sessionId) || 0;
    if (now - last < 1500) return null;
    this.recentStops.set(sessionId, now);
    const s = this.getSession(sessionId);
    const extra = { cwd: this.sessionCwd.get(sessionId), ...additional };
    if (s.lastAssistantText) extra.last_assistant_message = s.lastAssistantText;
    if (s.lastModel) extra.model = s.lastModel;
    return this.envelope("Stop", sessionId, extra);
  }

  envelope(hookEventName, sessionId, extra = {}, replyTarget) {
    if (!sessionId) return null;
    const env = {
      hook_event_name: hookEventName,
      event_id: randomUUID(),
      source: SOURCE,
      session_id: prefixedSessionId(sessionId),
      pid: process.pid,
      // The machine this ran on, by its own name — see the plugin spec.
      hostname: osHostname(),
      terminal: terminalFields(),
      ...extra,
    };
    if (process.env.NOOK_HOST || endpointFile()) env.remote = true;
    if (replyTarget) this.replyTargets.set(env.event_id, replyTarget);
    return env;
  }

  mapEvent(ev) {
    const handler = EVENT_HANDLERS[ev.type];
    if (!handler) return null;
    return this[handler](ev);
  }

  // ── Event handlers ────────────────────────────────────────────────────

  handleSessionCreated(ev) {
    const p = ev.properties || {};
    if (!p.info) return null;
    const cwd = p.info.directory || this.directory || undefined;
    this.sessionCwd.set(p.info.id, cwd);
    return this.markSessionStarted(p.info.id, cwd);
  }

  handleSessionDeleted(ev) {
    const p = ev.properties || {};
    if (!p.info) return null;
    this.sessions.delete(p.info.id);
    this.sessionCwd.delete(p.info.id);
    this.knownSessions.delete(p.info.id);
    return this.envelope("SessionEnd", p.info.id);
  }

  handleSessionUpdated(ev) {
    const p = ev.properties || {};
    if (!p.info) return null;
    if (p.info.directory) this.sessionCwd.set(p.info.id, p.info.directory);
    if (p.info.time && p.info.time.archived) {
      this.sessions.delete(p.info.id);
      this.sessionCwd.delete(p.info.id);
      this.knownSessions.delete(p.info.id);
      return this.envelope("SessionEnd", p.info.id);
    }
    return this.markSessionStarted(p.info.id, this.sessionCwd.get(p.info.id));
  }

  handleSessionStatus(ev) {
    const p = ev.properties || {};
    if (!p.sessionID) return null;
    // `retry` is a transient error (auto-retry follows); only idle ends
    // the turn. Errors that halt the session arrive as `session.error`.
    const isIdle =
      ev.type === "session.idle" || (p.status && p.status.type === "idle");
    return isIdle ? this.markSessionStopped(p.sessionID) : null;
  }

  handleSessionError(ev) {
    const p = ev.properties || {};
    if (!p.sessionID) return null;
    const err = p.error;
    if (!err) return null;
    // Retryable API errors are transient — the session auto-retries
    // (session.status "retry" follows). Surface only errors that halt
    // the session: non-API failures (auth, aborted, output length) and
    // non-retryable API errors.
    if (err.name === "APIError" && err.data && err.data.isRetryable)
      return null;
    const text =
      (err.data && err.data.message) || err.name || "Session errored";
    return this.envelope("SessionError", p.sessionID, { error: text });
  }

  handleMessageUpdated(ev) {
    const p = ev.properties || {};
    if (!p.info || !p.info.id || !p.info.sessionID) return null;
    this.msgRoles.set(p.info.id, {
      role: p.info.role,
      sessionID: p.info.sessionID,
    });
    boundedMap(this.msgRoles, 200);
    // capture assistant model id, attached to the Stop payload below
    const assistant = p.info.metadata && p.info.metadata.assistant;
    if (p.info.role === "assistant" && assistant && assistant.modelID) {
      this.getSession(p.info.sessionID).lastModel = assistant.modelID;
    }
    const pending = this.pendingPartsByMessage.get(p.info.id) || [];
    this.pendingPartsByMessage.delete(p.info.id);
    return pending
      .map((part) =>
        this.mapEvent({
          type: "message.part.updated",
          properties: { sessionID: p.info.sessionID, part },
        }),
      )
      .filter(Boolean)
      .flat();
  }

  handleMessagePartUpdated(ev) {
    const p = ev.properties || {};
    const part = p.part || {};
    if (part.id && part.type) {
      // Record the part type: reasoning and text parts both stream deltas
      // on field "text", but only text is decode (see the delta handler).
      this.partTypes.set(part.id, part.type);
      boundedMap(this.partTypes, 200);
    }
    if (part.type === "text" && part.messageID)
      return this.handleTextPart(p, part);
    if (part.type === "tool" && part.sessionID)
      return this.handleToolPart(p, part);
    return null;
  }

  handleTextPart(p, part) {
    const meta = this.msgRoles.get(part.messageID);
    if (!meta) {
      this.rememberPendingPart(part);
      return null;
    }
    const s = this.getSession(meta.sessionID);
    const cwd = this.sessionCwd.get(meta.sessionID);
    const text = part.text || "";
    if (meta.role === "user" && text) {
      s.lastUserText = text;
      // Fallback: ensure the session is created even if session.created
      // was not emitted (e.g., opencode creates it lazily on first message).
      const sessionStartEnv = this.markSessionStarted(meta.sessionID, cwd);
      const promptEnv = this.envelope("UserPromptSubmit", meta.sessionID, {
        cwd,
        prompt: text,
      });
      return sessionStartEnv ? [sessionStartEnv, promptEnv] : promptEnv;
    }
    if (meta.role === "assistant" && text) {
      s.lastAssistantText = text;
    }
    return null;
  }

  handleToolPart(p, part) {
    if (part.messageID && !this.msgRoles.has(part.messageID)) {
      this.rememberPendingPart(part);
      return null;
    }
    const st = part.state && part.state.status;
    const cwd = this.sessionCwd.get(part.sessionID);
    const toolName =
      (part.tool || "").charAt(0).toUpperCase() + (part.tool || "").slice(1);
    const extra = { cwd, tool_name: toolName };
    if (part.id) extra.tool_use_id = part.id;
    if (st === "running" || st === "pending") {
      extra.tool_input = (part.state && part.state.input) || {};
      return this.envelope("PreToolUse", part.sessionID, extra);
    }
    if (st === "completed" || st === "error") {
      return this.envelope("PostToolUse", part.sessionID, extra);
    }
    return null;
  }

  handleMessagePartDelta(ev) {
    const p = ev.properties || {};
    if (!p.sessionID || !p.partID || p.field !== "text") return null;
    const key = `${p.sessionID}:${p.partID}`;
    const next = (this.partBuffers.get(key) || "") + (p.delta || "");
    this.partBuffers.set(key, next);
    boundedMap(this.partBuffers, 200);
    // Both text and reasoning parts stream with field "text"; only text
    // parts are decode (assistant output). Reasoning is prompt processing
    // — the island's badge must keep growing through it. An unknown part
    // type never emits (in the real flow part.updated precedes deltas).
    if (this.partTypes.get(p.partID) !== "text") return null;
    // Gated on the same check so reasoning text can't leak into the Stop
    // payload's last_assistant_message.
    this.getSession(p.sessionID).lastAssistantText = next;
    // Throttle: deltas arrive per token; one envelope per 2 s per session
    // keeps the bridge light while the badge (2 s render tick) stays fresh.
    const now = Date.now();
    if (now - (this.lastTokenSent.get(p.sessionID) || 0) < 2000) return null;
    this.lastTokenSent.set(p.sessionID, now);
    boundedMap(this.lastTokenSent, 200);
    return this.envelope("MessageUpdate", p.sessionID, {
      cwd: this.sessionCwd.get(p.sessionID),
    });
  }

  handlePermissionAsked(ev) {
    const p = ev.properties || {};
    if (!p.id || !p.sessionID) return null;
    const toolName =
      (p.permission || "").charAt(0).toUpperCase() +
      (p.permission || "").slice(1);
    const patterns = p.patterns || [];
    const toolInput = { patterns, metadata: p.metadata };
    if (p.permission === "bash" && patterns.length > 0) {
      toolInput.command = patterns.join(" && ");
    }
    if (
      (p.permission === "edit" || p.permission === "write") &&
      patterns.length > 0
    ) {
      toolInput.file_path = patterns[0];
    }
    const cwd = this.sessionCwd.get(p.sessionID);
    return this.envelope(
      "PermissionRequest",
      p.sessionID,
      {
        cwd,
        tool_name: toolName,
        tool_input: toolInput,
        permission_id: p.id,
        permission_title: `Allow ${toolName}`,
        permission_description:
          patterns.length > 0
            ? `OpenCode wants to run ${toolName}: ${patterns[0]}`
            : `OpenCode wants to run ${toolName}`,
        await_response: true,
      },
      { path: `/permission/${p.id}/reply`, cwd },
    );
  }

  handlePermissionReplied(ev) {
    const p = ev.properties || {};
    if (!p.sessionID) return null;
    return this.envelope("PostToolUse", p.sessionID, {
      cwd: this.sessionCwd.get(p.sessionID),
    });
  }

  handleQuestionAsked(ev) {
    const p = ev.properties || {};
    if (!p.id || !p.sessionID) return null;
    const questions = Array.isArray(p.questions) ? p.questions : [];
    const titles = [];
    const options = [];
    for (const q of questions) {
      if (!q) continue;
      const label = (q && (q.question || q.title)) || "";
      if (label) titles.push(label);
      const group = [];
      if (Array.isArray(q.options)) {
        for (const o of q.options) {
          const ol = optionLabel(o);
          if (ol) group.push(String(ol));
        }
      }
      options.push(group);
    }
    const title = titles.join("; ") || "OpenCode has a question";
    const cwd = this.sessionCwd.get(p.sessionID);
    return this.envelope(
      "QuestionAsked",
      p.sessionID,
      {
        cwd,
        question_id: p.id,
        question_title: title,
        question_titles: titles,
        question_options: options,
        await_response: true,
      },
      { path: `/question/${p.id}/reply`, cwd },
    );
  }

  handleQuestionReplied(ev) {
    const p = ev.properties || {};
    if (!p.sessionID) return null;
    return this.envelope("PostToolUse", p.sessionID, {
      cwd: this.sessionCwd.get(p.sessionID),
    });
  }

  // ── Dispatch ──────────────────────────────────────────────────────────

  async dispatchMapped(mapped) {
    if (!mapped) return;
    if (Array.isArray(mapped)) {
      for (const item of mapped) await this.dispatchMapped(item);
      return;
    }
    if (
      mapped.hook_event_name === "PermissionRequest" ||
      mapped.hook_event_name === "QuestionAsked"
    ) {
      const target = this.replyTargets.get(mapped.event_id);
      // Yolo override: auto-approve execution requests without awaiting the
      // app's directive. opencode still needs a reply to proceed, so answer
      // "once" immediately. (Native yolo — --auto-accept / permission: allow
      // — suppresses permission.asked entirely, so no event reaches here.)
      if (
        mapped.hook_event_name === "PermissionRequest" &&
        yoloOverrideActive()
      ) {
        this.replyTargets.delete(mapped.event_id);
        if (target) {
          void this.postReply(
            target.path,
            { reply: "once", message: undefined },
            target.cwd,
          );
        }
        return;
      }
      requestDirective(mapped).then((directive) => {
        this.replyTargets.delete(mapped.event_id);
        if (!target || !directive) return;
        if (mapped.hook_event_name === "PermissionRequest") {
          if (directive.action === "allow") {
            void this.postReply(
              target.path,
              { reply: "once", message: undefined },
              target.cwd,
            );
          } else if (directive.action === "deny") {
            void this.postReply(
              target.path,
              { reply: "reject", message: directive.reason },
              target.cwd,
            );
          }
        } else if (directive.action === "answer") {
          void this.postReply(
            target.path,
            { answers: directive.answers || [] },
            target.cwd,
          );
        }
      });
      return;
    }
    await sendEnvelope(mapped);
  }

  async dispatchEvent(event) {
    if (!event || !this.shouldProcessEvent(event)) return;
    await this.dispatchMapped(this.mapEvent(event));
  }

  install() {
    return {
      event: async ({ event }) => {
        // Subagent suppression: skip every event in subagent processes.
        if (process.env.PI_SUBAGENT_CHILD) return;
        try {
          await this.dispatchEvent(event);
        } catch {
          // fail open: never block the agent on bridge errors
        }
      },
      "shell.env": async (input, output) => {
        output.env.NOOK_ACTIVE = "1";
        for (const v of SHELL_ENV_KEYS) {
          if (process.env[v]) output.env["_AN_" + v] = process.env[v];
        }
      },
    };
  }
}

// ── OpenCode 2.x plugin API ────────────────────────────────────────────────
//
// V2 loads one plugin instance per location and calls setup(ctx); events
// arrive from ctx.event.subscribe() as {id, type, data, location} records
// with native names that differ from V1's (`session.inbox.enqueued` instead
// of `message.part.updated`, `form.created` instead of `question.asked`, …).
// The mapping below was verified against the v2.0.20 event stream:
//
//   session.created            → SessionStart (data.location.directory is cwd)
//   session.inbox.enqueued     → UserPromptSubmit (item.type "user")
//   session.execution.started  → SessionStart fallback
//   session.execution.succeeded→ Stop
//   session.execution.interrupted → Stop (reason)
//   session.execution.failed   → SessionError (halt; retry.scheduled and
//                                 step.failed are transient and ignored)
//   session.step.started       → model capture (providerID/id) for Stop
//   session.text.delta/ended   → MessageUpdate (2 s throttle) / final text
//   session.tool.input.started → tool name by call id
//   session.tool.called        → PreToolUse (input)
//   session.tool.success/failed→ PostToolUse
//   permission.asked           → PermissionRequest (await, ctx.permission.reply)
//   permission.replied/rejected→ PostToolUse
//   form.created               → QuestionAsked (await, service HTTP reply)
//   form.replied/cancelled     → PostToolUse
//   session.deleted/updated    → SessionEnd (deleted; archived)

const V2_EVENT_HANDLERS = {
  "session.created": "handleV2SessionCreated",
  "session.deleted": "handleV2SessionDeleted",
  "session.updated": "handleV2SessionUpdated",
  "session.idle": "handleV2SessionIdle",
  "session.inbox.enqueued": "handleV2InboxEnqueued",
  "session.execution.started": "handleV2ExecutionStarted",
  "session.execution.succeeded": "handleV2ExecutionSucceeded",
  "session.execution.interrupted": "handleV2ExecutionInterrupted",
  "session.execution.failed": "handleV2ExecutionFailed",
  "session.step.started": "handleV2StepStarted",
  "session.text.delta": "handleV2TextDelta",
  "session.text.ended": "handleV2TextEnded",
  "session.tool.input.started": "handleV2ToolInputStarted",
  "session.tool.called": "handleV2ToolCalled",
  "session.tool.success": "handleV2ToolCompleted",
  "session.tool.failed": "handleV2ToolCompleted",
  "permission.asked": "handleV2PermissionAsked",
  "permission.replied": "handleV2PermissionSettled",
  "permission.rejected": "handleV2PermissionSettled",
  "form.created": "handleV2FormCreated",
  "form.replied": "handleV2FormSettled",
  "form.cancelled": "handleV2FormSettled",
};

// The V2 plugin context deliberately omits form replies, so questions are
// settled over the service's own HTTP API. Credentials come from the same
// service registration the CLI's client uses.
function serviceCredentials() {
  try {
    const parsed = JSON.parse(
      readFileSync(
        `${process.env.HOME || homedir()}/.local/state/opencode/service.json`,
        "utf8",
      ),
    );
    if (parsed && parsed.url && parsed.password) return parsed;
  } catch {}
  return null;
}

async function postFormReply(sessionID, formID, answer) {
  const service = serviceCredentials();
  if (!service) return false;
  try {
    const origin = service.url.replace(/\/+$/, "");
    const response = await fetch(
      `${origin}/api/session/${encodeURIComponent(sessionID)}/form/${encodeURIComponent(formID)}/reply`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization:
            "Basic " +
            Buffer.from(`opencode:${service.password}`).toString("base64"),
        },
        body: JSON.stringify({ answer }),
      },
    );
    return response.ok;
  } catch {
    return false;
  }
}

// A directive answer row holds option labels; the API wants option values
// (or the raw string for freeform fields).
function formOptionValue(field, label) {
  const options = Array.isArray(field.options) ? field.options : [];
  const match = options.find(
    (o) => o && ((o.label !== undefined && o.label === label) || o.value === label),
  );
  return match && match.value !== undefined ? match.value : label;
}

export class OpenCodeBridgeV2 extends OpenCodeBridge {
  constructor({ ctx, directory }) {
    super({ client: undefined, serverUrl: undefined, directory });
    this.ctx = ctx;
    this.childSessions = new Set();
    this.toolNames = new Map();
  }

  mapEvent(ev) {
    const handler = V2_EVENT_HANDLERS[ev.type];
    if (!handler) return null;
    return this[handler](ev);
  }

  async dispatchEvent(event) {
    if (!event || !event.type) return;
    // One plugin instance loads per location: only this location's sessions
    // are ours, and events without a session are table misses anyway.
    const directory = event.location && event.location.directory;
    if (directory && this.directory && directory !== this.directory) return;
    // Subagent suppression: sessions created with a parentID belong to a
    // task/subagent and must not surface as their own sessions.
    if (this.childSessions.has(v2SessionId(event))) return;
    if (!this.shouldProcessEvent(event)) return;
    await this.dispatchMapped(this.mapEvent(event));
  }

  async dispatchMapped(mapped) {
    if (!mapped) return;
    if (Array.isArray(mapped)) {
      for (const item of mapped) await this.dispatchMapped(item);
      return;
    }
    if (mapped.hook_event_name === "PermissionRequest") {
      const target = this.replyTargets.get(mapped.event_id);
      this.replyTargets.delete(mapped.event_id);
      // Yolo override: auto-approve without awaiting the app's directive.
      // opencode still needs a reply to proceed, so answer "once" now.
      if (yoloOverrideActive()) {
        if (target) void this.replyPermission(target, "once");
        return;
      }
      requestDirective(mapped).then((directive) => {
        if (!target || !directive) return;
        if (directive.action === "allow")
          void this.replyPermission(target, "once");
        else if (directive.action === "deny")
          void this.replyPermission(target, "reject", directive.reason);
      });
      return;
    }
    if (mapped.hook_event_name === "QuestionAsked") {
      const target = this.replyTargets.get(mapped.event_id);
      this.replyTargets.delete(mapped.event_id);
      requestDirective(mapped).then((directive) => {
        if (!target || !directive) return;
        if (directive.action === "answer")
          void this.replyForm(target, directive.answers || []);
      });
      return;
    }
    await sendEnvelope(mapped);
  }

  async replyPermission(target, decision, message) {
    try {
      const input = {
        sessionID: target.sessionID,
        requestID: target.requestID,
        decision,
      };
      if (message !== undefined) input.message = message;
      await this.ctx.permission.reply(input);
    } catch {
      // fail open: the host's own permission flow proceeds
    }
  }

  async replyForm(target, answerRows) {
    const answer = {};
    const fields = Array.isArray(target.fields) ? target.fields : [];
    for (let i = 0; i < fields.length; i++) {
      const field = fields[i];
      if (!field || !field.key) continue;
      const row = Array.isArray(answerRows[i]) ? answerRows[i] : [];
      if (field.type === "multiselect") {
        const values = row
          .map((label) => formOptionValue(field, label))
          .filter((v) => v !== "");
        if (values.length > 0) answer[field.key] = values;
      } else {
        const first = row.find((v) => v !== undefined && v !== null && v !== "");
        if (first !== undefined) answer[field.key] = formOptionValue(field, first);
      }
    }
    await postFormReply(target.sessionID, target.formID, answer);
  }

  toolNameFor(callId) {
    const raw = this.toolNames.get(callId) || "Tool";
    return raw.charAt(0).toUpperCase() + raw.slice(1);
  }

  // ── Event handlers ────────────────────────────────────────────────────

  handleV2SessionCreated(ev) {
    const d = ev.data || {};
    if (!d.sessionID) return null;
    if (d.parentID) {
      this.childSessions.add(d.sessionID);
      return null;
    }
    if (d.model)
      this.getSession(d.sessionID).lastModel = `${d.model.providerID}/${d.model.id}`;
    const cwd = (d.location && d.location.directory) || this.directory || undefined;
    return this.markSessionStarted(d.sessionID, cwd);
  }

  handleV2SessionDeleted(ev) {
    const d = ev.data || {};
    const sid = d.sessionID || d.id;
    if (!sid) return null;
    this.sessions.delete(sid);
    this.sessionCwd.delete(sid);
    this.knownSessions.delete(sid);
    this.childSessions.delete(sid);
    return this.envelope("SessionEnd", sid);
  }

  handleV2SessionUpdated(ev) {
    const info = (ev.data || {}).info;
    if (!info || !info.id) return null;
    if (info.directory) this.sessionCwd.set(info.id, info.directory);
    if (info.time && info.time.archived) {
      this.sessions.delete(info.id);
      this.sessionCwd.delete(info.id);
      this.knownSessions.delete(info.id);
      return this.envelope("SessionEnd", info.id);
    }
    return null;
  }

  handleV2InboxEnqueued(ev) {
    const d = ev.data || {};
    const item = d.item;
    if (!d.sessionID || !item || item.type !== "user") return null;
    const text = item.payload && item.payload.text;
    if (!text) return null;
    const cwd = this.sessionCwd.get(d.sessionID) || this.directory || undefined;
    // Fallback: ensure the session exists even if session.created was
    // emitted before this plugin instance loaded.
    const sessionStartEnv = this.markSessionStarted(d.sessionID, cwd);
    const promptEnv = this.envelope("UserPromptSubmit", d.sessionID, {
      cwd,
      prompt: text,
    });
    return sessionStartEnv ? [sessionStartEnv, promptEnv] : promptEnv;
  }

  handleV2ExecutionStarted(ev) {
    const d = ev.data || {};
    if (!d.sessionID) return null;
    return this.markSessionStarted(
      d.sessionID,
      this.sessionCwd.get(d.sessionID),
    );
  }

  handleV2ExecutionSucceeded(ev) {
    const d = ev.data || {};
    return d.sessionID ? this.markSessionStopped(d.sessionID) : null;
  }

  handleV2ExecutionInterrupted(ev) {
    const d = ev.data || {};
    if (!d.sessionID) return null;
    const additional = {};
    if (d.reason) additional.reason = d.reason;
    return this.markSessionStopped(d.sessionID, additional);
  }

  handleV2ExecutionFailed(ev) {
    const d = ev.data || {};
    if (!d.sessionID || !d.error) return null;
    return this.envelope("SessionError", d.sessionID, {
      cwd: this.sessionCwd.get(d.sessionID),
      error: d.error.message || d.error.type || "Session errored",
    });
  }

  handleV2SessionIdle(ev) {
    // Name kept for stream parity with older 2.x builds; the observed
    // turn end is session.execution.succeeded. The stop dedup makes a
    // double fire harmless.
    const d = ev.data || {};
    return d.sessionID ? this.markSessionStopped(d.sessionID) : null;
  }

  handleV2StepStarted(ev) {
    const d = ev.data || {};
    if (!d.sessionID) return null;
    if (d.model)
      this.getSession(d.sessionID).lastModel = `${d.model.providerID}/${d.model.id}`;
    return this.markSessionStarted(
      d.sessionID,
      this.sessionCwd.get(d.sessionID),
    );
  }

  handleV2TextDelta(ev) {
    const d = ev.data || {};
    if (!d.sessionID) return null;
    const s = this.getSession(d.sessionID);
    // A turn has one text part per assistant message and ordinal; a new
    // key starts a fresh buffer so Stop reports the final text only.
    const key = `${d.assistantMessageID || ""}:${d.ordinal ?? ""}`;
    if (s.textKey !== key) {
      s.textKey = key;
      s.lastAssistantText = "";
    }
    s.lastAssistantText = (s.lastAssistantText || "") + (d.delta || "");
    // Throttle: deltas arrive per token; one envelope per 2 s per session.
    const now = Date.now();
    if (now - (this.lastTokenSent.get(d.sessionID) || 0) < 2000) return null;
    this.lastTokenSent.set(d.sessionID, now);
    boundedMap(this.lastTokenSent, 200);
    return this.envelope("MessageUpdate", d.sessionID, {
      cwd: this.sessionCwd.get(d.sessionID),
    });
  }

  handleV2TextEnded(ev) {
    const d = ev.data || {};
    if (!d.sessionID) return null;
    const s = this.getSession(d.sessionID);
    s.textKey = `${d.assistantMessageID || ""}:${d.ordinal ?? ""}`;
    if (typeof d.text === "string") s.lastAssistantText = d.text;
    return null;
  }

  handleV2ToolInputStarted(ev) {
    const d = ev.data || {};
    if (d.id && d.name) {
      this.toolNames.set(d.id, d.name);
      boundedMap(this.toolNames, 200);
    }
    return null;
  }

  handleV2ToolCalled(ev) {
    const d = ev.data || {};
    if (!d.sessionID || !d.id) return null;
    return this.envelope("PreToolUse", d.sessionID, {
      cwd: this.sessionCwd.get(d.sessionID),
      tool_name: this.toolNameFor(d.id),
      tool_use_id: d.id,
      tool_input: d.input,
    });
  }

  handleV2ToolCompleted(ev) {
    const d = ev.data || {};
    if (!d.sessionID || !d.id) return null;
    return this.envelope("PostToolUse", d.sessionID, {
      cwd: this.sessionCwd.get(d.sessionID),
      tool_name: this.toolNameFor(d.id),
      tool_use_id: d.id,
    });
  }

  handleV2PermissionAsked(ev) {
    const d = ev.data || {};
    if (!d.id || !d.sessionID) return null;
    const action = d.action || "permission";
    const label = action.charAt(0).toUpperCase() + action.slice(1);
    const resources = Array.isArray(d.resources) ? d.resources : [];
    const extra = {
      cwd: this.sessionCwd.get(d.sessionID),
      tool_name: label,
      tool_input: { action, resources, save: d.save, metadata: d.source },
      permission_id: d.id,
      permission_title: `Allow ${label}`,
      permission_description:
        resources.length > 0
          ? `OpenCode wants ${label}: ${resources[0]}`
          : `OpenCode wants ${label}`,
      await_response: true,
    };
    return this.envelope("PermissionRequest", d.sessionID, extra, {
      sessionID: d.sessionID,
      requestID: d.id,
    });
  }

  handleV2PermissionSettled(ev) {
    const d = ev.data || {};
    if (!d.sessionID) return null;
    return this.envelope("PostToolUse", d.sessionID, {
      cwd: this.sessionCwd.get(d.sessionID),
    });
  }

  handleV2FormCreated(ev) {
    const d = ev.data || {};
    const form = d.form || d;
    if (!form.id || !form.sessionID) return null;
    const fields = Array.isArray(form.fields) ? form.fields : [];
    const titles = [];
    const options = [];
    for (const field of fields) {
      if (!field) continue;
      titles.push(String(field.title || field.key || "Question"));
      const row = [];
      if (Array.isArray(field.options)) {
        for (const o of field.options) {
          if (o && (o.label || o.value)) row.push(String(o.label || o.value));
        }
      }
      options.push(row);
    }
    return this.envelope(
      "QuestionAsked",
      form.sessionID,
      {
        cwd: this.sessionCwd.get(form.sessionID),
        question_id: form.id,
        question_title:
          form.title || titles.join("; ") || "OpenCode has a question",
        question_titles: titles,
        question_options: options,
        await_response: true,
      },
      { sessionID: form.sessionID, formID: form.id, fields },
    );
  }

  handleV2FormSettled(ev) {
    const d = ev.data || {};
    const sid = d.sessionID || (d.form && d.form.sessionID);
    if (!sid) return null;
    return this.envelope("PostToolUse", sid, {
      cwd: this.sessionCwd.get(sid),
    });
  }
}

function v2SessionId(ev) {
  const d = ev.data || {};
  return d.sessionID || (d.form && d.form.sessionID) || (d.info && d.info.id) || "";
}

// The V2 plugin entry: subscribe to the public event stream, tag every
// shell the agent spawns with the terminal env fallbacks, and stop both
// on unload.
function installV2(ctx) {
  const bridge = new OpenCodeBridgeV2({
    ctx,
    directory: ctx.location && ctx.location.directory,
  });
  const controller = new AbortController();
  void (async () => {
    try {
      for await (const event of ctx.event.subscribe({
        signal: controller.signal,
      })) {
        try {
          await bridge.dispatchEvent(event);
        } catch {
          // fail open: never block the agent on bridge errors
        }
      }
    } catch {}
  })();
  void ctx.shell
    .hook("create.before", (event) => {
      event.env.NOOK_ACTIVE = "1";
      for (const v of SHELL_ENV_KEYS) {
        if (process.env[v]) event.env["_AN_" + v] = process.env[v];
      }
    })
    .catch(() => {});
  return () => controller.abort();
}

// opencode 1.x calls server(config); opencode 2.x calls setup(ctx).
const NookPlugin = async (config) => new OpenCodeBridge(config).install();

export default {
  id: "nook.opencode",
  server: NookPlugin,
  async setup(ctx) {
    return installV2(ctx);
  },
};

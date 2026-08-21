---
name: ihp-datastar
description: Gotchas and patterns for wiring datastar-haskell (SSE hypermedia) into this IHP app. Read before touching any Controller/View that streams SSE patches.
---

# IHP + Datastar integration notes

## Setup

- Bootstrapped from bare `ihp-boilerplate` (no `Web/` until `make -s all; new-application Web`).
- `datastar-hs`/`datastar-hs-zlib` via `callHackageDirect` in `flake.nix` (they postdate nixpkgs' cabal-hashes snapshot; plain `callHackage` fails).
- `datastar-hs` needs http-types >=0.12.5 for `WAI.hAcceptEncoding`; pinned nixpkgs has 0.12.4. Patched with `substituteInPlace --replace-fail` in `flake.nix` (fails loudly if the line moves) instead of bumping http-types (would rebuild wai/warp/IHP).

## POST body: `readPostSignals`, never `readSignals`

IHP's middleware drains the body stream, so Datastar's `readSignals` gets an empty body → 400. Decode IHP's cached copy instead, in **every** POST action:

```haskell
readPostSignals :: (FromJSON a, ?request :: Request) => IO (Either String a)
readPostSignals = eitherDecode <$> getRequestBody
```

`readSignals ?request` is only correct for GET (query string).

## Patching elements

- Whole-element replace (default): `patchElements html`. Inner: `(patchElements html){peSelector = Just "#id", peMode = Inner}`. Prepend: `peMode = Prepend` on a dedicated container.
- `patchElements ""` is a **no-op**, not an empty patch. To clear, `Outer`-replace with an empty-but-present copy: `patchElements "<div id=\"x\"></div>"`.

## HSX gotchas

- Direct HSX backend: render with `renderMarkupText`, not blaze's `renderHtml`.
- View-prelude `Html` = `(?context :: Request, ?request :: Request) => Markup` (v1.6: `ControllerContext = Request`). Controller helpers rendering view functions need both in their signature.
- Literal `{`/`}` inside a `{...}` splice break HSX's lexer. Use `data-class:name={expr}`, or braces only in quoted literal attr values (`data-signals="{...}"` is fine).
- `patchElements`/`sendPatchElements` don't escape — `renderMarkupText (escapeHtml userText)` first.
- `{}`-interpolation is dead inside `<script>`/`<style>`; pass values via attribute (`<script data-dark={val}>`).
- Bare `data-*` attrs auto-fill `="true"` — write `data-bind:delay=""` explicitly.
- `show` already returns `Text` here; `T.pack (show x)` is redundant (`tshow` for the general case).
- Unknown attr names fail to compile (whitelist + `data-`/`aria-`/`hx-`/`_`), e.g. `autocorrect`.

## Datastar attribute/expression gotchas

- HTML lowercases attr names: `data-signals:editingId` creates signal `editingid`, not `$editingId`. Use object-form `data-signals="{editingId: ''}"` or kebab-case (`data-bind:edit-title` → `$editTitle`).
- `;`-separated statements only work as a whole expression; inside a ternary/`&&` branch use the comma operator: `cond && (@patch(...), $x = '')`.
- Elements with transient DOM state (open `<dialog>` etc.) must live outside SSE-patched sections — every patch incl. heartbeats resets them. Feed them per-item data via signals (`$deleteUrl` from server-rendered `pathTo`).
- Focus-on-reveal: `data-effect="$editingId === 'id' && setTimeout(() => el.focus())"` — without the deferral the element may still be hidden and `focus()` silently no-ops.
- Open multi-tab SSE streams with `@post`, not `@get`: Firefox serializes concurrent same-URL GETs — the second tab's request is held (never sent) behind the first never-ending stream. `Cache-Control: no-store` does NOT fix it; POST does.

## Theme (dark/light)

basecoat's toggle (`window.basecoat.theme.toggle()`) + `localStorage`; a sync inline `<script>` in `<head>` sets `.dark` pre-paint. Re-derive from `Web/View/Layout.hs` if broken — the mechanism has changed shape repeatedly.

Tailwind v4 `dark:` tracks `prefers-color-scheme`, not the `.dark` class — needs `@custom-variant dark (&:where(.dark, .dark *));` in `Layout.hs` or `dark:` utilities silently follow OS only.

## Misc

- No automated tests for demo routes — verify in-browser; `nix flake check --impure` covers the build only.
- App-wide mutable state: `NOINLINE unsafePerformIO` top-level `IORef`/`TVar` (IHP has no other slot for it).
- Schema parser rejects `TIMESTAMPTZ` — write `TIMESTAMP WITH TIME ZONE`.
- `IHP.Prelude` re-exports only `throw, throwIO, catch` from `Control.Exception.Safe`; `bracket_` etc. need explicit import.
- `respondAndExit :: ... -> IO a` (needs `?request`/`?respond`); helpers wrapping it must stay `IO a` to unify with `action`'s `IO ResponseReceived`.
- AutoRoute verbs from constructor prefixes: `Create*`→POST, `Update*`→POST/PATCH (no PUT), `Delete*`→DELETE, other→GET/POST/HEAD. Match with `@post`/`@patch`/`@delete`.
- Multi-tab broadcast pattern (version TVar + `registerDelay` heartbeat + `bracket_` client count): see `Web/Controller/Todo.hs`.

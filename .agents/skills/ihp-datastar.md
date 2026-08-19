---
name: ihp-datastar
description: Gotchas and patterns for wiring datastar-haskell (SSE hypermedia) into this IHP app. Read before touching any Controller/View that streams SSE patches.
---

# IHP + Datastar integration notes

## Bootstrap

Started from a bare `ihp-boilerplate` clone, not `ihp-new` — so it had no `Web/` until `make -s all; new-application Web` scaffolded it.

## Datastar package sourcing

`datastar-hs`/`datastar-hs-zlib` come from Hackage via `callHackageDirect` in `flake.nix` (plain `callHackage` can't find a hash — they postdate nixpkgs' cabal-hashes snapshot).

`datastar-hs`'s `WAI.hs` needs `WAI.hAcceptEncoding` (http-types >=0.12.5); this project's pinned nixpkgs ships 0.12.4. Patched via `overrideCabal`/`postPatch`/`substituteInPlace --replace-fail` in `flake.nix` rather than bumping http-types project-wide (would rebuild `wai`/`warp`/IHP). Use `--replace-fail`, not `sed` — it fails loudly if the patched line ever moves.

## POST body: `readPostSignals`, never `readSignals`

Datastar's `readSignals` reads via `strictRequestBody`, but IHP's middleware already drained that stream → empty-body 400. Fix, decode from IHP's cached copy:

```haskell
readPostSignals :: (FromJSON a, ?request :: Request) => IO (Either String a)
readPostSignals = eitherDecode <$> getRequestBody
```

Apply to **every** POST action, not just the one in front of you — easy to fix one handler and miss a shared helper. `readSignals ?request` is only correct for GET (signals in query string).

## Patching elements

- Whole-element replace (default): `patchElements html`.
- Inner content only: `(patchElements html){peSelector = Just "#id", peMode = Inner}`.
- Prepend to a list: `peMode = Prepend`, targeting a dedicated container (so it can be reset later).
- **`patchElements ""` is a no-op**, not an empty patch (`peElements = Nothing` for blank input). To clear a container, `Outer`-replace it with an empty-but-present copy: `patchElements "<div id=\"x\"></div>"`.

## HSX gotchas

- `IHP.HSX.Markup.Html` ≠ `Text.Blaze.Html.Html` (this project uses the "direct" HSX backend). Render with `renderMarkupText`, not blaze's `renderHtml`. `Html` is a plain concrete type, no implicit params needed.
- `patchElements`/`sendPatchElements` do **not** escape their `Text` argument (raw HTML client-side). Escape user input first: `renderMarkupText (escapeHtml someText)`.
- `{}`-interpolation doesn't work inside `<script>`/`<style>` (parsed as raw text). Pass server values via an attribute instead: `<script data-dark={val}>`, read via `dataset.dark`.
- Bare `data-*` attrs get auto-filled `="true"`. Datastar's `data-bind:<signal>`/`data-popover` etc. want no value — write `data-bind:delay=""` explicitly.
- `tshow` (IHP prelude) = `Text.pack . show`; `show` itself already returns `Text` here, so `T.pack (show x)` is usually redundant.
- Only known HTML attribute names (plus `data-`/`aria-`/`hx-`/`_`) pass HSX's parser — e.g. `autocorrect` isn't in the whitelist and fails to compile.

## Theme (dark/light)

Handled by `basecoat`'s own theme toggle (`window.basecoat.theme.toggle()`), storing in `localStorage`; a synchronous inline `<script>` in `<head>` sets `.dark` before first paint to avoid a flash. Re-derive from `Web/View/Layout.hs` if this breaks — the mechanism has changed shape more than once (TVar → cookie → basecoat/localStorage).

Tailwind v4's `dark:` variant defaults to `prefers-color-scheme`, **not** the toggled `.dark` class — needs `@custom-variant dark (&:where(.dark, .dark *));` (a `<style type="text/tailwindcss">` block in `Layout.hs`) or `dark:` utilities silently only track OS preference.

## Misc

- No automated tests for the Datastar demo routes — verify manually in-browser; `nix flake check --impure` only covers the build.
- `NOINLINE unsafePerformIO` top-level `IORef`/`TVar` is this project's pattern for ad hoc app-wide mutable state (IHP has no built-in slot for it outside session/cookies) — e.g. `Rocket.hs`'s generation counter for cancelling stale SSE runs.

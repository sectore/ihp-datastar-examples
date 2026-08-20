module Web.View.Layout (defaultLayout, Html, themeToggleButtonHtml) where

import IHP.ViewPrelude
import IHP.Environment
import Generated.Types
import Web.Types
import Web.Routes
import Application.Helper.View

import IHP.Controller.Cookie (getCookie, setCookie)


defaultLayout :: Html -> Html
defaultLayout inner = [hsx|
<!DOCTYPE html>
<html lang="en">
    <head>
        {metaTags}
        {scripts}
        <title>{pageTitleOrDefault "IHP + Datastar"}</title>
    </head>
    <body
        class="min-h-screen transition-colors duration-200"
    >
        {pageHeader}
        {renderFlashMessages}
        {inner}
    </body>
</html>
|]
    where

        -- Hides the back-link on the welcome page (would link to itself).
        isHome :: Bool
        isHome = null (pathInfo ?request)

        pageHeader :: Html
        pageHeader = [hsx|
            <div>
                <div class="flex items-center justify-between p-4">
                    <div>{when (not isHome) backLink}</div>
                    {themeToggleButtonHtml}
                </div>
                <div class="flex flex-col items-center justify-center pb-12">
                    <a href="https://data-star.dev/" class="inline mb-4">
                        <img
                            src={assetPath "/datastar-logo.png"}
                            alt="Datastar"
                            class="size-16"
                        />
                    </a>
                    <div class="text-2xl">
                        <a type="button" class="btn text-2xl" data-variant="ghost" data-size="sm" href="https://ihp.digitallyinduced.com/">
                            IHP
                        </a>×
                        <a type="button" class="btn text-2xl" data-variant="ghost" data-size="sm" href="https://data-star.dev/">
                            Datastar
                        </a>
                    </div>
                </div>
            </div>
        |]

        backLink :: Html
        backLink = [hsx|
            <a href={WelcomeAction} class="text-sm text-gray-600 dark:text-gray-300 hover:underline">Home</a>
        |]

-- | Shared with 'Web.Controller.Theme.ToggleThemeAction's sendPatchElements
-- (same "theme-toggle" id).
themeToggleButtonHtml :: Html
themeToggleButtonHtml = [hsx|
    <button type="button" onclick="window.basecoat.theme.toggle()" class="btn rounded-full border-none size-8 cursor-pointer" data-variant="outline" data-size="icon">
        <span class="hidden dark:block">
            {iconSun}
        </span>
        <span class="block dark:hidden">
            {iconMoon}
        </span>
    </button>
    |]

scripts :: Html
scripts = [hsx|
        {when isDevelopment devScripts}
        <script src="https://unpkg.com/@tailwindcss/browser@4"></script>
        <!--
            Tailwind v4's default `dark:` variant follows the OS
            `prefers-color-scheme` media query, not any class. Without this,
            `dark:`-prefixed utility classes ignore the "dark" class the
            theme toggle sets on <html> entirely - they'd only ever match
            the visitor's OS setting. This repoints `dark:` at that class
            instead (Tailwind's own documented way to opt into class-based
            dark mode in v4).
        -->
        <style type="text/tailwindcss">
            @custom-variant dark (&:where(.dark, .dark *));
        </style>
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/basecoat-css@1.0.2/dist/basecoat-sera.cdn.min.css" />
        <script src="https://cdn.jsdelivr.net/npm/basecoat-css@1.0.2/dist/js/basecoat.min.js" defer></script>
        <script src="https://cdn.jsdelivr.net/npm/basecoat-css@1.0.2/dist/js/select.min.js" defer></script>
        <script type="module" src="https://cdn.jsdelivr.net/gh/starfederation/datastar@1.0.0/bundles/datastar.js"></script>
        <script>
          (() => {
            try {
              const stored = localStorage.getItem("themeMode");
              if (stored ? stored === "dark" : matchMedia("(prefers-color-scheme: dark)").matches) {
                document.documentElement.classList.add("dark");
              }
            } catch (_) {}
          })();
        </script>
    |]

-- | morphdom/helpers.js: unused by us, needed by livereload.js's globals.
-- Dev-only. Doesn't save a running SSE demo across a .hs edit - the dev
-- server kills the whole app process on reload regardless.
devScripts :: Html
devScripts = [hsx|
        <script src={assetPath "/vendor/morphdom-umd.min.js"}></script>
        <script src={assetPath "/helpers.js"}></script>
        <script id="livereload-script" src={assetPath "/livereload.js"} data-ws={liveReloadWebsocketUrl}></script>
    |]

metaTags :: Html
metaTags = [hsx|
    <meta charset="utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no"/>
    <meta property="og:title" content="App"/>
    <meta property="og:type" content="website"/>
    <meta property="og:url" content="TODO"/>
    <meta property="og:description" content="TODO"/>
    {autoRefreshMeta}
|]

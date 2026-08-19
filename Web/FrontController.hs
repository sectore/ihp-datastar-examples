module Web.FrontController where

import IHP.RouterPrelude
import Web.Controller.Prelude
import Web.View.Layout (defaultLayout)

-- Controller Imports
import Web.Controller.Static
import Web.Controller.Typewriter
import Web.Controller.Rocket

instance FrontController WebApplication where
    controllers =
        [ startPage WelcomeAction
        , parseRoute @TypewriterController
        , parseRoute @RocketController
        -- Generator Marker
        ]

instance InitControllerContext WebApplication where
    initContext = do
        setLayout defaultLayout

        -- The theme toggle keeps an SSE/fetch connection open just long enough to
        -- make these pages ineligible for the browser's bfcache. Without this
        -- header, hitting Back then serves the *original* HTTP-cached response
        -- (the page exactly as first rendered, before any toggle) instead of
        -- either a bfcache-restored live DOM or a fresh request - showing a stale
        -- theme no client-side fix can catch, since no page code runs at all.
        setHeader ("Cache-Control", "no-store")

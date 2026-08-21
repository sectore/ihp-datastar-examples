module Web.FrontController where

import IHP.RouterPrelude
import Web.Controller.Prelude
import Web.View.Layout (defaultLayout)

-- Controller Imports
import Web.Controller.Static
import Web.Controller.Typewriter
import Web.Controller.Rocket
import Web.Controller.Todo

instance FrontController WebApplication where
    controllers =
        [ startPage WelcomeAction
        , parseRoute @TypewriterController
        , parseRoute @RocketController
        , parseRoute @TodoController
        -- Generator Marker
        ]

instance InitControllerContext WebApplication where
    initContext = do
        setLayout defaultLayout

        -- Pages using SSE are bfcache-ineligible in Chrome; without this, Back
        -- serves the stale original HTTP response instead of a fresh request.
        setHeader ("Cache-Control", "no-store")

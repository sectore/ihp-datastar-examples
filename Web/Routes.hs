module Web.Routes where
import IHP.RouterPrelude
import Generated.Types
import Web.Types

-- Custom route: '/' has no natural AutoRoute path, so it's mapped explicitly here.
[routes|StaticController
GET /    WelcomeAction
|]

instance AutoRoute TypewriterController
instance AutoRoute RocketController

module Web.Types where

import IHP.Prelude
import IHP.ModelSupport
import Generated.Types
import Data.UUID (UUID)

data WebApplication = WebApplication deriving (Eq, Show)


data StaticController = WelcomeAction deriving (Eq, Show, Data)

data ThemeController = ToggleThemeAction deriving (Eq, Show, Data)

data TypewriterController
    = TypewriterAction
    | TypewriterStreamAction
    deriving (Eq, Show, Data)

data ActivityFeedController
    = ActivityFeedAction
    | EventGenerateAction
    | EventDoneAction
    | EventWarnAction
    | EventFailAction
    | EventInfoAction
    | EventResetAction
    deriving (Eq, Show, Data)

data HeapViewController
    = HeapViewSimpleListAction
    | HeapViewLiveMapAction
    | HeapViewLiveFibsAction
    | HeapAction { sessionId :: UUID }
    | ForceAction { sessionId :: UUID, addr :: Text }
    | RunAction { sessionId :: UUID }
    | ResetAction { existingSessionId :: Maybe Text, mode :: Maybe Text }
    deriving (Eq, Show, Data)

data RocketController
    = RocketAction
    | RocketRunAction
    deriving (Eq, Show, Data)

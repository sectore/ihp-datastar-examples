module Web.Types where

import IHP.Prelude
import IHP.ModelSupport
import Generated.Types

data WebApplication = WebApplication deriving (Eq, Show)


data StaticController = WelcomeAction deriving (Eq, Show, Data)

data TypewriterController
    = TypewriterAction
    | TypewriterStreamAction
    deriving (Eq, Show, Data)

data RocketController
    = RocketAction
    | RocketRunAction
    deriving (Eq, Show, Data)

data TodoController
    = TodosAction
    | TodosUpdatesAction
    | CreateTodoAction
    | ToggleTodoAction { todoId :: !(Id Todo) }
    | UpdateTodoAction { todoId :: !(Id Todo) }
    | DeleteTodoAction { todoId :: !(Id Todo) }
    deriving (Eq, Show, Data)

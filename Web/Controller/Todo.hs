module Web.Controller.Todo where

import Web.Controller.Prelude
import Web.View.Todo.Index

import Control.Concurrent.STM (TVar, atomically, modifyTVar', newTVarIO, readTVar, readTVarIO, registerDelay, retry)
import Control.Exception.Safe (bracket_)
import Data.Aeson (eitherDecode, withObject, (.:))
import Data.Functor (void)
import Data.Text qualified as T
import System.IO.Unsafe (unsafePerformIO)

import Network.HTTP.Types (status204)
import Network.Wai (responseLBS)

import Hypermedia.Datastar
import Hypermedia.Datastar.Compression.Zlib (deflate, gzip)

import IHP.HSX.Markup (renderMarkupText)

-- | STM wake signal: bumped by every mutation and connect/disconnect.
{-# NOINLINE todosVersion #-}
todosVersion :: TVar Int
todosVersion = unsafePerformIO (newTVarIO 0)

-- | Open /TodosUpdates connections.
{-# NOINLINE connectedClients #-}
connectedClients :: TVar Int
connectedClients = unsafePerformIO (newTVarIO 0)

compressors :: [Compressor]
compressors = [gzip, deflate]

heartbeatMicros :: Int
heartbeatMicros = 15 * 1000 * 1000

-- | Decode signals from IHP's cached body copy; readSignals would hit the
-- already-drained stream (see .agents/skills/ihp-datastar.md).
readPostSignals :: (FromJSON a, ?request :: Request) => IO (Either String a)
readPostSignals = eitherDecode <$> getRequestBody

newtype CreateSignals = CreateSignals { newTitle :: Text }
instance FromJSON CreateSignals where
    parseJSON = withObject "CreateSignals" \o -> CreateSignals <$> o .: "newTitle"

newtype EditSignals = EditSignals { editTitle :: Text }
instance FromJSON EditSignals where
    parseJSON = withObject "EditSignals" \o -> EditSignals <$> o .: "editTitle"

instance Controller TodoController where
    action TodosAction = render IndexView

    -- @post, not @get: Firefox serializes concurrent same-URL GETs (second
    -- tab hangs behind the never-ending first stream); POSTs are never
    -- coalesced. Cache-Control: no-store did NOT fix the GET variant.
    action TodosUpdatesAction = respondAndExit $ sseResponseWith nullLogger compressors ?request \gen ->
        bracket_ (trackClient 1) (trackClient (-1)) (broadcastLoop gen)

    action CreateTodoAction = do
        signals <- readPostSignals
        case signals of
            Right CreateSignals { newTitle }
                | title <- T.strip newTitle
                , not (T.null title) -> void $ newRecord @Todo |> set #title title |> createRecord
            _ -> pure ()
        bumpAndRespond204

    -- fetchOneOrNothing + forM_ in the {todoId} actions: no-op instead of 500
    -- when the row was already deleted elsewhere.
    action ToggleTodoAction { todoId } = do
        maybeTodo <- query @Todo |> filterWhere (#id, todoId) |> fetchOneOrNothing
        forM_ maybeTodo \todo -> todo |> set #completed (not todo.completed) |> updateRecord
        bumpAndRespond204

    action UpdateTodoAction { todoId } = do
        signals <- readPostSignals
        maybeTodo <- query @Todo |> filterWhere (#id, todoId) |> fetchOneOrNothing
        case (signals, maybeTodo) of
            (Right EditSignals { editTitle }, Just todo)
                | title <- T.strip editTitle
                , not (T.null title) -> void $ todo |> set #title title |> updateRecord
            _ -> pure ()
        bumpAndRespond204

    action DeleteTodoAction { todoId } = do
        maybeTodo <- query @Todo |> filterWhere (#id, todoId) |> fetchOneOrNothing
        forM_ maybeTodo deleteRecord
        bumpAndRespond204

-- | Connect/disconnect: adjust the client count and wake all loops.
trackClient :: Int -> IO ()
trackClient delta = atomically do
    modifyTVar' connectedClients (+ delta)
    modifyTVar' todosVersion (+1)

-- | Version read BEFORE the query: a bump during fetch/send re-renders
-- immediately instead of being lost. Heartbeat expiry re-sends the section;
-- the write fails on a dead socket and bracket_ cleans up.
broadcastLoop :: (?modelContext :: ModelContext, ?context :: ControllerContext, ?request :: Request) => ServerSentEventGenerator -> IO ()
broadcastLoop gen = do
    version <- readTVarIO todosVersion
    todos <- query @Todo |> orderBy #createdAt |> fetch
    connected <- readTVarIO connectedClients
    sendPatchElements gen $ patchElements $ renderMarkupText $ todoSectionHtml todos connected
    heartbeat <- registerDelay heartbeatMicros
    atomically do
        v <- readTVar todosVersion
        expired <- readTVar heartbeat
        when (v == version && not expired) retry
    broadcastLoop gen

-- | Unconditional bump even on no-op mutations: the only bridge from a
-- mutation to the broadcasts, and it converges the actor's own tab to true
-- state in the tightest race (e.g. toggling a row someone else deleted).
bumpAndRespond204 :: (?request :: Request, ?respond :: Respond) => IO a
bumpAndRespond204 = do
    atomically $ modifyTVar' todosVersion (+1)
    respondAndExit $ responseLBS status204 [] ""

-- Heavily inspired by HelloWorld example of `datastar-haskell`
-- https://github.com/starfederation/datastar-haskell/tree/main/examples

module Web.Controller.Typewriter where

import Web.Controller.Prelude
import Web.View.Typewriter.Index

import Control.Concurrent (threadDelay)
import Data.Aeson (FromJSON (..), withObject, (.:))
import Data.IORef (IORef, atomicModifyIORef', newIORef, readIORef)
import Data.Text qualified as T
import System.IO.Unsafe (unsafePerformIO)

import Network.HTTP.Types (status400)
import Network.Wai (responseLBS)

import Hypermedia.Datastar
import Hypermedia.Datastar.Compression.Zlib (deflate, gzip)

import IHP.HSX.Markup (renderMarkupText, escapeHtml)

-- | Signals sent by the browser via `data-signals:delay`/`data-signals:msg`.
data TypewriterSignals = TypewriterSignals {delay :: Int, msg :: Text}

instance FromJSON TypewriterSignals where
    parseJSON = withObject "TypewriterSignals" $ \o -> TypewriterSignals
        <$> o .: "delay"
        <*> o .: "msg"

-- | Generation counter, bumped per run so a stale run can notice a newer one and stop patching.
{-# NOINLINE typewriterGenCounter #-}
typewriterGenCounter :: IORef Int
typewriterGenCounter = unsafePerformIO (newIORef 0)

instance Controller TypewriterController where
    action TypewriterAction = render IndexView

    action TypewriterStreamAction = do
        signalsResult <- readSignals ?request :: IO (Either String TypewriterSignals)
        case signalsResult of
            Left err -> respondAndExit $ responseLBS status400 [] (cs err)
            Right signals -> respondAndExit $ sseResponseWith nullLogger [gzip, deflate] ?request $ \gen -> do
                myGeneration <- atomicModifyIORef' typewriterGenCounter (\t -> (t + 1, t + 1))

                let msg' = msg signals
                forM_ [1 .. T.length msg'] $ \i -> do
                    currentGeneration <- readIORef typewriterGenCounter
                    -- skip if a newer run has started
                    when (currentGeneration == myGeneration) do
                        let html = renderMarkupText (escapeHtml (T.take i msg'))
                        sendPatchElements gen (patchElements html){peSelector = Just "#output", peMode = Inner}
                        threadDelay (delay signals * 1000)

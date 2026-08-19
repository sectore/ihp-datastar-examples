-- Heavily inspired by HelloWorld example of `datastar-haskell`
-- https://github.com/starfederation/datastar-haskell/tree/main/examples

module Web.View.Typewriter.Index where

import Web.View.Prelude

data IndexView = IndexView

instance View IndexView where
    html IndexView = [hsx|
        <div class="max-w-xs mx-auto my-16">
            <div data-signals:delay="100" data-signals:msg="'Hello IHP + Datastar !!!'" class="space-y-3">
                <div role="group" class="field">
                    <label for="delay">Delay in ms</label>
                    <input
                        data-bind:delay=""
                        id="delay"
                        type="number"
                        step="50"
                        min="0"
                        class="input"
                    />
                </div>
                <div role="group" class="field">
                    <label for="message">Message</label>
                    <input
                        data-bind:msg=""
                        id="message"
                        class="input"
                    />
                </div>

                <button data-on:click={startExpr} class="btn cursor-pointer">
                    Run
                </button>
            </div>

            <h1 id="output" class="mt-6 text-2xl"></h1>
        </div>
    |]
        where
            startExpr :: Text
            startExpr = "@get('" <> pathTo TypewriterStreamAction <> "')"

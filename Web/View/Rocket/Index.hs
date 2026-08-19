module Web.View.Rocket.Index (IndexView (..), rocketCellId, pixelCellClass, rocketGridHtml) where

import Web.View.Prelude

data IndexView = IndexView

-- | 20x20 grid to render pixel-art rocket.
rocketRows :: [Int]
rocketRows = [1 .. 20]

rocketCols :: [Int]
rocketCols = [1 .. 20]

rocketCellId :: Int -> Int -> Text
rocketCellId row col = "px-" <> tshow row <> "-" <> tshow col

-- | Shared with 'Web.Controller.Rocket.rocketPatchHtml'.
pixelCellClass :: Text
pixelCellClass = "size-4 sm:size-6 transition-colors duration-50"

-- | Whole grid, every cell blank. Also reused by 'Web.Controller.Rocket' to
-- reset the grid before each run. Column/row sizes must match 'pixelCellClass'.
rocketGridHtml :: Html
rocketGridHtml = [hsx|
    <div
        id="rocket-grid"
        class="inline-grid mx-auto grid-cols-[repeat(20,1rem)] auto-rows-[1rem] sm:grid-cols-[repeat(20,1.5rem)] sm:auto-rows-[1.5rem]"
        data-class="{grayscale: $colorMode == 'grayscale-dark' || $colorMode == 'grayscale-light', invert: $colorMode == 'grayscale-light'}"
    >
        {forEach rocketRows renderRow}
    </div>
|]
  where
    renderRow :: Int -> Html
    renderRow row = forEach rocketCols (renderCell row)

    renderCell :: Int -> Int -> Html
    renderCell row col = [hsx|
        <div id={rocketCellId row col} class={pixelCellClass}></div>
    |]

instance View IndexView where
    html IndexView = [hsx|
        <div class="max-w-3xl mx-auto flex flex-col items-center"
            data-signals:colorMode="'colors'"
            data-init={runExpr}>
            <div class="flex gap-2 mb-12">
                {colorModeCombobox}
                <button
                    type="button" class="btn"
                    data-variant="ghost"
                    data-size="icon-lg"
                    data-on:click={runExpr}
                >
                    {iconRefresh}
                </button>
            </div>

            {rocketGridHtml}
        </div>
    |]
        where
            runExpr :: Text
            runExpr = "@post('" <> pathTo RocketRunAction <> "')"

            -- basecoat's select fires a bubbling CustomEvent('change') with event.detail.value on the root.
            colorModeCombobox :: Html
            colorModeCombobox = [hsx|
                <div
                    id="color-mode-select"
                    class="select"
                    data-placeholder="Colors"
                    data-on:change="$colorMode = evt.detail.value"
                >
                    <button
                        type="button"
                        class="w-48 uppercase text-sm"
                        id="color-mode-select-trigger"
                        aria-haspopup="listbox"
                        aria-expanded="false"
                        aria-controls="color-mode-select-listbox"
                    >
                        <span>Color</span>
                        {iconChevronDown}
                    </button>
                    <div id="color-mode-select-popover" data-popover="" aria-hidden="true">
                        <div role="listbox"
                            id="color-mode-select-listbox"
                            class="uppercase text-sm"
                            aria-orientation="vertical"
                            aria-labelledby="color-mode-select-trigger"
                        >
                            <div role="option" data-value="colors" aria-selected="true">Color</div>
                            <div role="option" data-value="grayscale-light">Grayscale (light)</div>
                            <div role="option" data-value="grayscale-dark">Grayscale (dark)</div>
                        </div>
                    </div>
                    <input type="hidden" name="color-mode" value="colors" />
                </div>
            |]

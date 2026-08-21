module Web.View.Todo.Index (IndexView (..), todoSectionHtml, todoItemHtml) where

import Web.View.Prelude
import Data.Aeson qualified as Aeson

data IndexView = IndexView

-- | Empty shell; content arrives via SSE. Signals sit outside #todomvc —
-- broadcasts outer-replace it, and re-applied data-signals resets values.
instance View IndexView where
    html IndexView = [hsx|
        <div
            class="max-w-xl mx-auto w-full px-4"
            data-signals="{filter: 'all', editingId: '', editTitle: '', newTitle: '', deleteUrl: '', deleteId: ''}"
            data-init={"@post('" <> pathTo TodosUpdatesAction <> "')"}
        >
            {sectionHtml loadingRowHtml 0 0}
            {deleteDialogHtml}
        </div>
    |]

-- | Spinner row shown in the list until the first SSE patch.
loadingRowHtml :: Html
loadingRowHtml = [hsx|
    <li class="flex justify-center center-items max-h p-8">
        <span class="badge" data-variant="secondary">{iconLoader} syncing</span>
    </li>
|]

-- | Shared confirm dialog; lives outside #todomvc so broadcasts (incl. the
-- 15s heartbeat) can't close it while open. Target/label arrive via signals.
deleteDialogHtml :: Html
deleteDialogHtml = [hsx|
    <dialog
        id="todo-delete-dialog"
        class="alert-dialog"
        aria-labelledby="todo-delete-dialog-title"
        aria-describedby="todo-delete-dialog-description"
        data-on:keydown={dialogKeydownExpr}
    >
        <div>
            <header>
                <figure>{iconTrash}</figure>
                <h2 id="todo-delete-dialog-title">Delete this todo?</h2>
                <p id="todo-delete-dialog-description">
                    Todo with ID "<span data-text="$deleteId"></span>" will be deleted permanently.
                </p>
            </header>
            <footer>
                <button type="button" class="btn" data-variant="outline"
                    data-on:click={cancelExpr}
                >Cancel</button>
                <button type="button" class="btn" data-variant="destructive"
                    data-on:click={confirmExpr}
                >Delete</button>
            </footer>
        </div>
    </dialog>
|]
  where
    cancelExpr :: Text
    cancelExpr = "el.closest('dialog').close()"
    confirmExpr = "@delete($deleteUrl); " <> cancelExpr
    -- Escape already closes natively; Enter's default (activate the
    -- focused Cancel button) is overridden so it confirms delete instead.
    dialogKeydownExpr =
        "evt.key === 'Enter' && (evt.preventDefault(), @delete($deleteUrl), " <> cancelExpr <> ")"

-- | User text as a JS string literal; HSX only escapes the HTML-attr layer.
jsString :: Text -> Text
jsString = cs . Aeson.encode

-- | Full #todomvc section, outer-replaced on every SSE wake.
todoSectionHtml :: [Todo] -> Int -> Html
todoSectionHtml todos connected = sectionHtml (forEach todos todoItemHtml) pending connected
  where
    pending = length $ filter (not . (.completed)) todos

-- | Section chrome, shared by the loading shell and broadcast renders.
sectionHtml :: Html -> Int -> Int -> Html
sectionHtml listBody pending connected = [hsx|
    <section id="todomvc" class="w-full">
        <header class="flex gap-2 p-4">
            <input
                class="input grow"
                type="text"
                placeholder="What needs to be done?"
                data-bind:new-title=""
                data-on:keydown={addOnEnterExpr}
            />
            <button
                type="button" class="btn"
                data-on:click={addExpr}
                data-indicator:_fetching=""
                data-attr:disabled="$_fetching"
            >Add</button>
        </header>
        <ul id="todo-list" class="divide-y min-h-56">
            {listBody}
        </ul>
        <footer class="flex items-center justify-between gap-2 p-4 text-sm">
            <span class="badge" data-variant="secondary">{pendingLabel}</span>
            <div class="flex gap-1">
                {filterButton "all" "All"}
                {filterButton "active" "Active"}
                {filterButton "completed" "Completed"}
            </div>
            <span class="badge" data-variant="secondary">{connected} connected</span>
        </footer>
    </section>
|]
  where
    addExpr = "$newTitle.trim() && (@post('" <> pathTo CreateTodoAction <> "'), $newTitle = '')"
    addOnEnterExpr = "evt.key === 'Enter' && " <> addExpr

    pendingLabel :: Text
    pendingLabel = tshow pending <> if pending == 1 then " item left" else " items left"

    filterButton :: Text -> Text -> Html
    filterButton value label = [hsx|
        <button
            type="button" class="btn" data-variant="ghost" data-size="sm"
            data-on:click={"$filter = '" <> value <> "'"}
            data-class:font-normal={noActive}
            data-class:underline={noActive}
        >{label}</button>
    |]
      where
        noActive = "$filter !== '" <> value <> "'"

-- | Display + edit views in one <li>, toggled by $editingId; filter
-- visibility is baked in from the row's own completed value.
todoItemHtml :: Todo -> Html
todoItemHtml todo = [hsx|
    <li id={"todo-" <> tshow todo.id} class="flex items-center px-4 py-2" data-show={visibilityExpr}>
        <div class="flex items-center gap-2 grow" data-show={"$editingId !== " <> idLit}>
            <input
                id={todo.id}
                type="checkbox" class="input"
                checked={todo.completed}
                data-on:click={"@post('" <> pathTo (ToggleTodoAction todo.id) <> "')"}
            />
            <label for={todo.id} class={titleClass}>{todo.title}</label>
            <button type="button" class="btn ml-auto" data-variant="ghost" data-size="sm"
                data-on:click={enterEditExpr}
            >Edit</button>
            <button type="button" class="btn" data-variant="ghost" data-size="sm"
                data-on:click={confirmDeleteExpr}
            >Delete</button>
        </div>
        <div class="flex items-center gap-2 grow" data-show={"$editingId === " <> idLit}>
            <input
                class="input grow text-sm font-normal" type="text"
                data-bind:edit-title=""
                data-on:keydown={editKeydownExpr}
                data-effect={focusExpr}
            />
            <button type="button" class="btn" data-size="sm"
                data-on:click={saveExpr}
                data-indicator:_fetching=""
                data-attr:disabled="$_fetching"
            >Save</button>
            <button type="button" class="btn" data-variant="ghost" data-size="sm"
                data-on:click="$editingId = ''"
            >Cancel</button>
        </div>
    </li>
|]
  where
    idLit = jsString $ tshow todo.id

    visibilityExpr :: Text
    visibilityExpr
        | todo.completed = "$filter !== 'active'"
        | otherwise      = "$filter !== 'completed'"

    titleClass :: Text
    titleClass = classes ["grow", ("line-through opacity-60", todo.completed)]

    enterEditExpr = "$editingId = " <> idLit <> "; $editTitle = " <> jsString todo.title

    focusExpr = "$editingId === " <> idLit <> " && setTimeout(() => el.focus())"

    confirmDeleteExpr =
        "$deleteUrl = '" <> pathTo (DeleteTodoAction todo.id) <> "'; $deleteId = " <> idLit
        <> "; document.getElementById('todo-delete-dialog').showModal()"

    savePatch = "@patch('" <> pathTo (UpdateTodoAction todo.id) <> "')"
    saveExpr = savePatch <> "; $editingId = ''"
    editKeydownExpr =
        "evt.key === 'Enter' ? $editTitle.trim() && (" <> savePatch <> ", $editingId = '') : evt.key === 'Escape' && ($editingId = '')"

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
            data-signals="{filter: 'all', editingId: '', editTitle: '', newTitle: '', deleteUrl: '', deleteTitle: ''}"
            data-init={"@post('" <> pathTo TodosUpdatesAction <> "')"}
        >
            {sectionHtml loadingRowHtml 0 0}
            {deleteDialogHtml}
        </div>
    |]

-- | Spinner row shown in the list until the first SSE patch.
loadingRowHtml :: Html
loadingRowHtml = [hsx|
    <li class="flex justify-center p-8">
        <span class="badge">{iconLoader} syncing</span>
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
    >
        <div>
            <header>
                <figure>{iconTrash}</figure>
                <h2 id="todo-delete-dialog-title">Delete this todo?</h2>
                <p id="todo-delete-dialog-description">
                    This action cannot be undone. This will permanently delete
                    "<span data-text="$deleteTitle"></span>".
                </p>
            </header>
            <footer>
                <button type="button" class="btn" data-variant="outline"
                    data-on:click="el.closest('dialog').close()"
                >Cancel</button>
                <button type="button" class="btn" data-variant="destructive"
                    data-on:click="@delete($deleteUrl); el.closest('dialog').close()"
                >Delete</button>
            </footer>
        </div>
    </dialog>
|]

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
        <ul id="todo-list" class="divide-y border-y">
            {listBody}
        </ul>
        <footer class="flex items-center justify-between gap-2 p-4 text-sm">
            <span>{pendingLabel}</span>
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
            data-class:font-bold={activeExpr}
            data-class:underline={activeExpr}
        >{label}</button>
    |]
      where
        activeExpr = "$filter === '" <> value <> "'"

-- | Display + edit views in one <li>, toggled by $editingId; filter
-- visibility is baked in from the row's own completed value.
todoItemHtml :: Todo -> Html
todoItemHtml todo = [hsx|
    <li id={"todo-" <> tshow todo.id} class="flex items-center px-4 py-2" data-show={visibilityExpr}>
        <div class="flex items-center gap-2 grow" data-show={"$editingId !== " <> idLit}>
            <input
                type="checkbox" class="checkbox"
                checked={todo.completed}
                data-on:click={"@post('" <> pathTo (ToggleTodoAction todo.id) <> "')"}
            />
            <span class={titleClass} data-on:click={enterEditExpr}>{todo.title}</span>
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
    titleClass = classes ["grow", "cursor-pointer", ("line-through opacity-60", todo.completed)]

    enterEditExpr = "$editingId = " <> idLit <> "; $editTitle = " <> jsString todo.title

    focusExpr = "$editingId === " <> idLit <> " && setTimeout(() => el.focus())"

    confirmDeleteExpr =
        "$deleteUrl = '" <> pathTo (DeleteTodoAction todo.id) <> "'; $deleteTitle = " <> jsString todo.title
        <> "; document.getElementById('todo-delete-dialog').showModal()"

    savePatch = "@patch('" <> pathTo (UpdateTodoAction todo.id) <> "')"
    saveExpr = savePatch <> "; $editingId = ''"
    editKeydownExpr =
        "evt.key === 'Enter' ? $editTitle.trim() && (" <> savePatch <> ", $editingId = '') : evt.key === 'Escape' && ($editingId = '')"

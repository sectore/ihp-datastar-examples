module Web.View.Static.Welcome where
import Web.View.Prelude

data WelcomeView = WelcomeView

instance View WelcomeView where
    html WelcomeView = [hsx|
        <div class="mx-auto max-w-lg flex-col gap-4">
            <a href={TypewriterAction} class="item">
                <section>
                <h3>Typewriter</h3>
                </section>
                <aside>{iconArrowRight}</aside>
            </a>
            <a href={RocketAction} class="item">
                <section>
                <h3>Rocket</h3>
                </section>
                <aside>{iconArrowRight}</aside>
            </a>
        </div>
    |]


    -- <div class="p-8">
    --     <div class="mx-auto max-w-lg divide-y divide-gray-200 dark:divide-gray-800 rounded-lg border border-gray-200 dark:border-gray-800 overflow-hidden">
    --         <a href={HelloWorldAction} class="block px-4 py-3 hover:bg-gray-50 dark:hover:bg-gray-800">
    --             Hello World
    --         </a>
    --         <a href={ActivityFeedAction} class="block px-4 py-3 hover:bg-gray-50 dark:hover:bg-gray-800">
    --             Activity Feed
    --         </a>
    --         <a href={HeapViewSimpleListAction} class="block px-4 py-3 hover:bg-gray-50 dark:hover:bg-gray-800">
    --             Heap Visualizer
    --         </a>
    --         <a href={HeapViewLiveMapAction} class="block px-4 py-3 hover:bg-gray-50 dark:hover:bg-gray-800">
    --             Heap Visualizer
    --         </a>
    --         <a href={HeapViewLiveFibsAction} class="block px-4 py-3 hover:bg-gray-50 dark:hover:bg-gray-800">
    --             Heap Visualizer
    --         </a>
    --     </div>
    -- </div>

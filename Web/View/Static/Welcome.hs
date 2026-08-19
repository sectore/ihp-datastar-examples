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

<%inherit file="/base.mako" />

<%def name="title()">Who's that Pokémon?</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">Pokédex</a></li>
    <li>Gadgets</li>
    <li>Who's that Pokémon?</li>
</ul>
</%def>

<h1>Who's that Pokémon?</h1>

<div id="js-dex-wtp">
    <button id="js-dex-wtp-start">Start</button>

    <div id="js-dex-wtp-thinking">
        Hang on, I'm thinking...
    </div>

    <div id="js-dex-wtp-board">
        <div class="question"></div>

        <form class="answer">
            <p> Identify this Pokémon: </p>
            <p> <input type="text" size="12" name="pokemon"> <button type="submit">OK</button> </p>
        </form>
    </div>

    <div id="js-dex-wtp-result">
        <div class="response"></div>
        <button id="js-dex-wtp-restart">Go again</button>
    </div>
</div>

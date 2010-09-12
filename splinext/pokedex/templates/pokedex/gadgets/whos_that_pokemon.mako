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
    <div id="js-dex-wtp-loading">
        loadin'
    </div>

    <div id="js-dex-wtp-options">
        <p class="intro">Pick your poison, and hit Start!</p>
        <div class="dex-column-container">
        <ul class="dex-column2">
            <li><label><input type="checkbox" name="category" value="cry"> Silhouettes</label></li>
            <li><label><input type="checkbox" name="category" value="cry"> Cries</label></li>
            <li><label><input type="checkbox" name="category" value="cry"> Pokédex flavor text</label></li>
            <li><label><input type="checkbox" name="category" value="cry"> Pokédex numbers</label></li>
        </ul>
        <ul class="dex-column2">
            <li><label><input type="radio" name="difficulty" value="baby"> Easy</label></li>
            <li><label><input type="radio" name="difficulty" value="normal" checked="checked"> Medium</label></li>
            <li><label><input type="radio" name="difficulty" value="spergin"> Hard</label></li>
        </ul>
        </div>

        <p class="go">
            <button id="js-dex-wtp-start">Start</button>
        </p>
    </div>

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

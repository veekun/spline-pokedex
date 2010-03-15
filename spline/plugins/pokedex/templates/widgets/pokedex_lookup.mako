<form id="pokedex-lookup" method="GET" action="${url(controller='dex', action='lookup')}">
<p> <label>
    Pokédex <br/>
    <a href="${url('/dex')}" style="float: left; margin-left: -20px;"><img src="${h.static_uri('spline', 'icons/question-white.png')}" alt="Help" title="Help!"></a>
    <input type="text" name="lookup" class="dex-lookup js-dex-suggest"/>
    <input type="submit" value="Look up"/>
</label> </p>
</form>

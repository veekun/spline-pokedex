<form id="pokedex-lookup" method="GET" action="${h.url_for(controller='dex', action='lookup')}">
<p> <label>
    Pokédex <br/>
    <input type="text" name="lookup" class="dex-lookup js-dex-complete"/>
    <input type="submit" value="Look up"/>
</label> </p>
</form>

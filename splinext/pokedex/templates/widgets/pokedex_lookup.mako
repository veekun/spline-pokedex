<%! from splinext.pokedex import i18n %>\

<form id="pokedex-lookup" method="GET" action="${url(controller='dex', action='lookup')}">
<p>
<label>
    ${_(u"Pokédex", context="lookup widget")} <br/>
    <a href="${url('/dex')}" style="float: left; margin-left: -20px;"><img src="${h.static_uri('spline', 'icons/question-white.png')}" alt="${_(u"Help")}" title="${_(u"Help!")}"></a>
    <input type="text" name="lookup" class="dex-lookup js-dex-suggest"/>
</label>
    <input type="submit" value="${_(u"Look up", context="lookup widget")}"/>
</p>
</form>

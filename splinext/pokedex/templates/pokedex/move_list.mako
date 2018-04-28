<%inherit file="/base.mako"/>
<%namespace name="dexlib" file="lib.mako"/>
<%! from splinext.pokedex import i18n %>\

<%def name="title()">${_("Moves")}</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">${_(u"Pokédex")}</a></li>
    <li>${_("Moves")}</li>
</ul>
</%def>

<h1>${_("Move lists")}</h1>
<p>${_(u'The following are all links to the <a href="{url}">move search</a>, so you can filter and sort however you want.').format(url=url(controller='dex_search', action='move_search')) | n}</p>

<h2>By generation</h2>
<ul class="classic-list">
    <li><a href="${url(controller='dex_search', action='move_search', introduced_in=['1','2','3','4','5','6','7'], sort='name')}">${_("EVERY MOVE EVER")}</a></li>
    <li><a href="${url(controller='dex_search', action='move_search', introduced_in='1', sort='id')}">${h.pokedex.generation_icon(1)} ${_("Red/Blue/Yellow")}</a></li>
    <li><a href="${url(controller='dex_search', action='move_search', introduced_in='2', sort='id')}">${h.pokedex.generation_icon(2)} ${_("Gold/Silver/Crystal")}</a></li>
    <li><a href="${url(controller='dex_search', action='move_search', introduced_in='3', sort='id')}">${h.pokedex.generation_icon(3)} ${_("Ruby/Sapphire/Emerald")}</a></li>
    <li><a href="${url(controller='dex_search', action='move_search', introduced_in='4', sort='id')}">${h.pokedex.generation_icon(4)} ${_("Diamond/Pearl/Platinum")}</a></li>
    <li><a href="${url(controller='dex_search', action='move_search', introduced_in='5', sort='id')}">${h.pokedex.generation_icon(5)} ${_("Black/White")}</a></li>
    <li><a href="${url(controller='dex_search', action='move_search', introduced_in='6', sort='id')}">${h.pokedex.generation_icon(6)} ${_("X/Y")}</a></li>
    <li><a href="${url(controller='dex_search', action='move_search', introduced_in='7', sort='id')}">${h.pokedex.generation_icon(7)} ${_("Sun/Moon")}</a></li>
</ul>

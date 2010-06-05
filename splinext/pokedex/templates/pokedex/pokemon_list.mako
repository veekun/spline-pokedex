<%inherit file="/base.mako"/>
<%namespace name="lib" file="/lib.mako"/>

<%def name="title()">Pokémon</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">Pokédex</a></li>
    <li>Pokémon</li>
</ul>
</%def>

<h1>Pokémon lists</h1>
<p>The following are all links to the <a href="${url(controller='dex_search', action='pokemon_search')}">Pokémon search</a>, so you can filter and sort however you want.</p>

<h2>By generation</h2>
<ul class="classic-list">
    <li><a href="${url(controller='dex_search', action='pokemon_search', introduced_in=['1','2','3','4'], sort='evolution-chain')}">EVERY POKéMON EVER</a></li>
    <li><a href="${url(controller='dex_search', action='pokemon_search', introduced_in='1', sort='evolution-chain')}">${h.pokedex.generation_icon(1)} Red/Blue/Yellow</a></li>
    <li><a href="${url(controller='dex_search', action='pokemon_search', introduced_in='2', sort='evolution-chain')}">${h.pokedex.generation_icon(2)} Gold/Silver/Crystal</a></li>
    <li><a href="${url(controller='dex_search', action='pokemon_search', introduced_in='3', sort='evolution-chain')}">${h.pokedex.generation_icon(3)} Ruby/Sapphire/Emerald</a></li>
    <li><a href="${url(controller='dex_search', action='pokemon_search', introduced_in='4', sort='evolution-chain')}">${h.pokedex.generation_icon(4)} Diamond/Pearl/Platinum</a></li>
</ul>

<h2>By regional Pokédex</h2>
<ul class="classic-list">
    <li><a href="${url(controller='dex_search', action='pokemon_search', in_pokedex='7', sort='evolution-chain')}">${h.pokedex.generation_icon(2)} Johto</a></li>
    <li><a href="${url(controller='dex_search', action='pokemon_search', in_pokedex='4', sort='evolution-chain')}">${h.pokedex.generation_icon(3)} Hoenn</a></li>
    <li><a href="${url(controller='dex_search', action='pokemon_search', in_pokedex='6', sort='evolution-chain')}">${h.pokedex.generation_icon(4)} Sinnoh</a></li>
</ul>

<h2>Miscellaneous interesting lists</h2>
<ul class="classic-list">
    <li><a href="${url(controller='dex_search', action='pokemon_search', evolution_stage='basic')}">Basic Pokémon</a></li>
    <li><a href="${url(controller='dex_search', action='pokemon_search', evolution_position='last')}">Fully-evolved Pokémon</a></li>
    <li><a href="${url(controller='dex_search', action='pokemon_search', evolution_position='only')}">Non-evolving Pokémon</a></li>
</ul>

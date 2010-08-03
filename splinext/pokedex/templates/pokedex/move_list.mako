<%inherit file="/base.mako"/>
<%namespace name="lib" file="/lib.mako"/>

<%def name="title()">Moves</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">Pokédex</a></li>
    <li>Moves</li>
</ul>
</%def>

<h1>Move lists</h1>
<p>The following are all links to the <a href="${url(controller='dex_search', action='move_search')}">move search</a>, so you can filter and sort however you want.</p>

<h2>By generation</h2>
<ul class="classic-list">
    <li><a href="${url(controller='dex_search', action='move_search', introduced_in=['1','2','3','4'], sort='name')}">EVERY MOVE EVER</a></li>
    <li><a href="${url(controller='dex_search', action='move_search', introduced_in='1', sort='id')}">${h.pokedex.generation_icon(1)} Red/Blue/Yellow</a></li>
    <li><a href="${url(controller='dex_search', action='move_search', introduced_in='2', sort='id')}">${h.pokedex.generation_icon(2)} Gold/Silver/Crystal</a></li>
    <li><a href="${url(controller='dex_search', action='move_search', introduced_in='3', sort='id')}">${h.pokedex.generation_icon(3)} Ruby/Sapphire/Emerald</a></li>
    <li><a href="${url(controller='dex_search', action='move_search', introduced_in='4', sort='id')}">${h.pokedex.generation_icon(4)} Diamond/Pearl/Platinum</a></li>
</ul>

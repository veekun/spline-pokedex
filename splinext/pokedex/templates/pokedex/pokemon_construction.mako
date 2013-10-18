<%inherit file="/base.mako"/>
<%namespace name="lib" file="/lib.mako"/>
<%namespace name="dexlib" file="lib.mako"/>
<%! from splinext.pokedex import db, i18n %>\

<%def name="title()">\
${_(u"{name} – Pokémon #{number}").format(name=(c.pokemon.name), number=c.pokemon.species.id)}
</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">${_(u'Pokédex')}</a></li>
    <li><a href="${url(controller='dex', action='pokemon_list')}">${_(u'Pokémon')}</a></li>
    <li>${c.pokemon.name}</li>
</ul>
</%def>

${dexlib.pokemon_page_header()}

<h1>${_('UNDER CONSTRUCTION')}</h1>

<img src="${h.static_uri('local', 'images/engiveer.png')}" align="right" alt="" title="I solve Pokémon problems">

<p>We don't have any data about ${c.pokemon.species.name} yet. Sorry.

<p>We can't rip data from X &amp; Y because the encryption hasn't been cracked yet.
But fear not! We're gathering info the old-fashioned way: by hand.
If you want to help us out, we're collecting info in <a href="https://docs.google.com/spreadsheet/ccc?key=0AuO1EN20b3BhdC16REg4ZkR3ZXFWczFNcy1mM1RuVHc&usp=drive_web">this spreadsheet</a>.
Ask <a href="${url('/chat')}">on IRC</a> for write access.

<p>In the meantime, try one of these other Pokédexes:

<%
    wiki_name = c.pokemon.species.name.replace(u" ", u"_")
    pokemondb_name = c.pokemon.species.name.replace(u"é", u"e")
%>
<ul class="classic-list">
<li><a href="http://bulbapedia.bulbagarden.net/wiki/${wiki_name}_%28Pok%C3%A9mon%29">Bulbapedia</a></li>
<li><a href="http://www.serebii.net/pokedex-xy/${"%03d" % c.pokemon.species.id}.shtml">Serebii.net</a></li>
<li><a href="http://pokemondb.net/pokedex/${pokemondb_name}">Pokémon Database</a>
<li><a href="http://pokemon.wikia.com/wiki/${wiki_name}">The Pokémon Wiki</a></li>
<li><a href="http://pokemon.gamepedia.com/${wiki_name}">Marriland Wiki</a></li>
</ul>

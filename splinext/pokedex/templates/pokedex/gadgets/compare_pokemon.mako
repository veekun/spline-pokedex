<%inherit file="/base.mako" />

<%def name="title()">Compare Pokémon</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">Pokédex</a></li>
    <li>Gadgets</li>
    <li>Compare Pokémon</li>
</ul>
</%def>

<h1>Compare Pokémon</h1>
<p>Select up to eight Pokémon to compare their stats, moves, etc.</p>

${h.form(url.current())}
<table class="striped-bodies dex-compare-pokemon">
<col class="labels">
<thead>
    <tr class="header-row">
        <th><button type="submit">Compare:</button></th>
        % for pokemon in c.pokemon:
        <th><input type="text" name="pokemon" value="${pokemon.full_name if pokemon else u''}"></th>
        % endfor
    </tr>
</thead>
</table>
${h.end_form()}

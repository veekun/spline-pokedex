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

${h.form(url.current(), method='GET')}
<table class="striped-bodies dex-compare-pokemon">
<col class="labels">
<thead>
    % if c.did_anything and any(_ and _.suggestions for _ in c.found_pokemon):
    <tr class="dex-compare-suggestions">
        <th><!-- label column --></th>
        % for found_pokemon in c.found_pokemon:
        <th>
            % if found_pokemon is None:
            <% pass %>\
            % elif found_pokemon.suggestions == []:
            no matches
            % elif found_pokemon.suggestions is not None:
            <ul>
                % for suggestion in found_pokemon.suggestions:
                <li><a href="${c.create_comparison_link(replace=found_pokemon, replace_to=suggestion.full_name)}">${suggestion.full_name}</a></li>
                % endfor
            </ul>
            % endif
        </th>
        % endfor
    </tr>
    % endif
    <tr class="header-row">
        <th><button type="submit">Compare:</button></th>
        % for found_pokemon in c.found_pokemon:
        <th><input type="text" name="pokemon" value="${found_pokemon.input if found_pokemon else u''}"></th>
        % endfor
    </tr>
    % if c.did_anything:
    <tr class="subheader-row">
        <th><!-- label column --></th>
        % for found_pokemon in c.found_pokemon:
        <th>
            % if found_pokemon and found_pokemon.pokemon:
            ${h.pokedex.pokemon_link(found_pokemon.pokemon,
                h.pokedex.pokemon_sprite(found_pokemon.pokemon, prefix=u'icons')
                + h.literal('<br>')
                + found_pokemon.pokemon.full_name)}
            % endif
        </th>
        % endfor
    </tr>
    % endif
</thead>
</table>
${h.end_form()}

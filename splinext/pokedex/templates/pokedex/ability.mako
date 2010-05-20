<%inherit file="/base.mako"/>
<%namespace name='dexlib' file='lib.mako'/>

<%def name="title()">${c.ability.name} – Ability #${c.ability.id}</%def>

<div id="dex-header">
    <a href="${url.current(name=c.prev_ability.name.lower(), form=None)}" id="dex-header-prev" class="dex-box-link">
        <img src="${h.static_uri('spline', 'icons/control-180.png')}" alt="«">
        ${c.prev_ability.id}: ${c.prev_ability.name}
    </a>
    <a href="${url.current(name=c.next_ability.name.lower(), form=None)}" id="dex-header-next" class="dex-box-link">
        ${c.next_ability.id}: ${c.next_ability.name}
        <img src="${h.static_uri('spline', 'icons/control.png')}" alt="»">
    </a>
    ${c.ability.id}: ${c.ability.name}
</div>

${h.h1('Essentials')}

<div class="dex-page-portrait">
    <p id="dex-page-name">${c.ability.name}</p>
    <p>${h.pokedex.generation_icon(c.ability.generation)}</p>
</div>

<div class="dex-page-beside-portrait">
    <h2>Summary</h2>
    <p>${h.literal(c.ability.short_effect.as_html)}</p>
</div>

${h.h1('Effect')}
<div class="dex-effect">
    ${h.literal(c.ability.effect.as_html)}
</div>
<h2>Flavor Text</h2>
<dl class="dex-pokemon-flavor-text">
    % for flavor_text_group in h.pokedex.collapse_flavor_text(c.ability.flavor_text):
    <% versions = sum((text.version_group.versions for text in flavor_text_group), []) %>
    % if len(versions) == len(versions[0].generation.versions):
    <dt>${h.pokedex.generation_icon(versions[0].generation)}</dt>
    % else:
    <dt>${h.pokedex.version_icons(*versions)}</dt>
    % endif
    <dd>${h.pokedex.render_flavor_text(flavor_text_group[0].flavor_text)}</dd>
    % endfor
</dl>

${h.h1(u'Pokémon', id='pokemon')}
<table class="dex-pokemon-moves striped-rows">
    ${dexlib.pokemon_table_columns()}
    <thead>
        <tr class="header-row">
            ${dexlib.pokemon_table_header()}
        </tr>
    </thead>
    <tbody>
        % for pokemon in c.pokemon:
        <tr>
            ${dexlib.pokemon_table_row(pokemon)}
        </tr>
        % endfor
    </tbody>
</table>

${h.h1('External Links', id='links')}
<ul class="classic-list">
    <li><a href="http://bulbapedia.bulbagarden.net/wiki/${c.ability.name.replace(' ', '_')}_%28ability%29">Bulbapedia</a></li>
    <li><a href="http://legendarypokemon.net/dp/abilities#${c.ability.name.lower().replace(' ', '+')}">Legendary Pokémon</a></li>
    <li><a href="http://serebii.net/abilitydex/${c.ability.name.lower().replace(' ', '')}.shtml">Serebii.net</a></li>
    <li><a href="http://smogon.com/dp/abilities/${c.ability.name.lower().replace(' ', '_')}">Smogon</a></li>
</ul>

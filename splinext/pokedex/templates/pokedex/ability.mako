<%inherit file="/base.mako"/>
<%namespace name="lib" file="/lib.mako"/>
<%namespace name='dexlib' file='lib.mako'/>
<%! from splinext.pokedex import i18n %>\

<%def name="title()">${_("%s - Abilities") % c.ability.name}</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">${_(u"Pokédex")}</a></li>
    <li><a href="${url(controller='dex', action='abilities_list')}">${_("Abilities")}</a></li>
    <li>${c.ability.name}</li>
</ul>
</%def>

<div id="dex-header">
    <a href="${url.current(name=c.prev_ability.name.lower())}" id="dex-header-prev" class="dex-box-link">
        <img src="${h.static_uri('spline', 'icons/control-180.png')}" alt="«">
        ${c.prev_ability.name}
    </a>
    <a href="${url.current(name=c.next_ability.name.lower())}" id="dex-header-next" class="dex-box-link">
        ${c.next_ability.name}
        <img src="${h.static_uri('spline', 'icons/control.png')}" alt="»">
    </a>
    ${c.ability.name}

    % if c.ability.conquest_pokemon:
    <ul class="inline-menu">
        <li>Main</li>
        <li><a href="${url(controller='dex_conquest', action='abilities', name=c.ability.name.lower())}">Conquest</a></li>
    </ul>
    % endif
</div>


<%lib:cache_content>
${h.h1(_('Essentials'))}
<div class="dex-page-portrait">
    <p id="dex-page-name">${c.ability.name}</p>
    <p>${dexlib.generation_icon(c.ability.generation)}</p>
</div>

<div class="dex-page-beside-portrait">
    <h2>${_("Summary")}</h2>
    <div class="markdown">
        ${c.ability.short_effect}
    </div>
</div>


${h.h1(_('Effect'))}
<div class="markdown">
    ${c.ability.effect}
</div>

% if c.moves:
${h.h2(_('Moves affected'), id=_('moves', context='anchor'))}
<table class="dex-pokemon-moves striped-rows">
    ${dexlib.move_table_columns()}
    <thead>
        <tr class="header-row">
            ${dexlib.move_table_header()}
        </tr>
    </thead>
    <tbody>
        % for move in c.moves:
        <tr>
            ${dexlib.move_table_row(move)}
        </tr>
        % endfor
    </tbody>
</table>
<p>${_(u'%d move', u'%d moves', len(c.moves)) % len(c.moves)}</p>
% endif


% if c.ability.changelog:
${h.h1(_('History'))}
<dl>
    % for change in c.ability.changelog:
    <dt>${_('Before %s') % dexlib.version_icons(*change.changed_in.versions) | n}</dt>
    <dd class="markdown">${change.effect}</dd>
    % endfor
</dl>
% endif


${h.h1(_('Flavor'))}
<div class="dex-column-container">
<div class="dex-column-2x">
    <h2>${_("Flavor Text")}</h2>
    ${dexlib.flavor_text_list(c.ability.flavor_text)}
</div>

<div class="dex-column">
    <h2>${_("Foreign Names")}</h2>
    <%dexlib:foreign_names object="${c.ability}"/>
</div>
</div>


${h.h1(_(u'Pokémon', context='plural'))}
<table class="dex-pokemon-moves striped-rows">
    ${dexlib.pokemon_table_columns()}
    % for method, pokemon_list in c.pokemon:
    <tbody>
        <tr class="header-row" id="pokemon:${method.lower()}">
            ${dexlib.pokemon_table_header()}
        </tr>
        <tr class="subheader-row">
            <th colspan="13">
                <a href="#pokemon:${method.lower()}" class="subtle"><strong>${method}</strong></a>: ${c.method_labels[method]}
            </th>
        </tr>
        % for pokemon in pokemon_list:
        <tr>
            ${dexlib.pokemon_table_row(pokemon)}
        </tr>
        % endfor
    </tbody>
    % endfor
</table>

<p>${_(u'%d Pokémon') % sum(len(pokemon_list) for method, pokemon_list in c.pokemon)}</p>


${h.h1(_('External Links'), id='links')}
<ul class="classic-list">
    <li><a href="http://bulbapedia.bulbagarden.net/wiki/${c.ability.name.replace(' ', '_')}_%28ability%29">${_("Bulbapedia")}</a></li>
    % if c.ability.generation_id <= 4:
    <li>${dexlib.generation_icon(4)} <a href="http://legendarypokemon.net/dp/abilities#${c.ability.name.lower().replace(' ', '+')}">${_(u"Legendary Pokémon")}</a></li>
    % endif
    <li><a href="http://serebii.net/abilitydex/${c.ability.name.lower().replace(' ', '')}.shtml">${_("Serebii.net")}</a></li>
    <li><a href="http://smogon.com/dex/sm/abilities/${c.ability.name.lower().replace(' ', '_')}">${_("Smogon")}</a></li>
</ul>
</%lib:cache_content>

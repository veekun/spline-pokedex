<%inherit file="/base.mako"/>
<%namespace name="dexlib" file="lib.mako"/>

<%def name="title()">${c.item.name} - Items (${c.item.pocket.name})</%def>

${h.h1('Essentials')}

## Portrait block
<div class="dex-page-portrait">
    <p id="dex-page-name">${c.item.name}</p>
    <%
        if c.item.is_underground or c.item.berry:
            sprite_path = 'items/big'
        else:
            sprite_path = 'items'
    %>\
    <div id="dex-pokemon-portrait-sprite">
        ${h.pokedex.pokedex_img(u"{0}/{1}.png".format(sprite_path, h.pokedex.filename_from_name(c.item.name)))}
    </div>
    <p id="dex-page-types">
        <a href="${url(controller='dex', action='item_pockets', pocket=c.item.pocket.identifier)}">
            ${h.pokedex.pokedex_img(u"chrome/bag/{0}.png".format(c.item.pocket.identifier))}
            ${c.item.pocket.name}
        </a> pocket
    </p>
</div>

<div class="dex-page-beside-portrait">
<dl>
    <dt>Cost</dt>
    <dd>
        % if c.item.cost:
        ${c.item.cost} Pokédollars
        % else:
        Can't be bought or sold
        % endif
    </dd>
</dl>
</div>


${h.h1('Effect')}
<p>${c.item.effect}</p>

% if c.item.fling_effect or c.item.berry:
<h2>Special move effects</h2>
<dl>
    % if c.item.fling_effect:
    <dt><a href="${url(controller='dex', action='moves', name='fling')}">Fling</a></dt>
    <dd>${c.item.fling_effect.effect}</dd>
    % endif
    % if c.item.berry:
    <dt><a href="${url(controller='dex', action='moves', name='natural gift')}">Natural Gift</a></dt>
    <dd>Inflicts regular ${h.pokedex.type_link(c.item.berry.natural_gift_type)} damage with ${c.item.berry.natural_gift_power} power.</dd>
    % endif
</dl>
% endif

<h2>Flavor text</h2>
<dl>
    <dt>${h.pokedex.generation_icon(4)}</dt>
    <dd>${c.item.flavor_text}</dd>
</dl>


% if c.item.berry:
${h.h1('Berry tag')}
<div class="dex-column-container">
<div class="dex-column">
    <h2>Growth</h2>
    <dl>
        <dt>Maximum harvest</dt>
        <dd>${c.item.berry.max_harvest} berries</dd>
        <dt>Time to grow</dt>
        <dd>
            ${c.item.berry.growth_time} hours per stage<br>
            ${c.item.berry.growth_time * 4} hours total<br>
            <%! from spline.plugins.pokedex.db import get_by_name %>
            ${h.pokedex.item_link(c.growth_mulch)}:
                ${c.item.berry.growth_time * 3 / 4}/${c.item.berry.growth_time * 3} hours<br>
            ${h.pokedex.item_link(c.damp_mulch)}:
                ${c.item.berry.growth_time * 5 / 4}/${c.item.berry.growth_time * 5} hours
        </dd>
        <dt>Soil drying rate</dt>
        <dd>${c.item.berry.soil_dryness}</dd>
    </dl>
</div>
<div class="dex-column">
    <h2>Taste</h2>
    <dl>
        % for berry_flavor in c.item.berry.flavors:
        <dt>${berry_flavor.contest_type.flavor.title()}</dt>
        <dd>
            % if berry_flavor.flavor:
            ${berry_flavor.flavor}
            (raises ${h.pokedex.pokedex_img("chrome/contest/{0}.png".format(berry_flavor.contest_type.name), alt=berry_flavor.contest_type.name)})
            % else:
            —
            % endif
        </dd>
        % endfor
        <dt>Smoothness</dt>
        <dd>${c.item.berry.smoothness}</dd>
    </dl>
</div>
<div class="dex-column">
    <h2>Flavor</h2>
    <dl>
        <dt>Size</dt>
        <dd>${"{0:.1f}".format(c.item.berry.size / 25.4)}" or ${"{0:.1f}".format(c.item.berry.size / 10.0)} cm</dd>
        <dt>Firmness</dt>
        <dd>${c.item.berry.firmness}</dd>
</div>
</div>
% endif


% if c.holding_pokemon:
${h.h1(u'Held by wild Pokémon')}
<table class="dex-pokemon-moves striped-rows">
## Columns
% for i, column in enumerate(c.held_version_columns):
% if i in c.held_version_last_columns:
<col class="dex-col-version dex-col-last-version">
% else:
<col class="dex-col-version">
% endif
% endfor
${dexlib.pokemon_table_columns()}

## Headers
<tr class="header-row">
    <%! import itertools %>\
    % for i, column in enumerate(c.held_version_columns):
    <th>
      ## Only print a generation icon if the whole gen is one column
      % if i in c.held_version_last_columns and \
          (i == 0 or i - 1 in c.held_version_last_columns):
        ${h.pokedex.generation_icon(column[0].generation)}
      % else:
        % for _, versions in itertools.groupby(column, key=lambda version: version.version_group):
        ${h.pokedex.version_icons(*versions)}<br>
        % endfor
      % endif
    </th>
    % endfor
    ${dexlib.pokemon_table_header()}
</tr>

## Rows
% for pokemon, version_rarities in sorted(c.holding_pokemon.items(), \
                                          key=lambda (k, v): k.id):
<tr>
    % for column in c.held_version_columns:
    <td>
        % if version_rarities[column[0]]:
        ${version_rarities[column[0]]}%
        % endif
    </td>
    % endfor

    ${dexlib.pokemon_table_row(pokemon)}
</tr>
% endfor
</table>
% endif

<%inherit file="/base.mako"/>
<%namespace name="dexlib" file="lib.mako"/>
<%! from splinext.pokedex import i18n %>\

<%def name="title()">${_("%s - Items") % c.item.name}</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">${_(u"Pokédex")}</a></li>
    <li><a href="${url(controller='dex', action='items_list')}">${_("Items")}</a></li>
    <li><a href="${url(controller='dex', action='item_pockets', pocket=c.item.pocket.identifier)}">${_("%s pocket") % c.item.pocket.name}</a></li>
    <li>${c.item.name}</li>
</ul>
</%def>

${h.h1(_('Essentials'))}

## Portrait block
<div class="dex-page-portrait">
    <p id="dex-page-name">${c.item.name}</p>
    <%
        if c.item.berry:
            sprite_path = 'items/berries'
        elif c.item.appears_underground:
            sprite_path = 'items/underground'
        else:
            sprite_path = 'items'
    %>\
    <div id="dex-item-portrait-sprite">
        ${dexlib.pokedex_img(u"{0}/{1}.png".format(sprite_path, h.pokedex.item_filename(c.item)))}
    </div>
    <p id="dex-page-types">
        <a href="${url(controller='dex', action='item_pockets', pocket=c.item.pocket.identifier)}">
            ${dexlib.pokedex_img(u"item-pockets/{0}.png".format(c.item.pocket.identifier))}
            ${c.item.pocket.name}
        </a> ${_("pocket")}
    </p>
</div>

<div class="dex-page-beside-portrait">
<h2>${_('Summary')}</h2>
${c.item.short_effect}

<h2>${_('Stats')}</h2>
<dl>
    <dt>${_("Cost")}</dt>
    <dd>
        % if c.item.cost:
        ${_(u"%s Pokédollars") % c.item.cost}
        % else:
        ${_(u"Can't be bought or sold")}
        % endif
    </dd>
    <dt>${_(u"Flags")}</dt>
    <dd>
        <ul class="classic-list">
            % for flag in c.item.flags:
            <li>${flag.description}</li>
            % endfor
        </ul>
    </dd>
</dl>
</div>


${h.h1(_('Effect'))}
<div class="markdown">
${c.item.effect}
</div>

% if c.item.pocket.identifier == u'machines':
${h.h1(_('Moves'))}
<p>${_(u"These are the moves taught by {item.name} in different games.").format(item=c.item)}</p>
<table class="dex-pokemon-moves striped-rows">
<colgroup>
    ## XXX These columns shouldn't be sortable
    <col>
    <col>
<colgroup>
    ${dexlib.move_table_columns()}
<thead>
    <tr class="header-row">
        <th></th>
        <th></th>
        ${dexlib.move_table_header()}
    </tr>
<tbody>
    % for generation, machines in h.pokedex.group_by_generation(c.item.machines):
        % for versions, move in h.pokedex.collapse_versions(machines, key=lambda x: x.move):
        <tr>
            <td>${dexlib.generation_icon(generation)}</td>
            <td>${dexlib.version_icons(*versions)}</td>
            ${dexlib.move_table_row(move)}
        </tr>
        % endfor
    % endfor
</table>
% endif

% if c.item.fling_effect or c.item.berry:
<h2>${_("Special move effects")}</h2>
<dl>
    % if c.item.fling_effect:
    <dt><a href="${url(controller='dex', action='moves', name='fling')}">${_("Fling")}</a></dt>
    <dd>${c.item.fling_effect.effect}</dd>
    % endif
    % if c.item.berry:
    <dt><a href="${url(controller='dex', action='moves', name='natural gift')}">${_("Natural Gift")}</a></dt>
    <dd>${_("Inflicts regular {type} damage with {power} power").format(type=dexlib.type_link(c.item.berry.natural_gift_type), power=c.item.berry.natural_gift_power) | n}.</dd>
    % endif
</dl>
% endif


${h.h1(_('Flavor'))}
<div class="dex-column-container">
<div class="dex-column-2x">
    <h2>${_("Flavor text")}</h2>
    ${dexlib.flavor_text_list(c.item.flavor_text)}
</div>

<div class="dex-column">
    <h2>${_("Foreign names")}</h2>
    <%dexlib:foreign_names object="${c.item}"/>
</div>
</div>


% if c.item.berry:
${h.h1(_('Berry tag'))}
<div class="dex-column-container">
<div class="dex-column">
    <h2>${_("Growth")}</h2>
    <dl>
        <dt>${_("Maximum harvest")}</dt>
        <dd>${_("%s berries") % c.item.berry.max_harvest}</dd>
        <dt>${_("Time to grow")}</dt>
        <dd>
            <% growth_time = c.item.berry.growth_time %>
            ${_("%s hours per stage", plural="%s hour per stage", n=growth_time) % growth_time}<br>
            ${_("%s hour total", plural="%s hours total", n=growth_time * 4) % (growth_time * 4)}<br>
            ${dexlib.item_link(c.growth_mulch)}:
                ${_("%s/%s hours", plural="%s/%s hours", n=growth_time * 3) % (growth_time * 3 / 4, growth_time * 3)}<br>
            ${dexlib.item_link(c.damp_mulch)}:
                ${_("%s/%s hours", plural="%s/%s hours", n=growth_time * 5) % (growth_time * 5 / 4, growth_time * 5)}
        </dd>
        <dt>${_("Soil drying rate")}</dt>
        <dd>${c.item.berry.soil_dryness}</dd>
    </dl>
</div>
<div class="dex-column">
    <h2>${_("Taste")}</h2>
    <dl>
        % for berry_flavor in c.item.berry.flavors:
        <dt>${berry_flavor.contest_type.flavor.title()}</dt>
        <dd>
            % if berry_flavor.flavor:
            ${berry_flavor.flavor}
            ${_("(raises %s)") % dexlib.pokedex_img("contest-types/{1}/{0}.png".format(berry_flavor.contest_type.identifier, c.game_language.identifier), alt=(berry_flavor.contest_type.name)) | n}
            % else:
            ${_(u"—")}
            % endif
        </dd>
        % endfor
        <dt>${_("Smoothness")}</dt>
        <dd>${c.item.berry.smoothness}</dd>
    </dl>
</div>
<div class="dex-column">
    <h2>${_("Flavor")}</h2>
    <dl>
        <dt>${_("Size")}</dt>
        <dd>${"{0:.1f}".format(c.item.berry.size / 25.4)}" or ${"{0:.1f}".format(c.item.berry.size / 10.0)} cm</dd>
        <dt>${_("Firmness")}</dt>
        <dd>${c.item.berry.firmness}</dd>
</div>
</div>
% endif


% if c.holding_pokemon:
${h.h1(_(u'Held by wild Pokémon'), id='pokemon')}
<table class="dex-pokemon-moves striped-rows">
## Columns
% for column_group in c.held_version_columns:
<colgroup class="dex-colgroup-versions">
    % for column in column_group:
    <col class="dex-col-version">
    % endfor
</colgroup>
% endfor
<colgroup>${dexlib.pokemon_table_columns()}</colgroup>

## Headers
<thead>
  <tr class="header-row">
    <% from itertools import groupby %>
    % for column_group in c.held_version_columns:
      ## Only print a generation icon if the whole gen is one column
      % if len(column_group) == 1:
        <th>${dexlib.generation_icon(column_group[0][0].generation)}</th>
      % else:
        % for column in column_group:
        <th>
          % for key, version_group in groupby(column, lambda version: version.version_group):
          ${dexlib.version_icons(*version_group)}<br />
          % endfor
        </th>
        % endfor
      % endif
    % endfor

    ${dexlib.pokemon_table_header()}
  </tr>
</thead>

## Rows
<tbody>
% for pokemon, version_rarities in h.keysort(c.holding_pokemon, lambda k: k.order):
    <tr>
        % for column in sum(c.held_version_columns, []):
            % if version_rarities[column[0]]:
            <td>${version_rarities[column[0]]}%</td>
            % else:
            <td></td>
            % endif
        % endfor

        ${dexlib.pokemon_table_row(pokemon)}
    </tr>
% endfor
</tbody>
</table>

<p>${_(u'%d Pokémon') % len(c.holding_pokemon)}</p>
% endif

${h.h1(_(u'External Links'), id='links')}
<ul class="classic-list">
    <li><a href="http://bulbapedia.bulbagarden.net/wiki/${c.item.name.replace(" ", "_")}">Bulbapedia</a></li>
    <li><a href="http://serebii.net/itemdex/${c.item.name.lower().replace(" ", "")}.shtml">Serebii.net</a></li>
</ul>

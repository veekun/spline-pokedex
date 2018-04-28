<%inherit file="/base.mako"/>
<%namespace name="lib" file="/lib.mako"/>
<%namespace name="dexlib" file="lib.mako"/>
<%! from splinext.pokedex import i18n %>\
<%! from splinext.pokedex import db %>\

<%def name="title()">${_(u"%s - Types") % c.type.name.title()}</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">${_(u"Pokédex")}</a></li>
    <li><a href="${url(controller='dex', action='types_list')}">${_(u"Types")}</a></li>
    <li>${c.type.name}</li>
</ul>
</%def>

<div id="dex-header">
    <a href="${url.current(name=c.prev_type.name.lower())}" id="dex-header-prev" class="dex-box-link">
        <img src="${h.static_uri('spline', 'icons/control-180.png')}" alt="«">
        ${dexlib.type_icon(c.prev_type)}
    </a>
    <a href="${url.current(name=c.next_type.name.lower())}" id="dex-header-next" class="dex-box-link">
        ${dexlib.type_icon(c.next_type)}
        <img src="${h.static_uri('spline', 'icons/control.png')}" alt="»">
    </a>
    ${dexlib.type_icon(c.type)}
</div>

<%lib:cache_content>
${h.h1(_('Essentials'))}

<div class="dex-page-portrait">
    <p id="dex-page-name">${c.type.name.title()}</p>
    <p id="dex-page-types">
        ${dexlib.type_icon(c.type)}
        % if c.type.damage_class is not None:
        ${dexlib.damage_class_icon(c.type.damage_class)}<span style="position: absolute" class="faded">*</span>
        % endif
    </p>
    <p>${dexlib.generation_icon(c.type.generation)}</p>
    % if c.type.damage_class is not None:
    <br/>
    <p class="faded">*before ${dexlib.generation_icon(4)}</p>
    % endif
</div>

<div class="dex-page-beside-portrait">
% if c.type.identifier == u'unknown':
    <h2>${_('Damage Dealt/Taken')}</h2>
    <p>??? theoretically took and dealt 1× damage with every type, but there were no ??? Pokémon or damaging moves.</p>
% elif c.type.identifier == u'shadow':
    <h2>${_('Damage Dealt/Taken')}</h2>
    <p>In XD, Shadow moves are super-effective against non-Shadow Pokémon and not very effective against Shadow
    Pokémon.  In Colosseum, Shadow Rush is regularly effective against everything.</p>
% else:
    <h2>${_('Damage Dealt')}</h2>
    <ul class="dex-type-list">
        % for type_efficacy in sorted(c.type.damage_efficacies, key=lambda efficacy: efficacy.target_type.name):
        <li class="dex-damage-dealt-${type_efficacy.damage_factor}">
             ${dexlib.type_link(type_efficacy.target_type)} ${h.pokedex.type_efficacy_label[type_efficacy.damage_factor]}
        </li>
        % endfor
    </ul>

    <h2>${_(u"Damage Taken")}</h2>
    <ul class="dex-type-list">
        % for type_efficacy in sorted(c.type.target_efficacies, key=lambda efficacy: efficacy.damage_type.name):
        <li class="dex-damage-taken-${type_efficacy.damage_factor}">
             ${dexlib.type_link(type_efficacy.damage_type)} ${h.pokedex.type_efficacy_label[type_efficacy.damage_factor]}
        </li>
        % endfor
    </ul>
% endif
</div>

${h.h1(_(u'Pokémon'), id='pokemon')}
% if c.type.identifier == u'unknown':
<%! from pokedex.db import markdown %>
<div class="markdown">
${markdown.MarkdownString(_(u"""
In Generation IV, pure []{type:flying}-types become ???-type during []{move:roost}.  This can be accomplished with
[]{move:conversion}, []{move:conversion-2}, or the ability []{ability:color-change}.  A Pokémon can legitimately have both
Roost and one of these only through the use of []{move:mimic}, []{move:sketch}, []{move:role-play}, or []{move:skill-swap}.
(No Pokémon that has []{ability:trace} or []{ability:multitype} learns Roost, and Multitype cannot be copied.)

Generation IV has [sprites for a ???-type Arceus](%s), even though Arceus cannot become ???-type through regular play.
Eggs are purely ???-type before hatching before Generation V, and are displayed as such in the Generation III status
screen.  In Generation V, the ??? type no longer exists.
""") % url(controller='dex', action='pokemon_flavor', name='arceus', form='???'), db.pokedex_session, c.language)}
</div>
% elif c.type.identifier == u'shadow':
<p>Shadow Pokémon are Pokémon whose hearts have been closed in Pokémon Colosseum and Pokémon XD: Gale of Darkness.  The
Shadow type, Shadow Pokémon, and Shadow moves are unique to those games.</p>

<p>A list of obtainable Shadow Pokémon is pending.</p>
% else:
<table class="dex-pokemon-moves striped-rows">
    ${dexlib.pokemon_table_columns()}
    <thead>
        <tr class="header-row">
            ${dexlib.pokemon_table_header()}
        </tr>
    </thead>
    <tbody>
        % for pokemon in c.type.pokemon:
        <tr>
            ${dexlib.pokemon_table_row(pokemon)}
        </tr>
        % endfor
    </tbody>
</table>
<p>${_(u"%d Pokémon") % len(c.type.pokemon)}</p>
% endif

${h.h1(_('Moves'))}
% if c.type.moves:
<table class="dex-pokemon-moves striped-rows">
    ${dexlib.move_table_columns()}
    <thead>
        <tr class="header-row">
            ${dexlib.move_table_header(gen_instead_of_type=True)}
        </tr>
    </thead>
    <tbody>
        % for move in c.type.moves:
        <tr>
            ${dexlib.move_table_row(move, gen_instead_of_type=True)}
        </tr>
        % endfor
    </tbody>
</table>
<p>${_(u"%d move", u"%d moves", n=len(c.type.moves)) % len(c.type.moves)}</p>
% endif

% if c.type.move_changelog:
${h.h2(_('Formerly {0}-type moves').format(c.type.name), _('moves:former'))}
<table class="dex-pokemon-moves striped-rows">
    <col>
    ${dexlib.move_table_columns()}
    <thead>
        <tr class="header-row">
            <th>${_('Before')}</th>
            ${dexlib.move_table_header()}
        </tr>
    </thead>
    <tbody>
        % for move_change in sorted(c.type.move_changelog, key=lambda c: c.move.name):
        <tr>
            <td>${dexlib.version_icons(*move_change.changed_in.versions)}</td>
            ${dexlib.move_table_row(move_change.move)}
        % endfor
    </tbody>
</table>
<p>${_(u"%d move", u"%d moves", n=len(c.type.move_changelog)) % len(c.type.move_changelog)}</p>
% endif


${h.h1(_('External Links'), id='links')}
<ul class="classic-list">
    % if c.type.generation.id <= 1:
    <li>${dexlib.generation_icon(1)} <a href="http://www.math.miami.edu/~jam/azure/pokedex/comp/${c.type.name}.htm">${_("Azure Heights")}</a></li>
    % endif
    % if c.type.identifier == u'unknown':
    <li><a href="http://bulbapedia.bulbagarden.net/wiki/%3F%3F%3F_(type)">${_("Bulbapedia")}</a></li>
    % elif c.type.identifier == u'shadow':
    <li><a href="http://bulbapedia.bulbagarden.net/wiki/Shadow_move">${_("Bulbapedia")}</a></li>
    % else:
    <li><a href="http://bulbapedia.bulbagarden.net/wiki/${c.type.name}_(type)">${_("Bulbapedia")}</a></li>
    <li><a href="http://www.smogon.com/dex/sm/types/${c.type.identifier}">${_("Smogon")}</a></li>
    % endif
</ul>
</%lib:cache_content>

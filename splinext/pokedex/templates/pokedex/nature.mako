<%inherit file="/base.mako"/>
<%namespace name="dexlib" file="lib.mako"/>
<%namespace name="lib" file="/lib.mako"/>
<%! from splinext.pokedex import i18n %>\

<%def name="title()">${_("%s - Natures") % c.nature.name}</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">${_(u"Pokédex")}</a></li>
    <li><a href="${url(controller='dex', action='natures_list')}">${_("Natures")}</a></li>
    <li>${c.nature.name}</li>
</ul>
</%def>

${h.h1(_('Essentials'))}

<div class="dex-page-portrait">
    <p id="dex-page-name">${c.nature.name}</p>

    % if c.nature.increased_stat == c.nature.decreased_stat:
    <p>
        ${_(u"Same as:")}
        <ul>
            % for nature in c.neutral_natures:
            <li><a href="${url(controller='dex', action='natures', name=nature.name.lower())}">${nature.name}</a></li>
            % endfor
        </ul>
    </p>
    % else:
    <p>${_(u"Inverse of")} <a href="${url(controller='dex', action='natures', name=c.inverse_nature.name.lower())}">${c.inverse_nature.name}</a></p>
    % endif
</div>

<div class="dex-page-beside-portrait">
    % if c.nature.increased_stat == c.nature.decreased_stat:
    <p>${_(u"This nature is neutral; it does not affect stats and causes no flavor preference.")}</p>
    % else:
    <dl>
        <dt>${_(u"Stat changes")}</dt>
        <dd>
            ${_(u"+10%")} ${c.nature.increased_stat.name}<br>
            ${_(u"-10%")} ${c.nature.decreased_stat.name}
        </dd>
        <dt>${_(u"Taste preference")}</dt>
        <dd>
            ${_(u"Likes %s; good for") % c.nature.likes_flavor.flavor}
            ${h.pokedex.pokedex_img("chrome/contest/{0}.png".format(c.nature.likes_flavor.identifier), alt=c.nature.likes_flavor.name)}<br>
            ${_(u"Hates %s; bad for") % c.nature.hates_flavor.flavor}
            ${h.pokedex.pokedex_img("chrome/contest/{0}.png".format(c.nature.hates_flavor.identifier), alt=c.nature.hates_flavor.name)}
        </dd>
    </dl>
    % endif
</div>


${h.h1(_('Not-so-essentials'))}
<div class="dex-column-container">
<div class="dex-column">
    <h2>${_(u"Battle Style Preferences")}</h2>
    <p>${_(u"These only affect the Battle Palace and Battle Tent.")}</p>

    <dl>
        <dt>${_(u"> 50% HP")}</dt>
        <dd>
            % for pref in c.nature.battle_style_preferences:
            ${pref.high_hp_preference}% ${pref.battle_style.name}<br>
            % endfor
        </dd>
        <dt>${_(u"< 50% HP")}</dt>
        <dd>
            % for pref in c.nature.battle_style_preferences:
            ${pref.low_hp_preference}% ${pref.battle_style.name}<br>
            % endfor
        </dd>
    </dl>
</div>

<div class="dex-column">
    <h2>${_(u"Pokéathlon Stats")}</h2>
    <ul class="classic-list">
        % for effect in c.nature.pokeathlon_effects:
        <li>${_(u"Up to {change} {stat}").format(change=effect.max_change, stat=effect.pokeathlon_stat.name)}</li>
        % endfor
    </ul>
</div>

<div class="dex-column">
    <h2>${_(u"Foreign Names")}</h2>
    <dl>
        % for foreign_name in c.nature.foreign_names:
        <dt>${foreign_name.language.name} <img src="${h.static_uri('spline', "flags/{0}.png".format(foreign_name.language.iso3166))}" alt=""></dt>
        % if foreign_name.language.name == 'Japanese':
        <dd>${foreign_name.name} (${h.pokedex.romanize(foreign_name.name)})</dd>
        % else:
        <dd>${foreign_name.name}</dd>
        % endif
        % endfor
    </dl>
</div>
</div>


${h.h1(_(u'Pokémon'))}
% if c.nature.increased_stat == c.nature.decreased_stat:
<p>${_(u"These Pokémon are selected automatically, based on having roughly equal stats.  Don't take this as carefully-constructed tournament advice.")}</p>
% else:
<p>${_(u"These Pokémon are selected automatically, based on having high {histat} and low {lostat}. Don't take this as carefully-constructed tournament advice.").format(histat=c.nature.increased_stat.name, lostat=c.nature.decreased_stat.name)}</p>
% endif

<table class="dex-pokemon-moves striped-rows">
## Columns
${dexlib.pokemon_table_columns()}

## Headers
<tr class="header-row">
    ${dexlib.pokemon_table_header()}
</tr>

## Rows
% for pokemon in c.pokemon:
<tr>
    ${dexlib.pokemon_table_row(pokemon)}
</tr>
% endfor
</table>

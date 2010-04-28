<%inherit file="/base.mako"/>
<%namespace name="dexlib" file="lib.mako"/>
<%namespace name="lib" file="/lib.mako"/>

<%def name="title()">${c.nature.name} - Nature</%def>

${h.h1('Essentials')}

<div class="dex-page-portrait">
    <p id="dex-page-name">${c.nature.name}</p>

    % if c.nature.increased_stat == c.nature.decreased_stat:
    <p>
        Same as:
        <ul>
            % for nature in c.neutral_natures:
            <li><a href="${url(controller='dex', action='natures', name=nature.name.lower())}">${nature.name}</a></li>
            % endfor
        </ul>
    </p>
    % else:
    <p>Inverse of <a href="${url(controller='dex', action='natures', name=c.inverse_nature.name.lower())}">${c.inverse_nature.name}</a></p>
    % endif
</div>

<div class="dex-page-beside-portrait">
    % if c.nature.increased_stat == c.nature.decreased_stat:
    <p>This nature is neutral; it does not affect stats and causes no flavor preference.</p>
    % else:
    <dl>
        <dt>Stat changes</dt>
        <dd>
            +10% ${c.nature.increased_stat.name}<br>
            -10% ${c.nature.decreased_stat.name}
        </dd>
        <dt>Taste preference</dt>
        <dd>
            Likes ${c.nature.likes_flavor.flavor}; good for
            ${h.pokedex.pokedex_img("chrome/contest/{0}.png".format(c.nature.likes_flavor.name), alt=c.nature.likes_flavor.name)}<br>
            Hates ${c.nature.hates_flavor.flavor}; bad for
            ${h.pokedex.pokedex_img("chrome/contest/{0}.png".format(c.nature.hates_flavor.name), alt=c.nature.hates_flavor.name)}
        </dd>
    </dl>
    % endif
</div>


<h1>Less essentials</h1>
<div class="dex-column-container">
<div class="dex-column">
    <h2>Battle Style Preferences</h2>
    <p>These only affect the Battle Palace and Battle Tent.</p>

    <dl>
        <dt>&gt; 50% HP</dt>
        <dd>
            % for pref in c.nature.battle_style_preferences:
            ${pref.high_hp_preference}% ${pref.battle_style.name}<br>
            % endfor
        </dd>
        <dt>&lt; 50% HP</dt>
        <dd>
            % for pref in c.nature.battle_style_preferences:
            ${pref.low_hp_preference}% ${pref.battle_style.name}<br>
            % endfor
        </dd>
    </dl>
</div>
<div class="dex-column">
    <h2>Pokéathlon Stats</h2>
    <ul class="classic-list">
        % for effect in c.nature.pokeathlon_effects:
        <li>Up to ${effect.max_change} ${effect.pokeathlon_stat.name}</li>
        % endfor
    </ul>
</div>
</div>


<h1>Pokémon</h1>
% if c.nature.increased_stat == c.nature.decreased_stat:
<p>These Pokémon are selected automatically, based on having roughly equal stats.  Don't take this as carefully-constructed tournament advice.</p>
% else:
<p>These Pokémon are selected automatically, based on having high ${c.nature.increased_stat.name} and low ${c.nature.decreased_stat.name}.  Don't take this as carefully-constructed tournament advice.</p>
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

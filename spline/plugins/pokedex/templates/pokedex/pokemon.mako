<%inherit file="/base.mako"/>
<%namespace name="lib" file="/pokedex/lib.mako"/>

<%def name="title()">${c.pokemon.name}</%def>

<h1>Essentials</h1>

## Portrait block
<div id="dex-pokemon-portrait">
    <p id="dex-pokemon-name">${c.pokemon.name}</p>
    ${lib.pokedex_img('platinum/%d.png' % c.pokemon.id, alt=c.pokemon.name, id="dex-pokemon-portrait-sprite")}
    <p id="dex-pokemon-types">
        % for type in c.pokemon.types:
        ${lib.type_icon(type)}
        % endfor
    </p>
</div>

<h2>Abilities</h2>
<dl>
    % for ability in c.pokemon.abilities:
    <dt>${ability.name}</dt>
    <dd>${ability.effect}</dd>
    % endfor
</dl>

<h2>Damage Taken</h2>
## Boo not using <dl>  :(  But I can't get them to align horizontally with CSS2
## if the icon and value have no common element..
<ul id="dex-pokemon-damage-taken">
    % for type, damage_factor in sorted(c.type_efficacies.items(), \
                                        key=lambda x: x[0].name):
    <li class="dex-damage-${damage_factor}">
        ${lib.type_icon(type)} ${c.dexlib.type_efficacy_label[damage_factor]}
    </li>
    % endfor
</ul>

<div class="dex-column-container">
<div class="dex-column">
    <h2>Pokédex Numbers</h2>
    <dl>
        <dt>Introduced in</dt>
        <dd>${lib.generation_icon(c.pokemon.generation)} ${c.pokemon.generation.name}</dd>
        % if c.pokemon.generation == c.dexlib.generation(1):
        <dt>${lib.version_icons('Red', 'Blue')} internal id</dt>
        <dd>${c.pokemon.gen1_internal_id} (<code>0x${"%02x" % c.pokemon.gen1_internal_id}</code>)</dd>
        % endif
        % for dex_number in c.pokemon.dex_numbers:
        <dt>${lib.generation_icon(dex_number.generation)} ${dex_number.generation.main_region}</dt>
        <dd>${dex_number.pokedex_number}</dt>
        % endfor
    </dl>

    <h2>Names</h2>
    <dl>
        % for foreign_name in c.pokemon.foreign_names:
        <dt>${foreign_name.language.name}</dt>
        <dd>${foreign_name.name}</dt>
        % endfor
    </dl>
</div>
<div class="dex-column">
    <h2>Breeding</h2>
    <dl>
        <dt>Gender</dt>
        <dd>${lib.pokedex_img('gender-rates/%d.png' % c.pokemon.gender_rate, alt='')} ${c.dexlib.gender_rate_label[c.pokemon.gender_rate]}</dd>
        <dt>Egg groups</dt>
        <dd>
            <ul>
                % for i, egg_group in enumerate(c.pokemon.egg_groups):
                <li>${egg_group.name}</li>
                % endfor
            </ul>
        </dd>
        <dt>Steps to hatch</dt>
        <dd>${c.pokemon.evolution_chain.steps_to_hatch}</dd>
        <dt>Compatibility</dt>
        <dd>XXX</dd>
    </dl>
</div>
<div class="dex-column">
    <h2>Training</h2>
    <dl>
        <dt>Base EXP</dt>
        <dd>
            <span id="dex-pokemon-exp-base">${c.pokemon.base_experience}</span> <br/>
            <span id="dex-pokemon-exp">${c.dex_formulae.earned_exp(base_exp=c.pokemon.base_experience, level=100)}</span> EXP at level <input type="text" size="3" value="100" id="dex-pokemon-exp-level">
        </dd>
        <dt>Effort points</dt>
        <dd>
            <ul>
                % for pokemon_stat in c.pokemon.stats:
                % if pokemon_stat.effort:
                <li>${pokemon_stat.effort} ${pokemon_stat.stat.name}</li>
                % endif
                % endfor
            </ul>
        </dd>
        <dt>Capture rate</dt>
        <dd>${c.pokemon.capture_rate}</dd>
        <dt>Base happiness</dt>
        <dd>${c.pokemon.base_happiness}</dd>
        <dt>Growth rate</dt>
        <dd>${c.pokemon.evolution_chain.growth_rate.name}</dd>
        <dt>Wild held items</dt>
        <dd>XXX</dd>
    </dl>
</div>
</div>

<h1>Evolution</h1>
<table class="dex-evolution-chain">
<thead>
<tr>
    <th>Baby</th>
    <th>Basic</th>
    <th>Stage 1</th>
    <th>Stage 2</th>
</tr>
</thead>
<tbody>
% for row in c.evolution_table:
<tr>
    % for col in row:
    ## Empty cell
    % if col == '':
    <td></td>
    % elif col != None:
    <td rowspan="${col['span']}">
        <a href="${h.url_for(controller='dex', action='pokemon', name=col['pokemon'].name.lower())}" class="dex-evolution-chain-pokemon">
            ${lib.pokedex_img('icons/%d.png' % col['pokemon'].id, style='float: left;')}
            ${col['pokemon'].name}
        </a>
        % if col['pokemon'].evolution_method:
        <span class="dex-evolution-chain-method">
            % if col['pokemon'].evolution_parameter:
            ${col['pokemon'].evolution_method.name}:
            ${col['pokemon'].evolution_parameter}
            % else:
            ${col['pokemon'].evolution_method.name}
            % endif
        </span>
        % endif
    </td>
    % endif
    % endfor
</tr>
% endfor
</tbody>
</table>

<h1>Stats</h1>
<%
    # Most people want to see the best they can get
    default_stat_level = 100
    default_stat_effort = 255
%>\
<table class="dex-pokemon-stats">
<col class="dex-col-stat-name">
<col class="dex-col-stat-bar">
<col class="dex-col-stat-result">
<col class="dex-col-stat-result">
<tr>
    <th><!-- stat name --></th>
    <th><!-- bar and value --></th>
    <th><label for="dex-pokemon-stats-level">Level</label></th>
    <th><input type="text" size="3" value="${default_stat_level}" disabled="disabled" id="dex-pokemon-stats-level"></th>
</tr>
<tr>
    <th><!-- stat name --></th>
    <th><!-- bar and value --></th>
    <th><label for="dex-pokemon-stats-iv">Effort</label></th>
    <th><input type="text" size="3" value="${default_stat_effort}" disabled="disabled" id="dex-pokemon-stats-effort"></th>
</tr>
<tr class="header-row">
    <th><!-- stat name --></th>
    <th><!-- bar and value --></th>
    <th>Min IVs</th>
    <th>Max IVs</th>
</tr>
% for pokemon_stat in c.pokemon.stats:
<tr>
    <th>${pokemon_stat.stat.name}</th>
    <td>
        <div class="dex-pokemon-stats-bar-container">
            <div class="dex-pokemon-stats-bar" style="width: ${pokemon_stat.base_stat * 100 / 255.0}%;">${pokemon_stat.base_stat}</div>
        </div>
    </td>
<%
    if pokemon_stat.stat.name == 'HP':
        stat_formula = c.dex_formulae.calculated_hp
    else:
        stat_formula = c.dex_formulae.calculated_stat
%>\
    <td class="dex-pokemon-stats-result">${stat_formula(pokemon_stat.base_stat, level=default_stat_level, iv=0, effort=default_stat_effort)}</td>
    <td class="dex-pokemon-stats-result">${stat_formula(pokemon_stat.base_stat, level=default_stat_level, iv=31, effort=default_stat_effort)}</td>
</tr>
% endfor
</table>

<h1>Flavor</h1>

<div class="dex-column-container">
<div class="dex-column-2x">
    <h2>Flavor Text</h2>
    <ul>
        % for version_name in 'Diamond', 'Pearl':
        <li>${lib.version_icons(version_name)} ${c.flavor_text[version_name]}</li>
        % endfor
    </ul>
</div>
<div class="dex-column">
    ## Only showing current generation's sprites and text
    <h2>Sprites</h2>
    ${lib.pokedex_img('platinum/%d.png' % c.pokemon.id)}
    ${lib.pokedex_img('platinum/frame2/%d.png' % c.pokemon.id)}
    ${lib.pokedex_img('platinum/shiny/%d.png' % c.pokemon.id)}
    ${lib.pokedex_img('platinum/shiny/frame2/%d.png' % c.pokemon.id)}
    <br/>
    % if c.pokemon.has_gen4_fem_sprite:
    ${lib.pokedex_img('platinum/female/%d.png' % c.pokemon.id)}
    ${lib.pokedex_img('platinum/female/frame2/%d.png' % c.pokemon.id)}
    ${lib.pokedex_img('platinum/shiny/female/%d.png' % c.pokemon.id)}
    ${lib.pokedex_img('platinum/shiny/female/frame2/%d.png' % c.pokemon.id)}
    % endif
</div>
</div>

<div class="dex-column-container">
<div class="dex-column">
    <h2>Miscellany</h2>
    <dl>
        <dt>Species</dt>
        <dd>${c.pokemon.species}</dd>
        <dt>Color</dt>
        <dd>${c.pokemon.color}</dd>
        <dt>Cry</dt>
        <dd>${h.HTML.a('download mp3', href=h.url_for(controller='dex', action='media', path='cries/%d.mp3' % c.pokemon.id))}</dd>
        % if c.pokemon.generation.id <= 3:
        <dt>Habitat ${lib.generation_icon(3)}</dt>
        <dd>${lib.pokedex_img('chrome/habitats/%s.png' % c.dexlib.filename_from_name(c.pokemon.habitat))} ${c.pokemon.habitat}</dd>
        % endif
        <dt>Pawprint</dt>
        <dd>${lib.pokedex_img('pawprints/%d.png' % c.pokemon.id, alt='')}</dd>
        <dt>Shape</dt>
        <dd>
            ${lib.pokedex_img('chrome/shapes/%d.png' % c.pokemon.shape.id, alt='')}
            ${c.pokemon.shape.awesome_name}
        </dd>
    </dl>
</div>
<div class="dex-column">
    <h2>Height</h2>
    <p>
        ${int(c.pokemon.height * 0.32808399)}'${"%.1f" % ((c.pokemon.height * 0.32808399 % 1) * 12)}"
        or ${"%.1f" % (c.pokemon.height / 10.0)} m
    </p>
    <div class="dex-size">
        ${lib.pokedex_img('chrome/trainer-male.png', alt='Trainer dude', style="height: %.2f%%" % (c.heights['male'] * 100))}
        ${lib.pokedex_img('chrome/trainer-female.png', alt='Trainer dudette', style="height: %.2f%%" % (c.heights['female'] * 100))}
        ${lib.pokedex_img('chrome/shapes/cropped/%d.png' % c.pokemon.shape.id, alt='', style="height: %.2f%%;" % (c.heights['pokemon'] * 100))}
    </div>
</div>
<div class="dex-column">
    <h2>Weight</h2>
    <p>
        ${"%.1f" % (c.pokemon.weight / 10 * 2.20462262)} lb
        or ${"%.1f" % (c.pokemon.weight / 10)} kg
    </p>
    <div class="dex-size">
        ${lib.pokedex_img('chrome/trainer-male.png', alt='Trainer dude', style="height: %.2f%%" % (c.weights['male'] * 100))}
        ${lib.pokedex_img('chrome/trainer-female.png', alt='Trainer dudette', style="height: %.2f%%" % (c.weights['female'] * 100))}
        ${lib.pokedex_img('chrome/shapes/cropped/%d.png' % c.pokemon.shape.id, alt='', style="height: %.2f%%;" % (c.weights['pokemon'] * 100))}
    </div>
</div>
</div>

<h1>Locations</h1>
<table class="dex-encounters">
<tr class="header-row">
    <th></th>
    % for version in c.dexlib.generation(4).versions:
    <th colspan="3">${lib.version_icons(version)}</th>
    % endfor
</tr>
% for location_area, version_encounters in sorted(c.encounters.items(), \
                                                  key=lambda (k, v): k.location.name):
<%
    num_method_rows = max(map(lambda x: len(x), version_encounters.values())) 
%>\
% for row_idx in range(num_method_rows):
<tr>
    ## We're doing delicious rowspan hackery, so only show the location label
    ## for the first physical row
    % if row_idx == 0:
    <td rowspan="${num_method_rows}">
        ${location_area.location.name}
        % if location_area.name:
        <div class="dex-location-area">${location_area.name}</div>
        % endif
    </td>
    % endif
    % for version in c.dexlib.generation(4).versions:
<%
        version_encounters.setdefault(version, {})
        if len(version_encounters[version]) <= row_idx:
            context.write("<td colspan='3'></td>")
            continue
        (type, condition), enc_dict = version_encounters[version].items()[row_idx]
%>\
    <td>
        % if enc_dict['icon_url']:
        ${lib.pokedex_img(enc_dict['icon_url'])}
        % endif
    </td>
    <td>${enc_dict['level']}</td>
    <td>${enc_dict['rarity']}%</td>
    % endfor
</tr>
% endfor
% endfor
</table>

<h1>Moves</h1>
<p>XXX</p>

<h1>External Links</h1>
<%!
    import re
%>\
<%
    # Some sites don't believe in Unicode URLs.  Scoff, scoff.
    # And they all do it differently.  Ugh, ugh.
    lp_name = c.pokemon.name
    ghpd_name = c.pokemon.name.lower()
    smogon_name = c.pokemon.name.lower()
    if c.pokemon.name == u'Nidoran♀':
        lp_name = 'Nidoran(f)'
        ghpd_name = 'nidoran_f'
        smogon_name = 'nidoran-f'
    elif c.pokemon.name == u'Nidoran♂':
        lp_name = 'Nidoran(m)'
        ghpd_name = 'nidoran_m'
        smogon_name = 'nidoran-m'
    elif c.pokemon.name == 'Mr. Mime':
        ghpd_name = 'mr_mime'
        smogon_name = 'mr_mime'
%>
<ul>
% if c.pokemon.generation.id <= 1:
<li>${lib.generation_icon(1)} <a href="http://www.math.miami.edu/~jam/azure/pokedex/species/${"%03d" % c.pokemon.id}.htm">Azure Heights</a></li>
% endif
<li><a href="http://bulbapedia.bulbagarden.net/wiki/${re.sub(' ', '_', c.pokemon.name)}_%28Pok%C3%A9mon%29">Bulbapedia</a></li>
% if c.pokemon.generation.id <= 2:
<li>${lib.generation_icon(2)} <a href="http://www.pokemondungeon.com/pokedex/${ghpd_name}.shtml">Gengar and Haunter's Pokémon Dungeon</a></li>
% endif
<li><a href="http://www.legendarypokemon.net/pokedex/${lp_name}">Legendary Pokémon</a></li>
<li><a href="http://www.psypokes.com/dex/psydex/${"%03d" % c.pokemon.id}">PsyPoke</a></li>
<li><a href="http://www.serebii.net/pokedex-dp/${"%03d" % c.pokemon.id}.shtml">Serebii</a></li>
<li><a href="http://www.smogon.com/dp/pokemon/${smogon_name}">Smogon</a></li>
</ul>

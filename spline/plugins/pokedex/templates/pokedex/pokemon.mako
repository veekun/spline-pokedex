<%inherit file="/base.mako"/>
<%namespace name="lib" file="/pokedex/lib.mako"/>

<%def name="title()">${c.pokemon.name}</%def>

<h1>Essentials</h1>

## Portrait block
<div id="dex-pokemon-portrait">
    <p id="dex-pokemon-name">${c.pokemon.name}</p>
    ${h.HTML.img(src=h.url_for(controller='dex', action='images', image_path='platinum/%d.png' % c.pokemon.id), alt=c.pokemon.name, id="dex-pokemon-portrait-sprite")}
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

<h2>Pokédex Numbers</h2>
<dl>
    <dt>Generation</dt>
    <dd>${lib.generation_icon(c.pokemon.generation)} ${c.pokemon.generation.name}</dd>
    % if c.pokemon.generation == c.dexlib.generation(1):
    <dt>${lib.version_icons('Red', 'Blue')} internal id</dt>
    <dd>${c.pokemon.gen1_internal_id}</dd>
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

<h2>Breeding</h2>
<dl>
    <dt>Gender</dt>
    <dd>${h.HTML.img(src=h.url_for(controller='dex', action='images', image_path='gender-rates/%d.png' % c.pokemon.gender_rate), alt='')} ${c.dexlib.gender_rate_label[c.pokemon.gender_rate]}</dd>
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

<h2>Training</h2>
<dl>
    <dt>Base EXP</dt>
    <dd>${c.pokemon.base_experience}</dd>
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

<h1>Evolution Chain</h1>
<ul>
    % for pokemon in c.pokemon.evolution_chain.pokemon:
    <li>${pokemon.name}</li>
    % endfor
</ul>

<h1>Stats</h1>
<dl>
    % for pokemon_stat in c.pokemon.stats:
    <dt>${pokemon_stat.stat.name}</dt>
    <dd>${pokemon_stat.base_stat}</dt>
    % endfor
</dl>

<h1>Flavor</h1>
<dl>
    <dt>Current sprites</dt>
    <dd>XXX</dd>
    <dt>Current flavor</dt>
    <dd>XXX</dd>
    <dt>Height</dt>
    <dd>
        ${int(c.pokemon.height * 0.32808399)}'${"%.1f" % ((c.pokemon.height * 0.32808399 % 1) * 12)}"
        or ${"%.1f" % (c.pokemon.height / 10.0)} m
        <div class="dex-size">
            ${h.HTML.img(src=h.url_for(controller='dex', action='images', image_path='chrome/trainer-male.png'), alt='Trainer dude', style="height: %.2f%%" % (c.heights['male'] * 100))}
            ${h.HTML.img(src=h.url_for(controller='dex', action='images', image_path='chrome/trainer-female.png'), alt='Trainer dudette', style="height: %.2f%%" % (c.heights['female'] * 100))}
            ${h.HTML.img(src=h.url_for(controller='dex', action='images', image_path='chrome/shapes/cropped/%d.png' % c.pokemon.shape.id), alt='', style="height: %.2f%%;" % (c.heights['pokemon'] * 100))}
        </div>
    </dd>
    <dt>Weight</dt>
    <dd>
        ${"%.1f" % (c.pokemon.weight / 10 * 2.20462262)} lb
        or ${"%.1f" % (c.pokemon.weight / 10)} kg
        <div class="dex-size">
            ${h.HTML.img(src=h.url_for(controller='dex', action='images', image_path='chrome/trainer-male.png'), alt='Trainer dude', style="height: %.2f%%" % (c.weights['male'] * 100))}
            ${h.HTML.img(src=h.url_for(controller='dex', action='images', image_path='chrome/trainer-female.png'), alt='Trainer dudette', style="height: %.2f%%" % (c.weights['female'] * 100))}
            ${h.HTML.img(src=h.url_for(controller='dex', action='images', image_path='chrome/shapes/cropped/%d.png' % c.pokemon.shape.id), alt='', style="height: %.2f%%;" % (c.weights['pokemon'] * 100))}
        </div>
    </dd>
    <dt>Species</dt>
    <dd>${c.pokemon.species}</dd>
    <dt>Color</dt>
    <dd>${c.pokemon.color}</dd>
    <dt>Cry</dt>
    <dd>XXX</dd>
    <dt>Habitat</dt>
    <dd>${c.pokemon.habitat}</dd>
    <dt>Pawprint</dt>
    <dd>XXX</dd>
    <dt>Shape</dt>
    <dd>
        ${h.HTML.img(src=h.url_for(controller='dex', action='images', image_path='chrome/shapes/%d.png' % c.pokemon.shape.id), alt='')}
        ${c.pokemon.shape.awesome_name}
    </dd>

</dl>

<h1>Locations</h1>
<p>XXX</p>

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

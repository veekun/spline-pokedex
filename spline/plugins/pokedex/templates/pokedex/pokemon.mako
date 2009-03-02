<%inherit file="/base.mako"/>

<%def name="title()">${c.pokemon.name}</%def>

<h1>Essentials</h1>

<ul>
    % for type in c.pokemon.types:
    <li>${type.name}</li>
    % endfor
</ul>

<h2>Abilities</h2>
<dl>
    % for ability in c.pokemon.abilities:
    <dt>${ability.name}</dt>
    <dd>${ability.effect}</dd>
    % endfor
</dl>

<h2>Damage Taken</h2>
<dl>
    % for type, damage_factor in sorted(c.type_efficacies.items(), \
                                        key=lambda x: x[0].name):
    <dt>${type.name}</dt>
    <dd>${damage_factor}</dd>
    % endfor
</dl>

<h2>Pok&eacute;dex Numbers</h2>
<dl>
    <dt>Generation</dt>
    <dd>XXX</dd>
    % for dex_number in c.pokemon.dex_numbers:
    <dt>${dex_number.generation.name}</dt>
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

<h2>Misc(??????)</h2>
rby code.........  eh

<h2>Breeding</h2>
<dl>
    <dt>Gender</dt>
    <dd>${c.pokemon.gender_rate}/8 female XXX</dd>
    <dt>Egg groups</dt>
    <dd>XXX</dd>
    <dt>Steps to hatch</dt>
    <dd>${c.pokemon.evolution_chain.steps_to_hatch}</dd>
    <dt>Compatibility</dt>
    <dd>XXX</dd>
</dl>

<h2>Training</h2>
<dl>
    <dt>Base EXP</dt>
    <dd>${c.pokemon.base_experience}</dd>
    <dt>Capture rate</dt>
    <dd>${c.pokemon.capture_rate}</dd>
    <dt>Base happiness</dt>
    <dd>${c.pokemon.base_happiness}</dd>
    <dt>Growth rate</dt>
    <dd></dd>
    <dt>Effort points</dt>
    <dd></dd>
    <dt>Wild held items</dt>
    <dd></dd>
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
    <dd></dd>
    <dt>Current flavor</dt>
    <dd></dd>
    <dt>Height</dt>
    <dd>${c.pokemon.height} dm</dd>
    <dt>Weight</dt>
    <dd>${c.pokemon.weight} hg</dd>
    <dt>Species</dt>
    <dd>${c.pokemon.species}</dd>
    <dt>Color</dt>
    <dd>${c.pokemon.color}</dd>
    <dt>Cry</dt>
    <dd></dd>
    <dt>Habitat</dt>
    <dd>${c.pokemon.habitat}</dd>
    <dt>Pawprint</dt>
    <dd></dd>
    <dt>Shape</dt>
    <dd></dd>
</dl>

<h1>Locations</h1>
<h1>Moves</h1>

<h1>external links</h1>

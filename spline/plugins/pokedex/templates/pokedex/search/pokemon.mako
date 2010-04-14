<%inherit file="/base.mako"/>
<%namespace name="lib" file="/lib.mako"/>
<%namespace name="dexlib" file="/pokedex/lib.mako"/>

<%def name="title()">Pokémon Search</%def>


### RESULTS ###
## XXX: errors
## XXX: no results

% if c.form.was_submitted:
<h1>Results</h1>
<p><a href="${url.current()}">Clear form</a></p>

## Display.  Could be one of several options...
% if c.display_mode == 'custom-table':
## Some sort of table.  (Standard table is also done this way.)
## These defs are all at the bottom of this file
<table class="dex-pokemon-moves striped-rows">
% for column in c.display_columns:
${getattr(self, 'col_' + column)()}
% endfor
<tr class="header-row">
    % for column in c.display_columns:
    ${getattr(self, 'th_' + column)()}
    % endfor
</tr>
% for result in c.results:
<tr>
    % for column in c.display_columns:
    ${getattr(self, 'td_' + column)(result)}
    % endfor
</tr>
% endfor
</table>

% elif c.display_mode == 'custom-list':
## Plain list with a Template.
<ul class="classic-list">
    % for result in c.results:
    <li>${h.pokedex.pokemon_link(result, h.pokedex.apply_pokemon_template(c.display_template, result))}</li>
    % endfor
</ul>

% elif c.display_mode == 'icons':
## Grid of icons
<ul class="inline">
    % for result in c.results:
    <li>${h.pokedex.pokemon_link(result, h.pokedex.pokemon_sprite(result, prefix=u'icons'), class_='dex-icon-link')}</li>
    % endfor
</ul>

% elif c.display_mode == 'sprites':
## Grid of most recent sprites
<ul class="inline">
    % for result in c.results:
    <li>${h.pokedex.pokemon_link(result, h.pokedex.pokemon_sprite(result), class_='dex-icon-link')}</li>
    % endfor
</ul>

% endif  ## display_mode

% endif  ## search performed


### SEARCH FORM ###

<h1>Pokémon Search</h1>
${h.form(url.current(), method='GET')}
<p>Unless otherwise specified: matching Pokémon must match ALL of the criteria, but can match ANY selections within a group (e.g., evolution stage).</p>
<p>Anything left blank is ignored entirely.</p>

<h2>Essentials and flavor</h2>
<dl class="standard-form">
    ${lib.field('name')}
    ${lib.field('ability')}
    ${lib.field('color')}
    ${lib.field('habitat')}
    <dt>${c.form.gender_rate.label() | n}</dt>
    <dd>${c.form.gender_rate_operator() | n} ${c.form.gender_rate() | n}</dd>
    <dt>${c.form.egg_group.label() | n}</dt>
    <dd>
        ${c.form.egg_group_operator() | n}
        % for widget in c.form.egg_group:
        ${widget() | n}
        % endfor
    </dd>
</dl>

<h2>Type</h2>
<p>Type must be ${c.form.type_operator() | n}.</p>
% for error in c.form.type_operator.errors:
<p class="error">${error}</p>
% endfor
## Umm.  This class is increasingly misnamed.
<ul class="dex-page-damage">
    ## always sort ??? last
    % for a_field in sorted(c.form.type, key=lambda field: field.label.text):
    <li> <label>
        ${h.pokedex.type_icon(a_field.label.text)}
        ${a_field() | n}
    </label> </li>
    % endfor
</ul>
% for error in c.form.type.errors:
<p class="error">${error}</p>
% endfor

<h2>Evolution</h2>
<div class="dex-column-container">
<div class="dex-column">
    <dl class="standard-form">
        ${lib.field('evolution_stage')}
    </dl>
</div>
<div class="dex-column">
    <dl class="standard-form">
        ${lib.field('evolution_position')}
    </dl>
</div>
<div class="dex-column">
    <dl class="standard-form">
        ${lib.field('evolution_special')}
    </dl>
</div>
</div>

<h2>Generation</h2>
<div class="dex-column-container">
<div class="dex-column">
    <dl class="standard-form">
        ${lib.field('introduced_in')}
    </dl>
</div>
<div class="dex-column-2x">
    <dl class="standard-form">
        ${lib.field('in_pokedex')}
    </dl>
</div>
</div>

<h2>Numbers</h2>
<p>Understands ranges in the form <code>-3, 5, 9, 12-16, 20+</code>.</p>
<div class="dex-column-container">
<div class="dex-column">
    <h3>Base stats</h3>
    <dl class="standard-form">
        % for stat_id, field_name in c.stat_fields:
        ${lib.field('stat_' + field_name)}
        % endfor
    </dl>
</div>
<div class="dex-column">
    <h3>Effort</h3>
    <dl class="standard-form">
        % for stat_id, field_name in c.stat_fields:
        ${lib.field('effort_' + field_name)}
        % endfor
    </dl>
</div>
</div>

<h2>Display and sorting</h2>
<div class="dex-column-container">
<div class="dex-column">
    <dl class="standard-form">
        ${lib.field('display')}
        ${lib.field('sort')}
    </dl>
</div>
<div class="dex-column-2x">
    <dl class="standard-form">
        ${lib.field('columns')}
    </dl>
</div>
<div class="dex-column-2x">
    <dl class="standard-form">
        ${lib.field('format')}
    </dl>
</div>
</div>

<p>
    ## Always shorten when the form is submitted!
    ${c.form.shorten(value=1) | n}
    <button type="submit">Search</button>
    <button type="reset">Reset form</button>
</p>
${h.end_form()}





### Display columns defs
<%def name="col_id()"><col class="dex-col-id"></%def>
<%def name="th_id()"><th>Num</th></%def>
<%def name="td_id(pokemon)"><td>${pokemon.national_id}</td></%def>

<%def name="col_name()"><col class="dex-col-name"></%def>
<%def name="th_name()"><th>Name</th></%def>
<%def name="td_name(pokemon)"><td>${h.pokedex.pokemon_link(pokemon, pokemon.full_name)}</td></%def>

<%def name="col_type()"><col class="dex-col-type2"></%def>
<%def name="th_type()"><th>Type</th></%def>
<%def name="td_type(pokemon)">\
<td class="type2">
% for type in pokemon.types:
${h.pokedex.type_link(type)}
% endfor
</td>\
</%def>

<%def name="col_ability()"><col class="dex-col-ability"></%def>
<%def name="th_ability()"><th>Ability</th></%def>
<%def name="td_ability(pokemon)">\
<td class="ability">
% for ability in pokemon.abilities:
<a href="${url(controller='dex', action='abilities', name=ability.name.lower())}">${ability.name}</a><br>
% endfor
</td>\
</%def>

<%def name="col_gender()"><col class="dex-col-gender"></%def>
<%def name="th_gender()"><th>Gender</th></%def>
<%def name="td_gender(pokemon)"><td>${h.pokedex.pokedex_img('gender-rates/%d.png' % pokemon.gender_rate, alt=h.pokedex.gender_rate_label[pokemon.gender_rate])}</td></%def>

<%def name="col_egg_group()"><col class="dex-col-egg-group"></%def>
<%def name="th_egg_group()"><th>Egg Group</th></%def>
<%def name="td_egg_group(pokemon)">\
<td class="egg-group">
% for egg_group in pokemon.egg_groups:
${egg_group.name}<br>
% endfor
</td>
</%def>

<%def name="col_stat_hp()"><col class="dex-col-stat"></%def>
<%def name="th_stat_hp()"><th><abbr title="Hit Points">HP</abbr></th></%def>
<%def name="td_stat_hp(pokemon)"><td class="stat">${pokemon.stat('HP').base_stat}</td></%def>

<%def name="col_stat_attack()"><col class="dex-col-stat"></%def>
<%def name="th_stat_attack()"><th><abbr title="Attack">Atk</abbr></th></%def>
<%def name="td_stat_attack(pokemon)"><td class="stat">${pokemon.stat('Attack').base_stat}</td></%def>

<%def name="col_stat_defense()"><col class="dex-col-stat"></%def>
<%def name="th_stat_defense()"><th><abbr title="Defense">Def</abbr></th></%def>
<%def name="td_stat_defense(pokemon)"><td class="stat">${pokemon.stat('Defense').base_stat}</td></%def>

<%def name="col_stat_special_attack()"><col class="dex-col-stat"></%def>
<%def name="th_stat_special_attack()"><th><abbr title="Special Attack">SpA</abbr></th></%def>
<%def name="td_stat_special_attack(pokemon)"><td class="stat">${pokemon.stat('Special Attack').base_stat}</td></%def>

<%def name="col_stat_special_defense()"><col class="dex-col-stat"></%def>
<%def name="th_stat_special_defense()"><th><abbr title="Special Defense">SpD</abbr></th></%def>
<%def name="td_stat_special_defense(pokemon)"><td class="stat">${pokemon.stat('Special Defense').base_stat}</td></%def>

<%def name="col_stat_speed()"><col class="dex-col-stat"></%def>
<%def name="th_stat_speed()"><th><abbr title="Speed">Spd</abbr></th></%def>
<%def name="td_stat_speed(pokemon)"><td class="stat">${pokemon.stat('Speed').base_stat}</td></%def>

<%def name="col_stat_total()"><col class="dex-col-stat"></%def>
<%def name="th_stat_total()"><th>Total</th></%def>
<%def name="td_stat_total(pokemon)"><td class="stat">${sum((pokemon_stat.base_stat for pokemon_stat in pokemon.stats))}</td></%def>

<%def name="col_effort()"><col class="dex-col-effort"></%def>
<%def name="th_effort()"><th>Effort</th></%def>
<%def name="td_effort(pokemon)">\
<td class="effort">
% for pokemon_stat in pokemon.stats:
% if pokemon_stat.effort:
${pokemon_stat.effort} ${pokemon_stat.stat.name}<br>
% endif
% endfor
</td>\
</%def>

<%def name="col_link()"><col class="dex-col-link"></%def>
<%def name="th_link()"><th></th></%def>
<%def name="td_link(pokemon)"><td>${h.pokedex.pokemon_link(pokemon, h.literal("""<img src="{0}" alt="-&gt;">""".format(h.static_uri('spline', 'icons/arrow.png'))))}</td></%def>

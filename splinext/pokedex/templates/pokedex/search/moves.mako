<%inherit file="/base.mako"/>
<%namespace name="lib" file="/lib.mako"/>
<%namespace name="dexlib" file="/pokedex/lib.mako"/>

<%def name="title()">Move Search</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">Pokédex</a></li>
    <li>Moves</li>
    <li>Move Search</li>
</ul>
</%def>

## RESULTS ##
% if c.form.was_submitted:
<h1>Results</h1>
<ol>
    % for move in c.results:
    <li>${move.name}</li>
    % endfor
</ol>
% endif


### SEARCH FORM ###

<h1>Move Search</h1>
${h.form(url.current(), method='GET')}
<p>Unless otherwise specified: matching moves must match ALL of the criteria, but can match ANY selections within a group.</p>
<p>Anything left blank is ignored entirely.</p>

<h2>Essentials</h2>
<dl class="standard-form">
    ${lib.field('name')}
    <dt>Damage class</dt>
    <dd>
        <ul>
            % for a_field in c.form.damage_class:
            <li> <label>
                ${a_field() | n}
                ${h.pokedex.pokedex_img("chrome/damage-classes/{0}.png".format(a_field.data), alt=u'')}
                ${a_field.label}
            </label> </li>
            % endfor
        </ul>
        % for error in c.form.damage_class.errors:
        <p class="error">${error}</p>
        % endfor
    </dd>
    <dt>Generation</dt>
    <dd>
        <ul>
            % for a_field in c.form.generation:
            <li> <label>
                ${a_field() | n}
                ${h.pokedex.pokedex_img("versions/generation-{0}.png".format(a_field.data), alt=u'')}
                ${a_field.label}
            </label> </li>
            % endfor
        </ul>
        % for error in c.form.generation.errors:
        <p class="error">${error}</p>
        % endfor
    </dd>
    ${lib.field('similar_to')}

    <dt>Flags</dt>
    <dd>
        <ul>
            % for field, _ in c.flag_fields:
            <li>${c.form[field]() | n} ${c.form[field].label() | n}</li>
            % endfor
        </ul>
    </dd>

    <dt>Categories</dt>
    <dd>
        ${lib.bare_field('category_operator')}
        <ul>
            % for field in c.form.category:
            <li>${field() | n} ${field.label() | n}</li>
            % endfor
        </ul>
    </dd>
</dl>

<h2>Type</h2>
<ul class="dex-type-list">
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

<h2>Numbers</h2>
<dl class="standard-form">
    ${lib.field('accuracy')}
    ${lib.field('pp')}
    ${lib.field('power')}
    ${lib.field('effect_chance')}
    ${lib.field('priority')}
</dl>

<h2>Pokémon</h2>
<div class="dex-column-container">
<div class="dex-column">
    <h3>Pokémon</h3>
    <ul>
        % for field in c.form.pokemon:
        <li>
            ${field(class_='js-dex-suggest js-dex-suggest-pokemon') | n}
            % for error in field.errors:
            <p class="error">${error}</p>
            % endfor
        </li>
        % endfor
    </ul>
</div>
<div class="dex-column">
    <h3>Learned by</h3>
    ${lib.bare_field('pokemon_method')}
</div>
<div class="dex-column">
    <h3>Version</h3>
    ${dexlib.pretty_version_group_field(c.form.pokemon_version_group, c.generations)}
</div>
</div>

<p>
    ## Always shorten when the form is submitted!
    ${c.form.shorten(value=1) | n}
    <button type="submit">Search</button>
    <button type="reset">Reset form</button>
</p>
${h.end_form()}

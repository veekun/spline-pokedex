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

<p>
    ## Always shorten when the form is submitted!
    ${c.form.shorten(value=1) | n}
    <button type="submit">Search</button>
    <button type="reset">Reset form</button>
</p>
${h.end_form()}

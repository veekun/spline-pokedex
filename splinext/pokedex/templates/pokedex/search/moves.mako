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

<dl class="standard-form">
    ${lib.field('name')}
</dl>

<p>
    ## Always shorten when the form is submitted!
    ${c.form.shorten(value=1) | n}
    <button type="submit">Search</button>
    <button type="reset">Reset form</button>
</p>
${h.end_form()}

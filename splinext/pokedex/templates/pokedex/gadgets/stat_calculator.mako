<%inherit file="/base.mako" />
<%namespace name="lib" file="/lib.mako"/>
<%namespace name="dexlib" file="/pokedex/lib.mako"/>

<%def name="title()">Stat calculator</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">Pokédex</a></li>
    <li>Gadgets</li>
    <li>Stat calculator</li>
</ul>
</%def>

<h1>Stat calculator</h1>

${h.form(url.current(), method=u'GET')}
<dl class="standard-form">
    ${lib.field(u'pokemon')}
    ${lib.field(u'level', size=3)}
    ${lib.field(u'nature')}
</dl>

<table class="dex-stat-calculator striped-row-groups">
<col>
<colgroup>
    % for stat in c.stats:
    <col class="dex-col-stat-calc">
    % endfor
</colgroup>
<thead>
    % if c.form.nature.data and not c.form.nature.data.is_neutral:
    <tr>
        <th></th>
        % for stat in c.stats:
        % if c.form.nature.data.increased_stat == stat:
        <th class="dex-nature-buff">+10%</th>
        % elif c.form.nature.data.decreased_stat == stat:
        <th class="dex-nature-nerf">&minus;10%</th>
        % else:
        <th></th>
        % endif
        % endfor
    </tr>
    % endif
    <tr class="header-row">
        <th></th>
        % for stat in c.stats:
        <th>${stat.name}</th>
        % endfor
    </tr>
</thead>
<tbody>
    <tr>
        <th>Stats</th>
        % for field_name in c.stat_fields:
        <td>${lib.bare_field(field_name, size=3)}</td>
        % endfor
    </tr>
    <tr>
        <th></th>
        <td colspan="${len(c.stats)}" class="protip">
            Your Pokémon's actual stats, from the Summary screen in-game.
        </td>
    </tr>
</tbody>
<tbody>
    <tr>
        <th>Effort</th>
        % for field_name in c.effort_fields:
        <td>${lib.bare_field(field_name, size=3)}</td>
        % endfor
    </tr>
    <tr>
        <th></th>
        <td colspan="${len(c.stats)}" class="protip">
            Accumulated as your Pokémon battles. <br>
            If you don't know what this is, and your Pokémon has EVER battled or eaten a vitamin, this calculator CANNOT work.  Using Rare Candy is okay, though.
        </td>
    </tr>
</tbody>
% if c.results:
<tbody>
    <tr>
        <th>Genes<br>(IVs)</th>
        % for stat in c.stats:
        <td>
            ${c.results[stat]}
        </td>
        % endfor
    </tr>
    <tr>
        <th></th>
        <td colspan="${len(c.stats)}" class="protip">
            Your Pokémon's awesome-ness for each stat, from 0 to 31.
        </td>
    </tr>
</tbody>
% endif
</table>

<p><button type="submit">Let's do this!</button></p>
<p><button type="reset">Reset</button></p>
${h.end_form()}

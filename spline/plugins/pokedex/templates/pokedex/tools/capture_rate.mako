<%inherit file="/base.mako" />
<%namespace name="lib" file="/lib.mako"/>
<%namespace name="dexlib" file="/pokedex/lib.mako"/>

<%def name="title()">Pokéball performance</%def>

<p>Have you spent the past six hours trying to catch Giratina in Ultra Balls?  Me too!  This gadget will let you find out which ball is the best choice against your target, and about how long it'll take to catch.</p>

<h1>Target Pokémon</h1>

${h.form(url.current(), method='GET')}
<dl class="standard-form">
    ${lib.field('pokemon', class_='js-dex-suggest')}
    ${lib.field('level', size=3)}
    ${lib.field('current_hp', size=3)}
    ${lib.field('status_ailment')}
</dl>

<h2>Specialty ball stuff</h2>
<p>These affect the functionality of some specialty balls, but aren't part of the regular capture rate calculations.  You can skip them if you want.</p>

<dl class="standard-form">
    ${lib.field('your_level', size=3)}
    ${lib.field('terrain')}
    ${lib.field('opposite_gender')}
    ${lib.field('caught_before')}
    ${lib.field('is_dark')}

    ${lib.field('is_pokemon_master')}
</dl>

<p><input type="submit" value="Pokéball, go!"></p>
${h.end_form()}


<%def name="ball_rows(ball)">
<tbody>
% for i, (condition, is_active, chances) in enumerate(c.results[ball]):
<tr class="${'inactive' if not is_active else ''}">
    % if i == 0:
    <th class="item" rowspan="${len(c.results[ball])}">
        ${h.pokedex.item_link(ball)}
    </th>
    % endif

    <td class="chance">
        % if c.form.is_pokemon_master.data:
            ${ "{0:.1f}%".format(chances[0] * 100 + 100) }
        % else:
            ${ "{0:.1f}%".format(chances[0] * 100) }
        % endif
    </td>
    <td class="condition">
        % if condition and len(c.results[ball]) > 1:
        ${condition}
        % endif
    </td>

    % if ball in (u'Timer Ball', u'Quick Ball'):
    ## These are handled super-specially!  Showing expected attempts when it
    ## depends on the number of turns is silly, so let's do it right
    % if i == 0:
    <td class="expected-attempts" rowspan="${len(c.results[ball])}">
        <%
            # Three identical partitions, plus one very long one
            partition_size = 10 if ball == u'Timer Ball' else 5
            partitions = [
                (c.results[ball][_][2][0], partition_size)
                for _ in range(3)
            ] + [
                (c.results[ball][3][2][0], None),
            ]
        %>
        ${"{0:.1f}".format( c.expected_attempts_oh_no(partitions) )}
        % endif
    % else:
    <td class="expected-attempts">
        ${"{0:.1f}".format( c.expected_attempts(chances[0]) )}
    % endif
    </td>
</tr>
% endfor
</tbody>
</%def>

% if c.results:
<h1>Ball Success Rates</h1>
<p>
    ${h.pokedex.pokemon_link(c.pokemon)}'s capture rate:
    ${c.pokemon.capture_rate}/255
    or about ${ "{0:.01f}%".format( 1.0 * c.pokemon.capture_rate / 255 * 100 ) }.
</p>

<table class="dex-capture-rates striped-row-groups">
<thead>
<tr class="header-row">
    <th>Ball</th>
    <th>Chance to catch</th>
    <th>Requirement</th>
    <th>Average tries</th>
</tr>
</thead>

<thead>
<tr class="subheader-row">
    <th colspan="4">Generation I</th>
</tr>
</thead>
${ball_rows(u'Poké Ball')}
${ball_rows(u'Great Ball')}
${ball_rows(u'Ultra Ball')}
${ball_rows(u'Master Ball')}
${ball_rows(u'Safari Ball')}

<thead>
<tr class="subheader-row">
    <th colspan="4">Generation II</th>
</tr>
</thead>
${ball_rows(u'Level Ball')}
${ball_rows(u'Lure Ball')}
${ball_rows(u'Moon Ball')}
${ball_rows(u'Love Ball')}
${ball_rows(u'Heavy Ball')}
${ball_rows(u'Fast Ball')}
${ball_rows(u'Sport Ball')}

<thead>
<tr class="subheader-row">
    <th colspan="4">Generation III</th>
</tr>
</thead>
${ball_rows(u'Premier Ball')}
${ball_rows(u'Repeat Ball')}
${ball_rows(u'Timer Ball')}
${ball_rows(u'Nest Ball')}
${ball_rows(u'Net Ball')}
${ball_rows(u'Dive Ball')}
${ball_rows(u'Luxury Ball')}

<thead>
<tr class="subheader-row">
    <th colspan="4">Generation IV</th>
</tr>
</thead>
${ball_rows(u'Heal Ball')}
${ball_rows(u'Quick Ball')}
${ball_rows(u'Dusk Ball')}
${ball_rows(u'Cherish Ball')}
${ball_rows(u'Park Ball')}
</table>

% endif

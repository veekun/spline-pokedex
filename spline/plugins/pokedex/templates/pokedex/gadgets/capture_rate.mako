<%inherit file="/base.mako" />
<%namespace name="lib" file="/lib.mako"/>
<%namespace name="dexlib" file="/pokedex/lib.mako"/>

<%def name="title()">Pokéball performance</%def>

<p>Have you spent the past six hours trying to catch Giratina in Ultra Balls?  Me, too!  What a jerk.  This gadget will tell you which ball is the best choice against your target, and about how long it'll take to catch.</p>

<h1>Target Pokémon</h1>

${h.form(url.current(), method='GET')}
<dl class="standard-form">
    ${lib.field('pokemon')}
    ${lib.field('current_hp', size=3, class_='js-dex-dynamic-hp-bar')}
    ${lib.field('status_ailment')}
</dl>

<h2>Specialty ball stuff</h2>
<p>These affect the functionality of some specialty balls, but aren't part of the regular capture rate calculations.  You can skip them if you want.</p>

<%def name="long_checkbox_field(name)">
    <dd>${c.form[name]() | n} ${c.form[name].label() | n}</dd>
</%def>
<dl class="standard-form">
    ${lib.field('level', size=3)}
    ${lib.field('your_level', size=3)}
    ${lib.field('terrain')}
    ${long_checkbox_field('twitterpating')}
    ${long_checkbox_field('caught_before')}
    ${long_checkbox_field('is_dark')}

    ${long_checkbox_field('is_pokemon_master')}
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

    % if c.form.is_pokemon_master.data:
    ## None of this math means anything; it's just meant to be both
    ## deterministic and ridiculous
    <td class="chance">
        <div class="dex-capture-rate-graph"></div>
    </td>
    <td class="chance">
        ${ "{0:.1f}%".format(chances[0] * 133 + 133) }
    </td>
    <td class="expected-attempts">
        ${ "{0:.1f}".format(-1 / (chances[0] * 1.33)) }
    </td>

    % else:  ## up+b
    <td class="chance">
        <div class="dex-capture-rate-graph"
             title="Capture: ${ "{0:.1f}%".format(chances[0] * 100) }">
            ## Only actually draw bars for the wobbles.  Capture is the
            ## default background color.
            ## catch 3 2 1 0 => 3 2 1 0 => 0 1 2 3
            % for wobbles, chance in enumerate( reversed(chances[1:]) ):
            <div class="dex-capture-rate-graph-bar wobble${wobbles}"
                 style="width: ${chance * 100}%"
                 title="${wobbles} wobble${'' if wobbles == 1 else 's'}: ${ "{0:.1f}%".format(chance * 100) }">
            </div>
            % endfor
        </div>
    </td>
    <td class="chance">
        ## And finally actually print the chance to capture
        ${ "{0:.1f}%".format(chances[0] * 100) }
    </td>

    % if ball in (u'Timer Ball', u'Quick Ball'):
    ## These are handled super-specially!  Showing expected attempts when it
    ## depends on the number of turns is silly, so let's do it right
    % if i == 0:
    <td class="expected-attempts" rowspan="${len(c.results[ball])}">
        <%
            if ball == u'Timer Ball':
                # Gradient, from 1 through 30 turns.  Ick.
                partitions = [
                    (c.capture_chance(n + 10)[0], 1) for n in range(1, 30)
                ] + [
                    (c.capture_chance(40)[0], None)
                ]
            else:
                # Quick Ball!  Great on turn 1; crap otherwise.
                partitions = [
                    (c.capture_chance(40)[0], 1),
                    (c.capture_chance(10)[0], None),
                ]
        %>
        ${"{0:.1f}".format( c.expected_attempts_oh_no(partitions) )}
        % endif
    % else:
    <td class="expected-attempts">
        ${"{0:.1f}".format( c.expected_attempts(chances[0]) )}
    % endif
    </td>

    % endif  ## up+b

    <td class="condition">
        % if condition:
        ${condition}
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

<p>Disclaimer: This is all approximate!  The game might still hate you more than these numbers indicate.</p>

% if c.form.is_pokemon_master.data:
<p>And no, Up+B doesn't actually do anything.</p>
% endif

<p class="dex-capture-rate-legend">
    Legend: Ball wobbles
    <span class="wobble0">zero</span>,
    <span class="wobble1">one</span>,
    <span class="wobble2">two</span>,
    <span class="wobble3">three</span> times.
    <span class="wobble4">Capture!</span>
    Mouseover for specifics.
</p>


<table class="dex-capture-rates striped-row-groups">
<thead>
<tr class="header-row">
    <th>Ball</th>
    <th colspan="2">Chance to catch</th>
    <th>Avg. tries</th>
    <th>Requirement</th>
</tr>
</thead>

<thead>
<tr class="subheader-row">
    <th colspan="5">Generation I</th>
</tr>
</thead>
${ball_rows(u'Poké Ball')}
${ball_rows(u'Great Ball')}
${ball_rows(u'Ultra Ball')}
${ball_rows(u'Master Ball')}
${ball_rows(u'Safari Ball')}

<thead>
<tr class="subheader-row">
    <th colspan="5">Generation II</th>
</tr>
</thead>
${ball_rows(u'Fast Ball')}
${ball_rows(u'Friend Ball')}
${ball_rows(u'Heavy Ball')}
${ball_rows(u'Level Ball')}
${ball_rows(u'Love Ball')}
${ball_rows(u'Lure Ball')}
${ball_rows(u'Moon Ball')}
${ball_rows(u'Sport Ball')}

<thead>
<tr class="subheader-row">
    <th colspan="5">Generation III</th>
</tr>
</thead>
${ball_rows(u'Premier Ball')}
${ball_rows(u'Dive Ball')}
${ball_rows(u'Luxury Ball')}
${ball_rows(u'Nest Ball')}
${ball_rows(u'Net Ball')}
${ball_rows(u'Repeat Ball')}
${ball_rows(u'Timer Ball')}

<thead>
<tr class="subheader-row">
    <th colspan="5">Generation IV</th>
</tr>
</thead>
${ball_rows(u'Cherish Ball')}
${ball_rows(u'Dusk Ball')}
${ball_rows(u'Heal Ball')}
${ball_rows(u'Quick Ball')}
${ball_rows(u'Park Ball')}
</table>

% endif

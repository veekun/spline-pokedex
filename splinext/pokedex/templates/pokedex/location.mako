<%inherit file="/base.mako"/>
<%namespace name="lib" file="lib.mako"/>

<%def name="title()">${c.location_name} - Locations</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">Pokédex</a></li>
    <li>Locations</li>
    <li>${c.location_name}</li>
</ul>
</%def>

<h1>${c.location_name}</h1>

% for location_area in c.areas:
% if location_area.name:
<h2 id="area:${location_area.name}">
    <a href="#area:${location_area.name}" class="subtle">${location_area.name}</a>
</h2>
% endif

<table class="dex-encounters striped-rows">
    ## Spit out <col> tags.  Zip cleverness lets us compare the current version
    ## to the one before it
    <col class="dex-col-name">
    % for version, prior_version in zip( \
        c.group_versions[location_area], \
        [None] + c.group_versions[location_area] \
    ):
    % if not prior_version or prior_version.version_group.generation \
                                 != version.version_group.generation:
    <col class="dex-col-encounter-version dex-col-first-version">
    % else:
    <col class="dex-col-encounter-version">
    % endif
    % endfor

    ## Draw a divider to separate terrain, in id order.  Why not?
    ## Include the versions header, too.
    % for terrain, pokemon_version_condition_encounters \
       in h.keysort(c.grouped_encounters.get(location_area, {}), lambda k: k.id):

    <tr class="header-row">
        <th></th>
        % for version in c.group_versions[location_area]:
        <th>${h.pokedex.version_icons(version)} ${version.name}</th>
        % endfor
    </tr>
    <tr class="subheader-row">
        <th colspan="100">
            ${h.pokedex.pokedex_img('encounters/' + c.encounter_terrain_icons.get(terrain.name, 'unknown.png'))}
            ${terrain.name}
        </th>
    </tr>

    ## One row per Pokémon, sorted by name
    % for pokemon, version_condition_encounters \
       in h.keysort(pokemon_version_condition_encounters, lambda k: k.name):
    <tr>
        <th class="location">
            ${h.pokedex.pokemon_link(
                pokemon,
                h.literal(u"""{0} {1}""".format(
                    h.pokedex.pokemon_sprite(pokemon, prefix='icons'),
                    pokemon.name,
                )),
                class_='dex-icon-link',
            )}
        </th>
        % for version in c.group_versions[location_area]:
        <% condition_encounters = version_condition_encounters[version] %>
        <td>
            ## Sort conditions by number of conditions (so "default" comes
            ## first, and simple before complex), then just by condition id.
            ## Conditions are only grouped in the first place so we can stick
            ## them in this div wrapper, which draws a divider line between
            ## them.
            % for conditions, condition_value_encounters in h.keysort( \
                condition_encounters, lambda k: [len(k)] + [cond.id for cond in k]):
            <div class="dex-encounter-condition-group">

            ## Sort in order of condition value id, too.  Pretty arbitrary, but
            ## the condition values are entirely under my control, and the
            ## order in the db is intuitive to me.
            % for condition_values, encounters in h.keysort( \
                condition_value_encounters, lambda k: [cv.id for cv in k]):
            <div class="dex-encounter-conditions">
                % for condition_value in condition_values:
                <div class="dex-encounter-icon">
                    ${h.pokedex.pokedex_img('encounters/' \
                                            + c.encounter_condition_value_icons.get(condition_value.name, 'unknown.png'), \
                                            alt=condition_value.name, \
                                            title=condition_value.name)}
                </div>
                % endfor

                <div class="dex-encounter-rarity">
                    ## Plus sign is only shown if there are conditions here;
                    ## the idea is that they're adding onto the base rarity,
                    ## which doesn't have a +
                    ${'+' if len(conditions) else ''}${sum(encounter['rarity'] for encounter in encounters)}%
                </div>
                <div class="dex-encounter-level">${c.level_range(min(enc['min_level'] for enc in encounters), \
                                                                 max(enc['max_level'] for enc in encounters))}</div>

                ## Show a little bar illustrating the contribution this rarity
                ## makes.  As a bonus, this visually separates the condition
                ## values.
                <div class="dex-rarity-bar">
                    % for encounter in sorted(encounters, \
                                              key=lambda enc: (enc['min_level'], enc['max_level'])):
                    <div class="dex-rarity-bar-fills" style="width: ${encounter['rarity']}%;" title="${c.level_range(encounter['min_level'], encounter['max_level'])}"></div>
                    % endfor
                </div>
            </div>
            % endfor
            </div>
            % endfor
        </td>
        % endfor
    </tr>
    % endfor
    % endfor
</table>
% endfor

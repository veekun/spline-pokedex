<%inherit file="/base.mako"/>
<%namespace name="lib" file="lib.mako"/>

<%def name="title()">${c.location_name} – Location</%def>

<h1>${c.location_name}</h1>

% for location_area in c.areas:
% if location_area.name:
<h2 id="area:${location_area.name}">
    <a href="#area:${location_area.name}" class="subtle">${location_area.name}</a>
</h2>
% endif

<table class="dex-encounters striped-rows">
    ## Draw a divider to separate terrain, in id order.  Why not?
    ## Include the versions header, too.
    % for terrain, pokemon_version_condition_encounters \
       in sorted(c.grouped_encounters.get(location_area, {}).items(), \
                 key=lambda (k, v): k.id):

    <tr class="header-row">
        <th></th>
        % for version in c.versions:
        <th>${h.pokedex.version_icons(version)} ${version.name}</th>
        % endfor
    </tr>
    <tr class="subheader-row">
        <th colspan="100">${terrain.name}</th>
    </tr>

    ## One row per Pokémon, sorted by name
    % for pokemon, version_condition_encounters \
       in sorted(pokemon_version_condition_encounters.items(), \
                 key=lambda (k, v): k.name):
    <tr>
        <th class="location">
            ${pokemon.name}
        </th>
        % for version in c.versions:
        <% condition_encounters = version_condition_encounters[version] %>
        <td>
            ## Sort conditions by number of conditions (so "default" comes
            ## first, and simple before complex), then just by condition id.
            ## Conditions are only grouped in the first place so we can stick
            ## them in this div wrapper, which draws a divider line between
            ## them.
            % for conditions, condition_value_encounters \
               in sorted(condition_encounters.items(), \
                         key=lambda (k, v): [len(k)] + [cond.id for cond in k] ):
            <div class="dex-encounter-condition-group">

            ## Sort in order of condition value id, too.  Pretty arbitrary, but
            ## the condition values are entirely under my control, and the
            ## order in the db is intuitive to me.
            % for condition_values, encounters \
               in sorted(condition_value_encounters.items(), \
                         key=lambda (k, v): [cv.id for cv in k] ):
            <div class="dex-encounter-conditions">
                % for condition_value in condition_values:
                <div class="dex-encounter-icon">
                    ${h.pokedex.pokedex_img('encounters/' \
                                            + c.encounter_condition_value_icons.get(condition_value.name, ''), \
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

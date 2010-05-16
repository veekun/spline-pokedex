<%inherit file="/base.mako"/>
<%namespace name="lib" file="/lib.mako"/>

<%def name="title()">Types</%def>

${h.h1('Type chart')}

<table class="dex-type-chart striped-rows">
<tr class="header-row">
    <th>Move</th>
    <th colspan="${len(c.types)}">Pokémon</th>
</tr>
<tr class="subheader-row">
    <th></th>
    % for type in c.types:
    <th>${h.pokedex.type_link(type)}</th>
    % endfor
</tr>
% for type in c.types:
<tr>
    <th>${h.pokedex.type_link(type)}</th>
    % for efficacy in sorted(type.damage_efficacies, key=lambda _: _.target_type.name):
    <td class="dex-damage-dealt-${efficacy.damage_factor}">${h.pokedex.type_efficacy_label[efficacy.damage_factor]}</td>
    % endfor
</tr>
% endfor
</table>

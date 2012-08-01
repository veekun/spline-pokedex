<%inherit file="/base.mako"/>
<%namespace name="conqlib" file="lib.mako"/>

<%! from splinext.pokedex import i18n %>\

<%def name="title()">Pokémon - Pokémon Conquest</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">${_(u'Pokédex')}</a></li>
    <li><a href="${url('/dex/conquest')}">${_(u'Conquest')}</a></li>
    <li>${_(u'Pokémon')}</li>
</ul>
</%def>

${h.h1(_(u'Pokémon list'))}
<table class="dex-pokemon-moves striped-rows">
${conqlib.pokemon_table_columns()}
${conqlib.pokemon_table_header()}

<tbody>
    % for pokemon in c.pokemon:
    <tr>
        ${conqlib.pokemon_table_row(pokemon)}
    </tr>
    % endfor
</tbody>
</table>

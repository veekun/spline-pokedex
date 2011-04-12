<%inherit file="/base.mako"/>
<%namespace name="dexlib" file="lib.mako"/>
<%! from splinext.pokedex import i18n %>\
<%! from itertools import groupby %>\
<%! from operator import attrgetter %>\

<%def name="title()">${_("Locations")}</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">${_(u"Pokédex")}</a></li>
    <li>${_("Locations")}</li>
</ul>
</%def>

${h.h1(_("Locations"))}

## assume these have already been sorted
% for region, locations in groupby(c.locations, attrgetter('region')):
% if region is not None:
${h.h2(_(region.name))}

<ul class="classic-list">
    % for loc in locations:
    <li>
        <a href="${url(controller='dex', action='locations', name=loc.name.lower())}">
            ${loc.name}
        </a>
    </li>
    % endfor
</ul>
% endif
% endfor



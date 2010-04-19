<%inherit file="/base.mako"/>
<%namespace name="lib" file="/lib.mako"/>

<%def name="title()">Natures</%def>

${h.h1('Nature list')}

<table class="striped-rows">
<tr class="header-row">
    <th>Name</th>
    <th>+10%</th>
    <th>-10%</th>
</tr>
% for nature in c.natures:
<tr>
    <td><a href="${url(controller='dex', action='natures', name=nature.name.lower())}">${nature.name}</a></td>
    % if nature.increased_stat == nature.decreased_stat:
    <td>—</td>
    <td>—</td>
    % else:
    <td>${nature.increased_stat.name}</td>
    <td>${nature.decreased_stat.name}</td>
    % endif
</tr>
% endfor
</table>

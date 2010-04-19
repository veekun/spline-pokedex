<%inherit file="/base.mako"/>
<%namespace name="lib" file="/lib.mako"/>

<%def name="title()">${c.nature.name} - Nature</%def>

${h.h1('Essentials')}

<div class="dex-page-portrait">
    <p id="dex-page-name">${c.nature.name}</p>
</div>

<div class="dex-page-beside-portrait">
    <h2>Stats affected</h2>
    % if c.nature.increased_stat == c.nature.decreased_stat:
    <p>This nature is neutral; it does not affect stats.</p>
    % else:
    <dl>
        <dt>Stat increased</dt>
        <dd>+10% ${c.nature.increased_stat.name}</dd>
        <dt>Stat decreased</dt>
        <dd>-10% ${c.nature.decreased_stat.name}</dd>
    </dl>
    % endif
</div>

<%inherit file="/base.mako"/>

<%def name="title()">Disambiguation</%def>

<h1>${c.input}</h1>
% if c.exact:
<p>Hmmm, there are several things with that name.  Did you mean:</p>
% else:
<p>It seems you don't know how to spell.  Did you mean one of these?</p>
% endif

<ul class="classic-list">
% for result in c.results:
<li>The ${c.table_labels[result.__class__]} ${h.HTML.a(result.name, href=url(controller='dex', action=result.__tablename__, name=result.name.lower()))}</li>
% endfor
</ul>

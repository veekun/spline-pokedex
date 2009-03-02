<%def name="type_icon(type)">
${h.HTML.img(src=h.url_for(controller='dex', action='images', image_path='chrome/types/%s.png' % type.name), alt=type.name)}
</%def>

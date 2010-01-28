// Scoping
var pokedex = {
    // Returns n as an integer iff it is valid and min <= n <= max; otherwise,
    // returns undefined.
    'parse_integer': function(n, min, max) {
        var parsed = parseInt(n);
        if (isNaN(parsed) || parsed != n || n < min || n > max)
            return undefined;

        return parsed;
    },

    // Javascript versions of pokedex.formulae.  Unfortunate to duplicate this,
    // but it's pretty simple and the alternatives are ajax or source code
    // translation.
    'formulae': {
        'calculated_stat': function(params) {
            // Need to fake floor division
            return Math.floor(
                (params.base_stat * 2
                    + params.iv
                    + Math.floor(params.effort / 4))
                * params.level / 100) + 5;
        },
        'calculated_hp': function(params) {
            // Shedinja
            if (params.base_stat == 1)
                return 1;

            return Math.floor(
                (params.base_stat * 2
                    + params.iv
                    + Math.floor(params.effort / 4))
                * params.level / 100) + 10 + params.level;
        },

        'earned_exp': function(params) {
            return Math.floor(params.base_exp * params.level / 7);
        },
    },
};

// Stuff for collapsing Pokémon-move tables
pokedex.pokemon_moves = {
    'init': function() {
        $('.dex-pokemon-moves').each(function() {
            var $this = $(this);
            var $first_tr = $this.find('tr').eq(0);

            // Remember the arrangement of version columns and separators
            // on page load
            var column_classes = [];
            var num_generations = 0;
            var $version_columns = $this.find('col.dex-col-version');
            $version_columns.each(function() {
                column_classes.push(this.className);
                if ($(this).hasClass('dex-col-last-version')) {
                    num_generations++;
                }
            });
            $this.data('pokemon_moves.first_generation',
                       pokedex.generation_ct - num_generations + 1);
            $this.data('pokemon_moves.column_classes', column_classes);
            $this.data('pokemon_moves.version_column_count',
                       $version_columns.length);

            // Remember the arrangement of rows, including header rows.  Using
            // references to the rows themselves will also let us delete them
            // at will and restore them later, which makes resetting to page
            // default much easier
            var row_order = $this.find('tr').get();
            $this.data('pokemon_moves.original_rows', row_order);


            var $controls = $('<tr class="js-dex-pokemon-moves-controls"></tr>');

            // Create buttons for filtering by generation
            var vg_start = 0;
            var vg_width = 0;
            var $last_filter_control;
            for (var i = 0; i < $version_columns.length; i++) {
                vg_width++;
                if ($( $version_columns[i] )
                    .hasClass('dex-col-last-version'))
                {
                    var $control = $(
                        '<td class="js-dex-pokemon-moves-filter-link" colspan="' + vg_width + '">'
                        + '<img src="/static/spline/icons/table-select-column.png" alt="Filter" title="Filter">'
                        + '<div class="js-label">Hide<br>others</div>'
                        + '</td>'
                    );

                    $control.data(
                        'pokemon_moves.column_endpoints', {
                            'start': vg_start,
                            'end':   vg_start + vg_width - 1
                        }
                    );
                    $last_filter_control = $control;
                    $control.click(pokedex.pokemon_moves.filter_columns);
                    $controls.append($control);
                    vg_start += vg_width;
                    vg_width = 0;
                }
            }

            // Create buttons for sorting by a column
            var $first_tds = $first_tr.find('td, th');
            var $first_data = $this.find('tr:not(.js-dex-pokemon-moves-controls)'
                                         + ':not(.header-row)'
                                         + ':not(.subheader-row)')
                                   .eq(0)
                                   .find('td');
            var num_columns = $first_tds.length;
            for (var i = $version_columns.length; i < num_columns; i++) {
                var is_numeric = false;

                if (parseInt($first_data.eq(i).text()))
                    // Ought to cover stats, which are always numeric
                    is_numeric = true;

                // Other columns that are numeric in theory but may contain
                // missing or junk data
                // Fair warning: this is kinda brittle
                var column_title = $first_tds.eq(i).text();
                if (column_title == 'PP'  || column_title == 'Power' ||
                    column_title == 'Acc' || column_title == 'Pri')
                {
                    is_numeric = true;
                }

                var $control = $(
                    '<td class="js-dex-pokemon-moves-sort-link">'
                    + '<img src="/static/spline/icons/sort-'
                        + (is_numeric ? 'number-descending' : 'alphabet')
                        + '.png" alt="Sort" title="Sort">'
                    + '</td>'
                );
                $control.data('pokemon_moves.column', i + 1);
                $control.data('pokemon_moves.is_numeric', is_numeric);
                $control.click(pokedex.pokemon_moves.sort_rows);
                $controls.append($control);
            }

            // Add controls to the document
            $first_tr.before($controls);

            if ($last_filter_control) {
                // Initially filter to only the most recent games, i.e., the last
                // column
                $last_filter_control.click();
            }
        });
    },

    //// These functions handle restoring the table to its original state.
    //// There isn't a simple way to undo a sort without affecting the
    //// generation filter or vice versa.  Also, when a filter is removed, the
    //// table needs to be reset (in case the filter removed any rows) and then
    //// resorted.  So if either is disabled, we actually just reset the entire
    //// table and then re-apply whatever's appropriate.

    // Reset filtering
    'unfilter': function(e) {
        var $td = $(e.target).closest('td');
        var $table = $td.closest('table.dex-pokemon-moves');
        var $controls = $table.find('tr.js-dex-pokemon-moves-controls');

        // Restore column definitions
        $table.find('col.dex-col-version').remove();
        var column_classes = $table.data('pokemon_moves.column_classes');
        for (var col = column_classes.length; col >= 1; col--) {
            $table.prepend('<col class="' + column_classes[col - 1] + '">');
        }

        // Unhide everything in the controls row
        $controls.find('td, th').css('display', null);

        // Unhide generation columns in ALL rows and unmark them as filtered
        var $original_rows = $( $table.data('pokemon_moves.original_rows') );
        $original_rows.find('td, th').css('display', null);
        $original_rows.removeData('pokemon_moves.filtered_out');

        // Blank the table
        $table.find('tr')
               .not('.js-dex-pokemon-moves-controls')
               .slice(1)  // leave the first header row
               .remove();

        // Repopulate the table, to restore any filtered-out rows
        var sorted_rows = $table.data('pokemon_moves.sorted_rows');
        var $sorted_rows;
        if (sorted_rows) $sorted_rows = $(sorted_rows);
        else             $sorted_rows = $original_rows;
        $table.append($sorted_rows);

        // Reset filter links
        $td.unbind('click', pokedex.pokemon_moves.unfilter);
        $td.click(pokedex.pokemon_moves.filter_columns);
        $td.find('img').attr({
            'src':   '/static/spline/icons/table-select-column.png',
            'alt':   'Filter',
            'title': 'Filter'
        });
        $td.find('.js-label').html("Hide<br>others");
    },

    // Reset sorting
    'unsort': function(e) {
        var $td = $(e.target).closest('td');
        var $table = $td.closest('table.dex-pokemon-moves');

        $table.removeData('pokemon_moves.sorted_rows');

        // Restore list of rows...  but only if they haven't been removed by
        // filtering
        // Can't use remove() here, as it clears the data() on the rows
        $table.find('tr:not(.js-dex-pokemon-moves-controls)').each(function() {
            this.parentNode.removeChild(this);
        });
        var $original_rows = $( $table.data('pokemon_moves.original_rows') );
        var $unfiltered_rows = $original_rows.filter(function() {
            return ! $(this).data('pokemon_moves.filtered_out');
        });

        $table.append($unfiltered_rows);

        // Reset sort links and remove styling
        pokedex.pokemon_moves.unsort_partial($table);
    },

    // Reset the current sorted column's link to its original "sort this"
    // state, and delete the colorful sorted-by class from the sorted column.
    // Used if we sort by one column, then sort by another without unsorting
    // first
    'unsort_partial': function($table) {
        // Remove highlight class
        $table.find('td.js-sorted-by').removeClass('js-sorted-by');

        $table.find('tr.js-dex-pokemon-moves-controls'
                  + ' img[src*="sort--minus.png"]').each(function() {
            var $this = $(this);
            var $td = $this.closest('td');

            // Reset click event handler
            $td.unbind('click', pokedex.pokemon_moves.unsort);
            $td.click(pokedex.pokemon_moves.sort_rows);

            // Reset icon
            var is_numeric = $this.closest('td')
                                  .data('pokemon_moves.is_numeric');
            $this.attr({
                'src':   '/static/spline/icons/sort-'
                         + (is_numeric ? 'number-descending' : 'alphabet')
                         + '.png',
                'alt':   'Sort',
                'title': 'Sort'
            });
        });
    },

    //// Actually do filtering or sorting

    // Show only the columns numbered in the passed list
    'filter_columns': function(e) {
        var $td = $(e.target).closest('td');
        var $tr = $(e.target).closest('tr');
        var $this = $tr.closest('table.dex-pokemon-moves');
        // First unhide everything
        $this.find('td, th').css('display', null);

        // Get the indexes of the columns in the selected generation
        var columns_hash = {};
        var start_end = $td.data('pokemon_moves.column_endpoints');
        for (var i = start_end.start; i <= start_end.end; i++) {
            columns_hash[i + 1] = 1;
        }

        // Write out only the <col> tags for the columns we're keeping
        var column_classes = $this.data('pokemon_moves.column_classes');
        var hidden_cell_css = [];
        var visible_cell_css = [];
        $this.find('col.dex-col-version').remove();
        for (var col = column_classes.length; col >= 1; col--) {
            if (columns_hash[col]) {
                $this.prepend('<col class="' + column_classes[col - 1] + '">');
                visible_cell_css.push(':nth-child(' + col + ')')
            }
            else {
                hidden_cell_css.push(':nth-child(' + col + ')')
            }
        }

        // Hide the appropriate cells in every row that isn't mucked up by
        // colspan (i.e. a subheader or the control row)
        var $all_rows = $( $this.data('pokemon_moves.original_rows') );
        var $non_spanned_rows = $all_rows.not('.subheader-row')
                                         .not($tr);
        var $cells = $non_spanned_rows.find('th, td');
        $cells.filter( hidden_cell_css.join(',') )
              .css('display', 'none');

        // Hide any rows that only have empty cells remaining
        // i.e. hide any rows that AREN'T rows WITHOUT empty cells remaining.
        var $visible_cells = $cells.filter( visible_cell_css.join(',') )
        var $relevant_rows = $visible_cells.not('.tutored, :empty')
                                           .closest('tr');
        // Tutors have a different notion of "empty", as each cell is its own
        // mini table thing.  They're empty iff they have no img children.
        var $relevant_tutor_rows = $visible_cells.filter('.tutored')
                                                 .children('img')
                                                 .closest('tr');
        $relevant_rows = $relevant_rows.add($relevant_tutor_rows);

        var $empty_rows = $non_spanned_rows.not($relevant_rows);
        // Must do remove() FIRST, as it nukes data()
        $empty_rows.remove()
                   .data('pokemon_moves.filtered_out', true);

        // Similarly filter the control row
        $tr.find('td.js-dex-pokemon-moves-filter-link')
           .not($td)
           .css('display', 'none');

        // Set the lone remaining filter icon to unfilter
        $td.unbind('click', pokedex.pokemon_moves.filter_columns);
        $td.click(pokedex.pokemon_moves.unfilter);
        $td.find('img').attr({
            'src':   '/static/spline/icons/table-select-all.png',
            'alt':   'Unfilter',
            'title': 'Unfilter'
        });
        $td.find('.js-label').text("Show all");
    },

    // Sort the table by the selected column
    'sort_rows': function(e) {
        var $td = $(e.target).closest('td');
        var $tr = $td.closest('tr');
        var $this = $tr.closest('table.dex-pokemon-moves');

        // Reset the currently-sorted column, if any
        pokedex.pokemon_moves.unsort_partial($this);

        // Highlight the current sort
        $td.addClass('js-sorted-by');

        // Multi-step process, here.
        // 1. Find all the rows that aren't the control row or the first header
        //    row.
        // 2. Save the rows that contain actual data.
        // 3. Delete everything.
        // 4. Sort the saved rows.
        // 5. Reinsert the saved rows.
        var $rows = $this.find('tr').not($tr);
        $rows = $rows.slice(1);
        // Can't use remove() here, as it clears the data() on the rows
        $rows.each(function() {
            this.parentNode.removeChild(this);
        });

        // Get a list of all the data rows -- i.e., not the headers
        var $original_rows = $( $this.data('pokemon_moves.original_rows') );
        var $data_rows = $original_rows.not('.header-row, .subheader-row');

        // Create a sort function.
        // Experimentation reveals that Array.sort(func) will actually call
        // func() for every pair of items that need comparing—which is O(n²) in
        // the worst case.  Let's cache the sort key for each row, then, and
        // remove it afterwards.
        var column_idx = $td.data('pokemon_moves.column');
        var is_numeric = $td.data('pokemon_moves.is_numeric');
        var name_column_idx = 1 + $this.data('pokemon_moves.version_column_count');
        $data_rows.each(function() {
            var $this = $(this);
            // Use html() over text() so types sort correctly.  Yes, that means
            // the sort key is '<a href=".../normal">...'.  Gross.
            var $td = $this.find('td:nth-child(' + column_idx + ')');
            var sortkey = $td.html();
            if (is_numeric) {
                sortkey = parseInt(sortkey);
                // Negative so biggest comes first
                if (sortkey) sortkey *= -1;
                else sortkey = 0;
            }
            $this.data('pokemon_moves.sortkey1', sortkey);

            // Name is always fallback
            var name = $this.find('td:nth-child(' + name_column_idx + ')')
                            .text();
            $this.data('pokemon_moves.sortkey2', name);

            // While we're here!  Add a class to make it obvious what we're
            // sorting by
            $td.addClass('js-sorted-by');
        });
        var sort_callback = function(a, b) {
            var a_value = $(a).data('pokemon_moves.sortkey1');
            var b_value = $(b).data('pokemon_moves.sortkey1');
            if      (a_value > b_value) return  1;
            else if (a_value < b_value) return -1;

            // Try names as a fallback
            var a_name = $(a).data('pokemon_moves.sortkey2');
            var b_name = $(b).data('pokemon_moves.sortkey2');
            if      (a_name > b_name) return  1;
            else if (a_name < b_name) return -1;

            // Equal, as far as we care
            return 0;
        };

        // Sort the rows in groups divided by header rows.  (If we're in merged
        // mode, there will only be one header at the top anyway, so there's no
        // need to do anything special)
        var $unsorted_rows = $( $original_rows );
        var sorted_rows = [];
        while ($unsorted_rows.length) {
            // Pull out header rows followed by everything up until the next
            // header row
            var first_header = $unsorted_rows.filter('.header-row').get(1);
            var $chunk;
            if (first_header) {
                var endpoint = $unsorted_rows.index(first_header);
                $chunk = $unsorted_rows.slice(0, endpoint)
                $unsorted_rows = $unsorted_rows.slice(endpoint);
            }
            else {
                $chunk = $unsorted_rows;
                $unsorted_rows = $( [] );
            }

            var $headers = $chunk.filter('.header-row, .subheader-row');
            var data = $chunk.not('.header-row, .subheader-row').get();
            data.sort(sort_callback);

            sorted_rows = sorted_rows.concat($headers.get())
                                     .concat(data);
        }

        // Some of the rows are hidden by the generation filter and won't be
        // shown, but the order of ALL the rows needs to be saved so the filter
        // can be removed without having to re-sort everything
        $this.data('pokemon_moves.sorted_rows', sorted_rows);
        var $sorted_rows = $(sorted_rows).filter(function() {
            return ! $(this).data('pokemon_moves.filtered_out');
        });
        $this.append($sorted_rows);

        // Change the link to unsort
        var $img = $td.find('img');
        $td.unbind('click', pokedex.pokemon_moves.sort_rows);
        $td.click(pokedex.pokemon_moves.unsort);
        $img.attr({
            'src':   '/static/spline/icons/overlay/sort--minus.png',
            'alt':   'Unsort',
            'title': 'Unsort'
        });
    },
};

$(function() { pokedex.pokemon_moves.init() });



// Easter egg: obdurate
$(function() {
    $('.dex-obdurate').each(function() {
        var $this = $(this);
        var text = $this.text();

        // Wrap words in these so the browser doesn't break in the middle of a
        // "word"
        var nobr_start = '<nobr>';
        var nobr_end = '</nobr><wbr>';

        var newtext = [ nobr_start ];

        for (var i = 0; i < text.length; i++) {
            var ch = text.substr(i, 1);
            newtext.push('<img src="/dex/media/fonts/diamond-pearl-platinum/' + ch + '.png">');

            if (ch == ' ') {
                // Allow break on spaces
                newtext.push(nobr_end);
                newtext.push(nobr_start);
            }
        }

        newtext.push(nobr_end);
        $this.html(newtext.join(''));
    });
});

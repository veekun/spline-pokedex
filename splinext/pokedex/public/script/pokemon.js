// onload: mini exp calculator
$(function() {
    // This just takes a level and sticks in some calculated exp

    var base_exp = $('#dex-pokemon-exp-base').text();

    // Event handler to update the calculated EXP
    var update_exp_handler = function() {
        var $level_textbox = $('#dex-pokemon-exp-level');
        var level = pokedex.parse_integer($level_textbox.val(), 1, 100);

        if (level == undefined) {
            // Not a number from 1 to 100; bail!
            $level_textbox.addClass('error');
            return;
        }
        else {
            $level_textbox.removeClass('error');
        }

        var exp = pokedex.formulae.earned_exp({
            'base_exp': base_exp,
            'level': level,
        });

        $('#dex-pokemon-exp').text(exp);
    };

    // Run the above handler when the level is changed, but also during load
    // (i.e. now) to fix the initial value
    $('#dex-pokemon-exp-level').keyup(update_exp_handler);
    update_exp_handler();
});

// onload: stats table
$(function() {
    var $textboxes = $('input#dex-pokemon-stats-level, input#dex-pokemon-stats-effort');
    var $parent_table = $textboxes.parents('table.dex-pokemon-stats');
    var $stat_rows = $parent_table.find('tr:has(td.dex-pokemon-stats-result)');

    // Since JS is obviously enabled, let the people change the level/EVs
    $textboxes.removeAttr('disabled');

    // Event handler to update the calculated stats
    var update_stats_handler = function() {
        // Error checking; make sure we have integers in both boxes
        var bail = false;       // becomes true if we find an error
        var box_ranges = {      // textboxes and possible values
            'level':  {'min': 1, 'max': 100},
            'effort': {'min': 0, 'max': 255}
        };
        var input = {};         // parsed integer values
        for (var box in box_ranges) {
            var range = box_ranges[box];
            var $textbox = $('#dex-pokemon-stats-' + box);
            var value = pokedex.parse_integer($textbox.val(),
                                              range.min, range.max);
            if (value == undefined) {
                $textbox.addClass('error');
                bail = true;
            }
            else {
                $textbox.removeClass('error');
                input[box] = value;
            }
        }

        if (bail) return;

        // Iterate over each stat row and update accordingly
        $stat_rows.each(function() {
            var $row = $(this);
            var $cells = $row.find('td.dex-pokemon-stats-result');

            // Use HP or general stat formula?
            var stat_name = $row.find('th:first-child').text();
            var formula;
            if (stat_name.match(/HP/))
                formula = pokedex.formulae.calculated_hp;
            else
                formula = pokedex.formulae.calculated_stat;

            // Calculate and update the table
            var base_stat = $row.find('.dex-pokemon-stats-bar').text()
            var min_stat = formula({
                'iv':        0,
                'base_stat': base_stat,
                'level':     input.level,
                'effort':    input.effort
            });
            var max_stat = formula({
                'iv':        31,
                'base_stat': base_stat,
                'level':     input.level,
                'effort':    input.effort
            });
            $( $cells[0] ).text(min_stat);
            $( $cells[1] ).text(max_stat);
        });
    };

    // Update the stats when a key is pressed in a textbox...
    $textboxes.keyup(update_stats_handler);
    // ...but also now during page load, as e.g. firefox might remember old input
    update_stats_handler();
});


//// Trainer scaling stuff
// Same as spline.plugins.pokedex.helpers.scale_sizes().
// Normalizes a hash of sizes so the largest is 1.
function scale_sizes(sizes, dimensions) {
    if (!dimensions)
        dimensions = 1;

    var max_size = 0;
    for (var key in sizes) {
        if (sizes[key] > max_size)
            max_size = sizes[key];
    }

    var scaled_sizes = {};
    for (var key in sizes) {
        scaled_sizes[key] = Math.pow(sizes[key] / max_size, 1 / dimensions);

        // 0.00000001 comes out as 1e-8, which doesn't make for a valid
        // height in CSS.  Past a certain point, just return 0.
        if (scaled_sizes[key] < 1e-6)
            scaled_sizes[key] = 0;
    }

    return scaled_sizes;
};

// onload to set up the size graph
$(function() {
    // Also, if there's a cookie containing previously-chosen sizes, let's
    // fill them in.
    var sizes_cookie = $.cookies.get('dex-trainer-size');
    if (sizes_cookie && typeof(sizes_cookie) == typeof("")) {
        // If it's a string, it's old.  Promote to an object
        // XXX remove this shim
        var cookie_parts = sizes_cookie.split(';');
        sizes_cookie = {
            height: { input: cookie_parts[0] },
            weight: { input: cookie_parts[1] },
        };
    }

    if (sizes_cookie) {
        $('input#dex-pokemon-height').val(sizes_cookie.height.input);
        $('input#dex-pokemon-weight').val(sizes_cookie.weight.input);
    }
    else {
        // Blank; fill in some defaults
        sizes_cookie = {
            height: { input: $('input#dex-pokemon-height').val() },
            weight: { input: $('input#dex-pokemon-weight').val() },
        };
    }

    var $textboxes = $('input#dex-pokemon-height, input#dex-pokemon-weight');

    // Since JS is obviously enabled, let people change the trainers' sizes
    $textboxes.removeAttr('disabled');

    // Little function that actually applies the size
    function do_size_change($element, units, dimensions) {
        $element.removeClass('error');

        // Scale stuff proportionally
        var sizes = {
            'trainer': units,
            'pokemon': $element.parents('.dex-size')
                              .find('.js-dex-size-raw')
                              .text(),
        };
        sizes = scale_sizes(sizes, dimensions);

        // Resize trainer and shape proportionally
        var $container = $element.parents('.dex-size');
        $container.find('.dex-size-trainer img')
                  .css('height', sizes.trainer * 100 + '%');
        $container.find('.dex-size-pokemon img')
                  .css('height', sizes.pokemon * 100 + '%');
    };

    // Event handler to update the relative sizes
    var update_sizes_handler = function() {
        var $target = $(this);
        var input = $target.val();
        var dimensions, size_key;

        if ($target.is('#dex-pokemon-height')) {
            size_key = 'height';
            dimensions = 1;
        }
        else {
            size_key = 'weight';
            dimensions = 2;
        }

        // If what's been written is what's already in the cookie and there's a
        // value there, no need to hit the server
        if (sizes_cookie[size_key].input == input &&
            sizes_cookie[size_key].output !== undefined)
        {
            do_size_change($target, sizes_cookie[size_key].output, dimensions);
            return;
        }

        // Ajax request conservation
        // If the text didn't actually change, do nothing.
        var last_input = $target.data('pokedex-trainer-size-input');
        if (last_input !== undefined && last_input == input) {
            return;
        }
        $target.data('pokedex-trainer-size-input', input);
        // If there's already a request going, kill it
        var last_req = $target.data('pokedex-trainer-size-request');
        if (last_req) {
            last_req.abort();
        }

        // Let Python take care of the parsing, because it has to for Pokémon
        // search, and JavaScript parsing sucks
        var req = $.ajax({
            type: "GET",
            url: '/dex/parse_size',
            data: {
                size: input,
                mode: size_key,
            },

            // Got a size, already in Pokémon units
            success: function(res) {
                var units = parseFloat(res);

                // Store the validated value in a cookie
                sizes_cookie[size_key] = {
                    input: input,
                    output: units,
                };
                $.cookies.set('dex-trainer-size', sizes_cookie);

                do_size_change($target, units, dimensions);
            },

            // Miserable failure results in a 400, which will be interpreted as
            // an error.  Make the thing bright red and angry
            error: function() {
                $target.addClass('error');
            },
        });
        $target.data('pokedex-trainer-size-request', req);
    };

    $textboxes.keyup(update_sizes_handler);
    $textboxes.keyup();
});

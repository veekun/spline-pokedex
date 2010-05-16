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

////////////////////////////////////////////////////////////////////////////////
// The below is all for live trainer resizing.  I am very sorry.

var si_prefixes = {
    'yotta': 1e24,      'yocto': 1e-24,
    'zetta': 1e21,      'zepto': 1e-21,
    'exa'  : 1e18,      'atto' : 1e-18,
    'peta' : 1e15,      'femto': 1e-15,
    'tera' : 1e12,      'pico' : 1e-12,
    'giga' : 1e9,       'nano' : 1e-9,
    'mega' : 1e6,       'micro': 1e-6,
    'kilo' : 1000,      'milli': 1/1000,
    'hecta': 100,       'centi': 1/100,
    'deca' : 10,        'deci' : 1/10,
};
var si_abbrs = {
    'Y' : 'yotta',      'y' : 'yocto',
    'Z' : 'zetta',      'z' : 'zepto',
    'E' : 'exa',        'a' : 'atto',
    'P' : 'peta',       'f' : 'femto',
    'T' : 'tera',       'p' : 'pico',
    'G' : 'giga',       'n' : 'nano',
    'M' : 'mega',       'µ' : 'micro',
    'k' : 'kilo',       'm' : 'milli',
    'h' : 'hecta',      'c' : 'centi',
    'da': 'deca',       'd' : 'deci',
};

// 1 of each unit is X meters
var height_units = {
    'meter':    1,
    'metre':    1,

    'ångström': 1e-10,
    'angstrom': 1e-10,
    'thou':     0.0000254,
    'inch':     0.0254,
    'hand':     0.1016,
    'foot':     0.3048,
    'yard':     0.9144,
    'furlong':  201.168,
    'mile':     1609.344,
    'league':   4828.032,
    'link':     0.201168,
    'rod':      5.0292,
    'pole':     5.0292,
    'chain':    20.1168,

    // nautical
    'fathom':   1.853184,
    'cable':    185.3184,
    'nauticalmile': 1853.184,

    // astronomy and physics
    'astronomicalunit': 1.496e11,
    'lightyear':        9.461e15,
    'lightsecond':      299792458,
    'lightminute':      17987547480,
    'lighthour':        1079252848800,
    'lightday':         2.59020684e13,
    'lightweek':        1.81314479e14,
    'lightfortnight':   3.62628958e14,
    'parsec':           3.0857e16,
    'plancklength':     1.61625281e-35,
    'lightplanck':      1.61625281e-35,

    // ancient
    'cubit':    0.45,
    'royalcubit': 0.525,
};
var height_abbrs = {
    'Å'  : 'ångström',
    'm'  : 'meter',
    'in' : 'inch',
    'h'  : 'hand',
    'ft' : 'foot',
    'yd' : 'yard',
    'mi' : 'mile',
    'li' : 'link',
    'rd' : 'rod',
    'ch' : 'chain',
    'fur': 'furlong',
    'lea': 'league',
    'ftm': 'fathom',
    'cb' : 'cable',
    'NM' : 'nauticalmile',
    'au' : 'astronomicalunit',
    'ly' : 'lightyear',
    'pc' : 'parsec',
};


// 1 of these is X kilograms
var weight_units = {
    'grain':            0.00006479891,
    'dram':             0.001771845,
    'ounce':            0.02834952,
    'pound':            0.45359237,
    'stone':            6.35029318,
    'quarter':          12.70058636,
    'hundredweight':    45.359237,
    'shortton':         907.18474,
    'ton':              907.18474,
    'longton':          1016.0469088,
    'metricton':        1000,
    'troyounce':        0.03110348,
    'troypound':        0.3732417,
    'pennyweight':      0.001555174,
    'gram':             0.001,
    'bushel':           27.216,  // wheat

    'planckmass':       2.1764411e-8,
};
var weight_abbrs = {
    'gr':   'grain',
    'dr':   'dram',
    'oz':   'ounce',
    'lb':   'pound',
    'st':   'stone',
    'qtr':  'quarter',
    'cwt':  'hundredweight',
    'ozt':  'troyounce',
    'lbt':  'troypound',
    'dwt':  'pennyweight',
    'g':    'gram',
};



// Parses a string that looks (vaguely) like a height or weight.
// `size` is the string in question.
// `units` is a hash of unit names to scale factors.
// `abbrs` is a hash of abbreviations for unit names
// Also makes use of si_prefixes and si_abbrs above.
// Returns a single number, in whatever units the `units` hash scales to.
// TODO accept pokemon names
// TODO return the "primary" unit (whatever that means) and show pokemon size in it
// TODO just offload this to the server  :|
function parse_size(size, units, abbrs) {
    // Strip whitespace
    size = size.replace(/[\s,]/g, '');
    if (size == '') return undefined;

    // General approach here is to split the input string into number+unit
    // and add them all up.  This takes care of any combination of feet and
    // inches, but also allows meters plus centimeters or ridiculous
    // combinations like kilometers plus feet.
    // Right now, the input string looks like '2ft3in'.  Split this on
    // numbers to get '', '2', 'ft', '3', 'in'.
    // Note that '3ft.' is not allowed!  This gets ambiguous with e.g.
    // '3ft.5in.' -- is that three feet five inches or three feet half an
    // inch?
    var parts = size.split(/((?:\d*\.)?\d+)/);
    // If first part is not empty, something was before a number, and I
    // have no idea what that means.
    if (parts[0] != '') return undefined;
    parts.shift();

    // Accept 1'3 or 2m10; these are common abbreviations
    if (parts.length == 4 && parts[3] == '') {
        if (parts[1] == 'ft' || parts[1] == "'") {
            // 1'3 => 1'3"
            parts[3] = '"';
        }
        if (parts[1] == 'm') {
            // 2m10 => 2m10cm
            parts[3] = 'cm';
        }
    }

    var result = 0;
    var match;
    while (parts.length) {
        var amount = parseFloat(parts.shift());
        var unit = parts.shift();
        if (isNaN(amount) || ! unit) return undefined;

        // Simplify units to singular names
        // Hard-coded hackery, alas!
        if (unit == 'inches' || unit == "''" || unit == '"') unit = 'inch';
        else if (unit == 'feet' || unit == '\'') unit = 'foot';
        else unit = unit.replace(/s$/, '');

        // Try abbreviations -- note that BOTH the prefix and unit must be
        // abbreviated!  You can't do millift, sorry.
        // SI prefix can be zero chars (for none), one char (most of them),
        // or two chars (deca-).  To avoid a cross-join regex mess, just
        // try these three cases
        // Unit abbreviations are always case-sensitive.
        var si_abbr, unit_abbr;
        for (var i in [0, 1, 2]) {
            // Borrow these for readability
            si_abbr = unit.substr(0, i);
            unit_abbr = unit.substr(i);

            // Remember: empty string is a valid SI prefix
            if ((! si_abbr || si_abbrs[si_abbr]) && abbrs[unit_abbr]) {
                break;
            }

            si_abbr = unit_abbr = undefined;
        }
        if (unit_abbr) {
            var si_factor = 1;
            if (si_abbr)
                si_factor = si_prefixes[ si_abbrs[si_abbr] ];
            result += amount * units[ abbrs[unit_abbr] ] * si_factor;
            continue;
        }

        // Try full names; these can be case-insensitive.
        var si_factor = 1;
        for (var prefix in si_prefixes) {
            var regex = new RegExp('^' + prefix, 'i');
            if (unit.match(regex)) {
                si_factor = si_prefixes[prefix];
                unit = unit.replace(regex, '').toLowerCase();
                break;
            }
        }
        unit = unit.toLowerCase();
        if (units[unit]) {
            result += amount * units[unit] * si_factor;
            continue;
        }

        // Don't know!
        return undefined;
    }

    return result;
};

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

// onload: size graph
$(function() {
    // Also, if there's a cookie containing previously-chosen sizes, let's
    // fill them in.
    var sizes_cookie = $.cookie('dex-trainer-size');
    if (sizes_cookie) {
        var cookie_parts = sizes_cookie.split(';');
        $('input#dex-pokemon-height').val(cookie_parts[0]);
        $('input#dex-pokemon-weight').val(cookie_parts[1]);
    }
    // Need to remember the last valid height and weight so we can store
    // them in a cookie.
    var last_sizes = {
        'height': $('input#dex-pokemon-height').val(),
        'weight': $('input#dex-pokemon-weight').val(),
    };

    var $textboxes = $('input#dex-pokemon-height, input#dex-pokemon-weight');

    // Since JS is obviously enabled, let people change the trainers' sizes
    $textboxes.removeAttr('disabled');

    // Event handler to update the relative sizes
    var update_sizes_handler = function(event) {
        var $target = $(event.target);
        var input = $target.val();
        var value, dimensions, size_key;

        if ($target.is('#dex-pokemon-height')) {
            size_key = 'height';
            dimensions = 1;
            value = parse_size(input, height_units, height_abbrs);
            value *= 10;  // m => dm
        }
        else {
            size_key = 'weight';
            dimensions = 2;
            value = parse_size(input, weight_units, weight_abbrs);
            value *= 10;  // kg => hg
        }

        if (value == undefined || isNaN(value)) {
            $target.addClass('error');
            return;
        }
        $target.removeClass('error');

        // Store our validated value in a cookie
        last_sizes[size_key] = input;
        $.cookie('dex-trainer-size', last_sizes.height + ';' + last_sizes.weight)

        var sizes = {
            'trainer': value,
            'pokemon': $target.parents('.dex-size').find('.js-dex-size-raw')
                              .text(),
        };
        sizes = scale_sizes(sizes, dimensions);

        // Resize trainer and shape proportionally
        var $container = $target.parents('.dex-size');
        $container.find('.dex-size-trainer img')
                  .css('height', sizes.trainer * 100 + '%');
        $container.find('.dex-size-pokemon img')
                  .css('height', sizes.pokemon * 100 + '%');
    };

    $textboxes.keyup(update_sizes_handler);
    $textboxes.keyup();
});

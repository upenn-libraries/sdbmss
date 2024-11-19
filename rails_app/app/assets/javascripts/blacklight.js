// Overrides the default blacklight JS import file, because their import of bootstrap was conflicting with OUR importing of bootstrap, etc.

// These javascript files are compiled in via the Rails asset pipeline:
//= require blacklight/core
//= require blacklight/autofocus
//= require save_current_search
//= require blacklight/ajax_modal
//= require blacklight/search_context
//= require blacklight/collapsable

$('.no-js').removeClass('no-js').addClass('js');

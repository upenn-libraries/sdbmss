/**
 * sdbmApp module for angular.js
 *
 * We only use Angular for a few data entry pages, so all of the code
 * lives here instead of being broken out further into smaller modules
 * or files.
 */

/* Hints for eslint: */
/* eslint camelcase:0, no-underscore-dangle:0 */
/* global alert, angular, console, window, setTimeout, $, SDBM, URI */
var EntryScope;
var BOOKMARK_SCOPE;

(function () {

    "use strict";

    var sdbmApp = angular.module("sdbmApp", ["ngResource", "ui.bootstrap", "ngAnimate", "ui.sortable", "ngSanitize"]);
    
    sdbmApp.run(function ($http) {
        // For Rails CSRF
        var csrf_token = $('meta[name="csrf-token"]').attr('content');
        if(csrf_token) {
            $http.defaults.headers.put['X-CSRF-Token'] = csrf_token;
            $http.defaults.headers.post['X-CSRF-Token'] = csrf_token;
        } else {
            alert("Error: no meta tag found with csrf-token. Ajax calls won't work.");
        }
    });

    sdbmApp.factory('Entry', ['$resource',
                              function($resource){
                                  return $resource('/entries/:id.json', { id: '@id' }, {
                                      query: {
                                          method: 'GET',
                                          isArray: true
                                      },
                                      update: {
                                          method:'PUT'
                                      }
                                  });
                              }]);

    sdbmApp.factory('Source', ['$resource',
                              function($resource){
                                  return $resource('/sources/:id.json', { id: '@id' }, {
                                      query: {
                                          method: 'GET',
                                          isArray: true
                                      },
                                      update: {
                                          method:'PUT'
                                      }
                                  });
                              }]);

    sdbmApp.factory('Name', ['$resource',
                              function($resource){
                                  return $resource('/names/:id.json', { id: '@id' }, {
                                      query: {
                                          method: 'GET',
                                          isArray: true
                                      },
                                      update: {
                                          method:'PUT'
                                      }
                                  });
                              }]);

    sdbmApp.factory('Language', ['$resource',
                              function($resource){
                                  return $resource('/languages/:id.json', { id: '@id' }, {
                                      query: {
                                          method: 'GET',
                                          isArray: true
                                      },
                                      update: {
                                          method:'PUT'
                                      }
                                  });
                              }]);

    sdbmApp.factory('Place', ['$resource',
                              function($resource){
                                  return $resource('/places/:id.json', { id: '@id' }, {
                                      query: {
                                          method: 'GET',
                                          isArray: true
                                      },
                                      update: {
                                          method:'PUT'
                                      }
                                  });
                              }]);

    /* Globally available utility functions */
    sdbmApp.factory('sdbmutil', function () {

        /* An object is 'blank' if its keys don't have any meaningful
         * values. We use this to filter out records that user has
         * added on UI but not populated.
         */
        var isBlankObject = function(obj) {
            var blank = true;
            if(obj !== undefined) {
                // TODO: deal with nesting?
                for(var key in obj) {
                    if(obj[key]) { blank = false; }
                }
            }
            return blank;
        };

        /* This horribly named function is meant to take any kind of
         * input and test for its 'blankness', similar to Rails
         * ActiveSupport's Object#blank? method.
         */
        var isBlankThing = function(obj) {
            var blank = false;
            if(obj === undefined || obj === null ||
               (typeof(obj) === 'string' && obj.length === 0) ||
               (Array.isArray(obj) && obj.length === 0)) {
                blank = true;
            } else if (typeof(obj) === 'number') {
                // noop: treat all numbers as non-blank
            } else {
                blank = isBlankObject(obj);
            }
            return blank;
        };

        /* This fn filters out 'blank' records from objectWithAssociations,
         * using the (meta)data in the 'assoc' object, which specifies what
         * properties and child associations exist.
         */
        var filterBlankRecords = function (objectWithAssociations, assoc) {
            var objectArrayName = assoc.field;
            // construct array of passed-in object's properties, FKs,
            // and child associations, to check for blankness
            var thingsToCheck = (assoc.properties || []).concat(assoc.foreignKeyObjects || []);
            if(assoc.associations) {
                thingsToCheck = thingsToCheck.concat(assoc.associations.map(function (item) {
                    return item.field;
                }));
            }

            var objectArray = objectWithAssociations[objectArrayName];
            if(objectArray === undefined) {
                alert("error: couldn't find object array for '" + objectArrayName + "'");
            }
            // filter out items in array that are either empty objects or are objects that have blank fields
            objectArray.forEach(function (childObject) {

                // do depth-first recursion, so that records lower in
                // the tree get removed first
                var childAssociations = assoc.associations || [];
                childAssociations.forEach(function (childAssoc) {
                    filterBlankRecords(childObject, childAssoc);
                });

                var keep = true;
                if(assoc.skipChecking === undefined || !assoc.skipChecking(childObject)) {
                    //console.log('checking ' + objectArrayName + ' record id = ' + childObject.id);
                    keep = false;
                    thingsToCheck.forEach(function (propertyName) {
                        var propertyIsBlank = isBlankThing(childObject[propertyName]);
                        //console.log('is property ' + propertyName + ' (value=[' + childObject[propertyName] + ']) blank? ' + propertyIsBlank);
                        if(!propertyIsBlank) {
                            keep = true;
                        }
                    });
                }
                if(!keep) {
                    childObject._destroy = 1;
                }
            });
            objectWithAssociations[objectArrayName] = objectArray.filter(function(childObject) {
                if(childObject._destroy && !childObject.id) {
                    return false;
                }
                return true;
            });
        };

        /* returns the URL parameter 'manuscript_id' from the currently loaded page's URL */
        var getManuscriptId = function() {
            return URI().search(true).manuscript_id;
        };

        /* returns the path to the Create Entry page for a source,
           optionally passing along the 'manuscript_id' parameter if
           there is one.
         */
        var getEntryCreateURL = function (source_id) {
            var path = "/entries/new/?source_id=" + source_id;
            var manuscript_id = getManuscriptId();
            if(manuscript_id) {
                path += "&manuscript_id=" + manuscript_id;
            }
            return path;
        };

        var parseRailsErrors = SDBM.parseRailsErrors;

        return {
            /* returns a printable (ie. for use with console.log),
             * snapshot the passed-in object. This exists because if
             * you use console.log(obj), browsing that object in the
             * Firefox console will always give you the CURRENT object
             * state instead of its state at the time of printing. So
             * do console.log(sdbmutil.objectSnapshot(obj)) instead.
             */
            objectSnapshot: function (object) {
                return JSON.parse(JSON.stringify(object));
            },
            /* for each object in objectArray, find the member referenced
             * by relatedObjectName, which should be a JS object, and
             * replace it with that object's 'id' attribute.
             */
            replaceEntityObjectsWithIds: function (objectArray, relatedObjectName) {
                objectArray.forEach(function (element, index, array) {
                    if(element[relatedObjectName]) {
                        element[relatedObjectName + "_id"] = element[relatedObjectName].id;
                        delete element[relatedObjectName];
                    } else if (element[relatedObjectName] === null) {
                        element[relatedObjectName + "_id"] = null;
                        delete element[relatedObjectName];
                    }
                });
            },
            parseRailsErrors: parseRailsErrors,
            /*
             * assoc = a data object describing associations contained in objectWithAssociations
             */
            filterBlankRecords: filterBlankRecords,
            /* optionsArray is an array of two-item arrays (a Django
             * 'choices' data struct)
             */
            inOptionsArray: function (value, optionsArray) {
                for(var i in optionsArray) {
                    var option = optionsArray[i];
                    if(option[0] === value) {
                        return true;
                    }
                }
                return false;
            },
            /* optionsObjectsArray is an array of objects containing
             * key 'value', which we use to check for membership
             */
            inOptionsObjectsArray: function(value, optionsObjectsArray) {
                for(var i in optionsObjectsArray) {
                    var option = optionsObjectsArray[i];
                    if(option.value === value) {
                        return true;
                    }
                }
                return false;
            },
            getManuscriptId: getManuscriptId,
            /* Returns a fn that can be used as error callback on angular promises */
            promiseErrorHandlerFactory: function(msg) {
                return function(response) {
                    var append_str = "";
                    if(response.data && response.data.errors) {
                        // interpret Rails validation errors
                        var errors = parseRailsErrors(response.data.errors);
                        append_str = errors.join("; ");
                    } else {
                        var errorData = response.data;
                        if(errorData && errorData.length > 1000) {
                            errorData = errorData.substring(0, 1000) + " [truncated] ..."
                        }
                        append_str = "Unknown server error:" + SDBM.escapeHtml(errorData);
                    }
                    SDBM.showErrorModal("#modal", msg + ": " + append_str);
                };
            },
            getEntryCreateURL: getEntryCreateURL,
            redirectToSourceEditPage: function(source_id)  {
                window.location = "/sources/" + source_id + "/edit/";
            },
            redirectToEntryCreatePage: function(source_id)  {
                window.location = getEntryCreateURL(source_id);
            },
            redirectToEntryEditPage: function(entry_id)  {
                window.location = "/entries/" + entry_id + "/edit/";
            },
            redirectToEntryViewPage: function(entry_id)  {
                window.location = "/entries/" + entry_id;
            },
            redirectToEntryHistoryPage: function(entry_id)  {
                window.location = "/entries/" + entry_id + "/history/";
            },
            redirectToManuscriptEditPage: function(manuscript_id)  {
                window.location = "/manuscripts/" + manuscript_id + "/edit/";
            },
            redirectToFindOrCreateManuscriptForEntryPage: function(entry_id) {
                window.location = "/linkingtool/entry/" + entry_id;
            },
            redirectToDashboard: function() {
                window.location = "/dashboard";
            }
        };
    });

    /* Controller for selecting a source*/
    sdbmApp.controller("SelectSourceCtrl", function ($scope, $http, sdbmutil) {

        $scope.sdbmutil = sdbmutil;

        $scope.searchAttempted = false;
        $scope.title = "";
        $scope.date = "";
        $scope.agent = "";
        $scope.sources = [];

        $scope.setSource = function (source) {
          $scope.$emit('changeSource', source)
        }

        $scope.cancelSelectSource = function () {
          $scope.$emit('cancelSource');
        }

        $scope.createSourceURL = function () {
            var path = "/sources/new?create_entry=1";
            var manuscript_id = sdbmutil.getManuscriptId();
            if(manuscript_id) {
                path += "&manuscript_id=" + manuscript_id;
            }
            return path;
        };

        $scope.findSourceCandidates = function () {
            if($scope.title.length > 2 || $scope.date.length > 2 || $scope.agent.length > 2) {
                $scope.searchAttempted = true;
                $http.get("/sources/search.json", {
                    params: {
                        date: $scope.date,
                        title: $scope.title,
                        agent: $scope.agent,
                        limit: 20,
                        source_type_id: $scope.source_type,
                        id: $scope.source_id,
                        id_option: "without"
                    }
                }).then(function (response) {
                    $scope.sources = response.data.results;
                }, function(response) {
                    alert("An error occurred searching for sources");
                });
            } else {
                $scope.sources = [];
            }
        };

        $scope.$watch('title', $scope.findSourceCandidates);
        $scope.$watch('date', $scope.findSourceCandidates);
        $scope.$watch('agent', $scope.findSourceCandidates);
    });

    /* Entry screen controller */
    sdbmApp.controller("EntryCtrl", function ($scope, $http, Entry, Source, sdbmutil, $modal) {

        EntryScope = $scope;

        // affixes the association name and 'add' button to side, so that it is in view when list is long
        // FIX ME: glitchy, jumps
        // FIX ME: delay in loading causes the height calculations to malfunction
        $scope.affixer = function () {
          $('.side-title').each( function () {
            // ignore this if the list is short
            if ( $(this).closest('.row').height() < $(window).height() - 500) return;
            
            var top = $(this).closest('.row').offset().top;
            var bottom = $(document).height() - (top + $(this).closest('.row').height());
            $(this).affix({offset: {top: top, bottom: bottom} }); //Try it
            $(this).data('bs.affix').options.offset = {top: top, bottom: bottom};
          });
        };

        $scope.sortableOptions = {
          axis: 'y',
          scrollSpeed: 40,
          placeholder: "ui-state-highlight",
          cancel: ".ui-sortable-locked, .ui-sortable-locked + .input-block",
          handle: "label, .panel-heading",
          scrollSensitivity: 100,
          start: function(e, ui){
              ui.placeholder.height(ui.item.height());
          },
          stop: function (e, ui) {
            // this is an ugly way to just get a reference to the array (i.e. entry_titles, provenance) that we are sorting
            var field = ui.item.parent().attr('ng-model').split('.')[1];
            for (var i = 0; i < $scope.entry[field].length; i++) {
              $scope.entry[field][i].order = i;
            }
          }
        }

        $scope.lockProvenance = function ($event) {
          $($event.currentTarget).closest('.input-block').toggleClass('ui-sortable-locked')
        }

        $scope.sdbmutil = sdbmutil;

        // this describes the (nested) associations inside an Entry;
        // we use it, when saving, to identify and remove 'blank'
        // records, set foreign key ID fields, and rename the keys for
        // array values to follow the Rails '_attributes' convention
        // for nested attributes
        $scope.associations = [
            {
                field: 'entry_titles',
                properties: ['title', 'common_title', 'order']
            },
            {
                field: 'entry_authors',
                properties: ['observed_name', 'order'],
                foreignKeyObjects: ['author']
            },
            {
                field: 'entry_dates',
                properties: ['observed_date', 'date_normalized_start', 'date_normalized_end', 'order']
            },
            {
                field: 'entry_artists',
                properties: ['observed_name', 'order'],
                foreignKeyObjects: ['artist']
            },
            {
                field: 'entry_scribes',
                properties: ['observed_name', 'order'],
                foreignKeyObjects: ['scribe']
            },
            {
                field: 'entry_languages',
                foreignKeyObjects: ['language', 'order']
            },
            {
                field: 'entry_materials',
                properties: ['material', 'order']
            },
            {
                field: 'entry_places',
                properties: ['observed_name'],
                foreignKeyObjects: ['place', 'order']
            },
            {
                field: 'entry_uses',
                properties: ['use', 'order']
            },
            {
                field: 'sales',
                skipChecking: function(object) { return true; },
                associations: [
                    {
                        field: 'sale_agents',
                        skipChecking: function(object) { return true; },
                        properties: ['observed_name'],
                        foreignKeyObjects: ['agent']
                    }
                ]
            },
            {
                field: 'provenance',
                properties: ['start_date', 'end_date', 'associated_date', 'comment', 'observed_name', 'order'],
                foreignKeyObjects: ['provenance_agent']
            }
        ];

        $scope.pageTitle = "";

        $scope.badData = [];

        $scope.optionsTransactionType = undefined;
        $scope.optionsAuthorRole = undefined;
        $scope.optionsArtistRole = undefined;
        $scope.optionsSold = undefined;
        $scope.optionsCurrency = undefined;
        $scope.optionsMaterial = undefined;
        $scope.optionsAltSize = undefined;

        $scope.entry = undefined;

        $scope.originalEntryViewModel = undefined;

        $scope.warnWhenLeavingPage = true;

        $scope.edit = false;

        $scope.currentlySaving = false;

        $scope.$on('changeSource', function (e, src) {
          if (src.source_type != $scope.entry.source_bk.source_type.display_name) {
            alert('The new source must be of the same type as the old source.');
          }
          else {
            $scope.setSource(src);
          }
        });
        
        $scope.$on('cancelSource', function (e) {
          $scope.entry.source = $scope.entry.source_bk;
          $scope.selecting_source = false;
        });

        $scope.setSource = function (src) {
          $scope.entry.transaction_type = src.source_type == "Auction/Sale Catalog" ? "sale" : "no_transaction";
          $scope.entry.source = src;
          $scope.selecting_source = false;
        };

        $scope.editSource = function () {
          $scope.selecting_source = true;
          $scope.selecting_source_type = $scope.entry.source.source_type.id;
          $scope.old_source_id = $scope.entry.source.id;
          //console.log($scope.entry.source);
          $scope.entry.source_bk = $scope.entry.source;
          $scope.entry.source = undefined
        };

        $scope.updateProvenanceDateRange = function (prov, date) {
          //console.log('here', date);
          var observedDate = date.date;
          if(observedDate && (date.type == "Start" || date.type == "End")) {
              $http.get("/entry_dates/parse_observed_date.json" , {
                  params: {
                      date: observedDate
                  }
              }).then(function (response) {
                  if (response.data.date) {
                      if (date.type == "Start") {
                        prov.start_date_normalized_start = response.data.date.date_start;
                      } else if (date.type == "End") {
                        prov.end_date_normalized_end = response.data.date.date_end;
                      }
                  }
              }, function(response) {
                  alert("An error occurred trying to normalize date");
              });
          }
        }

        $scope.addProvenanceDate = function (prov) {
          if (!prov.dates) prov.dates = [];
          prov.dates.push({});
        }
        $scope.removeProvenanceDate = function (prov, date) {
          var index = prov.dates.indexOf(date);
          if (index != -1) {
            prov.dates.splice(index, 1);
          }
        }
        $scope.getProvenanceDateOptions = function (prov, date) {
          var d_options = ["Start", "End", "Associated"];
          for (var i = 0; i < prov.dates.length; i++) {
            if (prov.dates[i] == date) {}
            else if (prov.dates[i].type == "Start") {
              var j = d_options.indexOf("Start");
              if (j != -1) d_options.splice(j, 1);
            }
            else if (prov.dates[i].type == "End") {
              var j = d_options.indexOf("End");
              if (j != -1) d_options.splice(j, 1);
            }
          }
          return d_options;
        }

        $scope.addRecord = function (anArray) {
          anArray.push({});
          setTimeout( function () {            
            $scope.affixer();
          }, 2000);
        };

        // filter used by ng-repeat to hide records marked for deletion
        $scope.activeRecords = function(element) {
            return !element._destroy;
        };

        $scope.removeRecord = function (anArray, record) {
            if(window.confirm("Are you sure you want to remove this record?")) {
                var i;
                for (i = 0; i < anArray.length; i++) {
                    if (anArray[i] === record) {
                        if(record.id) {
                            record._destroy = 1;
                        } else {
                            anArray.splice(i, 1);
                        }
                        break;
                    }
                }
                // ensure that there's always one empty record
                if($.grep(anArray, $scope.activeRecords).length === 0) {
                    //anArray.push({});
                }

                setTimeout( function () {            
                  $scope.affixer();
                }, 2000);
          }
        };

        /* Returns true if record is the first one */
        $scope.isFirst = function (anArray, record) {
            if (anArray.length > 0) {
                return anArray[0] === record;
            }
            return false;
        };

        $scope.debug = function () {
            for (var key in $scope) {
                // don't display angular prefixed keys, and don't display methods
                if(key.substr(0,1) !== "$" && typeof $scope[key] !== "function") {
                    console.log(key);
                    console.log($scope[key]);
                }
            }
        };

        $scope.transactionTypeDisabled = function() {
            return $scope.entry && $scope.entry.source && $scope.entry.source.source_type.entries_transaction_field !== 'choose';
        };

        // sanity check that values in Entry are actually valid
        // options for dropdowns.
        $scope.sanityCheckFields = function(entry) {
            entry.entry_authors.forEach(function (entry_author) {
                if(entry_author.role) {
                    if(! sdbmutil.inOptionsArray(entry_author.role, $scope.optionsAuthorRole)) {
                        $scope.badData.push("Bad author role value: '" + entry_author.role + "'");
                    }
                }
            });
            entry.entry_artists.forEach(function (entry_artist) {
                if(entry_artist.role) {
                    if(! sdbmutil.inOptionsArray(entry_artist.role, $scope.optionsArtistRole)) {
                        $scope.badData.push("Bad author role value: '" + entry_artist.role + "'");
                    }
                }
            });


            if(entry.sale) {
                if(entry.sale.sold) {
                    if(!sdbmutil.inOptionsArray(entry.sale.sold, $scope.optionsSold)) {
                        $scope.badData.push("Bad sold value: '" + entry.sale.sold + "'");
                    }
                }
                if(entry.sale.currency) {
                    if(! sdbmutil.inOptionsArray(entry.sale.currency, $scope.optionsCurrency)) {
                        $scope.badData.push("Bad currency value: '" + entry.sale.currency + "'");
                    }
                }
            }

            entry.entry_materials.forEach(function (entry_material) {
                if(entry_material.material) {
                    if(! sdbmutil.inOptionsObjectsArray(entry_material.material, $scope.optionsMaterial)) {
                        $scope.badData.push("Bad material value: '" + entry_material.material + "'");
                    }
                }
            });
            if(entry.alt_size) {
                if(! sdbmutil.inOptionsArray(entry.alt_size, $scope.optionsAltSize)) {
                    $scope.badData.push("Bad alt size value: '" + entry.alt_size + "'");
                }
            }
        };

        // does some processing on Entry data structure retrieved via
        // API so that it can be used with the Angular form bindings
        $scope.populateEntryViewModel = function(entry) {

            //console.log("entry from API retrieval");
            //console.log(entry);

            // make blank initial rows, as needed, for user to fill out
            $scope.associations.forEach(function (assoc) {
                var fieldname = assoc.field;
                var objArray = entry[fieldname];
                if(!objArray || objArray.length === 0) {
                    //entry[fieldname] = [ {} ];
                    if (fieldname == 'provenance')
                      entry[fieldname] = [ {} ]
                    else
                      entry[fieldname] = [];
                }
            });

            // Transform EventAgent records into buyer, seller,
            // selling_agent fields on the Event, so that UI can bind
            // to that data easily
            if(entry.sale && entry.sale.sale_agents) {
                var sale_agents = entry.sale.sale_agents;
                for(var idx in sale_agents) {
                    var sale_agent = sale_agents[idx];
                    entry.sale[sale_agent.role] = sale_agent;
                }
                delete entry.sale.sale_agents;
            }
            
            if(!entry.transaction_type) {
                if(entry.source.source_type.entries_transaction_field !== 'choose') {
                    entry.transaction_type = entry.source.source_type.entries_transaction_field;
                } else {
                    // select the first one
                    entry.transaction_type = $scope.optionsTransactionType[0][0];
                }
            }

            if(!entry.sale) {
                entry.sale = {
                    sold: null
                };
                // prepopulate sale agent fields with data from source_agents
                var sourceAgents = entry.source.source_agents || [];
                sourceAgents.forEach(function (sourceAgent) {
                    var role = sourceAgent.role;
                    entry.sale[role] = {
                        agent: sourceAgent.agent
                    };
                });
            }

            $scope.sanityCheckFields(entry);

            // save copy at this point, so we have something to
            // compare to, when navigating away from page
            $scope.originalEntryViewModel = angular.copy(entry);
            //$scope.affixer();
            //
            //
            //
            // FIX ME! you need to find a better solution than a 2-second timeout!
            setTimeout( function () {
              $scope.affixer();
            }, 2000);
        };

        $scope.postEntrySave = function(entry) {
            $scope.warnWhenLeavingPage = false;

            $scope.entry = entry;
            var modalInstance = $modal.open({
                templateUrl: 'postEntrySave.html',
                backdrop: 'static',
                size: 'lg',
                scope: $scope
            });
            modalInstance.result.then(function () {
                // noop
            }, function() {
                // runs when promise is rejected (modal is dismissed)
                sdbmutil.redirectToEntryEditPage(entry.id);
            });
        };

        // append '_attributes' for Rails' accept_nested_attributes
        $scope.changeNestedAttributesNames = function(associations, obj) {
            associations.forEach(function (assoc) {
                if(obj[assoc.field]) {
                    var childObjects = obj[assoc.field];
                    obj[assoc.field + "_attributes"] = childObjects;
                    delete obj[assoc.field];
                    if(assoc.associations) {
                        childObjects.forEach(function (childObj) {
                            $scope.changeNestedAttributesNames(assoc.associations, childObj);
                        });
                    }
                }
            });
        };

        $scope.save = function () {
            // Transform angular's view models to JSON payload that
            // API expects: attach a bunch of things to Entry resource
            $scope.currentlySaving = true;

            var entryToSave = new Entry(angular.copy($scope.entry));

            // don't store a sale if it's not applicable
            if(entryToSave.transaction_type === 'no_transaction') {
                entryToSave.sale = null;
            }

            if(entryToSave.sale) {
                if(entryToSave.sale.price) {
                    entryToSave.sale.price = entryToSave.sale.price.replace(/[$,]/, '');
                }
                // Transform fields back into SaleAgent records
                entryToSave.sale.sale_agents = [];
                ["buyer", "selling_agent", "seller_or_holder"].forEach(function (role) {
                    if(entryToSave.sale[role]) {
                        var sale_agent = entryToSave.sale[role];
                        sale_agent.role = role;
                        if(sale_agent.agent) {
                            sale_agent.agent_id = sale_agent.agent.id;
                            delete sale_agent.agent;
                        }
                        entryToSave.sale.sale_agents.push(sale_agent);
                        delete entryToSave.sale[role];
                    }
                });
                entryToSave.sales = [ entryToSave.sale ];
                delete entryToSave.sale;
            } else {
                entryToSave.sales = [];
            }

            if (entryToSave.provenance) {
              for (var i = 0; i < entryToSave.provenance.length; i++) {
                var prov = entryToSave.provenance[i];
                prov.start_date = "", prov.end_date = "", prov.associated_date = "";
                if (prov.dates) {
                  for (var j = 0; j < prov.dates.length; j++) {
                    var date = prov.dates[j];
                    if (date.type == "Start") prov.start_date = date.date;
                    else if (date.type == "End") prov.end_date = date.date;
                    else if (date.type == "Associated") prov.associated_date += date.date + "\t";
                  }
                }
              }
            }

            // strip out blank objects
            $scope.associations.forEach(function (assoc) {
                sdbmutil.filterBlankRecords(entryToSave, assoc);
                if(entryToSave[assoc.field].length === 0) {
                    delete entryToSave[assoc.field];
                }
            });

            // To satisfy the API: replace nested Object
            // representations of related entities with just their IDs

            entryToSave.source_id = entryToSave.source.id;
            delete entryToSave.source;

            if(entryToSave.institution) {
                entryToSave.institution_id = entryToSave.institution.id;
                delete entryToSave.institution;
            }

            var objectArraysWithRelatedObjects = [
                [ entryToSave.entry_authors, 'author' ],
                [ entryToSave.entry_artists, 'artist' ],
                [ entryToSave.entry_scribes, 'scribe' ],
                [ entryToSave.entry_languages, 'language' ],
                [ entryToSave.entry_places, 'place' ],
                [ entryToSave.provenance, 'provenance_agent' ]                
            ];

            for(var idx in objectArraysWithRelatedObjects) {
                var record = objectArraysWithRelatedObjects[idx];
                var objectArray = record[0];
                var relatedObjectName = record[1];
                if(objectArray) {
                    sdbmutil.replaceEntityObjectsWithIds(objectArray, relatedObjectName);
                }
            }

            $scope.changeNestedAttributesNames($scope.associations, entryToSave);

        //  console.log("about to save this Entry: ");
        //  console.log(JSON.stringify(entryToSave));

            if(entryToSave.id) {
                entryToSave.$update(
                    $scope.postEntrySave,
                    sdbmutil.promiseErrorHandlerFactory("There was an error saving this entry")
                ).finally(function() {
                    $scope.currentlySaving = false;
                });
            } else {

                // link to Manuscript ID if present
                var manuscript_id = sdbmutil.getManuscriptId();
                if(manuscript_id) {
                    entryToSave.manuscript_id = manuscript_id;
                }

                entryToSave.$save(
                    $scope.postEntrySave,
                    sdbmutil.promiseErrorHandlerFactory("There was an error saving this entry")
                ).finally(function() {
                    $scope.currentlySaving = false;
                });
            }
        };

        $scope.markSourceAsEntered = function() {
            $http.post("/sources/" + $scope.entry.source.id + "/update_status", { status: 'Entered' }).then(
                function() {
                    sdbmutil.redirectToDashboard();
                },
                sdbmutil.promiseErrorHandlerFactory("There was an error marking source as Entered")
            );
        };

        // "constructor" for controller goes here

        $(window).bind('beforeunload', function() {
            if ($scope.warnWhenLeavingPage && angular.toJson($scope.originalEntryViewModel) !== angular.toJson($scope.entry)) {
                /*
                console.log("originalEntryViewModel=");
                console.log(angular.toJson($scope.originalEntryViewModel));
                console.log("current entry=");
                console.log(angular.toJson($scope.entry));
                */
                return "You have unsaved changes";
            }
            return;
        });

        SDBM.disableFormSubmissionOnEnter('#entry-form');

        $http.get("/entries/types/").then(
            function(result) {

                $scope.optionsTransactionType = result.data.transaction_type;
                $scope.optionsAuthorRole = result.data.author_role;
                $scope.optionsArtistRole = result.data.artist_role;
                $scope.optionsSold = result.data.sold;
                $scope.optionsCurrency = result.data.currency;
                $scope.optionsAltSize = result.data.alt_size;
                $scope.optionsAcquisitionMethod = result.data.acquisition_method;

                // material needs to be an array of objects that autocomplete can use
                $scope.optionsMaterial = $.map(result.data.material, function (material) {
                    return {
                        label: material[0],
                        value: material[1]
                    };
                });

                if($("#entry_id").val()) {
                    var entryId = $("#entry_id").val();
                    $scope.pageTitle = "Edit entry SDBM_" + entryId;
                    $scope.edit = true;
                    $scope.entry = Entry.get(
                        {id: entryId},
                        $scope.populateEntryViewModel,
                        sdbmutil.promiseErrorHandlerFactory("Error loading entry data for this page")
                    );
                } else {
                    $scope.pageTitle = "Add an Entry";

                    $scope.entry = new Entry();

                    var sourceId = $("#source_id").val();
                    Source.get(
                        {id: sourceId},
                        function(source) {
                            $scope.entry.source = source;
                            $scope.populateEntryViewModel($scope.entry);
                        },
                        sdbmutil.promiseErrorHandlerFactory("Error loading Source data for this page")
                    );
                }
            },
            // error callback
            sdbmutil.promiseErrorHandlerFactory("Error initializing dropdown options on this page, can't proceed.")
        );

    });

    /*
     * NOTES on different autocomplete widgets:
     *
     * We need a widget that allows autocompletion of entity names
     * (prov agents, authors, scribes, etc), and can reject invalid
     * values. Finding one that works well and is compatible with
     * other things we use (namely Angular) is harder than it might
     * first seem. I've experimented with the following:
     *
     * jquery UI's autocomplete - this works best; we use this to
     * manage the INPUTs ourselves, and manually update the Angular
     * models. This is low-tech and violates Angular's philosophy of
     * not touching the DOM, but 1) this isn't a problem since nothing
     * else on the page is updating the Angular models, so we don't
     * need to be concerned about keeping the INPUT in sync; 2) it
     * works and works well.
     *
     * UI Bootstrap (which uses Angular)'s typeahead - I couldn't get
     * this to disallow invalid input. By design, setting
     * typeahead-editable=false still lets you enter junk: see
     * <http://stackoverflow.com/questions/18128793/set-input-invalid-when-typeahead-editable-is-false>.
     * Writing various event handlers to detect invalid input is
     * tricky, because of a chicken-and-egg problem of which thing
     * gets modified first: the Angular models or the view
     * model. Here's what the HTML would look like:
     *
     * <input class="form-control" ng-model="source.selling_agent.agent" typeahead-wait-ms="250" typeahead-editable="false" typeahead-min-length="2" typeahead="choice as choice.display_value for choice in typeAheadService.getOptions($viewValue, '/agents/search.json')" sdbm-show-create-modal-on-model-change="CreateAgentModalCtrl" />
     *
     * xeditable (uses UI Bootstrap) - this widget is clunky. clicking
     * a hyperlink to turn it into a INPUT control is an extra step,
     * it doesn't look that good visually, and it conflicts with
     * Angular's validation capabilities.
     */

    /**
     * Angular directive that decorates an element with jQuery UI's
     * autocomplete. This is designed to support showing a modal for
     * creation of new entities not found in autocomplete. Attributes:
     *
     * sdbm-autocomplete = (required) should specify either a URL or name of a
     * scope variable containing an array of autocomplete candidates.
     *
     * sdbm-autocomplete-model = (required) angular model to update with
     * autocomplete selection.
     *
     * sdbm-autocomplete-params = (optional) an object containing
     * additional URL parameters to merge into the AJAX request. For name
     * lookups, this is usually an object containing key "type", used
     * for both search and modal popup.
     *
     * sdbm-autocomplete-assign-value-attr = (optional) flag for
     * whether 'value' attribute of selection should be assigned to
     * angular model. defaults to 'false' (assigns the ui.item
     * instead).
     *
     * sdbm-autocomplete-min-length = (optional) minimum length of str
     * to trigger autocomplete dropdown (defaults to 2).
     *
     * sdbm-autocomplete-modal-controller = (optional) controller to
     * use for displaying modal for entity creation.
     *
     * sdbm-autocomplete-modal-template = (optional) template use for
     * displaying modal for entity creation.
     */
    sdbmApp.directive("sdbmAutocomplete", function ($http, $parse, $timeout, $modal) {
        return function (scope, element, attrs) {
            var modelName = attrs.sdbmAutocompleteModel;
            var assignValueAttr = attrs.sdbmAutocompleteAssignValueAttr;
            var minLength = parseInt(attrs.sdbmAutocompleteMinLength || "2");
            var controller = attrs.sdbmAutocompleteModalController;
            var template = attrs.sdbmAutocompleteModalTemplate;
            var sourceStr = attrs.sdbmAutocomplete;
            var params = JSON.parse(attrs.sdbmAutocompleteParams || "{}");
            var options;
            var invalidInput = false;

            // WARNING: there be dragons here. Much of this code is
            // here to keep data in sync between INPUT and Angular
            // models and to limit text to valid selections only.

            if(!modelName) {
                alert("Error on page: sdbm-autocomplete directive is missing attributes");
            }

            /**
             * value argument is the ui.item or object representing a
             * database entity
             */
            var assignToModel = function(value) {
                var model = $parse(modelName);
                var valueToAssign = value;
                if(value && assignValueAttr === 'true') {
                    valueToAssign = value.value;
                }
                model.assign(scope, valueToAssign);
            };

            var eraseModel = function() {
              var model = $parse(modelName);
              model.assign(scope, null);
            }

            var refocus = function(badValue) {
                // TODO: calling focus() directly here doesn't work in
                // Firefox (but works in Chrome). Using setTimeout()
                // is susceptible to race conditions with the
                // browser's default handling of tab key, but in
                // practice, it works.  Need to find a better way.
                setTimeout(function() {
                    $(element).focus();
                }, 100);

                console.log(element, badValue, $(element), $(element).tooltip);
                $(element)
                    .tooltip("option", "content", badValue + " isn't valid input, please change it or select a value from the suggestion box")
                    .tooltip("option", "disabled", false)
                    .tooltip("open");
                setTimeout(function() {
                    $(element)
                        .tooltip("option", "content", "")
                        .tooltip("option", "disabled", true)
                        .tooltip("close");
                }, 3000);
            };

            // determine if source is a URL or a scope var

            var autocompleteSource;
            var sourceIsUrl = sourceStr.substr(0, 1) === "/";
            if(!sourceIsUrl) {
                autocompleteSource = $parse(sourceStr)(scope);
            } else {
                autocompleteSource = function (request, response_callback) {
                    var url  = sourceStr;
                    var searchTerm = request.term;
                    $http.get(url, {
                        params: $.extend({ autocomplete: 1, name: searchTerm, limit: 25 }, params)
                    }).then(function (response) {
                        // transform data from API call into format expected by autocomplete
                        var exactMatch = false;
                        options = response.data.results;
                        options.forEach(function(option) {
                            option.label = option.name;
                            option.value = option.id;

                            if(!exactMatch) {
                                exactMatch = searchTerm === option.label;
                            }
                        });
                        if (!exactMatch && controller) {
                            options.unshift({
                                label: "\u00BB Create '" + searchTerm + "'",
                                value: 'CREATE',
                                id: 'CREATE'
                            });
                        }
                        // sort options, prioritizing ones that match the type
                        options.sort( function (a, b) {
                          if (!a[params.type] && b[params.type] || a.id == 'CREATE')
                            return 1;
                          else
                            return -1;
                        });
                        response_callback(options);
                    });
                };
            }

            // we need this watch to populate the input, which happens
            // AFTER all the directives finish.
            scope.$watch(modelName, function(newValue, oldValue) {
                // initial value of undefined triggers an event to
                // watch() so we ignore it
                if(newValue) {
                    if(typeof newValue === 'object') {
                        $(element).val(newValue.label || newValue.name);
                    } else {
                        $(element).val(newValue);
                    }
                }
            });

            $(element).tooltip({
                items: "input",
                tooltipClass: "ui-state-highlight"
            });

            $(element).keypress(function(event) {
                // prevent ENTER from submitting the form; just blur
                // the input instead to trigger autocomplete
                if (event.which === 13) {
                    event.preventDefault();
                    $(element).blur();
                } else if (event.which !== 0 && !event.ctrlKey && !event.metaKey && !event.altKey) {
                    // if user typed an actual char, reset invalid flag
                    invalidInput = false;
                }
            });

            // if user tries to leave input, make sure value is valid
            $(element).focusout(function(event) {
                if(invalidInput) {
                    refocus($(element).val());
                }
            });

            $(element).autocomplete({
                source: autocompleteSource,
                minLength: minLength,
                focus: function(event, ui) {
                    // disable default behavior of populating input on focus
                    event.preventDefault();
                    // noop
                },
                change: function(event, ui) {
                    var inputValue = $(element).val() || "";
                    // if no actual selection was made
                    if(ui.item === null) {
                        if(inputValue.trim().length > 0) {
                            var match = false;
                            // did user type in something that actually
                            // matches an option? if so, select it.
                            if(options) {
                                options.forEach(function (option) {
                                    if(inputValue.toLowerCase() === option.label.toLowerCase()) {
                                        assignToModel(option);
                                        scope.$apply();
                                        match = true;
                                    }
                                });
                            }
                            if(!match) {
                                // force user to fix the value
                                if(inputValue) {
                                    refocus(inputValue);
                                    invalidInput = true;
                                }
                                assignToModel(null);
                                scope.$apply();
                            }
                        } else {
                            // whitespace or empty field - the user tried to erase the name entered, so let them
                            $(element).val("");
                            eraseModel();
//                            assignToModel(null);
                            scope.$apply();
                        }
                    } else {
                        invalidInput = false;
                    }
                },
                select: function(event, ui) {
                    // prevent autocomplete's default behavior of using value instead of label
                    event.preventDefault();

                    if(ui.item.value === 'CREATE') {
                        $timeout(function() {

                            var newNameValue = ui.item.label.substring(ui.item.label.indexOf("'") + 1, ui.item.label.lastIndexOf("'"));

                            var modalInstance = $modal.open({
                                templateUrl: template,
                                controller: controller,
                                resolve: {
                                    modalParams: function() {
                                        return {
                                            "name": newNameValue,
                                            "type": params.type
                                        };
                                    }
                                },
                                size: 'lg'
                            });

                            /* callback for handling result */
                            modalInstance.result.then(function (agent) {
                                assignToModel(agent);
                            }, function () {
                                $(element).val("");
                                assignToModel(null);
                            });

                        });
                    } else {
                        $(element).val(ui.item.label);
                        assignToModel(ui.item);
                        scope.$apply();
                    }
                }
            }).data("ui-autocomplete")._renderItem = function( ul, item ) {
                // if there's an 'unreviewed' attribute set to false,
                // tack on additional text indicating that.
                var text = item.label;
                if(item.reviewed === false) {
                    text += " (unreviewed)";
                }
                return $("<li>").text(text).appendTo(ul);
            };
        };
    });

    // attribute value should be the two IDs, comma-separated, of the
    // elements to populate with normalized dates.

    sdbmApp.directive("sdbmApproximateDateString", function ($http) {
        return function (scope, element, attrs) {
            var targets = attrs.sdbmApproximateDateString;
            var url = attrs.sdbmApproximateDateStringUrl;

            var targetIds = targets.split(",").map(function (s) { return s.trim(); });
            var startTargetId = targetIds[0];
            var endTargetId = targetIds[1];


        // we may not care if the DATE fields are already populated, we still want to correct them
        // modify function below to revert back
            var areTargetsPopulated = function() {
              return false;
//            return $("#" + startTargetId).val() || $("#" + endTargetId).val();
            };

            $(element).change(function(event) {
                var observedDate = $(element).val();
                if(observedDate && !areTargetsPopulated()) {
                    $http.get(url , {
                        params: {
                            date: observedDate
                        }
                    }).then(function (response) {
                        if(!areTargetsPopulated() && response.data.date) {
                            // we MUST manually trigger 'change' events here
                            // otherwise Angular bindings won't pick up these values
                            $("#" + startTargetId).val(response.data.date.date_start);
                            $("#" + startTargetId).change();
                            $("#" + endTargetId).val(response.data.date.date_end);
                            $("#" + endTargetId).change();
                            $("#" + startTargetId).select();
                        }
                    }, function(response) {
                        alert("An error occurred trying to normalize date");
                    });
                }
            });
        };
    });

    sdbmApp.directive("sdbmCatLotNoCheck", function($http) {
        return function (scope, element, attrs) {
            $(element).focusout(function(event) {
                $("#cat_lot_no_warning").text("");
                var cat_lot_no = $(element).val();
                if(cat_lot_no) {
                    $.ajax("/entries.json", {
                        data: {
                            search_field: "advanced",
                            op: "AND",
                            //approved: "*",
                            source: "SDBM_SOURCE_" + scope.entry.source.id,
                            catalog_or_lot_number: cat_lot_no
                        },
                        success: function(data, textStatus, jqXHR) {
                            var results = data.data || [];
                            if(results.length > 0) {
                                var msg = "Warning! An entry with that catalog number already exists.";
                                var editMode = !!scope.entry.id;
                                if (editMode) {
                                    msg = "Warning! Another entry with that catalog number already exists.";
                                    results.forEach(function (result) {
                                        if(result.id == scope.entry.id) {
                                            // search returned the entry we're editing, so don't warn
                                            msg = null;
                                        }
                                    });
                                }
                                if(msg) {
                                    $("#cat_lot_no_warning").text(msg);
                                }
                            }
                        }
                    });
                };
            });
        };
    });
    
    sdbmApp.directive("sdbmCertaintyFlags", function($modal, $parse) {
        return function (scope, element, attrs) {
            var modelName = attrs.sdbmCertaintyFlags;

            $(element).css("color", "black");

            $(element).tooltip({
                items: "div",
                tooltipClass: "ui-state-highlight",
                content: "Click this icon to cycle through these options:<br/><br/>check mark = source contains this information.<br/><br/>question mark = source expresses doubt<br/><br/>asterisk = source does not explicitly provide this data but you infer it from the source description"
            });

            // use a single handler for model changes, so we can always
            // account for both flags when cycling
            var cycle = function() {
                var uncertain_in_source = $parse(modelName + ".uncertain_in_source")(scope);
                var supplied_by_data_entry = $parse(modelName + ".supplied_by_data_entry")(scope);
                if(uncertain_in_source) {
                    $(element).find("span").removeClass().addClass("glyphicon glyphicon-question-sign");
                } else if(supplied_by_data_entry) {
                    $(element).find("span").removeClass().addClass("glyphicon glyphicon-asterisk");
                } else {
                    $(element).find("span").removeClass().addClass("glyphicon glyphicon-ok");
                }
            };

            scope.$watch(modelName + ".uncertain_in_source", cycle);
            scope.$watch(modelName + ".supplied_by_data_entry", cycle);

            $(element).click(function() {
                var uncertain_in_source = $parse(modelName + ".uncertain_in_source")(scope);
                var supplied_by_data_entry = $parse(modelName + ".supplied_by_data_entry")(scope);

                // cycle through flags
                if(uncertain_in_source) {
                    $parse(modelName + ".uncertain_in_source").assign(scope, false);
                    $parse(modelName + ".supplied_by_data_entry").assign(scope, true);
                } else if (supplied_by_data_entry) {
                    $parse(modelName + ".uncertain_in_source").assign(scope, false);
                    $parse(modelName + ".supplied_by_data_entry").assign(scope, false);
                } else {
                    $parse(modelName + ".uncertain_in_source").assign(scope, true);
                }
                scope.$apply();
            });
        };
    });

    /* To be used on elements that should get a tooltip when clicked */
    sdbmApp.directive("sdbmTooltip", function () {
        return function (scope, element, attrs) {
            var templateName = attrs.sdbmTooltip;
            element.addClass('sdbmss-tooltip-label');
            SDBM.registerTooltip(element, templateName);
        };
    });

    sdbmApp.controller('SourceCtrl', function ($scope, $http, $modal, sdbmutil, Source) {

        // store in scope, otherwise angular template code can't
        // get a reference to this
        // 
        $scope.sdbmutil = sdbmutil;

        $scope.currentlySaving = false;

        $scope.agent_role_types = ['institution', 'buyer', 'seller_or_holder', 'selling_agent'];

        $scope.associations = [
            {
                field: 'source_agents',
                properties: ['agent_id'],
                foreignKeyObjects: ['agent']
            }
        ];

        $scope.pageTitle = "";

        $scope.source = undefined;

        $scope.source_agents = [];

        $scope.debug = function () {
            console.log($scope.source);
        };

        $scope.getPageTitle = function() {
            if ($scope.edit) {
                return "Edit SDBM_SOURCE_" + $scope.source.id;
            }
            var sourceTypeForTitle = "Source";
            if($scope.source && $scope.source.source_type) {
                $scope.optionsSourceType.forEach(function (item) {
                    if(item.name === $scope.source.source_type.name) {
                        sourceTypeForTitle = item.display_name;
                    }
                });
            }
            return "Create a New " + sourceTypeForTitle;
        };

        $scope.showFields = function() {
            if($scope.source && $scope.source.source_type) {
                return true;
            }
            return false;
        };

        $scope.populateSourceViewModel = function (source) {
            // set source.source_type to object from
            // optionsSourceType, so that angular's preselection
            // works.
            source.source_type = $.grep($scope.optionsSourceType, function(item) {
                return item.id === source.source_type_id;
            })[0];

            source.date = SDBM.dateDashes(source.date);
            source.date_accessed = SDBM.dateDashes(source.date_accessed);

            $scope.agent_role_types.forEach(function (role) {
                source.source_agents.forEach(function (source_agent) {
                    if (source_agent.role === role) {
                        source[role] = source_agent;
                    }
                });
            });
            $scope.source_agents = [];
            //console.log(source);
        };

        $scope.postSourceSave = function(source) {
            $scope.source = source;
            var modalInstance = $modal.open({
                templateUrl: 'postSourceSave.html',
                backdrop: 'static',
                size: 'lg',
                scope: $scope
            });
            modalInstance.result.then(function () {
                // noop
            }, function() {
                // runs when promise is rejected (modal is dismissed)
                sdbmutil.redirectToSourceEditPage(source.id);
            });
        };

        $scope.similarSourcesModal = null;

        $scope.showSimilarSources = function() {
            $scope.similarSourcesModal = $modal.open({
                templateUrl: 'similarSources.html',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                scope: $scope
            });
        };

        $scope.confirmCreate = function() {
            $scope.similarSourcesModal.close();
            $scope.createSource($scope.sourceToSave);
        };

        $scope.cancelCreate = function () {
            $scope.similarSourcesModal.close();
        }

        /* source argument should be an Angular resource object */
        $scope.createSource = function(source) {
            source.$save(
                $scope.postSourceSave,
                sdbmutil.promiseErrorHandlerFactory("There was an error saving this record")
            ).finally(function() {
                $scope.currentlySaving = false;
            });
        };
        
        $scope.sourceToSave = null;

        $scope.getSimilarSources = function (source, callback) {
          $.ajax("/sources/conflict.json", {
              data: {
                  date: source.date,
                  title: source.title
              },
              success: function(data, textStatus, jqXHR) {
                  if (callback) callback(data);
              },
              error: function() {
                  alert("Error confirming that this new source doesn't already exist");
              },
              complete: function() {
                  $scope.currentlySaving = false;
              }
          });
        }

        $scope.showSimilar = function (data) {
          $scope.similarSources = data.similar;
        }

        $scope.save = function () {
            $scope.currentlySaving = true;

            $scope.sourceToSave = new Source(angular.copy($scope.source));
            var sourceToSave = $scope.sourceToSave;
            
            var sourceType = sourceToSave.source_type;

            sourceToSave.source_type_id = sourceToSave.source_type.id;
            delete sourceToSave.source_type;

            if(sourceToSave.date) {
                sourceToSave.date = sourceToSave.date.replace(/-/g, "");
            }

            if(sourceToSave.date_accessed) {
                sourceToSave.date_accessed = sourceToSave.date_accessed.replace(/-/g, "");
            }

            sourceToSave.source_agents = [];
            $scope.agent_role_types.forEach(function (role) {
                if (sourceToSave[role]) {
                    sourceToSave[role].role = role;
                    sourceToSave.source_agents.push(sourceToSave[role]);
                    delete sourceToSave[role];
                }
            });

            // filter out irrelevant fields and source_agent records
            // with invalid roles; these can be populated because user
            // started filling out the form but then changed the
            // source_type, causing stale data to be leftover in the
            // data structure
            sourceType.invalid_source_fields.forEach(function (field) {
                delete sourceToSave[field];
            });
            sourceToSave.source_agents = sourceToSave.source_agents.filter(function (source_agent) {
                var valid = false;
                sourceType.valid_roles_for_source_agents.forEach(function (role) {
                    if(source_agent.role === role) {
                        valid = true;
                    }
                });
                return valid;
            });

            sdbmutil.replaceEntityObjectsWithIds(sourceToSave.source_agents, "agent");

            // strip out blank objects
            $scope.associations.forEach(function (assoc) {
                sdbmutil.filterBlankRecords(sourceToSave, assoc);
                if(sourceToSave[assoc.field].length === 0) {
                    delete sourceToSave[assoc.field];
                }
            });

            // append '_attributes' for Rails' accept_nested_attributes
            sourceToSave.source_agents_attributes = sourceToSave.source_agents;
            delete sourceToSave.source_agents;

            if(sourceToSave.id) {
                sourceToSave.$update(
                    $scope.postSourceSave,
                    sdbmutil.promiseErrorHandlerFactory("There was an error saving this record")
                ).finally(function() {
                    $scope.currentlySaving = false;
                });
            } else {
                // check if similar sources exist before saving new one
                $scope.getSimilarSources(sourceToSave, function (data) {
                  if(data.similar && data.similar.length > 0) {
                      $scope.similarSources = data.similar;
                      $scope.showSimilarSources();
                  } else {
                      $scope.createSource($scope.sourceToSave);
                  }
                });
            }
        };

        // "constructor" for controller goes here

        SDBM.disableFormSubmissionOnEnter('#source-form');

        $http.get("/sources/types.json").then(
            function(result) {

                $scope.optionsSourceType = result.data.source_type;
                $scope.optionsMedium = result.data.medium;

                if($("#source_id").val() || $scope.sourceId) {
                    var sourceId = $("#source_id").val() || $scope.sourceId;
                    $scope.edit = true;
                    $scope.source = Source.get(
                        {id: sourceId},
                        $scope.populateSourceViewModel,
                        sdbmutil.promiseErrorHandlerFactory("Error loading entry data for this page")
                    );
                } else {
                    $scope.source = new Source({ source_type: "" });
                }
            },
            // error callback
            sdbmutil.promiseErrorHandlerFactory("Error initializing dropdown options on this page, can't proceed.")
        );

    });

    // Base generic NG controller fn for all modal popups that allow
    // you to search for a database object and create one. Specialized
    // controllers should call this fn and modify/supply anything in
    // $scope it needs to.
    var baseCreateEntityModalCtrl = function ($scope, $http, $modalInstance, sdbmutil) {

        $scope.readyToCreate = true;
        $scope.saveError = null;

        $scope.entity = $scope.entityFactory();

        // if calling code provides entity_attributes() in scope,
        // use it to do any modifications of the entity
        if($scope.entity_attributes) {
            $scope.entity_attributes($scope.entity);
        }

        $scope.save = function () {
            $scope.entity.$save(
                function (entity) {
                    $modalInstance.close(entity);
                },
                function(response) {
                    $scope.saveError = sdbmutil.parseRailsErrors(response.data.errors).join("; ") || "Unknown Error";
                }
            );
        };

        $scope.cancel = function () {
            $modalInstance.dismiss('cancel');
        };
    };

    sdbmApp.controller('CreateNameModalCtrl', function ($scope, $http, $modalInstance, sdbmutil, modalParams, Name) {
        $scope.entityFactory = function() { return new Name(); };

        $scope.entity_attributes = function(entity) {
            entity.name = modalParams.name;
            entity[modalParams.type] = true;
        };

        baseCreateEntityModalCtrl($scope, $http, $modalInstance, sdbmutil);

        $scope.entityName = "name";
        $scope.hasViafId = true;

        $scope.suggestions = [];

        $scope.loading = false;
        $scope.message = "";
        $scope.showSuggestions = false;

        $scope.findSuggestions = function(name) {
            $scope.message = "";
            $scope.showSuggestions = true;
            $scope.loading = true;
            $http.get("/names/suggest.json", {
                params: {
                    name: name
                }
            }).then(function (response) {
                if(response.data.already_exists) {
                    $scope.showSuggestions = false;
                    $scope.message = "The name \"" + $scope.entity.name + "\" already exists in this database, you can't create it here.";
                }
                $scope.suggestions = response.data.results;
            }, function() {
                $scope.message = "Error loading suggestions.";
            }).finally(function () {
                $scope.loading = false;
            });
        };

        $scope.useSuggestion = function(suggestion) {
            $scope.entity.name = suggestion.name;
            $scope.entity.viaf_id = suggestion.viaf_id;
        };
    });

    sdbmApp.controller('CreateLanguageModalCtrl', function ($scope, $http, $modalInstance, sdbmutil, modalParams, Language) {
        $scope.entityFactory = function() { return new Language(); };

        $scope.entity_attributes = function(entity) {
            entity.name = modalParams.name;
        };

        baseCreateEntityModalCtrl($scope, $http, $modalInstance, sdbmutil);

        $scope.entityName = "language";
    });

    sdbmApp.controller('CreatePlaceModalCtrl', function ($scope, $http, $modalInstance, sdbmutil, modalParams, Place) {
        $scope.entityFactory = function() { return new Place(); };

        $scope.entity_attributes = function(entity) {
            entity.name = modalParams.name;
        };

        baseCreateEntityModalCtrl($scope, $http, $modalInstance, sdbmutil);

        $scope.entityName = "place";
    });

    sdbmApp.controller('CreateNameCtrl', function ($scope, $http) {
      $scope.entityFactory = function() { return new Name(); };

      $scope.entity_attributes = function(entity) {
          entity.name = modalParams.name;
          entity[modalParams.type] = true;
      };

      $scope.findSuggestions = function(name) {
        $scope.message = "";
        $scope.showSuggestions = true;
        $scope.loading = true;
        $http.get("/names/suggest.json", {
            params: {
                name: name,
                check_exists: false
            }
        }).then(function (response) {
            $scope.suggestions = response.data.results;
        }, function() {
            $scope.message = "Error loading suggestions.";
        }).finally(function () {
            $scope.loading = false;
        });
    };

    $scope.useSuggestion = function(suggestion) {
        $scope.entity.name = suggestion.name;
        $scope.entity.viaf_id = suggestion.viaf_id;
    };
  });

  sdbmApp.controller('ManageBookmarks', function ($scope, $sce) {

    BOOKMARK_SCOPE = $scope;

    $scope.removetag = function (bookmark, tag) {
      $.get('/bookmarks/' + bookmark.id + '/removetag', {tag: tag}).done( function (e) {
        bookmark.tags = e.tags;
          $scope.renew();
      });
    }
    $scope.addtag = function (bookmark, tag) {
      $.get('/bookmarks/' + bookmark.id + '/addtag', {tag: tag}).done( function (e) {
        bookmark.tags = e.tags;
        bookmark.newtag = "";
        $scope.renew();
      });
    }
    $scope.removeBookmark = function (name, bookmark) {
      var i = $scope.all_bookmarks[name].indexOf(bookmark);
      if (i >= 0) {
        $.ajax({url: '/bookmarks/' + bookmark.id, method: 'delete'}).done( function (e) {
          console.log('done', e);
          $scope.all_bookmarks[name].splice(i, 1);
          $scope.renew();
        }).error( function (e) {
          console.log('error', e);
        });
      }
    }
    $scope.searchTag = function (tag) {
      // fix me: this should check the url, but also where the controller is (load details in main page, but not toolbar)
      $.get('/bookmarks/reload.json', {tag: tag, details: (window.location.pathname == "/bookmarks")}).done( function (e) {
        $scope.all_bookmarks = e;
        $scope.renew();
      }).error( function (e) {
        console.log('error.', e);
      });
    }
    $scope.addBookmark = function (id, type) {
      // check if already in bookmarks
      var b = $scope.findBookmark(type, id);
      if (b) {
        $scope.removeBookmark(type, b);
        return;
      }
      $.ajax({url: '/bookmarks/new', data: {document_id: id, document_type: type}}).done( function (e) {
        if (!e.error) {
          $scope.all_bookmarks[type].push(e);
          $scope.renew();
        } else {
          console.log(e.error);
        }
      }).error( function (e) {
        console.log("error: ", e);
      });
      return false;
    }
    $scope.renew = function () {
      $scope.$digest();
      $('.bookmark-link').css({color: "inherit"});
      for (var i = 0; i < $scope.tabs.length; i++) {
        var type = $scope.tabs[i];
        for (var j = 0; j < $scope.all_bookmarks[type].length; j++) {
          var link = $scope.all_bookmarks[type][j].link;
          $('.bookmark-link[in_bookmarks="' + link + '"]').css({color: "gold"});
        }
      }
    }
    // this is one ugly function
    $scope.actionButton = function (bookmark) {
      var page_info = window.location.pathname.split('/').splice(1,10);
      var bookmark_info = bookmark.link.split('/').splice(1,10);
      if (page_info[0] == 'linkingtool') {
        if (bookmark.document_type == "Entry") {
          return $sce.trustAsHtml('<a data-entry-id="' + bookmark.document_id + '" class="add-entry-link btn btn-info btn-xs">Add to queue</a>');
        } else if (bookmark.document_type == "Manuscript") {
          return '<a href="/linkingtool/manuscript/' + bookmark.document_id + '" class="btn btn-info btn-xs">Use this MS</a>';
        }
      } else if (page_info[0] != bookmark_info[0]) { // different record type
        return "";
      } else if (page_info[1] == bookmark_info[1]) { // same record already
        return "";
      } else if (page_info[2] == "merge" && (bookmark.document_type == "Name" || bookmark.document_type == "Source")) {
        return '<a href="' + window.location.pathname + '?target_id=' + bookmark.document_id + '" class="btn btn-xs btn-info">Merge</a>'
      }
    }
    $scope.tabs = ["Entry", "Manuscript", "Name", "Source"];
    $scope.searchTag("");

    $scope.findBookmark = function(type, id) {
      if (!$scope.all_bookmarks[type]) return false;
      for (var i = 0; i < $scope.all_bookmarks[type].length; i++) {
        if ($scope.all_bookmarks[type][i].document_id == id) {
          return $scope.all_bookmarks[type][i];
        }
      }
      return false;
    }

    $scope.exportBookmarks = function (type, link) {
      var plural = link.split('/')[1];
      if (type != "Entry") plural += "/search";
      var url = "/" + plural + ".csv?op=OR&search_field=advanced&per_page=5000";
      for (var i = 0; i < $scope.all_bookmarks[type].length; i++) {
        if (type == "Entry")
          url += "&entry_id[]=" + $scope.all_bookmarks[type][i].document_id;
        else
          url += "&id[]=" + $scope.all_bookmarks[type][i].document_id;  
      }
      window.location = url;
    }

  });

}());

// this works!  maybe not a good idea?
function addBookmark(id, type) {
  BOOKMARK_SCOPE.addBookmark(id, type);
}

function renewBookmarks() {
  BOOKMARK_SCOPE.renew();
}
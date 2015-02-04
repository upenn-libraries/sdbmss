/**
 * sdbmApp module for angular.js
 *
 * This contains code for public-facing pages.
 */

/* Hints for eslint: */
/* global alert, angular, console, window, $ */

(function () {

    "use strict";

    var sdbmApp = angular.module("sdbmApp", ["ngCookies", "ngResource", "ui.bootstrap"]);

    sdbmApp.run(function ($http, $cookies) {
        // For Rails CSRF
        var csrf_token = $('meta[name="csrf-token"]').attr('content');
        if(csrf_token) {
            $http.defaults.headers.put['X-CSRF-Token'] = csrf_token;
            $http.defaults.headers.post['X-CSRF-Token'] = csrf_token;
        } else {
            alert("Error: no meta tag found with csrf-token. Ajax calls won't work.");
        }
    });

    /* This is a service that does the AJAX call for typeaheads */
    sdbmApp.factory('typeAheadService', function($http) {
        /* return an object */
        return {
            getOptions: function (val, url) {
                return $http.get(url, {
                    params: {
                        term: val
                    }
                }).then(function (response) {
                    var options = response.data;
                    options.unshift({'id': 'CREATE', 'display_value': "&raquo; Create '" + val + "'"});
                    return response.data;
                });
            }
        };
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

    sdbmApp.factory('Agent', ['$resource',
                              function($resource){
                                  return $resource('/agents/:id.json', { id: '@id' }, {
                                      query: {
                                          method: 'GET',
                                          isArray: true
                                      },
                                      update: {
                                          method:'PUT'
                                      }
                                  });
                              }]);

    sdbmApp.factory('Artist', ['$resource',
                              function($resource){
                                  return $resource('/artists/:id.json', { id: '@id' }, {
                                      query: {
                                          method: 'GET',
                                          isArray: true
                                      },
                                      update: {
                                          method:'PUT'
                                      }
                                  });
                              }]);

    sdbmApp.factory('Author', ['$resource',
                              function($resource){
                                  return $resource('/authors/:id.json', { id: '@id' }, {
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

    sdbmApp.factory('Scribe', ['$resource',
                              function($resource){
                                  return $resource('/scribes/:id.json', { id: '@id' }, {
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
                    }
                });
            },
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
            /* Returns a fn that can be used as error callback on angular promises */
            promiseErrorHandlerFactory: function(msg) {
                return function(response) {
                    alert(msg + "; Server response:" + JSON.stringify(response.data));
                };
            },
            redirectToSourceEditPage: function(source_id)  {
                window.location = "/sources/" + source_id + "/edit/";
            },
            redirectToEntryCreatePage: function(source_id)  {
                window.location = "/entries/new/?source_id=" + source_id;
            },
            redirectToEntryEditPage: function(entry_id)  {
                window.location = "/entries/" + entry_id + "/edit/";
            },
            redirectToDashboard: function() {
                window.location = "/dashboard";
            }
        };
    });

    // filter for objects that are serialized database records; outputs
    // value in the field called 'display_value', otherwise 'None'
    sdbmApp.filter('label', function() {
        return function(input) {
            var displayValue;
            if(input) {
                displayValue = input.display_value;
            }
            return displayValue || 'Select...';
        };
    });

    /* Controller for selecting a source*/
    sdbmApp.controller("SelectSourceCtrl", function ($scope, $http) {

        $scope.searchAttempted = false;
        $scope.title = "";
        $scope.date = "";
        $scope.agent = "";
        $scope.sources = [];

        $scope.findSourceCandidates = function () {
            if($scope.title.length > 2 || $scope.date.length > 2 || $scope.agent.length > 2) {
                $scope.searchAttempted = true;
                return $http.get("/sources/search.json", {
                    params: {
                        date: $scope.date,
                        title: $scope.title,
                        agent: $scope.agent
                    }
                }).then(function (response) {
                    $scope.sources = response.data;
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
    sdbmApp.controller("EntryCtrl", function ($scope, $http, $cookies, typeAheadService, Entry, Source, sdbmutil, $modal) {

        $scope.sdbmutil = sdbmutil;
        
        // this describes the (nested) associations inside an Entry;
        // we use it, when saving, to identify and remove 'blank' records
        $scope.entryAssociations = [
            {
                field: 'entry_titles',
                properties: ['title', 'common_title']
            },
            {
                field: 'entry_authors',
                properties: ['observed_name'],
                foreignKeyObjects: ['author']
            },
            {
                field: 'entry_dates',
                properties: ['date', 'circa']
            },
            {
                field: 'entry_artists',
                foreignKeyObjects: ['artist']
            },
            {
                field: 'entry_scribes',
                foreignKeyObjects: ['scribe']
            },
            {
                field: 'entry_languages',
                foreignKeyObjects: ['language']
            },
            {
                field: 'entry_materials',
                properties: ['material']
            },
            {
                field: 'entry_places',
                foreignKeyObjects: ['place']
            },
            {
                field: 'entry_uses',
                properties: ['use']
            },
            {
                field: 'events',
                skipChecking: function(object) {
                    // skip 'primary' events (always keep them)
                    return object.primary ? true : false;
                },
                properties: ['acquire_date', 'end_date', 'comment'],
                entryAssociations: [
                    {
                        field: 'event_agents',
                        properties: ['observed_name'],
                        foreignKeyObjects: ['agent']
                    }
                ]
            }
        ];

        $scope.pageTitle = "";

        $scope.typeAheadService = typeAheadService;

        $scope.badData = [];

        $scope.optionsSold = undefined;
        $scope.optionsCurrency = undefined;
        $scope.optionsCirca = undefined;
        $scope.optionsMaterial = undefined;
        $scope.optionsAltSize = undefined;

        $scope.entry = undefined;

        $scope.edit = false;

        $scope.currentlySaving = false;

        $scope.addRecord = function (anArray) {
            anArray.push({});
        };

        $scope.removeRecord = function (anArray, record) {
            var i;
            for (i = 0; i < anArray.length; i++) {
                if (anArray[i] === record) {
                    anArray.splice(i, 1);
                    break;
                }
            }
            // ensure that there's always one empty record
            if(anArray.length === 0) {
                anArray.push({});
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
                if(!key.startsWith("$") && typeof $scope[key] !== "function") {
                    console.log(key);
                    console.log($scope[key]);
                }
            }
        };

        /* An object is 'blank' if its keys don't have any meaningful
         * values. We use this to filter out records that user has
         * added on UI but not populated.
         */
        $scope.isBlankObject = function(obj) {
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
        $scope.isBlankThing = function(obj) {
            var blank = false;
            if(obj === undefined || obj === null || (typeof(obj) === 'string' && obj.length === 0) || (Array.isArray(obj) && obj.length === 0)) {
                blank = true;
            } else {
                blank = $scope.isBlankObject(obj);
            }
            return blank;
        };

        $scope.confirmClearChanges = function() {
            // TODO
            alert("Not yet implemented");
        };

        // populates angular view models from the Entry object
        // retrieved via API
        $scope.populateEntryViewModel = function(entry) {

            console.log("entry from API retrieval");
            console.log(entry);

            // make blank initial rows, as needed, for user to fill out
            $scope.entryAssociations.concat({ field: 'entry_provenance' }).forEach(function (assoc) {
                var fieldname = assoc.field;
                var objArray = entry[fieldname];
                if(!objArray || objArray.length === 0) {
                    entry[fieldname] = [ {} ];
                }
            });

            // Transform EventAgent records into buyer, seller,
            // seller_agent fields on the Event, so that UI can bind
            // to that data easily
            for(var idx in entry.events) {
                var event = entry.events[idx];
                for(var idx2 in event.event_agents) {
                    var event_agent = event.event_agents[idx2];
                    event[event_agent.role] = event_agent;
                }
                delete event.event_agents;
            }

            entry.provenance = [];

            if(entry.events && entry.events.length > 0) {
                for(var key in entry.events) {
                    var event = entry.events[key];
                    if(event.primary) {
                        entry.sale = event;
                    } else {
                        entry.provenance.push(event);
                    }
                }
            }
            // TODO: only add 'sale' object if appropriate for source type
            if(!entry.sale) {
                entry.sale = {
                    primary: true,
                    sold: 'Unknown'
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
            if(entry.provenance.length === 0) {
                entry.provenance.push({});
            }

            // sanity check that values we got for dropdowns are
            // actually valid options
            if(! sdbmutil.inOptionsArray(entry.sale.sold, $scope.optionsSold)) {
                $scope.badData.push("Bad sold value: '" + entry.sale.sold + "'");
            }
            if(entry.sale.currency) {
                if(! sdbmutil.inOptionsArray(entry.sale.currency, $scope.optionsCurrency)) {
                    $scope.badData.push("Bad currency value: '" + entry.sale.currency + "'");
                }
            }
            entry.entry_dates.forEach(function (entry_date) {
                if(entry_date.circa) {
                    if(! sdbmutil.inOptionsArray(entry_date.circa, $scope.optionsCirca)) {
                        $scope.badData.push("Bad circa value: '" + entry_date.circa + "'");
                    }
                }
            });
            entry.entry_materials.forEach(function (entry_material) {
                if(entry_material.material) {
                    if(! sdbmutil.inOptionsArray(entry_material.material, $scope.optionsMaterial)) {
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

        $scope.postEntrySave = function(entry) {
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

        // assoc = an object from $scope.entryAssociations that
        // describes the associations contained in
        // objectWithAssociations
        $scope.filterBlankRecords = function (objectWithAssociations, assoc) {
            var objectArrayName = assoc.field;

            // construct array of passed-in object's properties, FKs,
            // and child associations, to check for blankness
            var thingsToCheck = (assoc.properties || []).concat(assoc.foreignKeyObjects || [])
            if(assoc.entryAssociations) {
                thingsToCheck = thingsToCheck.concat(assoc.entryAssociations.map(function (item) {
                    return item.field;
                }));
            }
            
            var objectArray = objectWithAssociations[objectArrayName];
            if(objectArray === undefined) {
                alert("error: couldn't find object array for '" + objectArrayName + "'");
            }

            // filter out items in array that are either empty objects or are objects that have blank fields
            objectWithAssociations[objectArrayName] = objectArray.filter(function (childObject) {

                // do depth-first recursion, so that records lower in
                // the tree get removed first
                var childAssociations = assoc.entryAssociations || [];
                childAssociations.forEach(function (child_assoc) {
                    $scope.filterBlankRecords(childObject, child_assoc);
                });

                if(assoc.skipChecking === undefined || !assoc.skipChecking(childObject)) {
                    //console.log('checking ' + objectArrayName + ' record id = ' + childObject.id);
                    var keep = false;
                    thingsToCheck.forEach(function (propertyName) {
                        var propertyIsBlank = $scope.isBlankThing(childObject[propertyName]);
                        console.log('is property ' + propertyName + ' blank? ' + propertyIsBlank);
                        if(!propertyIsBlank) {
                            keep = true;
                        }
                    });
                    //console.log("returning keep = " +  keep);
                    return keep;
                } else {
                    //console.log("returning keep = true");
                    return true;
                }                    
            });
        };

        $scope.save = function () {
            // Transform angular's view models to JSON payload that
            // API expects: attach a bunch of things to Entry resource
            $scope.currentlySaving = true;

            var entryToSave = new Entry(angular.copy($scope.entry));

            if (entryToSave.sale.price) {
                entryToSave.sale.price = entryToSave.sale.price.replace(/[$,]/, '');
            }
            
            // collapse Sale and Provenance into Events
            entryToSave.events = [].concat(entryToSave.provenance).concat([entryToSave.sale]);
            delete entryToSave.provenance;
            delete entryToSave.sale;

            // Transform fields back into EventAgent records
            entryToSave.events.forEach(function (event, index, array) {
                event.event_agents = [];
                ["buyer", "seller_agent", "seller_or_holder"].forEach(function (role) {
                    if(event[role]) {
                        var event_agent = event[role];
                        event_agent.role = role;
                        if(event_agent.agent) {
                            event_agent.agent_id = event_agent.agent.id;
                        }
                        event.event_agents.push(event_agent);
                        delete event[role];
                    }
                });
            });

            // strip out blank objects
            $scope.entryAssociations.forEach(function (assoc) {
                $scope.filterBlankRecords(entryToSave, assoc);
            });

            // To satisfy the API: replace nested Object
            // representations of related entities with just their IDs

            entryToSave.source_id = entryToSave.source.id;

            var objectArraysWithRelatedObjects = [
                [ entryToSave.entry_authors, 'author' ],
                [ entryToSave.entry_artists, 'artist' ],
                [ entryToSave.entry_scribes, 'scribe' ],
                [ entryToSave.entry_languages, 'language' ],
                [ entryToSave.entry_places, 'place' ]
            ];

            for(var idx in entryToSave.events) {
                var event = entryToSave.events[idx];
                objectArraysWithRelatedObjects.push(
                    [ event.event_agents, 'agent' ]
                );
            }

            for(var idx in objectArraysWithRelatedObjects) {
                var record = objectArraysWithRelatedObjects[idx];
                var objectArray = record[0];
                var relatedObjectName = record[1];
                sdbmutil.replaceEntityObjectsWithIds(objectArray, relatedObjectName);
            }

            console.log("about to save this Entry: ");
            console.log(sdbmutil.objectSnapshot(entryToSave));
            
            if(entryToSave.id) {
                entryToSave.$update(
                    $scope.postEntrySave,
                    sdbmutil.promiseErrorHandlerFactory("There was an error saving this entry")
                ).finally(function() {
                    $scope.currentlySaving = false;
                });
            } else {
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

        $http.get("/entries/form_dropdown_values/").then(
            function(result) {

                $scope.optionsSold = result.data.sold;
                $scope.optionsCurrency = result.data.currency;
                $scope.optionsCurrency.unshift(["", ""]);
                $scope.optionsCirca = result.data.circa;
                $scope.optionsCirca.unshift(["", ""]);
                $scope.optionsMaterial = result.data.material;
                $scope.optionsMaterial.unshift(["", ""]);
                $scope.optionsAltSize = result.data.alt_size;
                $scope.optionsAltSize.unshift(["", ""]);

                if($("#entry_id").val()) {
                    var entryId = $("#entry_id").val();
                    $scope.pageTitle = "Edit entry SDBM_" + entryId;
                    $scope.edit = true;
                    console.log("loading " + entryId);
                    $scope.entry = Entry.get(
                        {id: entryId},
                        $scope.populateEntryViewModel,
                        sdbmutil.promiseErrorHandlerFactory("Error loading entry data for this page")
                    );
                } else {
                    console.log("initializing");
                    $scope.pageTitle = "Add an Entry - Fill out details";

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
     * <input class="form-control" ng-model="source.seller_agent.agent" typeahead-wait-ms="250" typeahead-editable="false" typeahead-min-length="2" typeahead="choice as choice.display_value for choice in typeAheadService.getOptions($viewValue, '/agents/search.json')" sdbm-show-create-modal-on-model-change="CreateAgentModalCtrl" />
     *
     * xeditable (uses UI Bootstrap) - this widget is clunky. clicking
     * a hyperlink to turn it into a INPUT control is an extra step,
     * it doesn't look that good visually, and it conflicts with
     * Angular's validation capabilities.
     */
    
    // this is an alternative to sdbm-submit-on-selection directive.
    // it uses jquery ui's autocomplete instead of the xeditable
    // widget.
    sdbmApp.directive("sdbmAutocomplete", function ($http, $parse, $timeout, $modal) {
        return function (scope, element, attrs) {
            var modelName = attrs.sdbmAutocompleteModel;
            var controller = attrs.sdbmAutocompleteModalController;

            if(! (modelName && controller)) {
                alert("Error on page: sdbm-autocomplete directive is missing attributes");
            }
            
            // we need this watch to populate the input, which happens
            // AFTER all the directives finish.
            scope.$watch(modelName, function(newValue, oldValue) {
                // initial value of undefined triggers an event to
                // watch() so we ignore it
                if(newValue) {
                    $(element).val(newValue.display_value);
                }
            });

            $(element).tooltip({
                items: "input",
                tooltipClass: "ui-state-highlight"
            });

            $(element).keypress(function(event) {
                // prevent ENTER from submitting the form; just blur
                // the input instead to trigger autocomplete
                if (event.which == 13) {
                    event.preventDefault();
                    $(element).blur();
                }
            });
            
            $(element).autocomplete({
                source: function (request, response_callback) {
                    var url  = attrs.sdbmAutocomplete;
                    var searchTerm = request.term;
                    $http.get(url, {
                        params: {
                            term: searchTerm
                        }
                    }).then(function (response) {
                        // transform data from API call into format expected by autocomplete
                        var options = response.data;
                        options.forEach(function(option) {
                            option.label = option.display_value;
                            option.value = option.id;
                        });
                        options.unshift({
                            display_value: "\u00BB Create '" + searchTerm + "'",
                            label: "\u00BB Create '" + searchTerm + "'",
                            value: 'CREATE',
                            id: 'CREATE'
                        });
                        response_callback(options);
                    });
                },
                minLength: 2,
                focus: function(event, ui) {
                    // disable default behavior of populating input on focus
                    event.preventDefault();
                    // noop
                },
                change: function(event, ui) {
                    var inputValue = $(element).val();

                    // if no actual selection was made, clear the data model
                    if(ui.item === null) {

                        // if user typed in junk, clear it out and warn
                        if(inputValue) {
                            $(element).val("");
                            
                            $(element)
                                .tooltip("option", "content", inputValue + " isn't valid input")
                                .tooltip("option", "disabled", false)
                                .tooltip("open");
                            setTimeout(function() {
                                $(element)
                                    .tooltip("option", "content", "")
                                    .tooltip("option", "disabled", true)
                                    .tooltip("close");
                            }, 3000);
                        }
                            
                        var model = $parse(modelName);
                        model.assign(scope, null);
                        scope.$apply();
                    }
                },
                select: function(event, ui) {
                    // prevent autocomplete's default behavior of using value instead of label
                    event.preventDefault();

                    if(ui.item.value === 'CREATE') {
                        $timeout(function() {

                            var template = 'createEntityWithName.html';
                            var newNameValue = ui.item.label.substring(ui.item.label.indexOf("'")+1, ui.item.label.lastIndexOf("'"));

                            var modalInstance = $modal.open({
                                templateUrl: template,
                                controller: controller,
                                resolve: {
                                    newNameValue: function() { return newNameValue; }
                                },
                                size: 'lg'
                            });

                            /* callback for handling result */
                            modalInstance.result.then(function (agent) {
                                // $parse resolves the name in the current scope, which we
                                // need to do to reference objects properly from inside
                                // ng-repeat loops
                                var model = $parse(modelName);
                                model.assign(scope, agent);
                            }, function () {
                                $(element).val("");
                                var model = $parse(modelName);
                                model.assign(scope, null);
                            });

                        });
                    } else {
                        $(element).val(ui.item.label);
                        var model = $parse(modelName);
                        model.assign(scope, ui.item);
                        scope.$apply();
                    }
                }
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
                content: "Click this icon to cycle through these options:<br/><br/>check mark = source contains this information.<br/><br/>question mark = source expresses doubt<br/><br/>asterisk = you are supplying this information, based on a strong inference"
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
                /*
                var modalInstance = $modal.open({
                    templateUrl: "inferenceFlags.html",
                    controller: 'InferenceFlagsCtrl',
                    size: 'lg',
                    resolve: {
                        objectWithFlags: function() {
                            var model = $parse(modelName);
                            return model(scope);
                        }
                    },
                });
                */
            });
        };
    });

    /* To be used on elements that should get a tooltip when clicked */
    sdbmApp.directive("sdbmTooltip", function () {
        return function (scope, element, attrs) {
            var templateName = attrs.sdbmTooltip;
            element.addClass('tooltip-label');
            $(element).qtip({
                content: {
                    text: 'Loading...',
                    ajax: {
                        url: '/static/tooltips/' + templateName + '.html',
                        type: 'GET'
                    }
                },
                show: {
                    event: 'click'
                },
                hide: {
                    event: 'unfocus'
                },
                style: {
                    width: "500px"
                }
            });
        };
    });

    sdbmApp.controller('SourceCtrl', function ($scope, $modal, typeAheadService, sdbmutil, Source) {

        $scope.sdbmutil = sdbmutil;
        
        $scope.currentlySaving = false;
        
        $scope.agent_role_types = ['institution', 'buyer', 'seller_or_holder', 'seller_agent'];
        
        $scope.pageTitle = "";

        $scope.typeAheadService = typeAheadService;

        $scope.source = undefined;

        $scope.source_agents = [];

        $scope.debug = function () {
            console.log($scope.source);
        };

        $scope.showFields = function() {
            if($scope.source.source_type) {
                return true;
            }
            return false;
        };

        $scope.populateSourceViewModel = function (source) {
            $scope.agent_role_types.forEach(function (role) {
                source.source_agents.forEach(function (source_agent) {
                    if (source_agent.role === role) {
                        source[role] = source_agent;
                    }
                });
            });
            $scope.source_agents = [];
            console.log(source);
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

        $scope.save = function () {
            var sourceToSave = new Source(angular.copy($scope.source));

            //console.log(sourceToSave);
            sourceToSave.date = sourceToSave.date.replace(/-/g, "");

            sourceToSave.source_agents = [];
            $scope.agent_role_types.forEach(function (role) {
                if (sourceToSave[role]) {
                    sourceToSave[role].role = role;
                    sourceToSave.source_agents.push(sourceToSave[role]);
                    delete sourceToSave[role];
                }
            });

            sdbmutil.replaceEntityObjectsWithIds(sourceToSave.source_agents, "agent");

            if(sourceToSave.id) {
                sourceToSave.$update(
                    $scope.postSourceSave,
                    sdbmutil.promiseErrorHandlerFactory("There was an error saving this record")
                ).finally(function() {
                    $scope.currentlySaving = false;
                });
            } else {
                sourceToSave.$save(
                    $scope.postSourceSave,
                    sdbmutil.promiseErrorHandlerFactory("There was an error saving this record")
                ).finally(function() {
                    $scope.currentlySaving = false;
                });
            }
        };

        // "constructor" for controller goes here

        if($("#source_id").val()) {
            var sourceId = $("#source_id").val();
            $scope.pageTitle = "Edit SDBM_SOURCE_" + sourceId;
            $scope.edit = true;
            $scope.source = Source.get(
                {id: sourceId},
                $scope.populateSourceViewModel,
                sdbmutil.promiseErrorHandlerFactory("Error loading entry data for this page")
            );
        } else {
            $scope.pageTitle = "Create a new Source";

            $scope.source = new Source();
        }
        
    });

    // Base generic NG controller fn for all modal popups that allow
    // you to search for a database object and create one. Specialized
    // controllers should call this fn and modify/supply anything in
    // $scope it needs to.
    var baseCreateEntityModalCtrl = function ($scope, $http, $modalInstance, typeAheadService, sdbmutil, newNameValue) {

        $scope.typeAheadService = typeAheadService;

        $scope.readyToCreate = true;

        $scope.candidates = [];

        $scope.entity = $scope.entityFactory();
        $scope.entity.name = newNameValue;

        $scope.save = function () {
            $scope.entity.$save(
                function (entity) {
                    $modalInstance.close(entity);
                },
                sdbmutil.promiseErrorHandlerFactory("Error saving entity")
            );
        };

        $scope.cancel = function () {
            $modalInstance.dismiss('cancel');
        };
    };

    sdbmApp.controller('CreateAgentModalCtrl', function ($scope, $http, $modalInstance, typeAheadService, sdbmutil, newNameValue, Agent) {
        $scope.entityFactory = function() { return new Agent(); };

        baseCreateEntityModalCtrl($scope, $http, $modalInstance, typeAheadService, sdbmutil, newNameValue);

        $scope.entityName = "agent";
        $scope.hasViafId = true;
    });

    sdbmApp.controller('CreateArtistModalCtrl', function ($scope, $http, $modalInstance, typeAheadService, sdbmutil, newNameValue, Artist) {
        $scope.entityFactory = function() { return new Artist(); };

        baseCreateEntityModalCtrl($scope, $http, $modalInstance, typeAheadService, sdbmutil, newNameValue);

        $scope.entityName = "artist";
    });

    sdbmApp.controller('CreateAuthorModalCtrl', function ($scope, $http, $modalInstance, typeAheadService, sdbmutil, newNameValue, Author) {
        $scope.entityFactory = function() { return new Author(); };

        baseCreateEntityModalCtrl($scope, $http, $modalInstance, typeAheadService, sdbmutil, newNameValue);

        $scope.entityName = "author";
    });

    sdbmApp.controller('CreateLanguageModalCtrl', function ($scope, $http, $modalInstance, typeAheadService, sdbmutil, newNameValue, Language) {
        $scope.entityFactory = function() { return new Language(); };

        baseCreateEntityModalCtrl($scope, $http, $modalInstance, typeAheadService, sdbmutil, newNameValue);

        $scope.entityName = "language";
    });

    sdbmApp.controller('CreatePlaceModalCtrl', function ($scope, $http, $modalInstance, typeAheadService, sdbmutil, newNameValue, Place) {
        $scope.entityFactory = function() { return new Place(); };

        baseCreateEntityModalCtrl($scope, $http, $modalInstance, typeAheadService, sdbmutil, newNameValue);

        $scope.entityName = "place";
    });

    sdbmApp.controller('CreateScribeModalCtrl', function ($scope, $http, $modalInstance, typeAheadService, sdbmutil, newNameValue, Scribe) {
        $scope.entityFactory = function() { return new Scribe(); };

        baseCreateEntityModalCtrl($scope, $http, $modalInstance, typeAheadService, sdbmutil, newNameValue);

        $scope.entityName = "scribe";
    });

    sdbmApp.controller('InferenceFlagsCtrl', function ($scope, $modalInstance, objectWithFlags) {
        $scope.objectWithFlags = objectWithFlags;
    });
    
}());

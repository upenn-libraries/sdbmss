/**
 * sdbmApp module for angular.js
 *
 * We only Angular for a few data entry pages, so all of the code
 * lives here instead of being broken out further into smaller modules
 * or files.
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
            if(obj === undefined || obj === null || (typeof(obj) === 'string' && obj.length === 0) || (Array.isArray(obj) && obj.length === 0)) {
                blank = true;
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
                childAssociations.forEach(function (child_assoc) {
                    filterBlankRecords(childObject, child_assoc);
                });

                var keep = true;
                if(assoc.skipChecking === undefined || !assoc.skipChecking(childObject)) {
                    //console.log('checking ' + objectArrayName + ' record id = ' + childObject.id);
                    keep = false;
                    thingsToCheck.forEach(function (propertyName) {
                        var propertyIsBlank = isBlankThing(childObject[propertyName]);
                        //console.log('is property ' + propertyName + ' blank? ' + propertyIsBlank);
                        if(!propertyIsBlank) {
                            keep = true;
                        }
                    });
                }
                //console.log("returning keep = " +  keep);
                if(!keep) {
                    childObject._destroy = 1;
                }
            });
        };

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
                    }
                });
            },
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
            redirectToEntryViewPage: function(entry_id)  {
                window.location = "/entries/" + entry_id;
            },
            redirectToManuscriptEditPage: function(manuscript_id)  {
                window.location = "/manuscripts/" + manuscript_id + "/edit/";
            },
            redirectToFindOrCreateManuscriptForEntryPage: function(entry_id) {
                window.location = "/entries/" + entry_id + "/find_or_create_manuscript";
            },
            redirectToDashboard: function() {
                window.location = "/dashboard";
            }
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
                        agent: $scope.agent,
                        limit: 20
                    }
                }).then(function (response) {
                    $scope.sources = response.data.results;
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
    sdbmApp.controller("EntryCtrl", function ($scope, $http, $cookies, Entry, Source, sdbmutil, $modal) {

        $scope.sdbmutil = sdbmutil;
        
        // this describes the (nested) associations inside an Entry;
        // we use it, when saving, to identify and remove 'blank' records
        $scope.associations = [
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
                properties: ['observed_name'],
                foreignKeyObjects: ['artist']
            },
            {
                field: 'entry_scribes',
                properties: ['observed_name'],
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
                properties: ['start_date', 'end_date', 'comment'],
                associations: [
                    {
                        field: 'event_agents',
                        properties: ['observed_name'],
                        foreignKeyObjects: ['agent']
                    }
                ]
            }
        ];

        $scope.pageTitle = "";

        $scope.badData = [];

        $scope.optionsAuthorRole = undefined;
        $scope.optionsSold = undefined;
        $scope.optionsCurrency = undefined;
        $scope.optionsCirca = undefined;
        $scope.optionsMaterial = undefined;
        $scope.optionsAltSize = undefined;

        $scope.entry = undefined;

        $scope.originalEntryViewModel = undefined;

        $scope.warnWhenLeavingPage = true;
        
        $scope.edit = false;

        $scope.currentlySaving = false;

        $scope.addRecord = function (anArray) {
            anArray.push({});
        };

        // filter used by ng-repeat to hide records marked for deletion
        $scope.activeRecords = function(element) {
            return !element._destroy;
        }
        
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
                    anArray.push({});
                }
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
                if(key.substr(0,1) != "$" && typeof $scope[key] !== "function") {
                    console.log(key);
                    console.log($scope[key]);
                }
            }
        };

        $scope.confirmClearChanges = function() {
            // TODO
            alert("Not yet implemented");
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

            if(entry.transaction) {
                if(!sdbmutil.inOptionsArray(entry.transaction.sold, $scope.optionsSold)) {
                    $scope.badData.push("Bad sold value: '" + entry.transaction.sold + "'");
                }
                if(entry.transaction.currency) {
                    if(! sdbmutil.inOptionsArray(entry.transaction.currency, $scope.optionsCurrency)) {
                        $scope.badData.push("Bad currency value: '" + entry.transaction.currency + "'");
                    }
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
        
        // populates angular view models from the Entry object
        // retrieved via API
        $scope.populateEntryViewModel = function(entry) {

            //console.log("entry from API retrieval");
            //console.log(entry);

            // make blank initial rows, as needed, for user to fill out
            $scope.associations.forEach(function (assoc) {
                var fieldname = assoc.field;
                var objArray = entry[fieldname];
                if(!objArray || objArray.length === 0) {
                    entry[fieldname] = [ {} ];
                }
            });

            // Transform EventAgent records into buyer, seller,
            // selling_agent fields on the Event, so that UI can bind
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
                        entry.transaction = event;
                    } else {
                        entry.provenance.push(event);
                    }
                }
            }
            if(!entry.transaction && entry.source.entries_have_a_transaction) {
                entry.transaction = {
                    primary: true,
                    sold: 'Unknown'
                };
                // prepopulate transaction agent fields with data from source_agents
                var sourceAgents = entry.source.source_agents || [];
                sourceAgents.forEach(function (sourceAgent) {
                    var role = sourceAgent.role;
                    entry.transaction[role] = {
                        agent: sourceAgent.agent
                    };
                });
            }
            if(entry.provenance.length === 0) {
                entry.provenance.push({});
            }

            $scope.sanityCheckFields(entry);
                
            // save copy at this point, so we have something to
            // compare to, when navigating away from page
            $scope.originalEntryViewModel = angular.copy(entry);
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

            // collapse Transaction and Provenance back into Events
            entryToSave.events = [].concat(entryToSave.provenance);
            delete entryToSave.provenance;
            if(entryToSave.transaction) {
                if (entryToSave.transaction.price) {
                    entryToSave.transaction.price = entryToSave.transaction.price.replace(/[$,]/, '');
                }
                entryToSave.events = entryToSave.events.concat([entryToSave.transaction]);
                delete entryToSave.transaction;
            }

            // Transform fields back into EventAgent records
            entryToSave.events.forEach(function (event, index, array) {
                event.event_agents = [];
                ["buyer", "selling_agent", "seller_or_holder"].forEach(function (role) {
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
            $scope.associations.forEach(function (assoc) {
                sdbmutil.filterBlankRecords(entryToSave, assoc);
                if(entryToSave[assoc.field].length == 0) {
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
                if(objectArray) {
                    sdbmutil.replaceEntityObjectsWithIds(objectArray, relatedObjectName);
                }
            }

            $scope.changeNestedAttributesNames($scope.associations, entryToSave);
            
            //console.log("about to save this Entry: ");
            //console.log(sdbmutil.objectSnapshot(entryToSave));
            
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

        $(window).bind('beforeunload', function() {
            if ($scope.warnWhenLeavingPage && angular.toJson($scope.originalEntryViewModel) !== angular.toJson($scope.entry)) {1
                /*
                alert("NOT THE SAME!");
                console.log("originalEntryViewModel=");
                console.log(angular.toJson($scope.originalEntryViewModel));
                console.log("current entry=");
                console.log(angular.toJson($scope.entry));
                */
                return "You have unsaved changes";
            }
        });
            
        $http.get("/entries/types/").then(
            function(result) {

                $scope.optionsAuthorRole = result.data.author_role;
                $scope.optionsSold = result.data.sold;
                $scope.optionsCurrency = result.data.currency;
                $scope.optionsCirca = result.data.circa;
                $scope.optionsAltSize = result.data.alt_size;

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

            var refocus = function(badValue) {
                // TODO: calling focus() directly here doesn't work in
                // Firefox (but works in Chrome). Using setTimeout()
                // is susceptible to race conditions with the
                // browser's default handling of tab key, but in
                // practice, it works.  Need to find a better way.
                setTimeout(function() {
                    $(element).focus();
                }, 100);

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
            var sourceIsUrl = sourceStr.substr(0, 1) == "/";
            if(!sourceIsUrl) {
                autocompleteSource = $parse(sourceStr)(scope);
            } else {
                autocompleteSource = function (request, response_callback) {
                    var url  = sourceStr;
                    var searchTerm = request.term;
                    $http.get(url, {
                        params: $.extend({ autocomplete: 1, term: searchTerm, limit: 25 }, params)
                    }).then(function (response) {
                        // transform data from API call into format expected by autocomplete
                        var exactMatch = false;
                        options = response.data.results;
                        options.forEach(function(option) {
                            option.label = option.name;
                            option.value = option.id;
                            if(!exactMatch) {
                                exactMatch = searchTerm == option.label;
                            }
                        });
                        if (!exactMatch && controller) {
                            options.unshift({
                                label: "\u00BB Create '" + searchTerm + "'",
                                value: 'CREATE',
                                id: 'CREATE'
                            });
                        }
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
                if (event.which == 13) {
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
                            // it's just whitespace, so erase it
                            $(element).val("");
                            assignToModel(null);
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

                            var newNameValue = ui.item.label.substring(ui.item.label.indexOf("'")+1, ui.item.label.lastIndexOf("'"));

                            var modalInstance = $modal.open({
                                templateUrl: template,
                                controller: controller,
                                resolve: {
                                    modalParams: function() {
                                        return {
                                            "name": newNameValue,
                                            "type": params["type"]
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
            });
        };
    });

    /* To be used on elements that should get a tooltip when clicked */
    sdbmApp.directive("sdbmTooltip", function () {
        return function (scope, element, attrs) {
            var templateName = attrs.sdbmTooltip;
            element.addClass('sdbmss-tooltip-label');
            $(element).qtip({
                style: {
                    classes: 'sdbmss-tooltip'
                },
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
                }
            });
        };
    });

    sdbmApp.controller('SourceCtrl', function ($scope, $http, $modal, sdbmutil, Source) {

        /* TODO: source validation is complex: date is required only
           sometimes; review other fields as well, once all source
           types have been finalized */

        // store in scope, otherwise angular template code can't
        // get a reference to this
        $scope.sdbmutil = sdbmutil;
        
        $scope.currentlySaving = false;
        
        $scope.agent_role_types = ['institution', 'buyer', 'seller_or_holder', 'selling_agent'];

        $scope.associations = [
            {
                field: 'source_agents',
                properties: ['role'],
                foreignKeyObjects: ['agent']
            }
        ];
        
        $scope.pageTitle = "";

        $scope.source = undefined;

        $scope.source_agents = [];

        $scope.debug = function () {
            console.log($scope.source);
        };

        $scope.showFields = function() {
            if($scope.source && $scope.source.source_type) {
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

        $scope.save = function () {
            var sourceToSave = new Source(angular.copy($scope.source));

            if(sourceToSave.date) {
                sourceToSave.date = sourceToSave.date.replace(/-/g, "");
            }

            sourceToSave.source_agents = [];
            $scope.agent_role_types.forEach(function (role) {
                if (sourceToSave[role]) {
                    sourceToSave[role].role = role;
                    sourceToSave.source_agents.push(sourceToSave[role]);
                    delete sourceToSave[role];
                }
            });

            sdbmutil.replaceEntityObjectsWithIds(sourceToSave.source_agents, "agent");

            // strip out blank objects
            $scope.associations.forEach(function (assoc) {
                sdbmutil.filterBlankRecords(sourceToSave, assoc);
                if(sourceToSave[assoc.field].length == 0) {
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
                sourceToSave.$save(
                    $scope.postSourceSave,
                    sdbmutil.promiseErrorHandlerFactory("There was an error saving this record")
                ).finally(function() {
                    $scope.currentlySaving = false;
                });
            }
        };

        // "constructor" for controller goes here

        $http.get("/sources/types/").then(
            function(result) {

                $scope.optionsSourceType = result.data.source_type;
                $scope.optionsMedium = result.data.medium;

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
                    $scope.saveError = response.data.error || "Unknown Error";
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
            entity[modalParams["type"]] = true;
        };
        
        baseCreateEntityModalCtrl($scope, $http, $modalInstance, sdbmutil);

        $scope.entityName = "name";
        $scope.hasViafId = true;

        $scope.suggestions = [];
        
        $scope.loading = false;
        $scope.message = "";
        $scope.showSuggestions = false;
        
        $scope.find_suggestions = function(name) {
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

        $scope.use_suggestion = function(suggestion) {
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

    sdbmApp.controller('InferenceFlagsCtrl', function ($scope, $modalInstance, objectWithFlags) {
        $scope.objectWithFlags = objectWithFlags;
    });
    
}());

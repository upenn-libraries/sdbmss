/**
 * sdbmApp module for angular.js
 *
 * This contains code for public-facing pages.
 */

/* Hints for eslint: */
/* global alert, angular, console, window, $ */

(function () {

    "use strict";

    var sdbmApp = angular.module("sdbmApp", ["ngCookies", "ngResource", "xeditable", "ui.bootstrap"]);

    sdbmApp.run(function (editableOptions, $http, $cookies) {
        editableOptions.theme = 'bs3'; // bootstrap3 theme. Can be also 'bs2', 'default'

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
    sdbmApp.controller("EntryCtrl", function ($scope, $http, $cookies, typeAheadService, Entry, Source, sdbmutil) {

        $scope.entry_associations = [
            {
                field: 'entry_titles',
                properties: ['title', 'common_title']
            },
            {
                field: 'entry_authors',
                properties: ['observed_name'],
                foreign_key_objects: ['author']
            },
            {
                field: 'entry_dates',
                properties: ['date', 'circa']
            },
            {
                field: 'entry_artists',
                foreign_key_objects: ['artist']
            },
            {
                field: 'entry_scribes',
                foreign_key_objects: ['scribe']
            },
            {
                field: 'entry_languages',
                foreign_key_objects: ['language']
            },
            {
                field: 'entry_materials',
                properties: ['material']
            },
            {
                field: 'entry_places',
                foreign_key_objects: ['place']
            },
            {
                field: 'entry_uses',
                properties: ['use']
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

        $scope.redirectToEditPage = function(id)  {
            window.location = "/entries/" + id + "/edit/";
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

        $scope.isBlankStringOrObject = function(obj) {
            var blank = false;
            if(obj === undefined || (typeof(obj) === 'string' && obj.length === 0)) {
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

            var sellerAgent;
            var sellerOrHolder;
            var buyer;

            if(entry.source) {
                var sourceagents = entry.source.sourceagents || [];
                sourceagents.forEach(function (sourceagent) {
                    if(sourceagent.role === 'seller_agent') {
                        sellerAgent = sourceagent.agent;
                    }
                    else if(sourceagent.role === 'seller_or_holder') {
                        sellerOrHolder = sourceagent.agent;
                    }
                    else if(sourceagent.role === 'buyer') {
                        buyer = sourceagent.agent;
                    }
                });
            }

            // make blank initial rows, as needed, for user to fill out
            $scope.entry_associations.concat({ field: 'entry_provenance' }).forEach(function (assoc) {
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
                    primary: true
                };
                if(sellerAgent) {
                    entry.sale.seller_agent = {
                        agent: sellerAgent
                    };
                }
                if(sellerOrHolder) {
                    entry.sale.seller_or_holder = {
                        agent: sellerOrHolder
                    };
                }
                if(buyer) {
                    entry.sale.buyer = {
                        agent: buyer
                    };
                }
            }
            if(entry.provenance.length === 0) {
                entry.provenance.push({});
            }

            // sanity check that values we got for dropdowns are
            // actually valid options
            if(entry.sale.sold) {
                if(! sdbmutil.inOptionsArray(entry.sale.sold, $scope.optionsSold)) {
                    $scope.badData.push("Bad sold value: '" + entry.sale.sold + "'");
                }
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

        $scope.save = function () {
            // Transform angular's view models to JSON payload that
            // API expects: attach a bunch of things to Entry resource
            $scope.currentlySaving = true;

            var entryToSave = new Entry(angular.copy($scope.entry));

            // collapse Sale and Provenance into Events
            entryToSave.events = [].concat(entryToSave.provenance).concat([entryToSave.sale]);
            delete entryToSave.provenance;
            delete entryToSave.sale;

            // strip out blank objects
            $scope.entry_associations.forEach(function (assoc, index, array) {
                var objectArrayName = assoc.field;
                var objectArrayPropertiesAndForeignKeys = (assoc.properties || []).concat(assoc.foreign_key_objects || []);
                var objectArray = entryToSave[objectArrayName];
                // filter out items in array that are either empty objects or are objects that have blank fields
                entryToSave[objectArrayName] = objectArray.filter(function (object) {
                    var keep = false;
                    objectArrayPropertiesAndForeignKeys.forEach(function (propertyName) {
                        var propertyIsBlank = $scope.isBlankStringOrObject(object[propertyName]);
                        //console.log('is property ' + propertyName + ' blank? ' + propertyIsBlank);
                        if(!propertyIsBlank) {
                            keep = true;
                        }
                    });
                    //console.log("returning keep = " +  keep);
                    return keep;
                });
            });

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

            console.log(entryToSave);
            
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

            // Strip out blank records

            entryToSave.entry_artists = entryToSave.entry_artists.filter(function (item) {
                if(item.id || item.artist) {
                    return true;
                }
            });

            console.log(entryToSave);

            if(entryToSave.id) {
                console.log("updating record...");
                entryToSave.$update(
                    function (entry) {
                        $scope.redirectToEditPage(entry.id);
                    },
                    sdbmutil.promiseErrorHandlerFactory("There was an error saving this entry")
                );
            } else {
                console.log("saving new record...");
                entryToSave.$save(
                    function (entry) {
                        $scope.redirectToEditPage(entry.id);
                    },
                    sdbmutil.promiseErrorHandlerFactory("There was an error saving this entry")
                );
            }
        };


        // "constructor" for controller goes here

        $http.get("/entries/form_dropdown_values/").then(
            function(result) {

                $scope.optionsSold = result.data.sold;
                $scope.optionsSold.unshift(["", ""]);
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
                    var source = Source.get(
                        {id: sourceId},
                        function() {
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

    /* To be used on editable typeahead elements: submits the form
     * when user makes a selection. We can't use typeahead-on-select
     * because that doesn't give us the DOM element.
     */
    sdbmApp.directive("sdbmSubmitOnSelection", function () {
        return function (scope, element, attrs) {
            // listen for all clicks on the parent
            $(element).parent().on("click", function (event) {
                // target might be anything inside the A, so find the A
                var a = $(event.target).closest("a").get(0);
                if (a && $(a).parent().get(0).tagName === "LI") {
                    // if parent is LI, it means they made a selection
                    $(event.currentTarget).find("form").submit();
                } else {
                    //console.log("click happened on a " + event.target.tagName +" that was not an A element whose parent is LI, so ignoring");
                }
            });
        };
    });

    /** Directive to add a watch on the model for an editable */
    sdbmApp.directive("sdbmShowCreateModalOnModelChange", function ($parse, $timeout, $modal) {
        return function (scope, element, attrs) {
            var modelProperty = attrs.editableText;
            // attr value should be the name of the modal controller to use
            var controller = attrs.sdbmShowCreateModalOnModelChange;

            if(!modelProperty) {
                alert("can't use sdbm-on-editable-model-change on an element without editable-text");
            }

            scope.$watch(modelProperty, function(newValue, oldValue) {
                console.log("model value changed:");
                console.log(newValue);

                var userWantsToCreate = newValue !== undefined &&
                    typeof(newValue) === 'object' &&
                    newValue.id === 'CREATE';

                if(userWantsToCreate) {
                    $timeout(function() {

                        var template = 'createEntityWithName.html';
                        var newNameValue = newValue.display_value.substring(newValue.display_value.indexOf("'")+1, newValue.display_value.lastIndexOf("'"));
                        var originalModelValue = oldValue;

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
                            var model = $parse(modelProperty);
                            model.assign(scope, agent);
                        }, function () {
                            var model = $parse(modelProperty);
                            model.assign(scope, originalModelValue);
                        });

                    });
                }
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

    sdbmApp.controller('CreateSourceCtrl', function ($scope, typeAheadService, sdbmutil, Source) {

        $scope.typeAheadService = typeAheadService;

        $scope.source = new Source();

        $scope.sourceagents = [];

        $scope.showFields = function() {
            if($scope.source.source_type) {
                return true;
            }
            return false;
        };

        $scope.save = function () {
            var sourceToSave = new Source(angular.copy($scope.source));

            sourceToSave.date = sourceToSave.date.replace(/-/g, "");

            sourceToSave.sourceagents = [];
            ['institution', 'buyer', 'seller_or_holder', 'seller_agent'].forEach(function (role) {
                if (sourceToSave[role]) {
                    sourceToSave[role].role = role;
                    sourceToSave.sourceagents.push(sourceToSave[role]);
                    delete sourceToSave[role];
                }
            });

            sdbmutil.replaceEntityObjectsWithIds(sourceToSave.sourceagents, "agent");

            sourceToSave.$save(
                function (source) {
                    window.location = "/entry/add/source/" + source.id + "/";
                },
                sdbmutil.promiseErrorHandlerFactory("Error saving Source")
            );
        };
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

}());

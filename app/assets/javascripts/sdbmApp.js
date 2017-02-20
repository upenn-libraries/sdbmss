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

    var sdbmApp = angular.module("sdbmApp", ["ngResource", "ui.bootstrap", "ngAnimate", "ui.sortable", "ngSanitize", "ngCookies"]);
    
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
                    if(key == "order") {
                      // ignore order
                    } else if (key == "$$hashKey") {
                      // and this
                    }
                    else if(obj[key]) {
                      blank = isBlankThing(obj[key]);
                      // one blank field shouldn't override earlier non-blank fields...
                      if (blank == false) return false;
                    }
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
            } else if (typeof(obj) == 'string' || Array.isArray(obj)) {
                //console.log('array or string', obj);
                // strings and arrays (non-empty) are non-blank
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

        var getNewManuscript = function () {
            return URI().search(true).new_manuscript;
        };

        var getOriginalEntry = function () {
            return URI().search(true).original_entry;
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
            var new_manuscript = getNewManuscript();
            if(new_manuscript) {
                path += "&new_manuscript=" + new_manuscript;
            }            
            var original_entry = getOriginalEntry();
            if(original_entry) {
                path += "&original_entry=" + original_entry;
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
            isBlankThing: isBlankThing,
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
            getNewManuscript: getNewManuscript,
            getOriginalEntry: getOriginalEntry,
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

    // anchor
    sdbmApp.controller("DericciGameCtrl", function ($scope, $http, $modal, $sce) {
      EntryScope = $scope;
      $scope.records = [];
      $scope.current_record = undefined;
      $scope.current_url = "";
      $scope.current_index = 0;
      $scope.saving = false;
      $scope.gameID = $("#game_id").val();
      $scope.progress = {complete: 0, skipped: 0};
      $http.get("/dericci_games/" + $scope.gameID + ".json", {
      }).then(function (response) {
//        console.log(response);
        $scope.records = response.data.dericci_records;
        $scope.current_url = $sce.trustAsResourceUrl($scope.records[0].url);
        $scope.current_record = $scope.records[0];
        $scope.setProgress();
        $scope.initial = $scope.progress.complete;
      }, function(response) {
          alert("An error occurred when initializing the game.");
      });
      $scope.selectRecord = function (record) {
        $scope.current_record = record;
        $scope.current_index = $scope.records.indexOf(record);
        $scope.current_url = $sce.trustAsResourceUrl($scope.current_record.url);
      };
      $scope.findName = function (model) {
        $scope.name = {};
        var modal = $modal.open({
          templateUrl: "selectNameAuthority.html",
          controller: "SelectNameAuthorityCtrl",
          resolve: {
            recordType: function () { return "names"; },
            model: function () { return $scope.name; },
            type: function () { return "is_author"; },
            base: function () { return model.name; }
          },
          size: 'lg'
        });
        modal.result.then( function (results) {
          model.skipped = false;
          if ($scope.current_record.dericci_links.filter(function (dl) { return dl.name_id == $scope.name.id; }).length <= 0) {
            $scope.current_record.dericci_links.push({name_id: $scope.name.id, name: $scope.name.name});
            $scope.setProgress();
          } else {
            alert("You have already selected that name!");
          }
        });
      };
      $scope.isLinked = function (record) {
        return record && $scope.actualLinks(record).length > 0;
      };
      $scope.actualLinks = function (record) {
        return record && record.dericci_links.filter(function (l) { return l.name_id; });
      };
      $scope.skip = function (model) {
        if ($scope.actualLinks(model) <= 0) {
          model.skipped = true;
          $scope.next();
          $scope.setProgress();
        }
      };
      $scope.next = function () {
        var i = ($scope.current_index + 1) % $scope.records.length;
        $scope.selectRecord($scope.records[i]);
      };
      $scope.prev = function () {
        var i = ($scope.records.length + $scope.current_index - 1) % $scope.records.length;
        $scope.selectRecord($scope.records[i]);
      };
      $scope.removeLink = function (record, link) {
        var i = record.dericci_links.indexOf(link);
        if (i != -1) {
          // existing!
          if (record.dericci_links[i].id) {
            record.dericci_links[i]._destroy = true;
          } else {
            record.dericci_links.splice(i, 1);
          }
          $scope.setProgress();
        }
      };
      $scope.setProgress = function () {
        $scope.progress = {
          complete: Math.floor(100 * ($scope.records.filter( function (r) { return $scope.isLinked(r); }).length / 20)),
          skipped: Math.floor(100 * ($scope.records.filter( function (r) { return r.skipped; }).length / 20))
        };
      };
      $scope.activeRecords = function(element) {
        return !element._destroy;
      };

      $scope.save = function () {
        var records = angular.copy($scope.records).filter( function (r) { return r.dericci_links.length > 0; }).map( function (r) {
          r.dericci_links_attributes = r.dericci_links;
          return r;
        });
        $http.put("/dericci_games/" + $scope.gameID + ".json", { dericci_game: {id: $scope.gameId, skipped: $scope.progress.skipped, completed: $scope.progress.complete, dericci_records_attributes: records} }).then(function (response) {
          if (response.data.message == "Success!") {
            $scope.saving = true;
            window.location = "/dericci_games/";
          } else {
            console.log(response);
          }
        });
      };

      $(window).bind('beforeunload', function() {
          if (!$scope.saving && $scope.progress.complete != $scope.initial) {
              /*
              console.log("originalEntryViewModel=");
              console.log(angular.toJson($scope.originalEntryViewModel));
              console.log("current entry=");
              console.log(angular.toJson($scope.entry));
              */
            return "You have unsubmitted changes";
          }
          return;
      });
    });

    /* Controller for selecting a source*/
    sdbmApp.controller("SelectSourceCtrl", function ($scope, $http, $modalInstance, $modal, $rootScope, Source, sdbmutil, model, type) {

        $scope.sdbmutil = sdbmutil;

        $scope.searchAttempted = false;
        $scope.title = "";
        $scope.date = "";
        $scope.agent = "";
        $scope.sources = [];
        $scope.limit = 20;
        $scope.order = "id asc";

        $scope.source_type = type;

        $scope.setSource = function (source) {
          //model.source = source;
          Source.get(
            {id: source.id},
            function(source) {
                model.source = source;
                $modalInstance.close();
                //$scope.populateEntryViewModel(model);
            },
            sdbmutil.promiseErrorHandlerFactory("Error loading Source data for this page")
          );
          //$scope.$emit('changeSource', source)
        }

        $scope.cancelSelectSource = function () {
          $scope.$emit('cancelSource');
        }

        $scope.createSource = function () {
          var modalScope = $rootScope.$new();
          modalScope.model = model;
          modalScope.modalInstance = $modal.open({
            templateUrl: 'createSource.html',
            controller: 'SourceCtrl',
            scope: modalScope,
            size:'lg'
          });
          modalScope.modalInstance.result.then(function (agent) {
            if (model.source) {
              $modalInstance.close();
            }
          });
        }

        $scope.createSourceURL = function () {
            var path = "/sources/new?create_entry=1";
            var manuscript_id = sdbmutil.getManuscriptId();
            if(manuscript_id) {
                path += "&manuscript_id=" + manuscript_id;
            }
            var new_manuscript = sdbmutil.getNewManuscript();
            if(new_manuscript) {
                path += "&manuscript_id=" + new_manuscript;
            }
            var original_entry = sdbmutil.getOriginalEntry();
            if(original_entry) {
                path += "&original_entry=" + original_entry;
            }
            return path;
        };

        $scope.findSourceCandidates = function () {
            var source_type, source_type_options;
            if ($scope.source_type) {
              source_type = [$scope.source_type];
              source_type_options = ["contains"];
            } else {
              source_type = ["Personal Observation", "Provenance Observation"];
              source_type_options = ["does not contain", "does not contain"];
            }
            if($scope.title.length > 1 || $scope.date.length > 1 || $scope.agent.length > 1) {
                $scope.searchAttempted = true;
                var title = $scope.title.length > 1 ? $scope.title : '';
                var date = $scope.date.length > 1 ? $scope.date : '';
                var agent = $scope.agent.length > 1 ? $scope.agent : '';
                $http.get("/sources/search.json", {
                    params: {
                        order: $scope.order,
                        date: date,
                        title: title,
                        agent: agent,
                        limit: $scope.limit,
                        "source_type[]": source_type,
                        "source_type_option[]": source_type_options,
                        id: $scope.source_id,
                        id_option: "without"
                    }
                }).then(function (response) {
                    $scope.total = response.data.total;
                    $scope.sources = response.data.results;
                }, function(response) {
                    alert("An error occurred searching for sources");
                });
            } else {
              $scope.searchAttempted = false;
              $scope.sources = [];
            }
        };

        $scope.$watch('title', $scope.findSourceCandidates);
        $scope.$watch('date', $scope.findSourceCandidates);
        $scope.$watch('agent', $scope.findSourceCandidates);
    });

    sdbmApp.filter('humanize', function () {
      return function (input) {
        input = input || '';
        var capitalize = function(match, p1) {
         return p1.toUpperCase();
        }
        var output = input.replace(/_/g, ' ').replace(/\b(\w)/g, capitalize);
        return output;
      }
    });

    sdbmApp.controller("SelectNameAuthorityCtrl", function ($scope, $http, $modalInstance, $modal, recordType, model, type, base) {
      $scope.suggestions = [];
      $scope.type = type.replace('is_', '');
      $scope.warning = "To begin searching, enter search term in the search bar.";

      $scope.nameSearchString = base || "";

      setTimeout( function () {
        $('.search-form').focus();
      }, 10);

      $scope.selectSuggestion = function (s) {
        $scope.suggestion = s;
        $scope.selectName();
      }

      $scope.selectName = function () {
        model.id = $scope.suggestion.id; 
        model.name = $scope.suggestion.name;
        $modalInstance.close();
      }

      $scope.autocomplete = function () {
          var url  = "/" + recordType + "/more_like_this.json";
          var searchTerm = $scope.nameSearchString; // redundant?
          $scope.searchTerm = searchTerm;

          if (searchTerm.length <= 1) {
            $scope.suggestions = [];
            $scope.suggestion =  undefined;
            $scope.warning = "To begin searching, enter search term in the search bar."
            return;
          }
          $http.get(url, {
              params: $.extend({ autocomplete: 1, name: searchTerm, limit: 15 }, {})
          }).then(function (response) {
              // transform data from API call into format expected by autocomplete
              var exactMatch = false;
              var options = response.data.results;

              options.forEach(function(option) {
                  option.label = option.name;
                  option.value = option.id;

                  if(!exactMatch) {
                      exactMatch = searchTerm === option.label;
                  }
              });

              if (!exactMatch) {
                $scope.proposeNew = true;
              } else {
                $scope.proposeNew = false;
              }
              // sort options, prioritizing ones that match the type
              options.sort( function (a, b) {
                if (!a[type] && b[type])
                  return 1;
                else
                  return -1;
              });
              $scope.suggestions = options;
              $scope.suggestion = $scope.suggestions[0];              
              if ($scope.suggestions.length <= 0) $scope.warning = "No results found.  Consider searching for other possible spelling variations.";
              else $scope.warning = ""; 
          });
      };
      $scope.cancel = function () {
        $modalInstance.dismiss('cancel');
      }

      $scope.createName = function () {
        var newNameValue = $scope.nameSearchString;//ui.item.label.substring(ui.item.label.indexOf("'") + 1, ui.item.label.lastIndexOf("'"));


        var template = "";
        if (recordType == 'languages' || recordType == 'places') {
          template = 'createEntityWithName.html';
        } else {
          template = 'createName.html';
        }

        var entityName = recordType.replace('s', '');

        var controller = "";
        if (recordType == 'languages') controller = "CreateLanguageModalCtrl";
        else if (recordType == 'places') controller = "CreatePlaceModalCtrl";
        else controller = "CreateNameModalCtrl";

        var modalInstance = $modal.open({
            templateUrl: template,
            controller: controller,
            resolve: {
                modalParams: function() {
                    return {
                        "name": newNameValue,
                        "type": type,
                        "entityName": entityName,
                        "back": {
                          "recordType": recordType,
                          "model": model,
                          "type": type
                        }
                    };
                }
            },
            size: 'lg'
        });

        $modalInstance.close();

        /* callback for handling result */
        modalInstance.result.then(function (agent) {
          if (agent) {
            model.id = agent.id;
            model.name = agent.name;
          } else {
            model.id = null;
          }
        }, function () {
            model.id = null;
//            assignToModel(null);
        });
      };

      // do initial search if auto-populated
      if ($scope.nameSearchString.length > 0) {
        $scope.autocomplete();
      }

    });

    /* Entry screen controller */
    sdbmApp.controller("EntryCtrl", function ($scope, $http, $filter, Entry, Source, sdbmutil, $modal) {

        EntryScope = $scope;

        $scope.expand = function (e) {
          $(e.currentTarget).parent().parent('.expandable').addClass('expanded');
        }

        $scope.reduce = function (e) {
          $(e.currentTarget).parent().parent('.expandable').removeClass('expanded')
        }

        $scope.selectSourceModal = function (model, type) {
          if ($scope.mergeEdit !== false) {
            var modal = $modal.open({
                templateUrl: "selectSource.html",
                controller: "SelectSourceCtrl",
                resolve: {
                  //recordType: function () { return recordType },
                  model: function () { return model },
                  type: function () { return type },
                  base: ""
                },
                size: 'lg'
            });
            modal.result.then(function () {
              $scope.populateEntryViewModel($scope.entry);
            }, function () {
              console.log('dismissed');
            });
          }
        }
        
        $scope.selectNameAuthorityModal = function (recordType, model, type, base) {
          base = base || ""

          if (recordType == 'languages' || recordType == 'places') {
            var templateUrl = "selectModelAuthority.html";
          } else {
            var templateUrl = "selectNameAuthority.html";
          }

          var modal = $modal.open({
              templateUrl: templateUrl,
              controller: "SelectNameAuthorityCtrl",
              resolve: {
                recordType: function () { return recordType },
                model: function () { return model },
                type: function () { return type },
                base: function () { return base }
              },
              size: 'lg'
          });
        }

        $scope.removeNameAuthority = function (model, submodel) {
          model[submodel] = null;
          //model['observed_name'] = null;
        }

        // affixes the association name and 'add' button to side, so that it is in view when list is long
        // fix me: no longer used
        $scope.affixer = function () {
          $('.side-title').each( function () {
            // ignore this if the list is short: temp fix?
            if ( $(this).closest('.row').height() < $(window).height() - 500) return;
            else if ( $(window).height() < 600) return;

            var top = $(this).closest('.row').offset().top;
            var bottom = $(document).height() - (top + $(this).closest('.row').height());
            $(this).affix({offset: {top: top, bottom: bottom} }); //Try it
            $(this).data('bs.affix').options.offset = {top: top, bottom: bottom};
          });
        };

        $scope.sortableOptions = {
          axis: 'y',
          placeholder: "input-block-placeholder",
          cancel: ".ui-sortable-locked, .ui-sortable-locked + .input-block, input, select, textarea, a",
          scroll: false,
          containment: 'parent',
          forcePlaceholderSize: true,
          tolerance: 'pointer',
          //handle: ".control-label, .panel-heading",
          start: function(e, ui){
           // ui.placeholder.height(ui.item.height());
          },
          stop: function (e, ui) {
            // this is an ugly way to just get a reference to the array (i.e. entry_titles, provenance) that we are sorting
            var field = ui.item.parent().attr('ng-model').split('.')[1];
            var array = $scope.entry[field].filter( function (e) { return !e._destroy; });
            for (var i = 0; i < array.length; i++) {
              array[i].order = i;
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
                properties: ['title', 'common_title']
            },
            {
                field: 'entry_authors',
                properties: ['observed_name'],
                foreignKeyObjects: ['author']
            },
            {
                field: 'entry_dates',
                properties: ['observed_date', 'date_normalized_start', 'date_normalized_end']
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
                properties: ['observed_name'],
                foreignKeyObjects: ['place']
            },
            {
                field: 'entry_uses',
                properties: ['use']
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
                properties: ['start_date', 'end_date', 'associated_date', 'comment', 'observed_name'],
                foreignKeyObjects: ['provenance_agent']
            },
            {
              field: 'group_records',
              foreignKeyObjects: ['group']
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
          $scope.entry.transaction_type = src.source_type == "Auction/Dealer Catalog" ? "sale" : "no_transaction";
          $scope.entry.source = src;
          $scope.selecting_source = false;
        };

        $scope.editSource = function () {
          $scope.selecting_source = true;
          $scope.selecting_source_type = $scope.entry.source.source_type.id;
          $scope.old_source_id = $scope.entry.source.id;
          $scope.entry.source_bk = $scope.entry.source;
          $scope.entry.source = undefined
        };

        $scope.updateProvenanceDateRange = function (prov, date) {
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
          if (prov.dates.length <= 0) {
            prov.start_date_normalized_start = "";
            prov.end_date_normalized_end = "";
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
          if (anArray == $scope.entry.provenance) {
            anArray.push({dates: [{type: "Start"}]});
          } else if (anArray == $scope.entry.group_records) {
            anArray.push({permission: true});
          } else {            
            anArray.push({});
          }
          for (var i = 0; i < anArray.length; i++) {
            anArray[i].order = i;
          }
          setTimeout( function () {            
            $scope.affixer();
          }, 2000);
        };

        // filter used by ng-repeat to hide records marked for deletion
        $scope.activeRecords = function(element) {
            return !element._destroy;
        };

        $scope.removeRecord = function (anArray, record) {
          var doremove = function (anArray, record) {
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
          };
          if (sdbmutil.isBlankThing(record)) doremove(anArray, record);
          else {            
            dataConfirmModal.confirm({
              title: 'Confirm',
              text: 'Are you sure you want to remove this field and its contents?',
              commit: 'Yes',
              cancel: 'Cancel',
              zIindex: 10099,
              onConfirm: function() { doremove(anArray, record); $scope.$apply(); },
              onCancel:  function() { }
            });
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
            /*if(entry.sale && entry.sale.sale_agents) {
                var sale_agents = entry.sale.sale_agents;
                for(var idx in sale_agents) {
                    var sale_agent = sale_agents[idx];
                    entry.sale[sale_agent.role] = sale_agent;
                }
                delete entry.sale.sale_agents;
            }*/
            
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
                    sold: null,
                    sale_agents: []
                };
                // prepopulate sale agent fields with data from source_agents
                var sourceAgents = entry.source.source_agents || [];
                sourceAgents.forEach(function (sourceAgent) {
                    var sa = {agent: sourceAgent.agent, role: "selling_agent"};
                    entry.sale.sale_agents.push(sa);
                });
            }

            if (!entry.sale.sale_agents) entry.sale.sale_agents = [];

            $scope.sanityCheckFields(entry);

            // save copy at this point, so we have something to
            // compare to, when navigating away from page
            $scope.originalEntryViewModel = angular.copy(entry);
        };

        $scope.postEntrySave = function(entry) {
            $scope.warnWhenLeavingPage = false;
            window.location = "/entries/" + entry.id;
            /*
            //console.log(entry);
            $scope.entry = entry;
            $scope.populateEntryViewModel($scope.entry);

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
            });*/
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

                entryToSave.sale.sale_agents = entryToSave.sale.sale_agents || [];

                for (var i = 0; i < entryToSave.sale.sale_agents.length; i++) {
                  if (entryToSave.sale.sale_agents[i].agent) {
                    entryToSave.sale.sale_agents[i].agent_id = entryToSave.sale.sale_agents[i].agent.id;
                  } else {
                    entryToSave.sale.sale_agents[i]._destroy = 1;
                  }
                }
                // Transform fields back into SaleAgent records
                /*entryToSave.sale.sale_agents = [];
                ["buyer", "selling_agent", "seller_or_holder"].forEach(function (role) {
                    if(entryToSave.sale[role]) {
                        var sale_agent = entryToSave.sale[role];
                        sale_agent.role = role;
                        if(sale_agent.agent && sale_agent.agent.id) {
                          sale_agent.agent_id = sale_agent.agent.id;
                          delete sale_agent.agent;
                        } else {
                          sale_agent._destroy = 1;
                        }
                        entryToSave.sale.sale_agents.push(sale_agent);
                        delete entryToSave.sale[role];
                    }
                });
                //console.log(entryToSave.sale);*/
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
                entryToSave.provenance[i].dates = [];
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
                [ entryToSave.provenance, 'provenance_agent' ],               
                [ entryToSave.group_records, 'group' ]                
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

                var new_manuscript = sdbmutil.getNewManuscript();
                if (new_manuscript) {
                  entryToSave.new_manuscript = new_manuscript;
                }

                var original_entry = sdbmutil.getOriginalEntry();
                if (original_entry) {
                  entryToSave.original_entry = original_entry;
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

        $scope.checkForChanges = function (entry1, entry2) {

          // manually remove the blank selling agent and institution, if they exist
          var entry2 = angular.copy(entry2);
          if (entry2.institution == null || entry2.institution.id == null) {
            delete entry2.institution;
          }

          // strip out blank objects
          $scope.associations.forEach( function (assoc) {
            if (assoc.foreignKeyObjects && assoc.foreignKeyObjects.length > 0) {
              var field = assoc.field;
              var key = assoc.foreignKeyObjects[0];
              
              if (entry2[field]) {                
                entry2[field].forEach( function (f) {
                  if (f[key] && !f[key]['id']) {
                    delete f[key];
                  }
                });
              }
            }

          });

          if (entry2.provenance) {
            for (var i = 0; i < entry2.provenance.length; i++) {
              var prov = entry2.provenance[i];
              prov.start_date = "", prov.end_date = "", prov.associated_date = "";
              if (prov.dates) {
                for (var j = 0; j < prov.dates.length; j++) {
                  var date = prov.dates[j];
                  if (date.type == "Start") prov.start_date = date.date;
                  else if (date.type == "End") prov.end_date = date.date;
                  else if (date.type == "Associated") prov.associated_date += date.date + "\t";
                }
              }
              entry2.provenance[i].dates = [];
              if (entry2.provenance[i].associated_date.length <= 0) {
                delete entry2.provenance[i].associated_date;
              }
            }
          }

          console.log(angular.toJson(entry1), angular.toJson(entry2));
          // note: changing a numerical field, then restoring the original and saving will still trigger 'unsaved' because one is a string and the other is a number (in the JSON)
          return angular.toJson(entry1) !== angular.toJson(entry2);
        }

        // unfortunately, this can't be reworked with a modal, because browser/javascript doesn't let you
        $(window).bind('beforeunload', function() {
            if ($scope.warnWhenLeavingPage && $scope.checkForChanges($scope.originalEntryViewModel, $scope.entry)) {
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

        $http.get("/groups.json").then( function (result) {          
            $scope.groups = result.data;
          }
        );

        $http.get("/entries/types/").then(
            function(result) {

                $scope.optionsSaleAgentRole = result.data.sale_agent_role;
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
                    if (sourceId) {
                      Source.get(
                          {id: sourceId},
                          function(source) {
                              $scope.entry.source = source;
                              $scope.populateEntryViewModel($scope.entry);
                          },
                          sdbmutil.promiseErrorHandlerFactory("Error loading Source data for this page")
                      );
                    }
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

    sdbmApp.directive("encourageNameAuthority", function ($http, $parse, $timeout, $modal) {
      return function (scope, element, attrs) {
        var modelName = attrs.encourageNameAuthorityModel;
        var nameType = attrs.encourageNameAuthorityName;
        
        $(element).html('<span class="glyphicon glyphicon-warning-sign"></span> <span class="show-hover">You have not selected an authority name. <a href="#" class="close" data-dismiss="alert" aria-label="close">&times;</a></span>');

        scope.$watch(modelName, function(newValue, oldValue) {
          $(element).hide();
          if (newValue.observed_name && newValue.observed_name.length > 0) {
            if (!newValue[nameType] || !newValue[nameType].id) {
              $(element).show();
            }
          }
        }, true);

      }
    });

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
                //console.log(valueToAssign);
            };

            var eraseModel = function() {
              var model = $parse(modelName);
              model.assign(scope, null);
            };

            var refocus = function(badValue) {

                // TODO: calling focus() directly here doesn't work in
                // Firefox (but works in Chrome). Using setTimeout()
                // is susceptible to race conditions with the
                // browser's default handling of tab key, but in
                // practice, it works.  Need to find a better way.
                
                /*setTimeout(function() {
                    $(element).focus();
                }, 100);*/

                //console.log(element, badValue, $(element), $(element).tooltip);
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
                            option.label = option.username;
                            option.value = option.id;

                            if(!exactMatch) {
                                exactMatch = searchTerm === option.label;
                            }
                        });
                        if (!exactMatch && controller) {
                            options.unshift({
                                label: "\u00BB Propose '" + searchTerm + "'",
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
                if ($(element).val() == "") {}
                else if(invalidInput) {
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
                                        //scope.$apply();
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
                                //scope.$apply();
                            }
                        } else {
                            // whitespace or empty field - the user tried to erase the name entered, so let them
                            $(element).val("");
                            eraseModel();
                            invalidInput = false;
//                            assignToModel(null);
                           // scope.$apply();
                        }
                    } else {
                        invalidInput = false;
                    }
                    //console.log(scope.form);
                    if (scope.form && scope.form.source_agent)
                    {
                      scope.form.source_agent.$setValidity('text', !invalidInput);
                    }
                    scope.$apply();
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
                    }
                    invalidInput = false;
                    scope.$apply();
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
                                var msg = "Warning! An entry with that catalog number may already exist <a target='_blank' href='http://localhost:3000/catalog?utf8=%E2%9C%93&op=AND&catalog_or_lot_number%5B%5D=" + cat_lot_no + "&source%5B%5D=SDBM_SOURCE_" + scope.entry.source.id + "&sort=entry_id+asc&search_field=advanced&commit=Search'>(see here)</a>.";
                                var editMode = !!scope.entry.id;
                                if (editMode) {
                                    msg = "Warning! An entry with that catalog number may already exist <a target='_blank' href='http://localhost:3000/catalog?utf8=%E2%9C%93&op=AND&catalog_or_lot_number%5B%5D=" + cat_lot_no + "&source%5B%5D=SDBM_SOURCE_" + scope.entry.source.id + "&sort=entry_id+asc&search_field=advanced&commit=Search'>(see here)</a>.";
                                    results.forEach(function (result) {
                                        if(result.id == scope.entry.id) {
                                            // search returned the entry we're editing, so don't warn
                                            msg = null;
                                        }
                                    });
                                }
                                if(msg) {
                                    $("#cat_lot_no_warning").html(msg);
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

//    sdbmApp.controller("SourceCtrl", function ($scope, $http, $modal, Source, sdbmutil) {
    sdbmApp.controller('SourceCtrl', function ($scope, $http, $modal, Source, sdbmutil) {

        $scope.cancel = function () {
          $scope.modalInstance.close();
        }
        EntryScope = $scope;

        $scope.selectNameAuthorityModal = function (recordType, model, role, type) {
          if ($scope.mergeEdit !== false) {
            model.agent = {id: null};
            model.role = role;
            var m = model.agent;
            var modal = $modal.open({
                templateUrl: "selectNameAuthority.html",
                controller: "SelectNameAuthorityCtrl",
                resolve: {
                  recordType: function () { return recordType },
                  model: function () { return m },
                  type: function () { return type },
                  base: ""
                },
                size: 'lg'
            });
          }
        }


        $scope.removeNameAuthority = function (model, submodel) {
          if ($scope.mergeEdit !== false) {
            model[submodel] = null;
            model['observed_name'] = null;
          }
        }

        // store in scope, otherwise angular template code can't
        // get a reference to this


        $scope.beginMergeEdit = function () {
          $('.merge-into').removeClass('no-edit'); 
          $scope.backupSource = angular.copy($scope.source);
          $scope.mergeEdit = true;
          //console.log(1, $scope.source_agent); 
        };
        $scope.cancelMergeEdit = function () {
          $('.merge-into').addClass('no-edit');
          $scope.source = $scope.backupSource;
          //$scope.form.source_agent.$setValidity('text', true);
          $scope.mergeEdit = false;
        }
        $scope.confirmMergeEdit = function () {
          if ($scope.form.$valid) {
            $scope.backupSource = undefined;
            $scope.mergeEdit = false;
            $scope.save();
            $('.merge-into').addClass('no-edit');
          } else {
            alert('Error: invalid input detected.');
          }
        }

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

        $scope.source_type = $scope.source ? $scope.source.source_type : "";
        $scope.source = undefined;

        $scope.source_agents = [];

        $scope.addRecord = function (anArray) {
          anArray.push({});
        };

        $scope.removeRecord = function (anArray, record) {
          var doremove = function (anArray, record) {
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
          };
          if (sdbmutil.isBlankThing(record)) doremove(anArray, record);
          else {            
            dataConfirmModal.confirm({
              title: 'Confirm',
              text: 'Are you sure you want to remove this field and its contents?',
              commit: 'Yes',
              cancel: 'Cancel',
              zIindex: 10099,
              onConfirm: function() { doremove(anArray, record); $scope.$apply(); },
              onCancel:  function() { }
            });
          }
        };

        $scope.activeRecords = function(element) {
            return !element._destroy;
        };

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
            return 'Create a New ' + sourceTypeForTitle;
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
                if (!source.source_agents) return;
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
            if (window.location.pathname.indexOf('merge') != -1) {
              return;    
            }

            if ($scope.model) { 
              Source.get(
                {id: source.id},
                function(source) {
                    $scope.model.source = source;
                    $scope.modalInstance.close();
                    //$scope.populateEntryViewModel(model);
                    return;
                },
                sdbmutil.promiseErrorHandlerFactory("Error loading Source data for this page")
              );
              return;
            }

            $scope.source = source;
            $scope.populateSourceViewModel($scope.source);
            
            // if this source has been created to add an entry to a Manuscript record
            if (sdbmutil.getManuscriptId() || sdbmutil.getNewManuscript()) {
              sdbmutil.redirectToEntryCreatePage(source.id);
              return;
            }

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

        $scope.save = function (merging) {
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

            /*sourceToSave.source_agents = [];
            $scope.agent_role_types.forEach(function (role) {
                if (sourceToSave[role]) {
                    sourceToSave[role].role = role;
                    sourceToSave.source_agents.push(sourceToSave[role]);
                    delete sourceToSave[role];
                }
            });*/

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
                if (sourceToSave.source_type_id == 4) {
                  $scope.createSource($scope.sourceToSave);
                }
                else {                  
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
            }
        };

        // "constructor" for controller goes here

        SDBM.disableFormSubmissionOnEnter('#source-form');

        $scope.sourceTypeChange = function () {
          if ($scope.source && $scope.source.source_type) {
            if ($scope.source.source_type.name == 'online')
              $scope.source.medium = 'internet';
            else
              $scope.source.medium = '';
            $scope.source.source_agents = [];
          }
        };

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
                    var today = new Date();
                    var month = today.getMonth() + 1;
                    month = month < 10 ? "0" + month : month;
                    var date = today.getDate() < 10 ? "0" + today.getDate() : today.getDate();
                    var todayString = today.getFullYear() + "-" + month + "-" + date;
                    var source_type = $scope.optionsSourceType.filter(function (e) { return e.id == $scope.source_type });
                    source_type = source_type.length == 1 ? source_type[0] : "";
                    $scope.source = new Source({ source_type: source_type || "", date_accessed: todayString, date: source_type.id == 4 ? todayString : "" });
                }
                $scope.source.source_agents = [];
                if ($scope.user) {
                  $scope.source.author = $scope.user;
                }

                if ($scope.model && $scope.model.source) {
                  $scope.source_type = $scope.model.source.source_type;
                  $scope.source = {source_type: $scope.model.source.source_type, source_type_id: $scope.model.source.source_type.id};
                  $scope.sourceTypeChange();
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
    
    var baseSelectNameAuthorityModalCtrl = function ($scope, $http, $modalInstance, sdbmutil) {

    }

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
                $scope.saveResponse
            );
        };

        $scope.saveResponse = function(response) {
          $scope.saveError = sdbmutil.parseRailsErrors(response.data.errors).join("; ") || "Unknown Error";
        }

        $scope.useExisting = function (entity) {
          $modalInstance.close(entity);
        }

        $scope.cancel = function () {
            $modalInstance.dismiss('cancel');
        };
    };

    sdbmApp.controller('CreateNameModalCtrl', function ($scope, $http, $modalInstance, $modal, sdbmutil, modalParams, Name) {
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

        $scope.goBack = function () {
          $modalInstance.close();
          if (modalParams.back) {
            var modal = $modal.open({
                templateUrl: "selectNameAuthority.html",
                controller: "SelectNameAuthorityCtrl", //112
                resolve: {
                  recordType: function () { return modalParams.back.recordType },
                  model: function () { return modalParams.back.model },
                  type: function () { return modalParams.back.type },
                  base: function () { return modalParams.name }
                },
                size: 'lg'
            });
          }
        }

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


        $scope.saveResponse = function(response) {
          //console.log(response);
          $scope.errors = [];
          $scope.saveError = [];
          if (response.data.errors.name) {
            for (var i = 0; i < response.data.errors.name.length; i++) {
              $scope.saveError += response.data.errors.name[i].message + "\n";
              if (!response.data.errors.name[i].message) response.data.errors.name[i] = { message: response.data.errors.name[i]};
              $scope.errors.push(response.data.errors.name[i]);
            }
          }
          if (response.data.errors.viaf_id) {
            for (var i = 0; i <  response.data.errors.viaf_id.length; i++) {
              $scope.saveError +=  response.data.errors.viaf_id[i].message + "\n";
              $scope.errors.push(response.data.errors.viaf_id[i]);
            }
          }
          //$scope.saveError = sdbmutil.parseRailsErrors(response.data.errors).join("; ") || "Unknown Error";
        }
    });

    sdbmApp.controller('CreateLanguageModalCtrl', function ($scope, $http, $modalInstance, $modal, sdbmutil, modalParams, Language) {
        $scope.entityFactory = function() { return new Language(); };

        $scope.entity_attributes = function(entity) {
            entity.name = modalParams.name;
        };

        $scope.goBack = function () {
          $modalInstance.close();
          if (modalParams.back) {
            var modal = $modal.open({
                templateUrl: "selectModelAuthority.html",
                controller: "SelectNameAuthorityCtrl", //112
                resolve: {
                  recordType: function () { return modalParams.back.recordType },
                  model: function () { return modalParams.back.model },
                  type: function () { return modalParams.back.type }
                },
                size: 'lg'
            });
          }
        }

        baseCreateEntityModalCtrl($scope, $http, $modalInstance, sdbmutil);

        $scope.entityName = "language";
    });

    sdbmApp.controller('CreatePlaceModalCtrl', function ($scope, $http, $modalInstance, $modal, sdbmutil, modalParams, Place) {
        $scope.entityFactory = function() { return new Place(); };

        $scope.entity_attributes = function(entity) {
            entity.name = modalParams.name;
        };

        $scope.goBack = function () {
          $modalInstance.close();
          if (modalParams.back) {
            var modal = $modal.open({
                templateUrl: "selectModelAuthority.html",
                controller: "SelectNameAuthorityCtrl", //112
                resolve: {
                  recordType: function () { return modalParams.back.recordType },
                  model: function () { return modalParams.back.model },
                  type: function () { return modalParams.back.type }
                },
                size: 'lg'
            });
          }
        }

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

 sdbmApp.controller('ManageBookmarks', function ($scope, $sce, $location, $http) {

    BOOKMARK_SCOPE = $scope;

    $scope.removetag = function (bookmark, tag) {
      var index = bookmark.tags.indexOf(tag);
      if (index != -1) {
        bookmark.tags.splice(index, 1);
        $http.get('/bookmarks/' + bookmark.id + '/removetag?tag=' + tag).then( function (e) {
        });
      }
    }
    $scope.addtag = function (bookmark, tag) {
      if (tag.length <= 0) return;
      if (bookmark.tags.indexOf(tag) == -1) {
        bookmark.tags.push(tag);
        bookmark.newtag = "";
        $http.get('/bookmarks/' + bookmark.id + '/addtag?tag=' + tag).then( function (e) {
          //console.log(e);
        });
      }
    }

    $scope.searchTag = function (tag) {
      $('input[name=tag-search]').val(tag);
      $scope.search_tag = tag;
      if (!$scope.search_tag || $scope.search_tag.length <= 0) {
        $scope.all_bookmarks_display = $scope.all_bookmarks;
      } else {        
        $scope.all_bookmarks_display = {};
        for (var key in $scope.all_bookmarks) {
          $scope.all_bookmarks_display[key] = [];
          for (var i = 0; i < $scope.all_bookmarks[key].length; i++) {
            if ($scope.all_bookmarks[key][i].tags.indexOf($scope.search_tag) != -1) {
              $scope.all_bookmarks_display[key].push($scope.all_bookmarks[key][i]);
            }
          }
        }
      }
    }

    $scope.loadBookmarks = function () {
      $http.get('/bookmarks/reload.json?details=true').then( function (e) {
        if (e.error) return;
        
        $scope.all_bookmarks = e.data.bookmarks;
        $scope.all_bookmarks_display = $scope.all_bookmarks;
        $scope.bookmark_tracker = e.bookmark_tracker;
        if ($scope.search_tag && $scope.search_tag.length > 0) {
          $scope.searchTag($scope.search_tag);
        }
      });
    }

    $scope.removeBookmark = function (name, bookmark) {
      var i = $scope.all_bookmarks[name].indexOf(bookmark);
      if (i >= 0) {
        $.ajax({url: '/bookmarks/' + bookmark.id, method: 'delete'}).done( function (e) {
          $scope.all_bookmarks[name].splice(i, 1);
          var id = bookmark.document_id, type = bookmark.document_type;
          $scope.$apply();        
          $scope.searchTag($scope.search_tag);
          addNotification(type + ' ' + id + ' un-bookmarked! <a data-dismiss="alert" aria-label="close" onclick="addBookmark(' + id + ',\'' + type + '\')">Undo</a>', 'warning');
        }).error( function (e) {
          console.log('error', e);
        });
      }
    }

    $scope.addBookmark = function (id, type) {
      // check if already in bookmarks
      var b = $scope.findBookmark(type, id);
      if (b) {
        $scope.removeBookmark(type, b);
        return;
      }
      $.ajax({url: '/bookmarks/new', data: {document_id: id, document_type: type}}).done( function (e) {
        if (!e.error && $scope.all_bookmarks[type]) {
          $scope.active = type;
          $scope.all_bookmarks[type].unshift(e);
          $scope.$apply();
          $scope.searchTag($scope.search_tag);
          addNotification(type + ' ' + id + ' bookmarked! <a data-dismiss="alert" aria-label="close" onclick="addBookmark(' + id + ',\'' + type + '\')">Undo</a>', 'success');
        } else {
          console.log(e.error);
        }
      }).error( function (e) {
        console.log("error: ", e);
      });
      return false;
    }

    $scope.renew = function () {
      $('.bookmark-link').css({color: ""});
      for (var i = 0; i < $scope.tabs.length; i++) {
        var type = $scope.tabs[i];
        for (var j = 0; j < $scope.all_bookmarks[type].length; j++) {
          var link = $scope.all_bookmarks[type][j].link;
          $('.bookmark-link[in_bookmarks="' + link + '"]').css({color: "gold"});
        }
      }

      $scope.saveLocalStorage();
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
      if (!link) {
        alert('There is nothing to export.');
        return false;
      }
      var plural = link.split('/')[1];
      if (type != "Entry") plural += "/search";
      var url = "/" + plural + ".csv?op=OR&search_field=advanced&per_page=5000";
      for (var i = 0; i < $scope.all_bookmarks[type].length; i++) {
        if (type == "Entry")
          url += "&entry_id[]=" + $scope.all_bookmarks[type][i].document_id;
        else
          url += "&id[]=" + $scope.all_bookmarks[type][i].document_id;  
      }

      exportCSV(url);
    }

    $scope.toggleSidebar = function (skip) {
      if (!skip) $('.sidebar, .main-content').addClass('transition');
      $('.sidebar').toggleClass('in');
      $('.main-content').toggleClass('in');
      setTimeout(function () {
        if ($('.sidebar').hasClass('in')) {
          $('.toggle-sidebar').html('<span class="glyphicon glyphicon-remove"></span>');
          localStorage.sidebar_open = "true";
        } else {
          $('.toggle-sidebar').html('<span class="glyphicon glyphicon-bookmark"></span>');
          localStorage.sidebar_open = "false";
        }
        $('.sidebar, .main-content').removeClass('transition');
      }, 500);
    }

    // should this be fixed, eventually?  is there any reason for this to be here, instead of hard-coded?
    $scope.tabs = ["Entry", "Manuscript", "Name", "Source"];
    $scope.all_bookmarks = {Entry: [], Manuscript: [], Name: [], Source: []};

    // load tag from url
    if (window.location.search && window.location.search.indexOf('tag=') != -1) {
      var search  = decodeURIComponent(window.location.search.split('tag=')[1]);
      $scope.tagSearch = search;
      $scope.searchTag(search);
    }

    $scope.addTabToStorage = function (name) {
      $scope.active = name;
      if (localStorage) localStorage.sidebar_tab = name;
    }

    if (localStorage && localStorage.sidebar_open == "true" && $('.sidebar').length > 0) {
      $scope.toggleSidebar(true);
    }

    $scope.loadBookmarks();
    
  });

}());
//function toggleSidebar() 

function exportCSV(url) {
  $.get(url).done(function (e) {
      if (e.error) {
          if (e.error == "at limit") {
              addNotification("You have reached your export limit.  Download or delete some of your exports <a href='/downloads/'>here</a>.", "danger");
          }
          return;
      }

      var myDownloadComplete = false;
      $('#user-nav a').css({color: 'green'});
      addNotification("CSV Export is being prepared...", "info");
      var download = JSON.parse(e);
      var url = "/downloads/" + download.id;
      var count = 0;
      var interval = setInterval( function () {
          $.ajax({url: url, data: {ping: true}}).done( function (r) {
              //window.location = url;
              if (r != "in progress" && !myDownloadComplete) {
                  addNotification(download.filename + " is ready - <a href='" + url + "'>download file</a>", "success", true);
                  $('#user-nav a').css({color: ''});
                  $('#downloads-count').text(download.count);
                  window.clearInterval(interval);
                  myDownloadComplete = true;
              } else {
                  count += 1;
              }

              if (count > 1000) window.clearInterval(interval);                    
          }).error( function (r) {
              console.log('error', r);
              window.clearInterval(interval);
          });
      }, 1000);
  }).error( function (e) {
      console.log('error', e);
  })
}

function addNotification (message, type, permanent) {
  var notification = $('<div><a class="close" data-dismiss="alert" aria-label="close">&times;</a>' + message + "</div>");
  notification.addClass('alert').addClass('alert-' + type).addClass('alert-absolute');
  
  notification.hide();
  $('.alerts-absolute').append(notification);
  notification.fadeIn();
  
  if (!permanent) {
    setTimeout(function () {
      notification.fadeOut('slow', function () {
        notification.remove();
      });
    }, 10000)
  } // fade out after ten seconds;
}

// this works!  maybe not a good idea?
function addBookmark(id, type) {
  //BOOKMARK_SCOPE.addBookmark(id, type);
  // if removed, have one 
  //addNotification(type + " " + id + " bookmarked! <span onclick='addBookmark(" + id + ',"' + type + "\")'>Undo<span>", 'info' );
}
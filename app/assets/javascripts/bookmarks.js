/*(function () {
  console.log('here')
  var bookmarks = angular.module('bookmarks', []);
  bookmarks.controller('ManageBookmarks', function ($scope) {
    $scope.removetag = function (bookmark, tag) {
      $.get('/bookmarks/' + bookmark.id + '/removetag', {tag: tag}).done( function (e) {
        bookmark.tags = e.tags;
        $scope.$apply();
      });
    }
    $scope.addtag = function (bookmark, tag) {
      $.get('/bookmarks/' + bookmark.id + '/addtag', {tag: tag}).done( function (e) {
        bookmark.tags = e.tags;
        bookmark.newtag = "";
        $scope.$apply();
      });
    }
    $scope.removeBookmark = function (name, bookmark) {
      var i = $scope.all_bookmarks[name].indexOf(bookmark);
      if (i >= 0) {
        $.ajax({url: '/bookmarks/' + bookmark.id, method: 'delete'}).done( function (e) {
          console.log('done', e);
          $scope.all_bookmarks[name].splice(i, 1);
          $scope.$apply();
        }).error( function (e) {
          console.log('error', e);
        });
      }
    }
    $scope.searchTag = function (tag) {
      $.get('/bookmarks/reload.json', {tag: tag}).done( function (e) {
        $scope.all_bookmarks = e;
        $scope.$digest();
      }).error( function (e) {
        console.log('error.', e);
      });
    }
    $scope.tabs = ["Entry", "Manuscript", "Name", "Source"];
    $scope.searchTag("");
  });
}());*/
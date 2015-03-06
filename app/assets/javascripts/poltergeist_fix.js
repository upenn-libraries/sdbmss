// TODO: PhantomJS, as of 1.9.8, doesn't support
// Function.prototype.bind() so we use this shim. This may be fixed in
// newer versions of PhantomJS/Webkit but no known (newer) version is
// specified in the bug.

// https://github.com/teampoltergeist/poltergeist/issues/292
if(typeof Function.prototype.bind == 'undefined') {
  Function.prototype.bind = function(target) {
    var f = this;
    return function() {
      f.apply(target, arguments);
    };
  };
}

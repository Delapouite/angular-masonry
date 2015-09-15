/*!
 * angular-masonry 0.12.0
 * Pascal Hartig, weluse GmbH, http://weluse.de/
 * License: MIT
 */
(function () {
  'use strict';
  angular.module('wu.masonry', []).controller('MasonryCtrl', [
    '$scope',
    '$element',
    '$timeout',
    function controller($scope, $element, $timeout) {
      var bricks = {};
      var schedule = [];
      var destroyed = false;
      var self = this;
      var masonry = null;
      // id
      var timeout = null;
      // in ms
      this.scheduleTimeout = 30;
      this.preserveOrder = false;
      this.loadImages = true;
      $scope.$on('masonry.created', function () {
        masonry = $scope.masonry;
      });
      this.scheduleMasonryOnce = function scheduleMasonryOnce() {
        var args = arguments;
        var found = schedule.some(function someFn(item) {
            return item[0] === args[0];
          });
        if (!found) {
          this.scheduleMasonry.apply(this, arguments);
        }
      };
      // Make sure it's only executed once within a reasonable time-frame in
      // case multiple elements are removed or added at once.
      this.scheduleMasonry = function scheduleMasonry() {
        if (timeout) {
          $timeout.cancel(timeout);
        }
        schedule.push([].slice.call(arguments));
        timeout = $timeout(function runMasonry() {
          if (destroyed) {
            return;
          }
          schedule.forEach(function scheduleForEach(args) {
            masonry[args]();
          });
          schedule = [];
        }, this.scheduleTimeout);
      };
      function defaultLoaded($element) {
        $element.addClass('loaded');
      }
      this.appendBrick = function appendBrick(id, element) {
        if (destroyed) {
          return;
        }
        function _append() {
          if (Object.keys(bricks).length === 0) {
            masonry.resize();
          }
          if (bricks[id] === undefined) {
            // Keep track of added elements.
            bricks[id] = true;
            defaultLoaded(element);
            masonry.appended(element);
          }
        }
        function _layout() {
          // I wanted to make this dynamic but ran into huuuge memory leaks
          // that I couldn't fix. If you know how to dynamically add a
          // callback so one could say <masonry loaded="callback($element)">
          // please submit a pull request!
          self.scheduleMasonryOnce('layout');
        }
        function _appendLayout() {
          _append();
          _layout();
        }
        if (!self.loadImages) {
          _appendLayout();
        } else if (self.preserveOrder) {
          _append();
          imagesLoaded(element, _layout);
        } else {
          imagesLoaded(element, _appendLayout);
        }
      };
      this.removeBrick = function removeBrick(id, element) {
        if (destroyed) {
          return;
        }
        delete bricks[id];
        masonry.remove(element);
        this.scheduleMasonryOnce('layout');
      };
      this.destroy = function destroy() {
        destroyed = true;
        // Gently uninitialize if still present
        masonry.destroy();
        $scope.$emit('masonry.destroyed');
        bricks = {};
      };
      this.reload = function reload() {
        masonry.layout();
        $scope.$emit('masonry.reloaded');
      };
    }
  ]).directive('masonry', function masonryDirective() {
    return {
      restrict: 'AE',
      controller: 'MasonryCtrl',
      scope: true,
      link: {
        pre: function preLink(scope, element, attrs, ctrl) {
          // read options and set defaults
          var attrOptions = scope.$eval(attrs.masonry || attrs.masonryOptions);
          var options = angular.extend({
              itemSelector: attrs.itemSelector || '.masonry-brick',
              columnWidth: parseInt(attrs.columnWidth, 10) || attrs.columnWidth
            }, attrOptions || {});
          scope.masonry = new Masonry(element[0], options);
          ctrl.scheduleTimeout = parseInt(attrs.scheduleTimeout, 10) && ctrl.scheduleTimeout;
          var loadImages = scope.$eval(attrs.loadImages);
          ctrl.loadImages = loadImages !== false;
          var preserveOrder = scope.$eval(attrs.preserveOrder);
          ctrl.preserveOrder = preserveOrder !== false && attrs.preserveOrder !== undefined;
          var reloadOnShow = scope.$eval(attrs.reloadOnShow);
          if (reloadOnShow !== false && attrs.reloadOnShow !== undefined) {
            scope.$watch(function () {
              return element.prop('offsetParent');
            }, function (isVisible, wasVisible) {
              if (isVisible && !wasVisible) {
                ctrl.reload();
              }
            });
          }
          var reloadOnResize = scope.$eval(attrs.reloadOnResize);
          if (reloadOnResize !== false && attrs.reloadOnResize !== undefined) {
            scope.$watch('masonryContainer.offsetWidth', function (newWidth, oldWidth) {
              if (newWidth !== oldWidth) {
                ctrl.reload();
              }
            });
          }
          scope.$emit('masonry.created', element);
          scope.$on('$destroy', ctrl.destroy);
        }
      }
    };
  }).directive('masonryBrick', function masonryBrickDirective() {
    return {
      restrict: 'AC',
      require: '^masonry',
      scope: true,
      link: {
        pre: function preLink(scope, element, attrs, ctrl) {
          var id = scope.$id, index;
          ctrl.appendBrick(id, element);
          element.on('$destroy', function () {
            ctrl.removeBrick(id, element);
          });
          scope.$on('masonry.reload', function () {
            ctrl.scheduleMasonryOnce('reloadItems');
            ctrl.scheduleMasonryOnce('layout');
          });
          scope.$watch('$index', function () {
            if (index !== undefined && index !== scope.$index) {
              ctrl.scheduleMasonryOnce('reloadItems');
              ctrl.scheduleMasonryOnce('layout');
            }
            index = scope.$index;
          });
        }
      }
    };
  });
}());
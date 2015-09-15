describe 'angular-masonry', ->

  controllerProvider = null

  beforeEach module('wu.masonry')
  beforeEach module((_$controllerProvider_) ->
    controllerProvider = _$controllerProvider_
    null
  )

  beforeEach inject(($rootScope) =>
    @scope = $rootScope.$new()
  )

  it 'should initialize', inject(($compile) =>
    element = angular.element '<masonry></masonry>'
    element = $compile(element)(@scope)
  )

  it 'should call masonry on init', inject(($compile) =>
    element = angular.element '<div masonry></div>'
    element = $compile(element)(@scope)
    masonry = element.scope().masonry

    expect(masonry).toBeDefined()
  )

  it 'should pass on the column-width attribute', inject(($compile) =>
    element = angular.element '<masonry column-width="200"></masonry>'
    element = $compile(element)(@scope)
    masonry = element.scope().masonry

    expect(masonry).toBeDefined()
    expect(masonry.options.columnWidth).toBe 200
  )

  it 'should pass on the item-selector attribute', inject(($compile) =>
    element = angular.element '<masonry item-selector=".mybrick"></masonry>'
    element = $compile(element)(@scope)
    masonry = element.scope().masonry

    expect(masonry).toBeDefined()
    expect(masonry.options.itemSelector).toBe '.mybrick'
  )

  it 'should pass on any options provided via `masonry-options`', inject(($compile) =>
    element = angular.element '<masonry masonry-options="{ isOriginLeft: true }"></masonry>'
    element = $compile(element)(@scope)
    masonry = element.scope().masonry

    expect(masonry).toBeDefined()
    expect(masonry.options.isOriginLeft).toBeTruthy()
  )

  it 'should pass on any options provided via `masonry`', inject(($compile) =>
    element = angular.element '<div masonry="{ isOriginLeft: true }"></div>'
    element = $compile(element)(@scope)
    masonry = element.scope().masonry

    expect(masonry).toBeDefined()
    expect(masonry.options.isOriginLeft).toBeTruthy()
  )

  it 'should setup a $watch when the reload-on-show is present', inject(($compile) =>
    sinon.spy(@scope, '$watch')
    element = angular.element '<masonry reload-on-show></masonry>'
    element = $compile(element)(@scope)

    expect(@scope.$watch).toHaveBeenCalled()
  )

  it 'should not setup a $watch when the reload-on-show is missing', inject(($compile) =>
    sinon.spy(@scope, '$watch')
    element = angular.element '<masonry></masonry>'
    element = $compile(element)(@scope)

    expect(@scope.$watch).not.toHaveBeenCalled()
  )

  it 'should setup a $watch when the reload-on-resize is present', inject(($compile) =>
    sinon.spy(@scope, '$watch')
    element = angular.element '<masonry reload-on-resize></masonry>'
    element = $compile(element)(@scope)

    expect(@scope.$watch).toHaveBeenCalledWith('masonryContainer.offsetWidth', sinon.match.func );
  )

  it 'should not setup a $watch when the reload-on-resize is missing', inject(($compile) =>
    sinon.spy(@scope, '$watch')
    element = angular.element '<masonry></masonry>'
    element = $compile(element)(@scope)

    expect(@scope.$watch).not.toHaveBeenCalledWith('masonryContainer.offsetWidth', sinon.match.func );
  )

  describe 'MasonryCtrl', =>
    beforeEach inject(($compile) =>
      element = angular.element '<masonry></masonry>'
      element = $compile(element)(@scope)

      @ctrl = element.controller('masonry')
      @masonry = element.scope().masonry

      spyOn(@masonry, 'remove')
      spyOn(@masonry, 'appended')
    )

    it 'should not remove after destruction', =>
      @ctrl.destroy()
      @ctrl.removeBrick()

      expect(@masonry.remove).not.toHaveBeenCalled()

    it 'should not add after destruction', =>
      @ctrl.destroy()
      @ctrl.appendBrick()

      expect(@masonry.appended).not.toHaveBeenCalled()

  describe 'masonry-brick', =>

    beforeEach =>
      self = this

      @appendBrick = sinon.spy()
      @removeBrick = sinon.spy()
      @scheduleMasonry = sinon.spy()
      @scheduleMasonryOnce = sinon.spy()

      controllerProvider.register('MasonryCtrl', =>
        @appendBrick = self.appendBrick
        @removeBrick = self.removeBrick
        @scheduleMasonry = self.scheduleMasonry
        @scheduleMasonryOnce = self.scheduleMasonryOnce
        this
      )

    it 'should register an element in the parent controller', inject(($compile) =>
      element = angular.element '''
        <masonry>
          <div class="masonry-brick"></div>
        </masonry>
      '''
      element = $compile(element)(@scope)

      expect(@appendBrick).toHaveBeenCalledOnce()
    )

    it 'should remove an element in the parent controller if destroyed', inject(($compile) =>
      @scope.bricks = [1, 2, 3]
      element = angular.element '''
        <masonry>
          <div class="masonry-brick" ng-repeat="brick in bricks"></div>
        </masonry>
      '''
      element = $compile(element)(@scope)
      @scope.$digest() # Needed for initial ng-repeat

      @scope.$apply(=>
        @scope.bricks.splice(0, 1)
      )

      expect(@appendBrick).toHaveBeenCalledThrice()
      expect(@removeBrick).toHaveBeenCalledOnce()
    )

  describe 'masonry-brick internals', =>

    beforeEach inject(($window) ->
      sinon.spy($window, 'imagesLoaded')

    )

    afterEach inject(($window) ->
      $window.imagesLoaded.restore()
    )

    it 'should append three elements to the controller', inject(($compile) =>
      element = angular.element '''
        <masonry>
          <div class="masonry-brick"></div>
          <div class="masonry-brick"></div>
          <div class="masonry-brick"></div>
        </masonry>
      '''
      element = $compile(element)(@scope)
      @scope.$digest()

      expect(@appendBrick).toHaveBeenCalledThrice()
    )

    it 'should append before imagesLoaded when preserve-order is set', inject(($compile, $timeout, $window) =>
      element = angular.element '''
        <masonry preserve-order>
          <div class="masonry-brick"></div>
        </masonry>
      '''
      element = $compile(element)(@scope)
      ctrl = element.controller('masonry')
      sinon.spy(ctrl, 'appendBrick')
      @scope.$digest()

      expect(ctrl.appendBrick).toHaveBeenCalled()
      #expect($window.imagesLoaded).toHaveBeenCalled()
      #expect(@appendBrick).toHaveBeenCalledBefore($window.imagesLoaded)
    )

    it 'should call layout after imagesLoaded when preserve-order is set', inject(($compile, $window) =>
      element = angular.element '''
        <masonry preserve-order>
          <div class="masonry-brick"></div>
        </masonry>
      '''
      element = $compile(element)(@scope)
      @scope.$digest()

      expect(@scheduleMasonryOnce).not.toHaveBeenCalledWith('layout')
      expect($window.imagesLoaded).toHaveBeenCalled()
      expect(@scheduleMasonryOnce).toHaveBeenCalledWith('layout')
    )

    it 'should append before imagesLoaded when load-images is set to "false"', inject(($compile) =>
      element = angular.element '''
        <masonry load-images="false">
          <div class="masonry-brick"></div>
        </masonry>
      '''
      imagesLoadedCb = undefined
      $.fn.imagesLoaded = (cb) -> imagesLoadedCb = cb
      element = $compile(element)(@scope)
      @scope.$digest()
      expect($.fn.masonry.calledWith('appended', sinon.match.any, sinon.match.any)).toBe(true)
    )

    it 'should call layout before imagesLoaded when load-images is set to "false"', inject(($compile, $timeout) =>
      element = angular.element '''
        <masonry load-images="false">
          <div class="masonry-brick"></div>
        </masonry>
      '''
      imagesLoadedCb = undefined
      $.fn.imagesLoaded = (cb) -> imagesLoadedCb = cb
      element = $compile(element)(@scope)
      @scope.$digest()
      $timeout.flush()
      expect($.fn.masonry.calledWith('layout', sinon.match.any, sinon.match.any)).toBe(true)
    )

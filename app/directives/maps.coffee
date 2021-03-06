'use strict'

angular.module 'directives.googleMaps', [
	'cordova.plugin.googleMaps'
]

.directive 'map', [
	'$q', '$document'
	($q, $document) ->
		restrict: 'AE'
		controller: 'mapController'
		controllerAs: 'ctrl'
		scope:
			markers: '='
			centerMapFn: '='
			getMapCenterFn: '='
			onInit: '='
			onMarkerClick: '='
			masked: '='
			image: '='

		link: (scope, element, attrs, ctrl) ->
			ctrl.init element[0]

			scope.$watch 'masked', (masked) ->
				return unless ctrl.Map?.getImage?
				if masked
					ctrl.Map.getImage ctrl.map
					.then (imageData) ->
						scope.image =
							url: imageData
							height: element.parent()[0].clientHeight
							width: element.parent()[0].clientWidth
				else
					scope.image?.url = null

]

.service 'mapData', [->]

.controller 'mapController', [
	'initMaps', '$injector', '$scope', '$q', '$cordovaGeolocation', 'locationMonitor', '$document', 'mapData', '$timeout'
	class MapController

		constructor: (@initMaps, @injector, @scope, @q, @geolocation, @locationMonitor, @document, @savedMapData, @timeout) ->
			angular.extend @scope,
				centerMapFn: @centerOnLocation
				getMapCenterFn: @getView

			@scope.$on '$destroy', @destructor

		init: (element) =>
			@_injectPlugin()
			.then => @_createMap element
			.then (@map) => @onInit()

		_injectPlugin: =>
			@q.when @initMaps
			.then (maps) => @Map = maps
			.catch (error) => alert error

		_createMap: (element) =>
			@Map.getMap element,
				center: @Map.latLng 52, 21
				zoom: 5

		onInit: =>
			@resizeHandler()

			@scope.$watch 'markers', @markersChanged, yes

			if @savedMapData?.coords
				pos = @Map.latLng @savedMapData.coords.latitude, @savedMapData.coords.longitude
				@map.setZoom @savedMapData.zoom
				@Map.moveTo @map, pos

			@scope.onInit?()

			@scope.$on 'MAP_VIEW_CHANGE', =>
				@getView().then (position) =>
					angular.extend @savedMapData, position

		_doCenterOnLocation: => _.debounce (position, fast) =>
			pos = @Map.latLng position.coords.latitude, position.coords.longitude
			@Map[if fast then 'moveTo' else 'panTo'] @map, pos, 14
		, 250

		centerOnLocation: (fast) =>
			@doCenterOnLocation ?= @_doCenterOnLocation()
			if @locationMonitor.lastPosition
				@doCenterOnLocation @locationMonitor.lastPosition, fast
			else
				@geolocation.getCurrentPosition().then (position) =>
					@doCenterOnLocation position, fast

		createCircleForPoints: (center, points) =>
			c =
				lat: center.coords.latitude
				lng: center.coords.longitude
			radius = center.coords.radius
			for point in points
				pt =
					lat: point.lat?() or point.lat
					lng: point.lng?() or point.lng
				distance = @Map.distance(c, pt)
				radius = Math.max distance, radius
			@Map.createCircle @map,
				center: @Map.latLng c.lat, c.lng
				radius: radius
				fillColor: 'rgba(0,0,0,0)'
				strokeColor: 'rgba(255, 0, 0, 0.5)'
				strokeWeight: 2

		doCenterOnMarkers: (position) =>
			@resizeHandler()
			pos = @Map.latLng position.coords.latitude, position.coords.longitude
			@Map.deleteCircle @viewCircle
			points = (@Map.getMarkerPositon marker for marker in @markers)
			@q.all points
			.then (points) =>
				@createCircleForPoints position, points
				.then (circle) =>
					points.push pos
					bounds = @Map.latLngBounds points
					@viewCircle = circle
					@timeout =>
						@resizeHandler()
						@Map.fitBounds @map, bounds

		centerOnMarkers: (position) =>
			return unless @markers
			if position
				@doCenterOnMarkers position
			else
				@getView().then @doCenterOnMarkers

		markersChanged: (markers) =>
			return unless markers?
			@cleanMarkers()
			return unless markers.points?.length
			promises = (@createMarker marker for marker in markers.points)
			@q.all promises
			.then (_markers) =>
				@markers = _markers
				@centerOnMarkers markers.center
				return @markers

		getView: => @Map.getView @map

		cleanMarkers: =>
			return unless @markers?.length
			if @map.clear?
				@map.clear()
				@map.off()
				return

			for marker, i in @markers
				@removeMarker marker
				delete @markers[i]

		removeMarker: (marker) =>
			@Map.deleteMarker marker

		createMarker: (marker) =>
			name = marker.wards.length if marker.wards?.length > 1
			name ?= '_' if marker.wards[0].no is 0
			suffix = '_d' if _.every marker.wards, protocolStatus: 'CONFIRMED'

			m = @Map.createMarker @map,
				position: @Map.latLng marker.location.latitude, marker.location.longitude
				icon:
					url: "img/marker#{suffix or ''}#{name or ''}.png"
					size:
						width: Math.round((58/2) * (0.85))
						height: Math.round((83/2) * (0.85))
			m.then (el) =>
				@Map.onMarkerClick el, => @onMarkerClick marker
			return m

		onMarkerClick: (marker) =>
			@scope.onMarkerClick marker

		resizeHandler: =>
			@Map.resize @map

		destructor: =>
			@getView().then (position) =>
				angular.extend @savedMapData, position
				@cleanMarkers()
]



'use strict'

angular.module 'main.data', [
]

.service 'ApplicationData', [
	'$rootScope'
	'VotingsResources'
	class ApplicationData
		markers: []
		votings: []
		ballots: []
		count: 2
		selectedVoting: null
		selectedWards: []
		constructor: ($rootScope, @resources) ->
			@getWards = _.debounce @_getWards, 250

			@votings = @resources.getVotings()
			@votings.$promise.then =>
				@selectedVoting ?= @votings[0].date

			$rootScope.$watch =>
				@selectedVoting
			, => if @selectedVoting
				@getBallots()

		_getWards: (position, date) =>
			@markers = []
			@resources.getWards
				date: @selectedVoting
				latitude: position.coords.latitude
				longitude: position.coords.longitude
				radius: Math.min(5000, position.coords.radius / 2 or 0)
				minCount: @count
			.$promise.then (values) =>
				if values.length
					@markers = _.chain(values)
					.groupBy (marker) ->
						[marker.location.latitude, marker.location.longitude]
					.map (group) ->
						location: group[0].location
						wards: group
					.value()

		getBallots: =>
			@ballots = @resources.getBallots
				date: @selectedVoting

		saveProtocol: (protocol) =>
			@resources.saveProtocol angular.extend
				date: @selectedVoting
			, protocol

]

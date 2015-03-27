'use strict'

angular.module 'main.controllers.ward', [
	'RequestContext'
	'main.resources.cloudinary'
	'main.controllers.ballot'
]

.controller 'WardController', [
	'$scope'
	'RenderContextFactory'
	'ApplicationData'
	'$cordovaCamera'
	'CloudinaryResources'
	'$location'

	class WardController
		constructor: (@scope, RenderContext, @data, @camera, @cloudinary, @location) ->
			renderContext = new RenderContext @scope, 'ward', ['community', 'no']

			@scope.$watch =>
				@wardNo
			, =>
				@ward = _.find @data.selectedWards, no: @wardNo

			@scope.$on "requestContextChanged", =>
				return unless renderContext.isChangeRelevant()
				@init(renderContext)

			@init renderContext

			if @data.ballots.length is 1
				@location.replace()
				@openBallot @data.ballots[0]

		openBallot: (ballot) =>
			@location.path "/wards/#{@communityCode}/#{@wardNo}/ballots/#{ballot.no}"

		init: (renderContext) =>
			@communityCode = renderContext.getParamAsInt 'community'
			@wardNo = renderContext.getParamAsInt 'no'

]
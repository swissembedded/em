angular.module('appRoutes', []).config(['$routeProvider', '$locationProvider', function($routeProvider, $locationProvider) {

	$routeProvider

		// home page
		.when('/', {
			templateUrl: 'views/home.html',
			controller: 'MainController'
		})

		.when('/nerds', {
			templateUrl: 'views/nerd.html',
			controller: 'NerdController'
		})

		.when('/geeks', {
			templateUrl: 'views/geek.html',
			controller: 'GeekController'	
		})

		.when('/temperature-list', {
			templateUrl: 'views/temperature-list.html',
			controller: 'TemperatureListController'	
		})
		
		.when('/add-device', {
			templateUrl: 'views/add-device.html',
			controller: 'DeviceController'	
		});


	$locationProvider.html5Mode(true);

}]);
angular.module('appRoutes', []).config(['$routeProvider', '$locationProvider', function($routeProvider, $locationProvider) {

	$routeProvider

		// home page
		.when('/', {
			templateUrl: 'views/home.html',
			controller: 'MainController'
		})

		.when('/temperature-list', {
			templateUrl: 'views/temperature-list.html',
			controller: 'TemperatureListController'	
		})
		
		.when('/add-device', {
			templateUrl: 'views/add-device.html',
			controller: 'DeviceController'	
		})

		.when('/list-devices', {
			templateUrl: 'views/list-devices.html',
			controller: 'ListDevicesController'	
		})
		;


		$locationProvider.html5Mode(true);

	}]);
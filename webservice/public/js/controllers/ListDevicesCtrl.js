angular.module('ListDevicesCtrl', ['geolocation', 'gservice']).controller('ListDevicesController', function($scope,$http, $timeout,geolocation, gservice) {

	$scope.title = "Device List";

	$scope.getData = function(){
		var req = $http({
			method : "GET",
			url : "/getDevices"
		})
		.then(function(response) {
	
			$scope.list = response.data;

			  //Refresh map
			    var selectedLat = 47.23;
        var selectedLong = -8.04;

		gservice.refresh(selectedLat, selectedLong);

		})
		.catch(function(response) {
			console.error('Gists error', response.status, response.data);
		})
		.finally(function() {
			console.log("finally finished gists");
		})
	}

// Function to replicate setInterval using $timeout service.
	$scope.intervalFunction = function(){
    $timeout(function() {
      $scope.getData();
      $scope.intervalFunction();
    }, 1000000)
  };

  // Kick off the interval
  $scope.intervalFunction();
});
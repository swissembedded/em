
angular.module('SolarApp',[])
	   .controller('ListController', function($scope, $http, $timeout) {
	
	var list;
    $scope.title = "Temperature List";

	 $scope.getData = function(){
			 $http({
			method : "GET",
			url : "http://localhost:3000/getTemperatures"
		}).then(function mySucces(response) {
			$scope.list = response.data;
		}, function myError(response) {
		   $scope.list = response.statusText;
		})
	}
	
	// Function to replicate setInterval using $timeout service.
	$scope.intervalFunction = function(){
    $timeout(function() {
      $scope.getData();
      $scope.intervalFunction();
    }, 1000)
  };

  // Kick off the interval
  $scope.intervalFunction();

	
}

);
	




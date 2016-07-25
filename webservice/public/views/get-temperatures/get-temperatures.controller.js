(function()
{
	angular
	.module("PassportApp")
	.controller("GetTemperaturesController", GetTemperaturesController);
	
	function GetTemperaturesController($scope,$http, $timeout)
	{
		$scope.getData = function(){
			var req = $http({
				method : "GET",
				url : "/getTemperatures"
			})
			.then(function(response) {
				$scope.list = response.data;
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
			}, 1000)
		};

		  // Kick off the interval
		  $scope.intervalFunction();
		}
	})();
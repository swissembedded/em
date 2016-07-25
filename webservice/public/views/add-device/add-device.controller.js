(function()
{
	angular
	.module("PassportApp")
	.controller("AddDeviceController", AddDeviceController);
	
	function AddDeviceController($scope,$http, $timeout)
	{
		
	//	angular.module('DeviceCtrl', ['geolocation', 'gservice']).
	//controller('DeviceController', function($scope,$http,geolocation, gservice) {

		//Cambiarlo para que el form le traiga los datos
		//agregar parametros en la llamada POST
		$scope.submit  = function(){

			var datos = JSON.stringify( {
				uuid: $scope.uuid ,
				user_id: '12',
				name:  $scope.name,
				lat:   $scope.latitude,
				lon:   $scope.longitude });

			var req = $http({
				method : "POST",
				url : "/addDevice",
				data : datos
			})
			.then(function(response) {
				
		         //Refresh map
				//gservice.refresh($scope.latitude, $scope.longitude);

				$scope.uuid = '';
				$scope.user_id = '';
				$scope.name = '';
				$scope.latitude = '';
				$scope.longitude = '';

				console.log('Success');
			})
			.catch(function(response) {
				console.error('Gists error', response.status, response.data);
			})
			.finally(function() {
				console.log("finally finished gists");
			})
		}
	}
})();
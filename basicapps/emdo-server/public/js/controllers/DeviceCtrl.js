angular.module('DeviceCtrl', []).controller('DeviceController', function($scope,$http) {

	$scope.title = "Add Device";

//Cambiarlo para que el form le traiga los datos
//agregar parametros en la llamada POST
$scope.submit  = function(){

	var datos = JSON.stringify( {
		uuid: $scope.uuid ,
		user_id: '12',
		name:  'name',
		lat:   '10.0',
		lon:   '10.0' });

	var req = $http({
		method : "POST",
		url : "/addDevice",
		data : datos
	})
	.then(function(response) {
		
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

});
(function()
{
	angular
	.module("PassportApp")
	.controller("ListDevicesController", ListDevicesController);
	//'geolocation', 
	function ListDevicesController($scope,$http, $timeout)
	{

		// $scope.getData = function(){
		// 	var req = $http({
		// 		method : "GET",
		// 		url : "/getDevices"
		// 	})
		// 	.then(function(response) {

		// 		$scope.list = response.data;

		// 	  //Refresh map
		// 	  var selectedLat = 47.23;
		// 	  var selectedLong = -8.04;

		// 	  gservice.refresh(selectedLat, selectedLong);

		// 	})
		// 	.catch(function(response) {
		// 		console.error('Gists error', response.status, response.data);
		// 	})
		// 	.finally(function() {
		// 		console.log("finally finished gists");
		// 	})
		// }

		// // Function to replicate setInterval using $timeout service.
		// $scope.intervalFunction = function(){
		// 	$timeout(function() {
		// 		$scope.getData();
		// 		$scope.intervalFunction();
		// 	}, 1000000)
		// };

		//   // Kick off the interval
		//   $scope.intervalFunction();


		var mapOptions = {
			zoom: 4,
			center: new google.maps.LatLng(47.2349952, 8.33),
			mapTypeId: google.maps.MapTypeId.ROADMAP
		}




		$scope.map = new google.maps.Map(document.getElementById('map'), mapOptions);

		$scope.markers = [];
		$scope.cities = [];

		var infoWindow = new google.maps.InfoWindow();

		$http.get('/getDevices').
		success(function (data) {

			$scope.device = data;
			$scope.device.forEach(function(device) {
				createMarker(device);
			});


		});

		var createMarker = function(device) {
			var marker = new google.maps.Marker({
				map: $scope.map,
				position: new google.maps.LatLng(device.lat, device.lon),
				title: device.name

			});
			marker.content = '<div class="infoWindowContent">' + device.name + '</div>';

			google.maps.event.addListener(marker, 'click', function() {
				infoWindow.setContent('<h2>' + marker.title + '</h2>' + marker.content);
				infoWindow.open($scope.map, marker);
			});

			$scope.markers.push(marker);
		};

    //$scope.openInfoWindow = function (e, selectedMarker) {
    //    e.preventDefault();
    //    google.maps.event.trigger(selectedMarker, 'click');
    //} 
}
})();
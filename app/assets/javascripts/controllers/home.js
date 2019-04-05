"use strict";

LayoutApp.controller('HomeCtrl', ['$scope', '$resource', function($scope, $resource) {

  $scope.loadMap = function(){
    $resource('/home/index.json').query(function(data){
      console.log(data);
      $scope.data = data;
    })
  }

  $scope.loadMap();

}]);

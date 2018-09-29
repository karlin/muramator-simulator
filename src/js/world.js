

// Create demo application
var app = new p2.WebGLRenderer(function(){

    // Create a World
    var world = new p2.World({
        gravity : [0,0]
    });
    this.setWorld(world);
    world.defaultContactMaterial.friction = 5;
    // var topWall = new p2.Box({ width: 100, height: 100 });
    // world.addBody(topWall);

    var floorShape = new p2.Plane();
    var floor = new p2.Body({
        // fixedY: true,
        // fixedX: true,
        position: [0,-5]
    });
    floor.addShape(floorShape);
    world.addBody(floor);
    
    var ceilingShape = new p2.Plane();
    var ceiling = new p2.Body({
        // fixedY: true,
        // fixedX: true,
        angle: 3.14,
        position: [0,5]
    });
    ceiling.addShape(ceilingShape);
    world.addBody(ceiling);

    // Left plane
    var planeLeft = new p2.Body({
        angle: -Math.PI/2,
        position: [-10, 0]
    });
    planeLeft.addShape(new p2.Plane());
    world.addBody(planeLeft);

    // Right plane
    var planeRight = new p2.Body({
        angle: Math.PI/2,
        position: [10, 0]
    });
    planeRight.addShape(new p2.Plane());
    world.addBody(planeRight);

    // Create a dynamic body for the chassis
    var chassisBody = new p2.Body({
        mass: 1
    });
    var boxShape = new p2.Capsule({ length: 1, angle: 0.2,
        radius: 0.8, position: [0, -150] });
    chassisBody.addShape(boxShape);
    world.addBody(chassisBody);
    world.followBody = chassisBody;

    // Create the vehicle
    var vehicle = new p2.TopDownVehicle(chassisBody);

    // Add one front wheel and one back wheel - we don't actually need four :)
    var frontWheel = vehicle.addWheel({
        localPosition: [0, 0.5] // front
    });
    frontWheel.setSideFriction(4);
    // frontWheel.setBrakeForce(2);

    // Back wheel
    var backWheel = vehicle.addWheel({
        localPosition: [0, -0.5] // back
    });
    backWheel.setSideFriction(3); // Less side friction on back wheel makes it easier to drift
    // backWheel.setBrakeForce(2);

    vehicle.addToWorld(world);

    // // Key controls
    var keys = {
        '37': 0, // left
        '39': 0, // right
        '38': 0, // up
        '40': 0 // down
    };
    var maxSteer = Math.PI / 5;
    this.on("keydown",function (evt){
        keys[evt.keyCode] = 1;
        onInputChange();
    });
    this.on("keyup",function (evt){
        keys[evt.keyCode] = 0;
        onInputChange();
    });
    function onInputChange(){

        // Steer value zero means straight forward. Positive is left and negative right.
        frontWheel.steerValue = maxSteer * (keys[37] - keys[39]);

        // Engine force forward
        backWheel.engineForce = keys[38] * 7;

        backWheel.setBrakeForce(0);
        if(keys[40]){
            if(backWheel.getSpeed() > 0.1){
                // Moving forward - add some brake force to slow down
                backWheel.setBrakeForce(5);
            } else {
                // Moving backwards - reverse the engine force
                backWheel.setBrakeForce(0);
                backWheel.engineForce = -4;
            }
        }
    }

});


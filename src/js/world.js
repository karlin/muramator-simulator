// Create demo application
export var app = new p2.WebGLRenderer(function() {
  // Create a World
  var world = new p2.World({
    gravity: [0, 0],
    sleepMode: p2.World.BODY_SLEEPING
  });
  this.setWorld(world);
  world.defaultContactMaterial.friction = 1;
  // world.solver.frictionIterations = 1;
  // world.useWorldGravityAsFrictionGravity=true
  // var topWall = new p2.Box({ width: 100, height: 100 });
  // world.addBody(topWall);

  var floorShape = new p2.Plane();
  var floor = new p2.Body({
    // fixedY: true,
    // fixedX: true,
    position: [0, -25]
  });
  floor.addShape(floorShape);
  world.addBody(floor);

  var ceilingShape = new p2.Plane();
  var ceiling = new p2.Body({
    // fixedY: true,
    // fixedX: true,
    angle: 3.14,
    position: [0, 25]
  });
  ceiling.addShape(ceilingShape);
  world.addBody(ceiling);

  // Left plane
  var planeLeft = new p2.Body({
    angle: -Math.PI / 2,
    position: [-50, 0]
  });
  planeLeft.addShape(new p2.Plane());
  world.addBody(planeLeft);

  // Right plane
  var planeRight = new p2.Body({
    angle: Math.PI / 2,
    position: [50, 0]
  });
  planeRight.addShape(new p2.Plane());
  world.addBody(planeRight);

  // Create a dynamic body for the chassis
  var chassisBody = new p2.Body({
    mass: 1.5
    // intertia: 0.0
  });
  var bodyShape = new p2.Capsule({
    length: 2,
    radius: 1.0
  });
  chassisBody.addShape(bodyShape);
  var sensor = new p2.Particle({ sensor: true });
  chassisBody.addShape(sensor, [0, 16]);
  world.addBody(chassisBody);
  this.followBody = chassisBody;

  // var sensor = new p2.Body({
  //     mass: 1,
  //     // type: p2.Body.KINEMATIC,
  //     // collisionResponse: false,
  //     // sensor: true,
  //     position: [0, 5]
  // });
  // sensor.addShape(new p2.Circle({ radius: 0.2 }));

  // world.addBody(sensor);
  // world.addConstraint(new p2.LockConstraint(sensor, chassisBody));

  // Create the vehicle
  var vehicle = new p2.TopDownVehicle(chassisBody);

  // Add one front wheel and one back wheel - we don't actually need four :)
  var frontWheel = vehicle.addWheel({
    localPosition: [0, 1.5] // front
  });
  frontWheel.setSideFriction(20);
  frontWheel.setBrakeForce(0);

  // Back wheel
  var backWheel = vehicle.addWheel({
    localPosition: [0, -1.5] // back
  });
  backWheel.setSideFriction(20); // Less side friction on back wheel makes it easier to drift
  backWheel.setBrakeForce(0);

  vehicle.addToWorld(world);

  world.setGlobalStiffness(1e8);
  world.setGlobalRelaxation(4);

  // var controlBody = new p2.Body({
  //     type: p2.Body.KINEMATIC,
  //     collisionResponse: false
  // });
  // var controlShape = new p2.Circle({
  //     radius: 2
  // });
  // controlBody.addShape(controlShape);
  // world.addBody(controlBody);

  world.on('beginContact', function(event) {
    if (event.shapeA.id === sensor.id || event.shapeB.id === sensor.id) {
      // document.dispatchEvent(new Event("obstacle"));
      world.emit({ type: 'obstacle' });
    }
  });

  world.on('endContact', function(event) {
    if (event.shapeA.id === sensor.id || event.shapeB.id === sensor.id) {
      world.emit({ type: 'noObstacle' });
    }
  });

  // // Key controls
  var keys = {
    '37': 0, // left
    '39': 0, // right
    '38': 0, // up
    '40': 0 // down
  };
  var maxSteer = Math.PI / 4;

  // "forward" neuron active
  world.on('forwardOn', e => {
    keys[38] = 1;
    keys[40] = 0;
    onInputChange();
  });

  // "forward" neuron off
  world.on('forwardOff', e => {
    keys[38] = 0;
    onInputChange();
  });

  world.on('turnOn', e => {
    keys[37] = 1;
    keys[40] = 1;
    onInputChange();
  });

  world.on('turnOff', e => {
    keys[37] = 0;
    keys[40] = 1;
    onInputChange();
  });

  this.on('keydown', function(evt) {
    keys[evt.keyCode] = 1;
    onInputChange();
  });
  this.on('keyup', function(evt) {
    keys[evt.keyCode] = 0;
    onInputChange();
  });
  function onInputChange() {
    // Steer value zero means straight forward. Positive is left and negative right.
    frontWheel.steerValue = maxSteer * (keys[37] - keys[39]);

    // Engine force forward
    backWheel.engineForce = keys[38] * 20;

    backWheel.setBrakeForce(0);
    if (keys[40]) {
      if (backWheel.getSpeed() > 0.01) {
        // Moving forward - add some brake force to slow down
        backWheel.setBrakeForce(10);
      } else {
        // Moving backwards - reverse the engine force
        backWheel.setBrakeForce(0.1);
        backWheel.engineForce = -12;
      }
    }
  }
});

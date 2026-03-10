// licensed under Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)
// https://creativecommons.org/licenses/by-sa/4.0/

// cubeworms float around, propelled by thrusters and repulsed by anti-grav wall. Starts life by fading into existence
public abstract class Cubeworm {
  private int id; // index in cubeworm array
  protected ColourCycler cols; // cubeworm colours
  protected PVector pos, rot, vel; // position, rotation, velocity
  protected ArrayList<Trailcube> trail; // trailcubes
  protected int nextTrailcube; // number of frames until we spawn the next trailcube
  protected int facecubes; // number of facecubes (small cubes around the cubeworm)
  protected float strokeW; // stroke width for glowy light pulse
  
  // Copy constructor — intentionally shallow. This is an ownership-transfer pattern: the caller
  // immediately replaces worms[id] with the new subclass instance (e.g. worms[id] = new Hypnoworm(this)),
  // so the old instance is discarded and aliasing the shared references is safe.
  public Cubeworm (Cubeworm c) {
    this.id = c.id;
    this.cols = c.cols;
    this.pos = c.pos;
    this.rot = c.rot;
    this.vel = c.vel;
    this.trail = c.trail;
    this.nextTrailcube = c.nextTrailcube;
    this.facecubes = c.facecubes;
    this.strokeW = c.strokeW;
  }
  
  // initialise bits of Cubeworm common to all subtypes
  public Cubeworm (int id) {
    this.id = id;
    cols = new ColourCycler(0, MAX_H, MIN_SAT, MAX_SAT, MIN_VERT_B, MAX_VERT_B);
    trail = new ArrayList<Trailcube>();
  }
  
  protected int id() { return id; }

  // Cubeworm behaviour is implemented in each different sub-class
  public abstract void update();
  
  // most Cubeworms become hypnotised when the beacon is placed, although some ignore it
  public void beaconPlaced() {
    worms[id()] = new Hypnoworm(this);
  }
  
  // only Hypnoworms are affected by beacon detonations
  public void beaconDetonated() {}
  
  // assuming initial orientation (1,0,0) and given a desired facing, calculate required XYZ rotations 
  public PVector calcEulers(PVector facing) {
    // right-hand direction (as seen by the viewer) is the "front"
    PVector init = new PVector(1,0,0);
    // cross product of plane described by inital and target orientation vectors = normal vector (axis)
    PVector axis = init.cross(facing);
    // get rotation around axis and plug into quaternion
    float theta = findTheta(init, facing);
    Quaternion q = new Quaternion(theta, axis);
    return q.eulers();
  }
  
  float findTheta(PVector v1, PVector v2) {
    return MathUtils.findTheta(v1, v2);
  }
  
  // project a given vector v2 onto another vector v1: proj = ((v1 dot v2) / |v1|^2) * v1
  PVector project(PVector v1, PVector v2) {
    float dot = v1.dot(v2);
    float v1MagSq = sq(v1.mag());
    return PVector.mult(v1, dot / v1MagSq); 
  }
  
  // choose a random (re-)spawn/recover position
  PVector getSpawnPos() {
    PVector p = new PVector(random(-1,1), random(-1,1), random(-1,1));
    p.normalize();
    p.mult(random(0, MAX_SPAWN_RAD));
    return p;
  }
  
  // leave a trail behind us
  void spawnTrail() {
    if (nextTrailcube > 0) {
      nextTrailcube--;
    } else {
      float spawnDist = random(TRAIL_MIN_SPAWN_DIST, TRAIL_MAX_SPAWN_DIST);
      float spawnRad = random(0, TRAIL_MAX_SPAWN_RAD);
      float trailSize = random(TRAIL_MIN_SIZE, TRAIL_MAX_SIZE);
      trailSize *= map(spawnRad, 0, TRAIL_MAX_SPAWN_RAD, 1, TRAIL_OFFSET_SIZE_MOD);

      PVector spawnPos = calcTrailSpawnPos(spawnDist, spawnRad);
      Trailcube tc = createTrailcube(spawnPos, trailSize);
      trail.add(tc);
      nextTrailcube = trailSpawnDelay();
    }
  }

  // calculate a randomised spawn position behind the cubeworm
  private PVector calcTrailSpawnPos(float spawnDist, float spawnRad) {
    float spawnTheta = random(0, TWO_PI);
    float yOff = sin(spawnTheta) * spawnRad * MathUtils.randomSign();
    float zOff = cos(spawnTheta) * spawnRad * MathUtils.randomSign();
    PVector spawnPos = vel.normalize(null);
    spawnPos.mult(-spawnDist);
    spawnPos = PVector.add(pos, spawnPos);
    spawnPos.add(new PVector(0, yOff, zOff));
    return spawnPos;
  }

  // create a trailcube with colour slightly randomised from cubeworm's current colour
  private Trailcube createTrailcube(PVector spawnPos, float trailSize) {
    float hDiff = random(0, TRAIL_MAX_HUE_DIFF) * MathUtils.randomSign();
    float sDiff = random(0, TRAIL_MAX_SAT_DIFF) * MathUtils.randomSign();
    float tFHue = constrain(cols.faceHue() + hDiff, 0, MAX_H);
    float tFSat = constrain(cols.faceSat() + sDiff, 0, MAX_SBA);
    float tVHue = constrain(cols.vertHue() + hDiff, 0, MAX_H);
    float tVSat = constrain(cols.vertSat() + sDiff, 0, MAX_SBA);
    color vertCol = color(tVHue, tVSat, cols.vertBright());
    return new Trailcube(tFHue, tFSat, vertCol, spawnPos, rot.copy(), trailSize);
  }
  
  // trailcube spawn rate scales linearly with velocity
  int trailSpawnDelay() {
    float s  = vel.mag();
    // explodeWorms can return a negative number here. It's ok because we test (nextTrailcube > 0) 
    return round(map(s, 0, MAX_SPEED, TRAIL_MIN_RATE, TRAIL_MAX_RATE));
  }
  
  // Prepare canvas to draw faces, but leave actual drawing implementation to subclasses
  public void displayFaces(PGraphics pg) {
    translateRotate(pg);
    pg.specular(cols.faceHue(), cols.faceSat(), MAX_SBA);
    pg.fill(cols.faceHue(), cols.faceSat(), FACE_BRIGHTNESS, MAX_SBA);
  }
  
  // Prepare canvas to draw vertices, but leave actual drawing implementation to subclasses
  public void displayVertices(PGraphics pg) {    
    translateRotate(pg);
    pg.stroke(cols.vertHue(), cols.vertSat(), cols.vertBright(), MAX_SBA);
    pg.strokeWeight(strokeW);
  }
  
  // translating & rotating in preparation for drawing to canvas
  public void translateRotate(PGraphics pg) {
    pg.translate(pos.x, pos.y, pos.z);
    pg.rotateZ(rot.z);
    pg.rotateY(rot.y);
    pg.rotateX(rot.x);
  }
  
  // draw satellite facecubes evenly around the cubeworm, starting at the "top" face
  public void drawFacecubes(PGraphics pg, float fcubeSize, float fcubeDist, float rotOffset) {
    for (int i = 0; i < facecubes; i++) {
      pg.pushMatrix();
        float theta = ((i*TWO_PI) / facecubes) + rotOffset;
        pg.translate(0, sin(theta) * fcubeDist, cos(theta) * fcubeDist);
        // rotate facecubes so they are pointing away from the cubeworm
        pg.rotateX(-HALF_PI - (TWO_PI/facecubes) * i);
        pg.box(fcubeSize);
      pg.popMatrix();
    }
  }
  
  // we don't always have a non-standard size or rotation offset for facecubes
  public void drawFacecubes(PGraphics pg, float fcubeDist) {
    drawFacecubes(pg, FACECUBE_SIZE, fcubeDist, 0);
  }
  
  // drawing the faces and vertices of trailcubes
  public void drawTrailFaces(PGraphics pg) {
    for (Trailcube t : trail) {
      t.displayFaces(pg);
    }
  }
  public void drawTrailVertices(PGraphics pg) {
    for (Trailcube t : trail) {
      t.displayVertices(pg);
    }
  }
}

/*************************************************************************
* Spawning subclcass - has quick animation for cubeworms when they spawn *
**************************************************************************/
public class Spawnworm extends Cubeworm {
  private int animFrame; // current frame of current step of spawn animation
  private AStep animStep; // current step of spawn animation
  private float facecubeGrow; // size of facecube for first step of spawn animation
  private float facecubeSplit; // after growing, facecubes split radially (2nd anim step)
  private float facecubeRot; // facecube rotation (3rd anim step)
  private float cubewormGrow; // size of cubeworm centre cube (3rd anim step)
  
  public Spawnworm(int id) {
    super(id);
    init();
  }
  
  // create Spawnworm from an existing cubeworm
  public Spawnworm(Cubeworm c) {
    super(c);
    init();
  }
  
  // set up stuff for a newly (re-)spawned worm
  private void init() {
    strokeW = SPAWN_STROKEW;
    
    // randomise starting position & rotation
    pos = getSpawnPos();
    vel = new PVector(random(-1,1), random(-1,1), random(-1,1));
    vel.normalize();
    rot = calcEulers(vel);
    
    // decorate the cube with trailcubes and facecubes
    nextTrailcube = trailSpawnDelay() + SPAWN_TRAIL_DELAY_MOD;
    facecubes = round(random(MIN_FACECUBES, MAX_FACECUBES));
    
    // spawn animation
    animFrame = 0;
    animStep = AStep.FACECUBE_GROW;
    facecubeGrow = facecubeSplit = facecubeRot = cubewormGrow = 0;
  }
  
  // run spawn animation
  public void update() {
    float eQuart = MathUtils.easeInOut(float(animFrame) / ANIM_STEP_LEN, 4);
    switch(animStep) {
      // first step of spawn animation: single facecube grows at centre
      case FACECUBE_GROW:
        facecubeGrow = FACECUBE_SIZE * eQuart;
        break;
      
      // second step of spawn animation: facecube splits into several, taking final positions
      case FACECUBE_SPLIT:
        facecubeSplit = FACECUBE_DIST * eQuart;
        break;
      
      // final step of spawn animation: facecubes rotate 360 while cubeworm grows at centre
      case CUBEWORM_GROW:
        facecubeRot = TWO_PI * eQuart;
        cubewormGrow = WORM_SIZE * eQuart;
        break;
    }
    
    // check if it's time to move to the next animation step
    animFrame++;
    if (animFrame == ANIM_STEP_LEN) {
      animStep = animStep.nextStepOrNull();
      animFrame = 0;
      // if we have finished animating, convert to Roamworm/Hypnoworm (depending on beacon)
      if (animStep == null) {
        if (beacon.isActive()) {
          worms[id()] = new Hypnoworm(this);
        } else {
          worms[id()] = new Roamworm(this);
        }
      }
    }
  }
  
  // spawning worms ignore the beacon until spawn animation is complete
  public void beaconPlaced() {}
  
  // draw faces
  public void displayFaces(PGraphics pg) {
    pg.pushMatrix();
      super.displayFaces(pg);
      pg.box(cubewormGrow);
      drawFacecubes(pg, facecubeGrow, facecubeSplit, facecubeRot);
    pg.popMatrix();
  }
  
  // draw vertices
  public void displayVertices(PGraphics pg) {
    pg.pushMatrix();
      super.displayVertices(pg);
      pg.box(cubewormGrow);
      drawFacecubes(pg, facecubeGrow, facecubeSplit, facecubeRot);
    pg.popMatrix();
  }
  
}

/**************************************************************************
* Roaming subclass - default state of cubeworms, just wandering around... *
**************************************************************************/
public class Roamworm extends Cubeworm {
  private Thruster thruster; // provides random movement to cubeworm
  protected float pulseSpeed; // speed (period) of light pulse
  private float pulseAnim; // xpos on pulse animation sine wave
  
  public Roamworm(Cubeworm c) {
    super(c);
    // try to copy additional roamworm stuff if present
    if (c instanceof Roamworm) {
      Roamworm r = (Roamworm)c;
      thruster = r.thruster;
      pulseSpeed = r.pulseSpeed;
      pulseAnim = r.pulseAnim;
    } else {
      // initialise roamworm-specific stuff if it doesn't already exist
      init();
    }
  }
  
  // initialise roamworm-specific stuff
  private void init() {
    // glowy pulse-y effect
    pulseSpeed = random(MIN_PULSE_SPEED, MAX_PULSE_SPEED);
    // inverse of the sine function we use below for animating the glowy pulse-y (here we know Y, need X)
    pulseAnim = asin(2 * ((SPAWN_STROKEW - MIN_EDGE) / (MAX_EDGE - MIN_EDGE)) - 1);
    // engines online! Use given (tiny) velocity from spawncube so rotation stays constant
    thruster = new Thruster(vel.copy());
  }
  
  // update movement & appearance of cubeworm
  public void update() {
    moveAndRotate();
    glowPulse();
    cols.run();
    updateTrailWithSpawn();
  }

  // motion for the worm - movement & rotation
  void moveAndRotate() {
    calcVelocity(); 
    rot = calcEulers();
  }
  
  // pulse thickness of stroke for nice glow-y effect
  void glowPulse() {
    strokeW = MIN_EDGE + ((sin(pulseAnim) + 1) / 2) * (MAX_EDGE - MIN_EDGE);
    pulseAnim += pulseSpeed;
  }
  
  // spawn a new trailcube and decay/remove existing ones
  void updateTrailWithSpawn() {
    spawnTrail();
    decayTrail();
  }

  // decay/remove existing trailcubes without spawning new ones
  void updateTrailNoSpawn() {
    decayTrail();
  }

  // shrink all trailcubes and remove dead ones
  private void decayTrail() {
    for (int i = trail.size() - 1; i >= 0; i--) {
      Trailcube t = trail.get(i);
      t.update();
      if (!t.isAlive()) {
        trail.remove(i);
      }
    }
  }
  
  void calcVelocity() {
    // update velocity: first fire thrusters, then apply effects from gravity/beacon
    PVector acceleration = thruster.run();
    acceleration.add(modAcceleration());
    
    // apply acceleration. Curtail speed if it's too fast
    vel.add(acceleration);
    float speed = vel.mag();
    float maxSpeed = maxSpeed();
    if (speed > maxSpeed) {
      vel.mult(maxSpeed / speed);
    }
    pos.add(vel);
  }
  
  // roamworm faces direction of velocity. (Seperated into distinct function for overriding in subclasses)
  PVector calcEulers() {
    return super.calcEulers(vel);
  }
  
  // roamworms are repelled by anti gravity wall
  PVector modAcceleration() {
    // inverse square law to push cubeworms away from grav wall
    float gravPwr = GRAV_PWR / sq(WALL_RAD - pos.mag());
    PVector grav = pos.normalize(null); // passing null prevents modification of original PVector
    grav.mult(-gravPwr);
    return grav;
  }
  
  // return max speed. Overridden in some subclasses
  float maxSpeed() {
    return MAX_SPEED;
  }
  
  // draw faces
  public void displayFaces(PGraphics pg) {
    pg.pushMatrix();
      super.displayFaces(pg);
      pg.box(WORM_SIZE);
      drawFacecubes(pg, FACECUBE_DIST);
    pg.popMatrix();
    drawTrailFaces(pg);
  }
  
  // draw vertices
  public void displayVertices(PGraphics pg) {    
    pg.pushMatrix();
      super.displayVertices(pg);
      pg.box(WORM_SIZE);
      drawFacecubes(pg, FACECUBE_DIST);
    pg.popMatrix();
    drawTrailVertices(pg);
  }
}

/*******************************************************************************************
* Travelling subclass - for cubeworms that travel to a destination, ignoring the grav wall *
*******************************************************************************************/
public class Travelworm extends Roamworm {
  protected PVector dest, toDest; // vectors representing travel destination and vector between our pos & the dest
  protected float distToDest; // magnitude of toDest vector
  
  public Travelworm(Cubeworm c) {
    super(c);
    dest = toDest = new PVector(); // unnecessary, but good practice
    distToDest = 0; // also just to be safe...
  }
  
  // calculate vector and scalar to destination before updating
  public void update() {
    calcToDest();
    super.update();
  }
  
  // travelworms are drawn to their destination rather than repulsed by the gravwall
  PVector modAcceleration() {
    PVector accMod = toDest.normalize(null); // passing null prevents modification of original object
    accMod.mult(ATTR_STR);
    return accMod;
  }
  
  // calculate vector and distance to destination
  void calcToDest() {
    toDest = PVector.sub(dest, pos);
    distToDest = toDest.mag();
  }
}

/******************************************************************************
* Hypnotised subclass - for cubeworms that have been hypnotised by the beacon *
******************************************************************************/
public class Hypnoworm extends Travelworm {
  private PPlane destPlane; // plane orthogonal to toDest vector at beacon location
  private PVector gaze; // vector representing direction worm is facing. vel by default, modified when fascinated
  private PVector prevGaze; // direction worm faced in previous frame - so we can interpolate
  private float lookLimRad; // radius of circle that worm must look at, shrinks with distance to beacon
  private boolean fascinated; // worms within a certain distance of the beacon become fascinated, unable to look away
  
  public Hypnoworm(Cubeworm c) {
    super(c);
    dest = beacon.pos();
    gaze = vel;
    prevGaze = vel;
    destPlane = new PPlane();
    lookLimRad = 0;
    fascinated = false;
    calcToDest();
  }
  
  public void update() {
    moveAndRotate();
    calcToDest();
    glowPulse();
    cols.run();
    updateTrailWithSpawn();
    prevGaze = gaze;
  }
  
  // this should never happen, but just in case...
  public void beaconPlaced() {}
  
  // hypnoworms will either explode or recover, depending on distance to beacon and luck
  public void beaconDetonated() {
    if (fascinated) {
      float survivalChance = map(distToDest, FASCINATE_RADIUS, BEACON_ATTRACT_RADIUS, 1, MIN_SURVIVAL_CHANCE);
      // will the worm survive?
      float badLuck = random(0,1);
      if (badLuck > survivalChance) {
        // uh oh... worm transitions via subclass-replacement (the established pattern here)
        float enumLen = ExplodeType.values().length;
        ExplodeType chooseYourDestiny = ExplodeType.values()[round(random(-RANDOM_FIX, enumLen - RANDOM_FIX))];
        switch (chooseYourDestiny) {
          case SPLITWORM:
            worms[id()] = new Splitworm(this);
            break;

          case EXPLODEWORM:
            worms[id()] = new Explodeworm(this);
            break;
        }
      } else {
        // phew, got away with it!
        worms[id()] = new Pushworm(this);
      }
    } else {
      worms[id()] = new Recoverworm(this);
    }
  }
  
  // hypnoworms don't always look directly at their velocity, depending on how close they are to the beacon
  PVector calcEulers() {
    gaze = vel; // look towards vel by default
    fascinated = distToDest < FASCINATE_RADIUS;
    if (fascinated) {
      calcAttractionGaze();
    }
    // if we want to look in a new direction from last frame, interpolate smoothly
    if (gaze != prevGaze) {
      PVector gazeDiff = PVector.sub(gaze, prevGaze);
      gazeDiff.mult(MAX_TURN_RATE);
      gaze = PVector.add(prevGaze, gazeDiff);
    }
    return calcEulers(gaze);
  }

  // constrain gaze to a circle of radius lookLimRad around the beacon on the dest plane
  private void calcAttractionGaze() {
    destPlane = new PPlane(dest, toDest);
    lookLimRad = (distToDest * LOOK_LIM_DIST_MOD) + (vel.mag() * LOOK_LIM_VEL_MOD);
    gaze = destPlane.findIntersect(pos, vel);
    if (gaze != null) {
      PVector gazeXsec = PVector.add(pos, gaze); // intersection between gaze & dest plane
      PVector gazeDestDif = PVector.sub(dest, gazeXsec);
      // if gaze too far from beacon: clamp to lookLimRad circle on destPlane.
      // use velocity's component parallel to destPlane because if worm is moving away from
      // beacon, (pos+vel) Xsec destPlane gives unhelpful backwards results
      if (gazeDestDif.mag() > lookLimRad) {
        PVector velOrtho = project(toDest, vel); // component of vel orthogonal to destPlane
        PVector velParallel = PVector.sub(vel, velOrtho); // component parallel to destPlane
        velParallel.normalize();
        velParallel.mult(lookLimRad);
        gaze = PVector.add(toDest, velParallel);
      }
    } else {
      // parallel or coincident ray (almost never happens): keep previous gaze
      gaze = prevGaze;
    }
  }
  
  // hypnoworms are attracted to the beacon - but don't get too close!
  PVector modAcceleration() {
    if (!fascinated) {
      return super.modAcceleration();
    }
    // fascinated: slow down and try to stay on the spherical cap between beacon and (0,0,0)
    PVector capAttract = super.modAcceleration();
    addCoreRepulsion(capAttract);
    addHerdForce(capAttract);
    return capAttract;
  }

  // repulse worms that get too close to the beacon core
  private void addCoreRepulsion(PVector accel) {
    if (distToDest < BEACON_ATTRACT_RADIUS) {
      PVector repulse = PVector.mult(toDest, BEACON_ATTRACT_RADIUS / distToDest * BEACON_CORE_REPULSE);
      accel.add(repulse);
    }
  }

  // push worms back toward the spherical cap if they stray outside it
  private void addHerdForce(PVector accel) {
    PVector capPlaneXsec = beacon.capPlane().findIntersect(pos, dest);
    if (capPlaneXsec == null) { return; } // no intersection; skip herd push
    PVector capPlaneBDist = PVector.sub(dest, PVector.add(pos, capPlaneXsec));
    if ((capPlaneBDist.mag() > beacon.capRad()) || (!vectorsSignsEqual(dest, capPlaneXsec))) {
      float bPosMag = beacon.pos().mag();
      PVector bSphereNearPt = PVector.mult(beacon.pos(), (bPosMag - BEACON_ATTRACT_RADIUS) / bPosMag);
      PVector nearPtAttract = PVector.sub(bSphereNearPt, pos);
      nearPtAttract.mult(BEACON_HERD_STRENGTH);
      accel.add(nearPtAttract);
    }
  }
  
  // check whether the x/y/z components of two vectors have the same signs (+, -, 0)
  private boolean vectorsSignsEqual(PVector v1, PVector v2) {
    if ((numSign(v1.x) == numSign(v2.x)) &&
        (numSign(v1.y) == numSign(v2.y)) &&
        (numSign(v1.z) == numSign(v2.z))) {
      return true;
    } else {
      return false;
    }
  }
  
  // return -1, 0 or 1 to indicate a number's sign. Used by vectorSigns
  private int numSign(float f) {
    if (f < 0) {
      return -1;
    } else if (f > 0) {
      return 1;
    } else {
      return 0;
    }
  }
  
  // worms slow down as they approach the beacon
  float maxSpeed() {
    if (fascinated) {
      return MAX_SPEED * (distToDest / FASCINATE_RADIUS);
    } else {
      return MAX_SPEED;
    }
  }
}

/**********************************************************************************************
* Pushed subclass - for cubeworms that were hit by beacon detonation but just got pushed away *
***********************************************************************************************/
public class Pushworm extends Roamworm {
  protected float maxSpeed; // temporarily increased max speed
  protected float resetSpeed; // when max speed slows to resetSpeed, convert to another type of worm
  
  public Pushworm(Cubeworm c) {
    super(c);
    resetSpeed = MAX_SPEED;
    
    // calc force and direction of push
    PVector expDir = PVector.sub(pos, beacon.pos());
    float dirMag = expDir.mag();
    // calc speed...
    maxSpeed = 1 / dirMag;
    maxSpeed = min(maxSpeed * PUSH_SPEED_MOD, MAX_PUSH_SPEED);
    // ... and apply to direction
    vel = PVector.mult(expDir, maxSpeed / dirMag);
  }
  
  public void update() {
    super.update();
    // if we have calmed down enough, convert to recoverworm or a hypnoworm if the beacon is active
    if (maxSpeed <= resetSpeed) {
      convertWorm();
    }
  }
  
  // when max speed has decayed to resetSpeed (MAX_SPEED), convert to another type of worm
  void convertWorm() {
    if (beacon.isActive()) {
      worms[id()] = new Hypnoworm(this);
    } else {
      worms[id()] = new Recoverworm(this);
    }
  }
  
  // Pushworms ignore beacons
  public void beaconPlaced() {}
  
  // ignore gravwall, beacon, etc while being pushed
  PVector modAcceleration() {
    return new PVector(0,0,0);
  }
  
  // pushworm slowly calms down
  float maxSpeed() {
    if (maxSpeed > resetSpeed) {
      maxSpeed -= SPEED_DECAY;
    }
    return maxSpeed;
  }
}

/*********************************************************************************************
* Splitting subclass - for cubeworms that split into lots of small bits on beacon detonation *
*********************************************************************************************/
public class Splitworm extends Cubeworm {
  private Fragment[] fragments; // fragments of worm, blazing across the sky...
  private float speed; // speed at which fragments travel
  public Splitworm(Cubeworm c) {
    super(c);
    
    // calc velocity (speed & direction)
    PVector expDir = PVector.sub(pos, beacon.pos());
    float dirMag = expDir.mag();
    speed = 1 / dirMag;
    speed = min(speed * PUSH_SPEED_MOD, MAX_SPLIT_SPEED);
    vel = PVector.mult(expDir, speed / dirMag);
    // use velocity to get rotation for facing
    rot = calcEulers(vel);
    
    // main cube starts as single large fragment, facecubes are small fragments that won't split
    fragments = new Fragment[facecubes + 1];
    fragments[0] = new Fragment(0, speed, WORM_SIZE);
    for (int i = 1; i < fragments.length; i++) {
      fragments[i] = new Fragment(MAX_SPLIT_DEPTH, speed, FACECUBE_SIZE);
    }
  }
  
  // each fragment runs update calculation for itself and its sub-fragments
  public void update() {
    if (strokeW < MAX_EDGE) {strokeW += STROKE_W_INC;}
    boolean stillRunning = false;
    for (int i = 0; i < fragments.length; i++) {
      if (fragments[i].update()) {
        stillRunning = true;
      }
    }
    
    // if all fragments have finished running, convert to a sleepworm
    if (!stillRunning) {
      worms[id()] = new Sleepworm(this);
    }
  }

  // translate/rotate to cubeworm's initial pos, then display fragments
  public void displayFaces(PGraphics pg) {
    pg.pushMatrix();
      super.displayFaces(pg);
      for (int i = 0; i < fragments.length; i++) {
        fragments[i].displayFaces(pg);
      }
    pg.popMatrix();
  }
  
  // translate/rotate to cubeworm's initial pos, then display fragments
  public void displayVertices(PGraphics pg) {
    pg.pushMatrix();
      super.displayVertices(pg);
      for (int i = 0; i < fragments.length; i++) {
        fragments[i].displayVertices(pg);
      }
    pg.popMatrix();
  }
  
  // Splitworms ignore the beacon
  public void beaconPlaced() {}
  
  // Fragment of a splitworm that has broken off (and may fragment further still)
  private class Fragment {
    Fragment[] fragments; // recursive things!
    int depth; // depth of this fragment
    float initSize; // initial size/mass of this fragment
    float size; // remaining size/mass in this fragment
    float pos; // fragment pos (relative to worm pos at detonation / parent pos at fragmentation)
    float speed; // speed of fragment
    PVector rot; // direction that fragment is facing
    boolean willFragment; // will this Fragment split into subfragments?
    float fragPoint; // split when reduced to this level of size/mass
    float fragSizeMult; // multiplier (<0) for size on fragmenting (how much size/mass given to sub-fragments?)
    float fragPos; // remember where we fragmented
    boolean stillRunning; // is size > 0 or at least one glimmer still alive?
    int activeGlimmers; // easier to remember how much of the trail is active than re-calc every frame
    
    // very hacky, but there are a *lot* of these. Probably more efficient than an arraylist of objects?
    float[] glimmerTrail; // points on the fragment's glimmer trail. Run each point if frag size < this
    float[] trailX; // x positions of trail points
    float[] trailY; // y offsets of trail points
    float[] trailRot; // rotation around X axis of trail points
    float[] trailRad; // radius of trail points
    float[] trailSpeed; // speeds of trail points
    float[] glimmerSpeed; // speed at which trail points glimmer
    int[] glimmerCount; // number of times a trailpoint will glimmer
    float[] trailAnim; // current animation state of glimmer trail point
    
    private Fragment(int depth, float speed, float size) {
      this.depth = depth;
      this.speed = speed;
      this.initSize = this.size = size;
      willFragment = false;
      fragPoint = 0;
      fragSizeMult = 0;
      stillRunning = true;
      activeGlimmers = -1; // need to have update() calc values for glimmer[0] too!
      
      // randomise direction in which this fragment splits off from parent
      if (this.depth > 0) {
        float rotX = random(0, TWO_PI);
        float rotY = random(0, MAX_SPLIT_THETA);
        rot = new PVector(rotX, rotY, 0);
      } else {
        rot = new PVector(0,0,0);
      }
      
      // decide if we will fragment and if so when
      if (depth < MAX_SPLIT_DEPTH) {
        willFragment = random(0, 1) < pow(FRAG_CHANCE, depth) ? true : false;
        if (willFragment) {
          // determine how many pieces we will fragment into
          int fragCount = round(random(MIN_SPLIT_FRAGS, MAX_SPLIT_FRAGS));
          fragments = new Fragment[fragCount];
          // randomise when we will fragment, and how much size/mass we retain after sub-fragmentation
          fragPoint = size * random(FRAG_MIN_POINT, FRAG_MAX_POINT);
          fragSizeMult = random(1.0f/(fragCount+1), 1.0f/(fragCount+1) * F_P_MAX_SIZE_MOD);
        }
      }
      
      // calculate spawn points of trail glimmers
      int preFragGlimmers = int((size - fragPoint) / G_AVERAGE_SPAWN) + 1;
      int postFragGlimmers = willFragment ? int((fragPoint * fragSizeMult) / G_AVERAGE_SPAWN) + 1 : 0;
      // now that we know number of glimmers, initalise arrays
      initGlimmerTrail(preFragGlimmers + postFragGlimmers);
      int g = 0;
      // glimmers spawned before fragmenting
      for (int i = int(size); i >= fragPoint; i -= G_AVERAGE_SPAWN) {
        glimmerTrail[g] = i + random(G_MIN_SPAWN_XOFF, G_MAX_SPAWN_XOFF);
        g++;
      }
      // glimmers spawned after fragmenting (if at all)
      if (willFragment) {
        for (int i = int(fragPoint * fragSizeMult); i >= 0; i -= G_AVERAGE_SPAWN) {
          glimmerTrail[g] = i + random(G_MIN_SPAWN_XOFF, G_MAX_SPAWN_XOFF);
          g++;
        }
      }
      // sometimes randomness might cause the first or last glimmer to have bad values
      glimmerTrail[0] = min(glimmerTrail[0], size);
      int trailLen = glimmerTrail.length-1;
      glimmerTrail[trailLen] = max(glimmerTrail[trailLen], 0);
    }
    
    // after calculating number of points in glimmer trail, initialise arrays
    private void initGlimmerTrail(int trailCount) {
      glimmerTrail = new float[trailCount];
      trailX = new float[trailCount];
      trailY = new float[trailCount];
      trailRot = new float[trailCount];
      trailRad = new float[trailCount];
      trailSpeed = new float[trailCount];
      glimmerSpeed = new float[trailCount];
      glimmerCount = new int[trailCount];
      trailAnim = new float[trailCount];
    }
    
    // update returns true if the fragment or one of its subfragments are still running
    private boolean update() {
      if (stillRunning) {
        // first run fragment...
        size -= FRAG_DECAY;
        pos += speed;
        boolean fragRunning = size > 0;
        
        // check if it's time for this fragment to split into sub-fragments
        if ((willFragment) && (size <= fragPoint) && (size + FRAG_DECAY > fragPoint)) {
          subFragment();
        }
        
        // ... then run glimmer trail
        boolean trailRunning = false;
        // check if any points in the glimmer trail are ready to come alive
        while ((activeGlimmers < glimmerTrail.length-1) && (glimmerTrail[activeGlimmers+1] > size)) {
          activeGlimmers++;
          initGlimmer(activeGlimmers);
        }
        // run each active trail point
        for (int i = 0; i < activeGlimmers; i++) {
          if (updateGlimmer(i)) {
            trailRunning = true;
          }
        }
        
        // are the fragment and trail all finished running?
        if ((!fragRunning) && (!trailRunning)) {
          stillRunning = false;
        }
      }
      
      // if this fragment has sub-fragments, recursively run (noting if they are still running)
      boolean anyStillRunning = stillRunning;
      if ((willFragment) && (size < fragPoint)) {
        for (int i = 0; i < fragments.length; i++) {
          if (fragments[i].update()) {
            anyStillRunning = true;
          }
        }
      }
      return anyStillRunning;
    }
    
    // split this fragment into some number of sub-fragments, spreading out size/mass
    private void subFragment() {
      // split by mass/volume, not just by radius! (eg: 10^3 = 1000 and 5^3 = 125, so size 10 / 2 != 5)
      float volume = pow(size, 3); // magic number 3 = cube power, convert from radius to volume
      fragPos = pos;
      float mainFragVol = volume * fragSizeMult * SPLIT_VOL_BOOST;
      float subFragsVol = volume * (1 - fragSizeMult) * SPLIT_VOL_BOOST;
      subFragsVol /= fragments.length;
      
      // size of main and subfragments
      size = pow(mainFragVol, 1.0f/3); // magic number 3 = cube root, convert from volume back to radius
      for (int i = 0; i < fragments.length; i++) {
        fragments[i] = new Fragment(depth + 1, speed, pow(subFragsVol, 1.0f/3));
      }
    }
    
    // if the glimmer were an object, all this would be in the constructor...
    private void initGlimmer(int g) {
      trailX[g] = ((initSize - size) / FRAG_DECAY) * speed;
      trailY[g] = random(0, G_MAX_SPAWN_YOFF);
      trailRot[g] = random(0, TWO_PI);
      trailRad[g] = 0;
      trailSpeed[g] = speed * G_INIT_SPEED_MOD;
      glimmerSpeed[g] = random(G_MIN_ANIM, G_MAX_ANIM);
      glimmerCount[g] = round(G_BLINKS * glimmerSpeed[g] * random(GLIMMER_BLINK_MOD_MIN, GLIMMER_BLINK_MOD_MAX));
      trailAnim[g] = G_BLINK_TIME;
    }
    
    // run/update a given point in the glimmer trail, or return false if it's already finished
    private boolean updateGlimmer(int g) {
      if ((glimmerCount[g] < 1) && (trailAnim[g] < -G_BLINK_TIME)) {
        return false;
      }
      // position & speed
      trailX[g] += trailSpeed[g];
      trailY[g] += trailSpeed[g] * G_Y_SPEED_MOD;
      trailSpeed[g] *= G_SPEED_DECAY;
      
      // blink animation
      if (trailAnim[g] > 0) {
        // trail glimmer is blinking
        float x = TWO_PI * (trailAnim[g] / G_BLINK_TIME);
        trailRad[g] = ((sin(x - HALF_PI) + 1) / 2) * G_MAX_RADIUS;
      } else {
        // trail glimmer is resting between blinks
        trailRad[g] = 0;
      }
      trailAnim[g] -= glimmerSpeed[g];
      
      // check if glimmer has completed a blink/rest cycle
      if ((trailAnim[g] < -G_BLINK_TIME) && (glimmerCount[g] > 0)) {
        trailAnim[g] = G_BLINK_TIME;
        glimmerCount[g]--;
      }
      return true;
    }
    
    // matrix has already been set translated & rotated to cubeworm condition at detonation
    private void displayFaces(PGraphics pg) {
      pg.pushMatrix();
        pg.rotateX(rot.x);
        pg.rotateY(rot.y);
        // display sub-fragments (if any), then this fragment
        if (willFragment && size < fragPoint) {
          displaySubFragFaces(pg);
        }
        if (size > 0) {
          pg.translate(pos, 0, 0);
          pg.box(size);
        }
      pg.popMatrix();
    }
    
    // matrix has already been set translated & rotated to cubeworm condition at detonation
    private void displayVertices(PGraphics pg) {
      if (stillRunning) {
        pg.pushMatrix();
          pg.rotateX(rot.x);
          pg.rotateY(rot.y);
          // draw glimmer trail first, then fragments
          for (int i = 0; i < activeGlimmers; i++) {
            if (trailRad[i] > 0) {
              pg.pushMatrix();
                pg.rotateX(trailRot[i]);
                pg.translate(trailX[i], trailY[i], 0);
                pg.sphere(trailRad[i]);
              pg.popMatrix();
            }
          }
          
          // display sub-fragments (if any), then this fragment
          if (willFragment && size < fragPoint) {
            displaySubFragVertices(pg);
          }
          if (size > 0) {
            pg.translate(pos, 0, 0);
            pg.box(size);
          }
        pg.popMatrix();
      }
    }
    
    // display faces of sub-fragments
    private void displaySubFragFaces(PGraphics pg) {
      pg.pushMatrix();
        pg.translate(fragPos, 0, 0);
        for (int i = 0; i < fragments.length; i++) {
          fragments[i].displayFaces(pg);
        }
      pg.popMatrix();
    }
    
    // display vertices of sub-fragments
    private void displaySubFragVertices(PGraphics pg) {
      pg.pushMatrix();
        pg.translate(fragPos, 0, 0);
        for (int i = 0; i < fragments.length; i++) {
          fragments[i].displayVertices(pg);
        }
      pg.popMatrix();
    }
  }
}

/*****************************************************************************************
* Exploding subclass - for cubeworms that explode like fireworks after beacon detonation *
*****************************************************************************************/
public class Explodeworm extends Pushworm {
  private boolean exploding; // has the worm started to explode?
  private ExplodeSphere[] spheres; // the worm core explodes into several layers of spheres
  private float explodePerc; // percentage of explosion animation
  private boolean drawWorm; // do we actually draw the worm? (no, after explosion starts)
  private ArrayList<TrailPoint> faceTrails; // facecube trails. The last object in the list is the actual facecube
  
  public Explodeworm(Cubeworm c) {
    super(c);
    // randomise initial speed, somewhat
    maxSpeed = MAX_EXP_SPEED;
    maxSpeed += maxSpeed * random(0, MAX_INIT_SPEED_MOD);
    resetSpeed = EXP_DET_SPEED; // worm updates (explodes) when speed = this
    explodePerc = 0;
    drawWorm = true;
    
    // facecubes leave a trail behind when exploding, but they're identical so we just need one list
    faceTrails = new ArrayList<TrailPoint>();
    // bit of a hack - have the last object in the list as the actual facecube. Makes coding drawFaces simpler
    faceTrails.add(new TrailPoint(FACECUBE_DIST, FACECUBE_SIZE));
  }
  
  public void update() {
    if (!exploding) {
      pulseSpeed += EXP_PULSE_INC;
      super.update();
    } else if (explodePerc >= 1) {
      updateExplosionFinished();
    } else {
      updateExplosionActive();
    }
  }

  // explosion finished: decay remaining facecube trails, then sleep
  private void updateExplosionFinished() {
    if (faceTrails.size() > 0) {
      updateFaceTrails(true);
    } else {
      worms[id()] = new Sleepworm(this);
    }
  }

  // explosion in progress: advance spheres, trails, and facecubes
  private void updateExplosionActive() {
    explodePerc = min(explodePerc + EXPLODE_SPEED, 1);
    float easedPerc = MathUtils.easeOutCubic(explodePerc);
    for (int i = 0; i < spheres.length; i++) {
      spheres[i].update(explodePerc, easedPerc);
    }
    updateTrailNoSpawn();
    updateExplodingFacecubes(easedPerc);
    if (drawWorm && spheres[spheres.length - 1].r > WORM_SIZE / 2) {
      drawWorm = false;
    }
  }

  // update facecube positions and trails during explosion
  private void updateExplodingFacecubes(float easedPerc) {
    int trailSize = faceTrails.size();
    float facecubeSize = FACECUBE_SIZE * invEaseInQuint(explodePerc);
    if (frameCount % FACETRAIL_SPAWN_FREQ == 0) {
      faceTrails.add(new TrailPoint(FACECUBE_EXP_DIST * easedPerc, facecubeSize));
    } else {
      faceTrails.get(trailSize - 1).reset(FACECUBE_EXP_DIST * easedPerc, facecubeSize);
    }
    updateFaceTrails(false);
  }
  
  // update TrailPoints in facecube trails
  private void updateFaceTrails(boolean doLast) {
    // the last object in the list is the actual facecube - unless the explosion is finished,
    // we don't want to decay its size
    int loopFrom = doLast ? 1 : 2;
    for (int i = faceTrails.size() - loopFrom; i >= 0; i--) {
      TrailPoint p = faceTrails.get(i);
      p.update();
      if (!p.isAlive()) {
        faceTrails.remove(i);
      }
    }
  }
  
  // rather than converting to another type of worm, move to second phase of explosion animation
  void convertWorm() {
    strokeW = MAX_EDGE;
    // create spheres of stars forming explosion
    spheres = new ExplodeSphere[EXP_SPHERE_COUNT];
    int icosaRecurseCount = EXP_OUTER_SPHERE_RECURSE;
    // each spheres' stars take turns to pulse, starting at a given anim %
    float pulseTime = (1.0f - STAR_PULSE_BEGIN) / EXP_SPHERE_COUNT;
    for (int i = EXP_SPHERE_COUNT - 1; i >= 0; i--) {
      float sphereRad = EXP_OUTER_SPHERE_RAD * (float(i+1) / EXP_SPHERE_COUNT);
      float pulseStart = STAR_PULSE_BEGIN + pulseTime * i;
      spheres[i] = new ExplodeSphere(sphereRad, icosaRecurseCount, pulseStart, pulseTime, cols.vertHue(), cols.vertSat(), cols.vertBright());
      icosaRecurseCount = max(icosaRecurseCount - 1, 0); // don't try to recurse < 0 times!
    }
    exploding = true;
  }
  
  // inverted quintic ease in - start from 1, decrease slowly, finish rapidly at 0
  private float invEaseInQuint(float perc) {
    return pow(perc, 5) * -1 + 1; // magic number 5 is for quintic power
  }
  
  void displayFaces(PGraphics pg) {
    if (drawWorm) {
      super.displayFaces(pg);
    }
  }
  
  // just copied/pasted from Roamworm with new bits for the explosion added in the middle
  void displayVertices(PGraphics pg) {
    pg.pushMatrix();
      translateRotate(pg);
      pg.stroke(cols.vertHue(), cols.vertSat(), cols.vertBright(), MAX_SBA);
      pg.strokeWeight(strokeW);
      if (drawWorm) {
        pg.box(WORM_SIZE);
      }
      drawFacecubes(pg, FACECUBE_DIST);
      // display spheres last because they might change the draw hue
      if (exploding) {
        for (int i = 0; i < spheres.length; i++) {
          spheres[i].displayVertices(pg);
        }
      }
    pg.popMatrix();
    drawTrailVertices(pg);
  }
  
  // copied/pasted from Roamworm with new bits for when we are exploding
  public void drawFacecubes(PGraphics pg, float fcubeSize, float fcubeDist, float rotOffset) {
    if (!exploding) {
      super.drawFacecubes(pg, fcubeSize, fcubeDist, rotOffset);
    } else {
      // facecubes fly off like comets in explosion 
      pg.pushMatrix();
      for (int i = 0; i < facecubes; i++) {
        for (TrailPoint p : faceTrails) {
          pg.pushMatrix();
          pg.translate(0, p.y, 0);
          pg.box(p.s);
          pg.popMatrix();
        }
        pg.rotateX(TWO_PI * (1.0f / facecubes));
      }
      pg.popMatrix();
    }
  }
  
  // class that looks after an explosion shell of the Explodeworm core detionation
  private class ExplodeSphere {
    float r, maxR; // current and maximum radius of explosion sphere
    PVector[] stars; // all stars in explosion shell (normalised)
    float starRad; // radius of explosion stars
    float pulseStart, pulseMid; // animation percentages for the star pulse
    float pulseTime; // duration of pulse animation (as percentage of full Explodeworm animation)
    float initHue, curHue, hueStep; // inital & current hue, and change per animation % (changes in 1st half of pulse anim)
    float s, b; // saturation & brightness
    boolean finished; // has this sphere finished animating?
    
    private ExplodeSphere(float maxR, int recurseCount, float pulseStart, float pulseTime, float initHue, float s, float b) {
      r = 0;
      this.maxR = maxR;
      starRad = STAR_INIT_RAD;
      this.pulseStart = pulseStart;
      this.pulseTime = pulseTime;
      pulseMid = pulseStart + pulseTime/2;
      Icosasphere iSphere = new Icosasphere(recurseCount);
      stars = iSphere.getAllPoints();
      
      // calculate hue & change per % of animation
      this.initHue = curHue = initHue;
      this.s = s;
      this.b = b;
      float targetHue = initHue + random(STAR_MIN_COL_DIFF, STAR_MAX_COL_DIFF) * MathUtils.randomSign();
      targetHue = HSBWrap(targetHue);
      // take most direct path to target hue, wrapping around 0 if necessary (actual wrapping happens in update())
      float forward, backward;
      if (targetHue > initHue) {
        forward = targetHue - initHue;
        backward = ((initHue + MAX_H) - targetHue) * -1;
      } else {
        forward = (targetHue + MAX_H) - initHue;
        backward = (initHue - targetHue) * -1;
      }
      hueStep = abs(forward) < abs(backward) ? forward : backward;
      hueStep /= (pulseMid - pulseStart);
    }
    
    private void update(float animPerc, float easedPerc) {
      // don't do anything if stars have already pulsed and faded
      if (!finished) {
        if (animPerc < pulseStart + pulseTime) {
          r = maxR * easedPerc;
          // if animation has passed startPulse, calculate star radius ("pulse")
          if (animPerc > pulseStart) {
            // frankensteined cosines give: STAR_INIT_RAD -> STAR_MAX_RAD for pulseStart -> pulseMid
            //                              STAR_MAX_RAD -> 0 for pulseMid -> pulseEnd
            float freq = TWO_PI / pulseTime;
            starRad = (cos(freq * animPerc + PI - (freq * pulseStart)) + 1) / 2;
            if (animPerc < pulseMid) {
              // starRad growing from STAR_INIT_RAD to STAR_MAX_RAD (also change hue)
              starRad = starRad * (STAR_MAX_RAD - STAR_INIT_RAD) + STAR_INIT_RAD;
              curHue = HSBWrap(initHue + hueStep * (animPerc - pulseStart));
            } else {
              // starRad shrinking from STAR_MAX_RAD to 0
              starRad *= STAR_MAX_RAD;
            }
          }
        } else {
          // ignore all future animation requests from parent
          finished = true;
        }
      }
    }
    
    // quick and dirty way to stop HSB hue from going out of bounds
    private float HSBWrap(float h) {
      if (h < 0) {return h + MAX_H;}
      if (h > MAX_H) {return h - MAX_H;}
      return h;
    }
    
    private void displayVertices(PGraphics pg) {
      if (!finished) {
        pg.stroke(curHue, s, b, MAX_SBA);
        for (int i = 0; i < stars.length; i++) {
          pg.pushMatrix();
            pg.translate(stars[i].x * r, stars[i].y * r, stars[i].z * r);
            pg.sphere(starRad);
          pg.popMatrix();
        }
      }
    }
  }
  
  // TODO: consider a more efficient approach here
  private class TrailPoint {
    float s, y; // size & y-coord
    private TrailPoint(float y, float s) {
      reset(y, s);
    }
    
    private void reset(float y, float s) {
      this.s = s;
      this.y = y;
    }
    
    private void update() {
      s -= FACETRAIL_DECAY;
    }
    
    private boolean isAlive() {
      return s > 0;
    }
  }
}

/*****************************************************************************************
* Recovering subclass - for cubeworms that managed to recover from a beacon detonation   *
* (either they weren't close enough to the beacon when it detonated, or they were lucky) *
*****************************************************************************************/
public class Recoverworm extends Travelworm {
  public Recoverworm(Cubeworm c) {
    super(c);
    dest = getSpawnPos();
  }
  
  // after runing movement/appearance, check to see if worm is close to our recovery destination
  public void update() {
    super.update();
    
    // is recovery complete? If so, convert back to roamworm
    if (distToDest < RECOVER_RAD) {
      worms[id()] = new Roamworm(this);
    }
  }
}

/*********************************************************************
* Sleeping subclass - for cubeworms are resting before (re-)spawning *
*********************************************************************/
public class Sleepworm extends Cubeworm {
  private int sleepTime;
  
  public Sleepworm(int id) {
    super(id);
    sleepTime = goToSleep();
  }
  
  public Sleepworm(Cubeworm c) {
    super(c);
    sleepTime = goToSleep();
    trail = new ArrayList<Trailcube>(); // clear left-over trailcubes
  }
  
  // to calc sleep time, find the sleepworm with the longest sleep time and then sleep for longer
  private int goToSleep() {
    int longestSleep = 0;
    for (int i = 0; i < worms.length; i++) {
      if (worms[i] instanceof Sleepworm) {
        Sleepworm s = (Sleepworm)worms[i];
        longestSleep = max(longestSleep, s.sleepTime);
      }
    }
    return longestSleep + round(random(MIN_SPAWN_DELAY, MAX_SPAWN_DELAY));
  }
  
  // keep sleeping until it is time to respawn
  public void update() {
    if (sleepTime <= 0) {
      worms[id()] = new Spawnworm(this);
    } else {
      sleepTime--;
    }
  }
  
  // Sleepworms ignore beacons
  public void beaconPlaced() {}
  
  // sleeping worms aren't displayed!
  public void displayFaces(PGraphics pg) {}
  public void displayVertices(PGraphics pg) {}
}

// different phases of spawing animation
public enum AStep {
  FACECUBE_GROW,
  FACECUBE_SPLIT,
  CUBEWORM_GROW {
    @Override
    public AStep nextStepOrNull() {
      return null; // there is no next value to increment to after CUBEWORM_GROW
    };
  };
  
  // increment the enum
  public AStep nextStepOrNull() {
    return values()[ordinal() + 1];
  }
}

// different ways that a worm can be exploded to death
public enum ExplodeType {
  SPLITWORM,
  EXPLODEWORM;
}
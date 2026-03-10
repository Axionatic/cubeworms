// licensed under Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)
// https://creativecommons.org/licenses/by-sa/4.0/

// beacon that attracts cubeworms and detonates on click
// worms are attracted to a spherical cap around beacon, located between beacon and (0,0,0)
public class Beacon {
  private BeaconState state; // current state of the beacon
  private int spawnFrame; // frame on which beacon was placed
  private float coreRad; // radius of beacon core
  private PVector pos; // beacon position
  private PVector capPos; // centre position of base of spherical cap
  private float capRad; // radius of spherical cap that worms are attracted to
  private PPlane capPlane; // plane on which base of spherical cap facing (0,0,0) lies
  private PVector rot; // rotate beacon such that it faces (0,0,0) and rotates around position vector
  private float spinTheta; // beacon rotates around position vector
  private Particle[] particles; // particles that orbit(?) the beacon
  private int detonationFrame; // detonation animation frame
  private float detonationPercent; // easier to calc once per frame than re-calc for every particle
  private float detonationRadiusMod; // radius modifier during detonation animation
  private float alpha; // sphere alpha, fades during detonation
  
  public Beacon() {
    state = BeaconState.INACTIVE;
    alpha = MAX_SBA;

    // cap radius will always be the same regardless of position
    // http://mathworld.wolfram.com/SphericalCap.html
    float h = BEACON_ATTRACT_RADIUS - BEACON_CAP_HEIGHT;
    capRad = sqrt(h * (2*BEACON_ATTRACT_RADIUS - h));
    
    particles = new Particle[P_COUNT];
    for (int i = 0; i < particles.length; i++) {
      particles[i] = new Particle(i);
    }
  }
  
  public void update() {
    rot = calcRot();
    // run particles
    for (int i = 0; i < particles.length; i++) {
      particles[i].update();
    }
    
    // calculate beacon core radius
    float spawnPerc = float(frameCount - spawnFrame) / B_SPAWN_LEN;
    if (spawnPerc < 1) {
      // cubic ease out of spawn animation
      coreRad = MathUtils.easeOutCubic(spawnPerc) * BEACON_CORE;
    } else {
      // normal core radius
      coreRad = BEACON_CORE;
    }

    // modify beacon radius if we are detonating (and calc alpha)
    if (state == BeaconState.DETONATING) {
      detonationPercent = float(detonationFrame) / B_DET_FRAMES;
      float detAnim = MathUtils.easeOutCubic(detonationPercent);
      alpha = MAX_SBA - (MAX_SBA * detAnim);
      detonationRadiusMod = coreRad * B_DET_RAD_MULT * detAnim;
      detonationFrame++;

      // finished detonation animation?
      if (detonationFrame > B_DET_FRAMES) {
        state = BeaconState.INACTIVE;
      }
    }
  }
  
  // activate the beacon, placing it at point p
  public void activate(PVector p) {
    state = BeaconState.ACTIVE;
    pos = p;
    spawnFrame = frameCount;
    coreRad = detonationRadiusMod = spinTheta = 0;
    detonationFrame = 0;
    detonationPercent = 0;
    alpha = MAX_SBA;
    
    // capPos: BEACON_CAP_HEIGHT units from the beacon toward the origin, centering the attractive
    // spherical cap on the side of the beacon facing (0,0,0)
    capPos = PVector.mult(pos, -1);
    capPos.normalize();
    capPos.mult(BEACON_CAP_HEIGHT);
    capPos.add(pos);
    
    // calculate plane on which cap lies
    capPlane = new PPlane(capPos, capPos); // capPos is both a point on the plane and normal to the plane
    
    // particles sleep for a while before emerging from beacon core
    for (int i = 0; i < particles.length; i++) {
      particles[i].sleep();
    }
    
    // hypnotise all eligible worms
    for (int i = 0; i < worms.length; i++) {
      worms[i].beaconPlaced();
    }
  }
  
  // detonate the beacon! Boom! Take that, worms!
  public void detonate() {
    // tell particles to record current position for use in explosion
    for (int i = 0; i < particles.length; i++) {
      particles[i].beaconDetonated();
    }
    
    state = BeaconState.DETONATING;
    
    // worms too close to the explosion also explode, others return to roaming 
    for (int i = 0; i < worms.length; i++) {
      worms[i].beaconDetonated();
    }
  }
  
  // calculate rotation of beacon: 1st rotate to point towards (0,0,0), then rotate around position vector
  public PVector calcRot() {
    // beacon "faces" up (0,0,-1) by default
    PVector init = new PVector(0,0,-1);
    // from pos, need to face towards (0,0,0)
    PVector v = PVector.mult(pos, -1);
    // cross product of plane described by inital and target orientation vectors = normal vector (axis)
    PVector axis = init.cross(v);
    float theta = MathUtils.findTheta(init, v);
    Quaternion facing = new Quaternion(theta, axis);
    
    // beacon rotates around position vector, stopping during detonation
    float deltaSpin = B_ROT_SPEED;
    if (state == BeaconState.DETONATING) {
      // use quadratic curve to slowly stop spinning by a given % of detonation animation
      float stopSpinFrame = float(B_DET_FRAMES) * B_DET_ROT_STOP;
      if (detonationFrame > stopSpinFrame) {
        deltaSpin = 0;
      } else {
        float stopSpinPerc = float(detonationFrame) / stopSpinFrame;
        deltaSpin *= sq(1 - stopSpinPerc); // quadratic ease out
      }
    }
    spinTheta += deltaSpin;
    
    Quaternion rotation = new Quaternion(spinTheta, pos.copy());
    Quaternion q = facing.mult(rotation);
    return q.eulers();
  }
  
  public boolean isActive() { return state == BeaconState.ACTIVE; }
  public boolean isVisible() { return state != BeaconState.INACTIVE; }
  public boolean isDetonating() { return state == BeaconState.DETONATING; }
  public PVector pos() { return pos; }
  public float capRad() { return capRad; }
  public PPlane capPlane() { return capPlane; }
  public float detonationPercent() { return detonationPercent; }

  public void display(PGraphics pg) {
    pg.pushMatrix();
      pg.translate(pos.x, pos.y, pos.z);
      pg.rotateZ(rot.z); 
      pg.rotateY(rot.y);
      pg.rotateX(rot.x);
      
      // draw particles around beacon
      pg.sphereDetail(P_LONGRES, P_LATRES);
      pg.strokeWeight(P_STROKE_WEIGHT);
      for (int i = 0; i < particles.length; i++) {
        particles[i].display(pg);
      }
      
      // draw beacon core
      pg.sphereDetail(B_SPHERE_DETAIL);
      pg.stroke(B_CORE_COL, alpha);
      pg.strokeWeight(1);
      pg.noFill(); // draw core as wireframe so the particles inside remain visible
      pg.sphere(coreRad + detonationRadiusMod);
      pg.fill(0, 0, 0, MAX_SBA);
    pg.popMatrix();
  }
}

public enum BeaconState {
  INACTIVE,
  ACTIVE,
  DETONATING;
}
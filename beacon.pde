// licensed under Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)
// https://creativecommons.org/licenses/by-sa/4.0/

// beacon that attracts cubeworms and detonates on click
// worms are attracted to a spherical cap around beacon, located between beacon and (0,0,0)
public class Beacon {
  boolean active; // is beacon currently active?
  boolean displayed; // display the beacon? (during detonation beacon is inactive but still displayed) 
  int spawnFrame; // frame on which beacon was placed
  float coreRad; // radius of beacon core
  PVector pos; // beacon position
  PVector capPos; // centre position of base of spherical cap
  float capRad; // radius of spherical cap that worms are attracted to
  PPlane capPlane; // plane on which base of spheical cap facing (0,0,0) lies
  PVector rot; // rotate beacon such that it faces (0,0,0) and rotates around position vector
  float spinTheta; // beacon rotates around position vector 
  Particle[] particles; // particles that orbit(?) the beacon
  boolean detLock; // lock placing/detonating during detonation animation
  int detFrame; // detonation animation frame
  float detPerc; // easier to calc once per frame than re-calc for every particle
  float detRadMod; // radius modifier during detonation animation
  float alpha; // sphere alpha, fades during detonation
  
  public Beacon() {
    active = false;
    displayed = false;
    spawnFrame = 0;
    pos = new PVector();
    capPos = new PVector();
    capPlane = new PPlane();
    spinTheta = 0;
    detLock = false;
    detFrame = 0;
    detPerc = 0;
    detRadMod = 0;
    alpha = MAX_SBA;
    
    // cap radius will always be the same regardless of position
    // http://mathworld.wolfram.com/SphericalCap.html
    float h = B_ATTR_RAD - B_CAP_H;
    capRad = sqrt(h * (2*B_ATTR_RAD - h));
    
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
      coreRad = cubEaseOut(spawnPerc) * BEACON_CORE;
    } else {
      // normal core radius
      coreRad = BEACON_CORE;
    }

    // modify beacon radius if we are detonating (and calc alpha)
    if (detLock) {
      detPerc = float(detFrame) / B_DET_FRAMES;
      float detAnim = cubEaseOut(detPerc);
      alpha = MAX_SBA - (MAX_SBA * detAnim);
      detRadMod = coreRad * B_DET_RAD_MULT * detAnim;
      detFrame++;
      
      // finished detonation animation?
      if (detFrame > B_DET_FRAMES) {
        displayed = false;
        detLock = false;
      }
    }
  }
  
  // activate the beacon, placing it at point p
  public void activate(PVector p) {
    active = true;
    displayed = true;
    pos = p;
    spawnFrame = frameCount;
    coreRad = detRadMod = spinTheta = 0;
    detFrame = 0;
    detPerc = 0;
    alpha = MAX_SBA;
    
    // capPos: B_CAP_H units from the beacon toward the origin, centering the attractive
    // spherical cap on the side of the beacon facing (0,0,0)
    capPos = PVector.mult(pos, -1);
    capPos.normalize();
    capPos.mult(B_CAP_H);
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
    
    active = false;
    detLock = true;
    
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
    // angle theta between initial and target orientations: cos(theta) = (a dot b)/(|a|*|b|)
    // clamp to [-1, 1] to guard against floating-point drift causing acos to return NaN
    float theta = acos(constrain(PVector.dot(init, v) / (init.mag() * v.mag()), -1.0, 1.0));
    Quaternion facing = new Quaternion(theta, axis);
    
    // beacon rotates around position vector, stopping during detonation
    float deltaSpin = B_ROT_SPEED; 
    if (detLock) {
      // use quadratic curve to slowly stop spinning by a given % of detonation animation
      float stopSpinFrame = float(B_DET_FRAMES) * B_DET_ROT_STOP;
      if (detFrame > stopSpinFrame) {
        deltaSpin = 0;
      } else {
        float stopSpinPerc = float(detFrame) / stopSpinFrame;
        deltaSpin *= sq(1 - stopSpinPerc); // quadratic ease out
      }
    }
    spinTheta += deltaSpin;
    
    Quaternion rotation = new Quaternion(spinTheta, pos.copy());
    Quaternion q = facing.mult(rotation);
    return q.eulers();
  }
  
  // cubic ease-out calculation (start fast, finish slow)
  private float cubEaseOut(float perc) {
    return 1 - pow(1-perc, 3); // magic number 3 is for cube power
  }
  
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
      pg.sphere(coreRad + detRadMod);
      pg.fill(0, 0, 0, MAX_SBA);
    pg.popMatrix();
  }
}
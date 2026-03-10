// licensed under Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)
// https://creativecommons.org/licenses/by-sa/4.0/

// Particles that make up the beacon (aside from the core, which is just a sphere)
public class Particle {
  private Point head; // "head" of particle
  private Point[] trail; // trail of points left behind particle
  private float yRot; // rotation around centre of beacon in Y (initial facing (1,0,0))
  private float zRot; // rotation around centre of beacon in Z. Only from -HALF_PI to HALF_PI
  private float xAmplitude; // amplitude of sine wave governing particle x pos
  private float yAmplitude; // amplitude of sine wave governing particle y pos
  private int animFrame; // current animation frame
  private int sleepTime; // frames of "sleep" before particle is displayed
  private PVector[] detPath; // series of points particle curves around during detonation
  
  public Particle(int id) {
    animFrame = P_SPAWN_FRAME;
    sleepTime = 0; // randomised on beacon activation
    detPath = new PVector[round(random(P_MIN_DET_PATH_LEN, P_MAX_DET_PATH_LEN))];
    
    // particle starts hidden inside beacon core
    head = new Point(0, 0, MAX_H, P_RADIUS, 0);
    trail = new Point[P_TRAIL_LEN];
    for (int i = 0; i < P_TRAIL_LEN; i++) {
      trail[i] = new Point(0,0,0,0,0);
    }
    
    // randomise movement
    yRot = (float(id) / P_COUNT) * TWO_PI; // particles are evenly distributed around beacon
    zRot = random(-QUARTER_PI, QUARTER_PI); // prevent beacon from just looking like magnetic field lines
    xAmplitude = random(P_X_AMP_MIN, P_X_AMP_MAX);
    yAmplitude = random(P_Y_AMP_MIN, P_Y_AMP_MAX) * -1; // downwards = y+ in processing
  }
  
  public void update() {
    if (sleepTime > 0) {
      sleepTime--;
    } else {
      if (beacon.isDetonating()) {
        updateDetonation();
      } else {
        updateOrbit();
      }
      head.zRot = TWO_PI * (float(frameCount) / P_ROT_SPEED);
      updateTrail();
      animFrame++;
      if (animFrame >= P_PERIOD) {
        animFrame = 0;
      }
    }
  }

  // particle curves along Catmull-Rom detonation path while beacon explodes
  private void updateDetonation() {
    float stepPerc = beacon.detonationPercent() * (detPath.length - 1);
    int pathStep = int(stepPerc);
    int pathNext = min(pathStep + 1, detPath.length - 1);
    stepPerc -= pathStep;
    PVector basePos = detPath[pathStep];
    PVector baseControl = detPath[max(pathStep - 1, 0)];
    PVector nextPos = detPath[pathNext];
    PVector nextControl = detPath[min(pathNext + 1, detPath.length - 1)];
    head.x = curvePoint(baseControl.x, basePos.x, nextPos.x, nextControl.x, stepPerc);
    head.y = curvePoint(baseControl.y, basePos.y, nextPos.y, nextControl.y, stepPerc);
    head.z = curvePoint(baseControl.z, basePos.z, nextPos.z, nextControl.z, stepPerc);
    head.r = P_RADIUS * (1 - beacon.detonationPercent());
    head.h -= 5;
    if (head.h < 0) { head.h += MAX_H; }
  }

  // normal orbit around beacon core on a sine-wave path
  private void updateOrbit() {
    float f = float(animFrame) / P_PERIOD;
    f = MathUtils.easeInOut(f, 3);
    float radians = f * TWO_PI;
    head.x = (sin(radians - HALF_PI) * xAmplitude) + xAmplitude;
    head.y = sin(radians) * yAmplitude;
    float yMod = (sin(radians - HALF_PI) + P_Y_MOD_CONST) * P_Y_MOD_AMP;
    head.y *= yMod;
    head.h = (1 - f) * MAX_H;
  }

  // decay existing trail points and spawn new ones on schedule
  private void updateTrail() {
    for (int i = 0; i < trail.length; i++) {
      trail[i].decayRad();
    }
    if (animFrame % P_TRAIL_FREQ == 0) {
      for (int i = trail.length - 1; i > 0; i--) {
        trail[i] = trail[i - 1];
      }
      trail[0] = new Point(head);
    }
  }
  
  // put particle to sleep for some amount of time (for beacon spawn animation)
  // also, prepare particle for next beacon detonation
  public void sleep() {
    sleepTime = B_SPAWN_LEN + round(random(0, P_PERIOD));
    animFrame = P_SPAWN_FRAME;
    head.x = 0;
    head.y = 0;
    head.z = 0;
    head.r = P_RADIUS;
    detPath = new PVector[round(random(P_MIN_DET_PATH_LEN, P_MAX_DET_PATH_LEN))];
    for (int i = 0; i < trail.length; i++) {
      trail[i].x = 0;
      trail[i].y = 0;
      trail[i].z = 0;
      trail[i].r = 0;
    }
  }
  
  // when beacon detonates, create detonation path starting at current position
  public void beaconDetonated() {
    if (sleepTime > 0) {
      // poor particle, it never got a chance...
      sleepTime += B_DET_FRAMES+1;
    } else {
      detPath[0] = new PVector(head.x, head.y, head.z);
      // particles inside beacon radius move to a random position (makes a more even-looking explosion)
      if (detPath[0].mag() < BEACON_CORE) {
        detPath[0] = new PVector(random(0,1), random(0,1), random(0,1));
        detPath[0].normalize();
      }
      // inject a bit of randomness into distance particle flies
      float startMag = detPath[0].mag();
      float posMultiplier = random(P_MIN_DET_MAG, P_MAX_DET_MAG) / startMag;
      // randomise positions on path
      for (int i = 1; i < detPath.length; i++) {
        float curMagMult = 1 + (posMultiplier - 1) * (float(i) / (detPath.length - 1));
        detPath[i] = PVector.mult(detPath[0], curMagMult);
        detPath[i].x += random(P_DET_MIN_POS_MOD, P_DET_MAX_POS_MOD);
        detPath[i].y += random(P_DET_MIN_POS_MOD, P_DET_MAX_POS_MOD);
        detPath[i].z += random(P_DET_MIN_POS_MOD, P_DET_MAX_POS_MOD);
      }
    }
  }
  
  public void display(PGraphics pg) {
    if (sleepTime < 1) {
      pg.pushMatrix();
        pg.rotateX(-HALF_PI);
        pg.rotateY(yRot);
        pg.rotateZ(zRot);
        // display point trail in reverse order so smaller points are drawn inside larger points if applicable
        for (int i = P_TRAIL_LEN-1; i >= 0; i--) {
          Point p = trail[i];
          pg.stroke(p.h, MAX_SBA, MAX_SBA, MAX_SBA);
          pg.pushMatrix();
            pg.translate(p.x, p.y, p.z);
            pg.rotateZ(p.zRot);
            pg.sphere(p.r);
          pg.popMatrix();
        }
        // draw "head" point
        pg.stroke(head.h, MAX_SBA, MAX_SBA, MAX_SBA);
        pg.pushMatrix();
          pg.translate(head.x, head.y, head.z);
          pg.rotateZ(head.zRot);
          pg.sphere(head.r);
        pg.popMatrix();
      pg.popMatrix();
    }
  }
  
  // helper class for particle: record all the details for a point in the particle
  private class Point {
    float x; // x pos
    float y; // y pos
    float z; // z pos (zero until exploding)
    float h; // hue
    float r; // radius
    float rDecay; // radius decay per frame
    float zRot; // Z rotation to face "forward"
                //(would be Y, but we already rotated around X by -HALF_PI)
    
    private Point(float x, float y, float h, float r, float zRot) {
      this.x = x;
      this.y = y;
      z = 0;
      this.h = h;
      this.r = r;
      this.zRot = zRot;
      calcRadDecay();
    }
    
    // copy constructor
    private Point(Point p) {
      x = p.x;
      y = p.y;
      z = p.z;
      h = p.h;
      r = p.r;
      zRot = p.zRot;
      calcRadDecay();
    }
    
    // particle shrinks over time
    private void decayRad() {
      r -= rDecay;
    }
    
    // calculated such that particles shrink nice and linearly
    private void calcRadDecay() {
      rDecay = r / (P_TRAIL_LEN * P_TRAIL_FREQ);
    }
  }
}
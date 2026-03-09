// licensed under Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)
// https://creativecommons.org/licenses/by-sa/4.0/
//
// Instructions: left click to place/detonate beacon. Right click and drag to rotate around origin (0,0,0)
//               Scroll to zoom. Press backspace to reset rotation/zoom. 

PShader bloom, blur;
PGraphics faces, vertices, brightPass, hBlur, vBlur;
Quaternion rot;
PVector rotateAround, eulers;
boolean rotApplied;
int sketchScale;
float baseX, baseY;
float deltaX, deltaY;
Cubeworm[] worms;
Beacon beacon;

void setup() {
  fullScreen(P3D);
  frameRate(60);
  colorMode(HSB, MAX_H, MAX_SBA, MAX_SBA, MAX_SBA);
  CAMERA_Z = (height/2.0) / tan(PI*60.0/360.0); // default processing camera z-pos
  HITHER = CAMERA_Z - (CAMERA_Z / 10); // default processing hither/near z-pos of view frustum
  BEACON_Z = SKETCH_Z + WALL_RAD; // Beacon pos is BEACON_Z_PERC % between near point of wall & hither
  BEACON_Z = WALL_RAD + (HITHER - BEACON_Z) * BEACON_Z_PERC;
  BEACON_Z -= BEACON_CORE / 2;
  // knowing beacon z pos & frustum fov angle, we can use trig to calc frustum dimensions at beacon z
  float theta = FOV_Y / 2;
  B_F_Y_LEN = tan(theta) * (CAMERA_Z - (SKETCH_Z + BEACON_Z + BEACON_CORE/2)); // (SKETCH_Z is negative)
  B_F_X_LEN = B_F_Y_LEN * (float(width)/float(height)); // (actually these values are len/2)
  
  // PGraphics
  faces = createGraphics(width, height, P3D); // faces of cubeworms (reflective)
  vertices = createGraphics(width, height, P3D); // vertices of cubeworms (glowing)
  brightPass = createGraphics(width, height, P2D); // brightpass filter for glow effect
  hBlur = createGraphics(width, height, P2D); // horizontal component of gaussian blur (for glow)
  vBlur = createGraphics(width, height, P2D); // vertical component of gaussian blur (for glow)
  brightPass.noSmooth();
  hBlur.noSmooth();
  vBlur.noSmooth();
  
  // shaders
  bloom = loadShader("bloomFrag.glsl");
  blur = loadShader("blurFrag.glsl");
  bloom.set("brightPassThreshold", BRIGHT_PASS);
  blur.set("blurSize", BLUR_SIZE);
  blur.set("sigma", BLUR_SIGMA);
  
  // click & drag rotation
  rot = new Quaternion();
  rotateAround = new PVector();
  eulers = new PVector();
  rotApplied = true;
  sketchScale = INIT_ZOOM;
  
  // cubeworms
  worms = new Cubeworm[WORM_COUNT];
  for (int i = 0; i < WORM_COUNT; i++) {
    worms[i] = new Sleepworm(i);
  }
  beacon = new Beacon();
}

void draw() {
  if (!rotApplied) {
    eulers = calcRotation();
    rotApplied = true;
  }
  // process worms
  for (int i = 0; i < WORM_COUNT; i++) {
    worms[i].update();
  }
  
  // draw faces
  faces.beginDraw();
  faces.colorMode(HSB, MAX_H, MAX_SBA, MAX_SBA, MAX_SBA);
  faces.ellipseMode(RADIUS);
  faces.background(BACKGROUND, MAX_SBA);
  faces.noStroke();
  faces.lightSpecular(0, 0, MAX_SBA);
  faces.directionalLight(D_LIGHT, D_LIGHT, D_LIGHT, 0, 0, -1);
  faces.shininess(SHININESS);
  faces.pushMatrix();
    translateRotateScale(faces, eulers);
    
    for (int i = 0; i < WORM_COUNT; i++) {
      worms[i].displayFaces(faces);
    }
  faces.popMatrix();
  faces.endDraw();
  
  // draw vertices
  // seems inefficient to duplicate a lot of this :-/
  vertices.beginDraw();
  vertices.colorMode(HSB, MAX_H, MAX_SBA, MAX_SBA, MAX_SBA);
  vertices.ellipseMode(RADIUS);
  vertices.background(BACKGROUND, 0);
  vertices.fill(0, 0, 0, MAX_SBA); // black fill to occlude rear vertices
  vertices.pushMatrix();
    translateRotateScale(vertices, eulers);
    vertices.sphereDetail(P_LONGRES, P_LATRES); // some worms use little spheres
    for (int i = 0; i < WORM_COUNT; i++) {
      worms[i].displayVertices(vertices);
    }
    if (beacon.displayed) {
      beacon.update();
      beacon.display(vertices);
    }
  vertices.popMatrix();
  vertices.endDraw();
  
  // bright pass
  brightPass.beginDraw();
  brightPass.shader(bloom);
  brightPass.image(vertices, 0, 0);
  brightPass.endDraw();
  
   //blur: horizontal pass
  blur.set("horizontalPass", 1);
  hBlur.beginDraw();
  hBlur.shader(blur);
  hBlur.image(brightPass, 0, 0);
  hBlur.endDraw();
  
  // blur: vertical pass
  blur.set("horizontalPass", 0);
  vBlur.beginDraw();
  vBlur.shader(blur);
  vBlur.image(hBlur, 0, 0);
  vBlur.endDraw();
  
  // will it blend?
  blendMode(BLEND);
  image(faces,0,0);
  blendMode(SCREEN);
  image(vertices,0,0);
  blendMode(ADD);
  for (int i = 0; i < GLOW_STRENGTH; i++) {
    image(vBlur,0,0);
  }
  blendMode(BLEND);
  
  fill(0, 0, MAX_SBA, MAX_SBA);
  text(frameRate, 20, 20);
}

// use black quaternion magic to calculate X, Y, Z rotations for click & drag
PVector calcRotation() {
    // rotation vector is created by moving the mouse 1 or more pixels 
    float a = rotateAround.mag() * MOUSE_SENSITIVITY;
    // need to rotate around the perpendicular (in X,Y) vector
    rotateAround.rotate(HALF_PI);
    // create the rotation... 
    Quaternion rotNext = new Quaternion(a, rotateAround);
     //... then apply it!
    rot = rot.mult(rotNext);
    // and translate into euler angles
    return rot.eulers();
}

// apply the current rotation & scale to a PGraphics object
void translateRotateScale(PGraphics pg, PVector eulers) {
  pg.translate(width/2, height/2, SKETCH_Z);
  pg.rotateZ(eulers.z); // TODO: understand and document why this rotation order is correct
  pg.rotateY(eulers.y);
  pg.rotateX(eulers.x);
  pg.scale(sketchScale * ZOOM_STEP);
}

// remember where the mouse was when clicked, for click & drag
void mousePressed() {
  if (mouseButton == RIGHT) {
    baseX = mouseX;
    baseY = mouseY;
  }
}

// create vectors based on mouse movements for rotations
void mouseDragged() {
  if ((mouseButton == RIGHT) && ((baseX != mouseX) || (baseY != mouseY))) {
    deltaX = mouseX - baseX;
    deltaY = mouseY - baseY;
    rotateAround = new PVector(deltaX, deltaY);
    
    baseX = mouseX;
    baseY = mouseY;
    // new rotation ready to be applied!
    rotApplied = false;
  }
}

// place and detonate attractor beacon
void mouseClicked() {
  if ((mouseButton == LEFT) && (!beacon.detLock)) {
    if (beacon.active) {
      beacon.detonate();
    } else {
      // place beacon at pre-specified z-pos under mouse X/Y
      // first calc pos if sketch has not yet been rotated...
      float hw = width/2; // half width
      float hh = height/2; // half height
      float bx = mouseX - hw;
      float by = mouseY - hh;
      bx = map(bx, -hw, hw, -B_F_X_LEN, B_F_X_LEN);
      by = map(by, -hh, hh, -B_F_Y_LEN, B_F_Y_LEN);
      PVector bPos = new PVector(bx, by, BEACON_Z);
      
      // ...then apply conjugate of rotation quaternion to get actual position
      Quaternion conj = rot.conj();
      bPos = conj.mult(bPos);
      bPos.mult(1 / (sketchScale * ZOOM_STEP)); // also account for sketch zoom
      beacon.activate(bPos);
    }
  }
}

void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  sketchScale = constrain(sketchScale - int(e), MIN_ZOOM, MAX_ZOOM);
}

// reset sketch rotation
void keyPressed() {
  if (key == BACKSPACE) {
    rot = new Quaternion();
    rotateAround = new PVector();
    rotApplied=false;
    sketchScale = INIT_ZOOM;
  }
}
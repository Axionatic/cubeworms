// licensed under Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)
// https://creativecommons.org/licenses/by-sa/4.0/

// stationary cubes that make up the trail behind the cubeworms. Quickly shrink into nothing
class Trailcube {
  float faceH, faceS; // hue & saturation of faces
  color vertC; // color of vertices
  PVector pos, rot; // position & rotation
  float size; // size (are these comments really that helpful?)

  public Trailcube(float faceH, float faceS, color vertC, PVector pos, PVector rot, float size) {
    this.faceH = faceH;
    this.faceS = faceS;
    this.vertC = vertC;
    this.pos = pos;
    this.rot = rot;
    this.size = size;
  }

  // trail slowly fades away
  public void update() {
    size -= T_DECAY;
  }

  // draw faces
  public void displayFaces(PGraphics pg) {
    applyTransform(pg);
      pg.specular(faceH, faceS, MAX_SBA);
      pg.fill(faceH, faceS, FACE_BRIGHTNESS, MAX_SBA);
      pg.box(size);
    pg.popMatrix();
  }

  // draw vertices
  public void displayVertices(PGraphics pg) {
    applyTransform(pg);
      pg.stroke(vertC);
      pg.box(size);
    pg.popMatrix();
  }

  private void applyTransform(PGraphics pg) {
    pg.pushMatrix();
    pg.translate(pos.x, pos.y, pos.z);
    pg.rotateZ(rot.z);
    pg.rotateY(rot.y);
    pg.rotateX(rot.x);
  }

  public boolean isAlive() {
    return (size > 0);
  }
}

// licensed under Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)
// https://creativecommons.org/licenses/by-sa/4.0/

// stationary cubes that make up the trail behind the cubeworms. Quickly shrink into nothing
class Trailcube {
  private float faceHue, faceSaturation; // hue & saturation of faces
  private color vertexColour; // colour of vertices
  private PVector pos, rot; // position & rotation
  private float size;

  public Trailcube(float faceHue, float faceSaturation, color vertexColour, PVector pos, PVector rot, float size) {
    this.faceHue = faceHue;
    this.faceSaturation = faceSaturation;
    this.vertexColour = vertexColour;
    this.pos = pos;
    this.rot = rot;
    this.size = size;
  }

  // trail slowly fades away
  public void update() {
    size -= TRAIL_DECAY;
  }

  // draw faces
  public void displayFaces(PGraphics pg) {
    applyTransform(pg);
      pg.specular(faceHue, faceSaturation, MAX_SBA);
      pg.fill(faceHue, faceSaturation, FACE_BRIGHTNESS, MAX_SBA);
      pg.box(size);
    pg.popMatrix();
  }

  // draw vertices
  public void displayVertices(PGraphics pg) {
    applyTransform(pg);
      pg.stroke(vertexColour);
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

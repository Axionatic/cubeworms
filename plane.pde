// licensed under Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)
// https://creativecommons.org/licenses/by-sa/4.0/

// simple class to represent a plane. "P"Plane because processing already has "P"Vector
// https://www.khanacademy.org/math/linear-algebra/vectors-and-spaces/dot-cross-products/v/defining-a-plane-in-r3-with-a-point-and-normal-vector
public class PPlane {
  float a, b, c, d; // for  plane representation (ax + by +cz = d)
  
  // simplest way to define a plane
  public PPlane (PVector point, PVector normal) {
    calcPlane(point, normal);
  }
  
  // default plane is XZ through (0,0,0)
  public PPlane() {
    calcPlane(new PVector(0,0,0), new PVector(0,1,0));
  }
  
  // define plane by any point on the plane & a vector normal to the plane
  private void calcPlane(PVector p, PVector norm) {
    a = norm.x;
    b = norm.y;
    c = norm.z;
    d = ((norm.x * -p.x) + (norm.y * -p.y) + (norm.z * -p.z)) * -1;
  }
  
  // find an intersection between plane and a vector starting at point p, travelling in direction v
  public PVector findIntersect(PVector p, PVector v) {
    float num = (a * p.x) + (b * p.y) + (c * p.z); // numerator: position dot normal
    float denom = (a * v.x) + (b * v.y) + (c * v.z); // denominator: direction dot normal

    if (denom == 0) {
      if (num == d) {
        // ray is coincident with plane: infinite intersections
        return null;
      } else {
        // ray is parallel to plane: no intersection
        return null;
      }
    } else {
      // single intersection: solve parametric ray equation for t
      float t = (d - num) / denom;
      return PVector.mult(v, t);
    }
  }
  
  // get vector orthogonal to plane
  public PVector normal() {
    return new PVector(a, b, c);
  }
}
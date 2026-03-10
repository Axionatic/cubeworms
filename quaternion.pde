/* code adapted (mostly copied) from Kynd
 * http://www.kynd.info/log/?p=611
 * https://github.com/kynd/PQuaternion
 *
 * "eulers" function from Thalmic Labs:
 * https://developer.thalmic.com/docs/api_reference/platform/hello-myo_8cpp-example.html
 * http://developerblog.myo.com/quaternions/
 *
 * All code & functions from above sources remain copyright of their respective owners
 */

public class Quaternion {
  private float x, y, z, w;

  public Quaternion() {
      x = y = z = 0;
      w = 1;
  }

  public Quaternion(float _x, float _y, float _z, float _w) {
      x = _x;
      y = _y;
      z = _z;
      w = _w;
  }

  public Quaternion(float angle, PVector axis) {
      setAngleAxis(angle, axis);
  }

  public Quaternion get() {
      return new Quaternion(x, y, z, w);
  }

  @Override
  public boolean equals(Object o) {
      if (!(o instanceof Quaternion)) return false;
      Quaternion q = (Quaternion) o;
      return x == q.x && y == q.y && z == q.z && w == q.w;
  }

  public void set(float _x, float _y, float _z, float _w) {
      x = _x;
      y = _y;
      z = _z;
      w = _w;
  }

  public void setAngleAxis(float angle, PVector axis) {
      axis = axis.normalize(null); // defensive copy to avoid mutating caller's vector
      float hcos = cos(angle / 2);
      float hsin = sin(angle / 2);
      w = hcos;
      x = axis.x * hsin;
      y = axis.y * hsin;
      z = axis.z * hsin;
  }

  public Quaternion conj() {
      Quaternion ret = new Quaternion();
      ret.x = -x;
      ret.y = -y;
      ret.z = -z;
      ret.w = w;
      return ret;
  }

  public Quaternion inverse() {
    Quaternion conj = conj();
    float normSq = w*w + x*x + y*y + z*z;
    return conj.mult(1/normSq);
  }

  public Quaternion mult(float r) {
      Quaternion ret = new Quaternion();
      ret.x = x * r;
      ret.y = y * r;
      ret.z = z * r;
      ret.w = w * r;
      return ret;
  }

  public Quaternion mult(Quaternion q) {
      Quaternion ret = new Quaternion();
      ret.x = q.w*x + q.x*w + q.y*z - q.z*y;
      ret.y = q.w*y - q.x*z + q.y*w + q.z*x;
      ret.z = q.w*z + q.x*y - q.y*x + q.z*w;
      ret.w = q.w*w - q.x*x - q.y*y - q.z*z;
      return ret;
  }

  public PVector mult(PVector v) {
    float px = (1 - 2 * y * y - 2 * z * z) * v.x +
               (2 * x * y - 2 * z * w) * v.y +
               (2 * x * z + 2 * y * w) * v.z;

    float py = (2 * x * y + 2 * z * w) * v.x +
               (1 - 2 * x * x - 2 * z * z) * v.y +
               (2 * y * z - 2 * x * w) * v.z;

    float pz = (2 * x * z - 2 * y * w) * v.x +
               (2 * y * z + 2 * x * w) * v.y +
               (1 - 2 * x * x - 2 * y * y) * v.z;

      return new PVector(px, py, pz);
  }

  // Calculate Euler angles (roll, pitch, and yaw) from the unit quaternion.
  public PVector eulers() {
    float roll = atan2(2.0f * (w * x + y * z), 1.0f - 2.0f * (x * x + y * y));
    float pitch = asin(max(-1.0f, min(1.0f, 2.0f * (w * y - z * x))));
    float yaw = atan2(2.0f * (w * z + x * y), 1.0f - 2.0f * (y * y + z * z));

    return new PVector(roll, pitch, yaw);
  }

  // return rotation represented as an angle around an axis
  public AngleAxis getAngleAxis() {
    if (abs(x) < 0.0001 && abs(y) < 0.0001 && abs(z) < 0.0001 && abs(w - 1) < 0.0001) {
      // quaternion is identity. Rotate around Y by 0 as a safe default
      return new AngleAxis(0, new PVector(0,1,0));
    } else {
      float angle = acos(w) * 2;
      float f = sin(angle/2);
      PVector axis = new PVector(x/f,y/f,z/f);
      return new AngleAxis(angle, axis);
    }
  }

  public void normalize() {
    float len = w*w + x*x + y*y + z*z;
    float factor = 1.0f / sqrt(len);
    x *= factor;
    y *= factor;
    z *= factor;
    w *= factor;
  }
}

// small class to represent rotation as an angle around an axis
public class AngleAxis {
  private final float angle;
  private final PVector axis;
  public AngleAxis(float angle, PVector axis) {
    this.angle = angle;
    this.axis = axis;
  }
  public float angle() { return angle; }
  public PVector axis() { return axis; }
}

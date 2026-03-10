// licensed under Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)
// https://creativecommons.org/licenses/by-sa/4.0/

// shared math utilities used across multiple classes
static class MathUtils {

  // randomly return 1 or -1
  static int randomSign() {
    return Math.random() >= 0.5 ? 1 : -1;
  }

  // angle theta between two vectors: cos(theta) = (v1 dot v2) / (|v1| * |v2|)
  // clamp to [-1, 1] to guard against floating-point drift causing acos to return NaN
  static float findTheta(PVector v1, PVector v2) {
    return acos(constrain(PVector.dot(v1, v2) / (v1.mag() * v2.mag()), -1.0, 1.0));
  }

  // symmetric ease in-out: accelerate until halfway, then decelerate (returns 0 to 1)
  // power controls the curve shape (3 = cubic, 4 = quartic, etc.)
  static float easeInOut(float perc, int power) {
    perc *= 2; // split animation into acceleration and deceleration halves
    if (perc < 1) {
      return pow(perc, power) / 2;
    } else {
      perc--;
      return 1 - (pow(1 - perc, power) / 2);
    }
  }

  // cubic ease-out: start fast, finish slow (returns 0 to 1)
  static float easeOutCubic(float perc) {
    return 1 - pow(1 - perc, 3);
  }
}

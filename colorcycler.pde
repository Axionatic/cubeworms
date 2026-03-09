// licensed under Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)
// https://creativecommons.org/licenses/by-sa/4.0/

/* little helper class to do colour fading stuff
 * assumes:
 * 1) both faces and vertices have the same min/max hue & saturation
 * 2) faces have fixed brightness */
public class ColourCycler {
  float minH, maxH; // min/max hue
  float minS, maxS; // min/max saturation
  float minVertBright, maxVertBright; // min/max vertices brightness
  Fader faceHue, faceSat; // face colour
  Fader vertHue, vertSat, vertBright; // vertice colour
  Fader[] faders; // easier to process the cyclers this way

  // Cycler needs to know limits for HSB values
  public ColourCycler(float minH, float maxH,
                      float minS, float maxS,
                      float minVB, float maxVB) {
    this.minH = minH;
    this.maxH = maxH;
    this.minS = minS;
    this.maxS = maxS;
    this.minVertBright = minVB;
    this.maxVertBright = maxVB;

    // set up faders
    faceHue = new Fader(minH, maxH);
    faceSat = new Fader(minS, maxS);
    vertHue = new Fader(minH, maxH);
    vertSat = new Fader(minS, maxS);
    vertBright = new Fader(minVB, maxVB);
    faders = new Fader[]{faceHue,faceSat,vertHue,vertSat,vertBright};
  }

  // lerp through colour properties
  public void run() {
    for (int i = 0; i < faders.length; i++) {
      faders[i].run();
    }
  }

  // accessors allow field name reuse between ColourCycler and Fader
  public float faceHue() {return faceHue.val;}
  public float faceSat() {return faceSat.val;}
  public float vertHue() {return vertHue.val;}
  public float vertSat() {return vertSat.val;}
  public float vertBright() {return vertBright.val;}
}

// for ColourCycler - fade between random values in a give range
public class Fader {
  float min, max; // minimum and maximum allowed values
  float val, target; // current & target values
  float delta; // value change per frame
  int steps; // number of steps to get to target

  public Fader(float min, float max) {
    this.min = min;
    this.max = max;
    this.val = random(min, max);
    chooseTarget();
  }

  // move to target value! If it hit our target, choose a new one
  public void run() {
    if (steps > 1) {
      val += delta;
      steps--;
    } else {
      val = target;
      chooseTarget();
    }
  }

  // choose a random target value and speed at which to move towards it
  private void chooseTarget() {
    target = random(min, max);
    delta = random(MIN_HSB_LERP, MAX_HSB_LERP);
    steps = abs(int((target - val) / delta)) + 1; // extra step for the last little bit
    // check if we're going down rather than up
    if (val > target) {delta *= -1;}
  }
}

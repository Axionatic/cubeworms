// licensed under Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)
// https://creativecommons.org/licenses/by-sa/4.0/

// provide random thrust to cubeworms in XYZ via 3 engine objects
public class Thruster {
  Engine x, y, z; // engines for each axis
  
  public Thruster() {
    x = new Engine();
    y = new Engine();
    z = new Engine();
  }
  
  // sometimes we want to begin by thrusting in a certain direction
  public Thruster(PVector v) {
    float maxThrust = random(MIN_E_PWR, MAX_E_PWR);
    int thrustLen = round(random(MIN_E_FUEL, MAX_E_FUEL));
    v.normalize();
    
    x = new Engine(thrustLen, maxThrust * v.x);
    y = new Engine(thrustLen, maxThrust * v.y);
    z = new Engine(thrustLen, maxThrust * v.z);
  }
  
  public PVector run() {
    return new PVector(x.burn(), y.burn(), z.burn());
  }
}

// provides thrust in single axis governed by cosine wave
public class Engine {
  int fuel; // frames of engine burn remaining
  int maxF; // maximum/starting fuel (number of burn frames) - period of cosine wave
  float maxB; // how hard the engine pushes at maximum burn - amplitude of cosine wave (can be negative!)
  int refuelTime; // how long refuelling takes (but where does the fuel come from!?)
  
  public Engine() {
    reset();
  }
  
  // sometimes we want to specify the parameters of our engine's first burn
  public Engine(int maxF, float maxB) {
    this.maxF = this.fuel = maxF; 
    this.maxB = maxB;
    refuelTime = round(random(MIN_REFUEL_TIME, MAX_REFUEL_TIME));
  }
  
  private void reset() {
    maxF = round(random(MIN_E_FUEL, MAX_E_FUEL));
    maxB = random(MIN_E_PWR, MAX_E_PWR);
    maxB *= random(1) >= 0.5 ? 1 : -1;
    refuelTime = round(random(MIN_REFUEL_TIME, MAX_REFUEL_TIME));
    fuel = maxF;
  }
  
  public float burn() {
    // fire the engine! ...If we still have fuel - otherwise refuel
    if (fuel > 1) {
      fuel--;
      // this formula is written so that the wave goes 0,0 -> maxF/2, maxT -> maxF, 0
      return ((cos(fuel/(maxF/TWO_PI) + PI) + 1) / 2) * maxB;
    }
    else if (refuelTime > 0) {
      refuelTime--;
      return 0;
    }
    else {
      // refueled and ready to go!
      reset();
      return burn(); 
    }
  }
}
// licensed under Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)
// https://creativecommons.org/licenses/by-sa/4.0/

// provide random thrust to cubeworms in XYZ via 3 engine objects
public class Thruster {
  private Engine x, y, z; // engines for each axis
  
  public Thruster() {
    x = new Engine();
    y = new Engine();
    z = new Engine();
  }
  
  // sometimes we want to begin by thrusting in a certain direction
  public Thruster(PVector v) {
    float maxThrust = random(MIN_ENGINE_POWER, MAX_ENGINE_POWER);
    int thrustLen = round(random(MIN_ENGINE_FUEL, MAX_ENGINE_FUEL));
    PVector dir = v.normalize(null); // defensive copy to avoid mutating caller's vector

    x = new Engine(thrustLen, maxThrust * dir.x);
    y = new Engine(thrustLen, maxThrust * dir.y);
    z = new Engine(thrustLen, maxThrust * dir.z);
  }
  
  public PVector run() {
    return new PVector(x.burn(), y.burn(), z.burn());
  }
}

// provides thrust in single axis governed by cosine wave
public class Engine {
  private int fuel; // frames of engine burn remaining
  private int maxFuel; // maximum/starting fuel (number of burn frames) - period of cosine wave
  private float maxBurn; // how hard the engine pushes at maximum burn - amplitude of cosine wave (can be negative!)
  private int refuelTime; // frames to wait after fuel runs out before engine burns again
  
  public Engine() {
    reset();
  }
  
  // sometimes we want to specify the parameters of our engine's first burn
  public Engine(int maxFuel, float maxBurn) {
    this.maxFuel = this.fuel = maxFuel; 
    this.maxBurn = maxBurn;
    refuelTime = round(random(MIN_REFUEL_TIME, MAX_REFUEL_TIME));
  }
  
  private void reset() {
    maxFuel = round(random(MIN_ENGINE_FUEL, MAX_ENGINE_FUEL));
    maxBurn = random(MIN_ENGINE_POWER, MAX_ENGINE_POWER);
    maxBurn *= MathUtils.randomSign();
    refuelTime = round(random(MIN_REFUEL_TIME, MAX_REFUEL_TIME));
    fuel = maxFuel;
  }
  
  public float burn() {
    // fire the engine! ...If we still have fuel - otherwise refuel
    if (fuel > 1) {
      fuel--;
      // this formula is written so that the wave goes 0,0 -> maxFuel/2, maxT -> maxFuel, 0
      return ((cos(fuel/(maxFuel/TWO_PI) + PI) + 1) / 2) * maxBurn;
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
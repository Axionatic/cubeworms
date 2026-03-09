// licensed under Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)
// https://creativecommons.org/licenses/by-sa/4.0/

// A class that starts with an icosahedron of radius 1, then recursively subdivides
// and normalises up to a given recursion limit to create a sphere-like structure
// https://stackoverflow.com/questions/7687148/drawing-sphere-in-opengl-without-using-glusphere
public class Icosasphere {
  Triangle[] triangles;
  int recurseCount;
  public Icosasphere(int recurseCount) {
    this.recurseCount = recurseCount;
    // icosahedron has 12 vertices
    final float GOLDEN_RATIO = (1 + sqrt(5)) / 2.0;
    float phi = GOLDEN_RATIO;
    PVector frontLeft = new PVector(-1, 0, phi);
    PVector frontRight = new PVector(1, 0, phi);
    PVector backLeft = new PVector(-1, 0, -phi);
    PVector backRight = new PVector(1, 0, -phi);
    PVector upperLeft = new PVector(-phi, -1, 0);
    PVector lowerLeft = new PVector(-phi, 1, 0);
    PVector upperRight = new PVector(phi, -1, 0);
    PVector lowerRight = new PVector(phi, 1, 0);
    PVector forwardTop = new PVector(0, -phi, 1);
    PVector rearTop = new PVector(0, -phi, -1);
    PVector forwardBottom = new PVector(0, phi, 1);
    PVector rearBottom = new PVector(0, phi, -1);
    // Explicit variables rather than a loop to keep vertex names readable during debugging
    frontLeft.normalize();
    frontRight.normalize();
    backLeft.normalize();
    backRight.normalize();
    upperLeft.normalize();
    lowerLeft.normalize();
    upperRight.normalize();
    lowerRight.normalize();
    forwardTop.normalize();
    rearTop.normalize();
    forwardBottom.normalize();
    rearBottom.normalize();
    
    // Icosahedron has 20 faces.
    triangles = new Triangle[20];
    triangles[0] = new Triangle(rearTop, forwardTop, upperRight);
    triangles[1] = new Triangle(rearTop, upperRight, backRight);
    triangles[2] = new Triangle(rearTop, backRight, backLeft);
    triangles[3] = new Triangle(rearTop, backLeft, upperLeft);
    triangles[4] = new Triangle(rearTop, upperLeft, forwardTop);
    triangles[5] = new Triangle(forwardTop, frontLeft, frontRight);
    triangles[6] = new Triangle(forwardTop, frontRight, upperRight);
    triangles[7] = new Triangle(upperRight, frontRight, lowerRight);
    triangles[8] = new Triangle(upperRight, lowerRight, backRight);
    triangles[9] = new Triangle(backRight, lowerRight, rearBottom);
    triangles[10] = new Triangle(backRight, rearBottom, backLeft);
    triangles[11] = new Triangle(backLeft, rearBottom, lowerLeft);
    triangles[12] = new Triangle(backLeft, lowerLeft, upperLeft);
    triangles[13] = new Triangle(upperLeft, lowerLeft, frontLeft);
    triangles[14] = new Triangle(upperLeft, frontLeft, forwardTop);
    triangles[15] = new Triangle(forwardBottom, frontRight, frontLeft);
    triangles[16] = new Triangle(forwardBottom, lowerRight, frontRight);
    triangles[17] = new Triangle(forwardBottom, rearBottom, lowerRight);
    triangles[18] = new Triangle(forwardBottom, lowerLeft, rearBottom);
    triangles[19] = new Triangle(forwardBottom, frontLeft, lowerLeft);
  }
  
  // concatenate all arrays of points from all triangles and return
  public PVector[] getAllPoints() {
    // all the trues & falses are for incL/incR/incB - such that each point is only
    // calculated once. This was also a huge pain to get right!
    int totalPoints = triangles[0].subdivide(true, true, true, recurseCount);
    totalPoints += triangles[1].subdivide(false, true, true, recurseCount);
    totalPoints += triangles[2].subdivide(false, true, true, recurseCount);
    totalPoints += triangles[3].subdivide(false, true, true, recurseCount);
    totalPoints += triangles[4].subdivide(false, false, true, recurseCount);
    totalPoints += triangles[5].subdivide(true, true, true, recurseCount);
    totalPoints += triangles[6].subdivide(false, false, true, recurseCount);
    totalPoints += triangles[7].subdivide(false, true, true, recurseCount);
    totalPoints += triangles[8].subdivide(false, false, true, recurseCount);
    totalPoints += triangles[9].subdivide(false, true, true, recurseCount);
    totalPoints += triangles[10].subdivide(false, false, true, recurseCount);
    totalPoints += triangles[11].subdivide(false, true, true, recurseCount);
    totalPoints += triangles[12].subdivide(false, false, true, recurseCount);
    totalPoints += triangles[13].subdivide(false, true, true, recurseCount);
    totalPoints += triangles[14].subdivide(false, false, false, recurseCount);
    totalPoints += triangles[15].subdivide(true, true, false, recurseCount);
    totalPoints += triangles[16].subdivide(true, false, false, recurseCount);
    totalPoints += triangles[17].subdivide(true, false, false, recurseCount);
    totalPoints += triangles[18].subdivide(true, false, false, recurseCount);
    totalPoints += triangles[19].subdivide(false, false, false, recurseCount);
    
    // return as single array. Seems computationally wasteful?
    PVector[] allTriPoints = new PVector[totalPoints];
    int count = 0;
    for (int i = 0; i < triangles.length; i++) {
      for (int j = 0; j < triangles[i].subdivided.length; j++) {
        allTriPoints[count] = triangles[i].subdivided[j];
        count++;
      }
    }
    return allTriPoints;
  }
  
  private class Triangle {
    PVector[] points; // initial 3 points describing triangle - [top, left, right]
    PVector[] subdivided; // array holding all points of subdivided triangle
    int insertAt; // index at which we insert subdivided triangle PVectors into results array
    
    private Triangle(PVector top, PVector left, PVector right) {
      points = new PVector[] {top, left, right};
      subdivided = new PVector[0]; // shouldn't be necessary, but safety first!
      insertAt = 0;
    }
    
    // subdivide the triangle and return an array of points
    private int subdivide(boolean incL, boolean incR, boolean incB, int recCount) {
      // calculate number of points in array after subdivision, accounting for incL/incR/incB
      int triRows = round(pow(2, recCount)) + 1;
      int arraySize = (triRows * (triRows+1)) / 2; // triangle number
      // subtract from arraySize for each point skipped by incL/R/B
      int skipRows = incL ? 0 : 1;
      skipRows += incR ? 0 : 1;
      skipRows += incB ? 0 : 1;
      int skipPoints = (triRows * skipRows);
      skipPoints -= ((skipRows-1) * skipRows) / 2; // don't count points twice when skipping multiple rows
      arraySize -= skipPoints;
      subdivided = new PVector[arraySize];
      
      // recursively divide triangle, adding all relevant points to the points array
      if (recCount > 0) {
        divideRecurse(points, recCount, incL, incR, incB);
      }
      // finally, add outer points of triangle
      if (incL && incR) {
        subdivided[insertAt] = points[0];
        insertAt++;
      }
      if (incL && incB) {
        subdivided[insertAt] = points[1];
        insertAt++;
      }
      if (incR && incB) {
        subdivided[insertAt] = points[2];
      }
      return arraySize;
    }
    
    // recursively subdivide a triangle and normalise, rounding it out in a sphere-like curve
    // arguments for number of recursions, and whether or not to include left/right/base sides
    private void divideRecurse(PVector[] triangle, int recCount, boolean incL, boolean incR, boolean incB) {
      // triangle[] always has 3 points, passed as top, left, right
      // calculate midpoints and recurse
      PVector lMid = PVector.add(triangle[1], triangle[0]);
      PVector rMid = PVector.add(triangle[2], triangle[0]);
      PVector bMid = PVector.add(triangle[2], triangle[1]);
      lMid.div(2);
      rMid.div(2);
      bMid.div(2);
      // normalising produces the sphere-like shape
      lMid.normalize();
      rMid.normalize();
      bMid.normalize();
      PVector[] t1 = {triangle[0], lMid, rMid};
      PVector[] t2 = {lMid, triangle[1], bMid};
      PVector[] t3 = {rMid, bMid, triangle[2]};
      PVector[] t4 = {bMid, rMid, lMid}; // middle of 3 subtriangles
      
      // retain incL/R/B data for relevant sides of the subtriangles
      recCount--;
      if (recCount > 0) {
        divideRecurse(t1, recCount, incL, incR, true);
        divideRecurse(t2, recCount, incL, true, incB);
        divideRecurse(t3, recCount, true, incR, incB);
        // also do centre (upside-down) triangle, to avoid Sierpinski triangle holes
        divideRecurse(t4, recCount, false, false, false);
      }
      
      // add points to results as required
      if (incL) {
        subdivided[insertAt] = lMid;
        insertAt++;
      }
      if (incR) {
        subdivided[insertAt] = rMid;
        insertAt++;
      }
      if (incB) {
        subdivided[insertAt] = bMid;
        insertAt++;
      }
    }
  }
}
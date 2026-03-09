// licensed under Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)
// https://creativecommons.org/licenses/by-sa/4.0/

// mess with these to change the sketch's behaviour
final float MOUSE_SENSITIVITY = 0.01; // affects click and drag to rotate
final int MAX_H = 360; // probably shouldn't change this...
final int MAX_SBA = 100; // ...or this
final int INIT_ZOOM = 16; // initial zoom (remember this will be multiplied by ZOOM_STEP!)
final float ZOOM_STEP = 0.0625; // how much we zoom in/out by on mouse wheel
final int MIN_ZOOM = 1; // minimum zoom level
final int MAX_ZOOM = 160; // maximum zoom level
final float BRIGHT_PASS = 0.0001; //***MUST*** be a float! (Aparrently glsl can't...)
final int BLUR_SIZE = 15; // ***MUST*** be an int! (... do implicit type conversion...)
final float BLUR_SIGMA = 20f; // ***MUST*** be a float! (... between int and float)
float CAMERA_Z = 0; // Z-pos of camera, calculated in sketch setup
float HITHER = 0; // hither/near face of view frustum, calculated in sketch setup
final float FOV_Y = PI / 3; // default processing value for vertical field-of-view angle
float B_F_Y_LEN = 0; // y-length of view frustum at beacon z-pos. Calculated at runtime
float B_F_X_LEN = 0; // x-length of view frustum at beacon z-pos. Calculated at runtime

// environment properties
final int BACKGROUND = 0; // background colour
final int D_LIGHT = 255; // strength of directional light shining on cubeworms
final int SHININESS = 25; // cubeworm shininess
final int GLOW_STRENGTH = 3; // number of times blur is added to sketch
final int GRAV_PWR = 10000; // we use a kind of inverted gravity to contain worms
final int WALL_RAD = 1500; // radius of gravitationally repulsive sphere "wall"
final float SKETCH_Z = WALL_RAD * -1.5; // Z position of sketch (so that the camera isn't inside the grav wall)

// beacon properties
final int BEACON_CORE = 20; // radius of sphere at core of beacon
final int B_SPAWN_LEN = 45; // duration of beacon core spawn animation
final int B_SPHERE_DETAIL = 8; // sphere detail settings for beacon
final color B_CORE_COL = -1; // -1 is just white
final float BEACON_Z_PERC = 0.5; // for BEACON_Z: percentage of distance between near point of grav wall & hither used as z pos 
float BEACON_Z = 0; // calculated at runtime: BEACON_Z_PERC % beteween near point of grav wall and hither/near frustum face
final float B_ROT_SPEED = TWO_PI / 240; // rotation speed of beacon core
final int B_DET_FRAMES = 180; // detonation animation length in frames
final float B_DET_RAD_MULT = 14; // radius multiplier for beacon core explosion animation
final float B_DET_ROT_STOP = 0.66; // % of detonation animation by which beacon has stopped rotating
final float B_ATTR_RAD = 500; // radius around beacon that cubeworms are attracted to. Limited to a spherical cap facing 0,0,0
final float B_CAP_H = B_ATTR_RAD / 8; // "height" (offset from sphere pos) of spherical cap that cubeworms are attracted to
final float FASCINATE_RAD = B_ATTR_RAD * 2; // worms within this radius of beacon become fascinated, unable to look away
final float B_CORE_REPULSE = -0.0006; // modifier for how strongly cubeworms are repulsed from beacon core
final float B_HERD_STR = 0.00025; // how strongly worms are pushed back to near side of beacon if they stray too far
final int P_COUNT = 180; // number of particles orbiting beacon

// particle propterties
final float P_RADIUS = 12; // radius of particle
final int P_LONGRES = 4; // longitudinal sphere detail setting for particles
final int P_LATRES = 1; // latitudinal sphere detail setting for particles
final float P_STROKE_WEIGHT = 0.5; // line weight of particles
final float P_X_AMP_MIN = 185; // min value of amplitude of sine wave for paricle x pos
final float P_X_AMP_MAX = 215; // max value of amplitude of sine wave for paricle x pos
final float P_Y_AMP_MIN = 100; // min value of amplitude of sine wave for paricle y pos
final float P_Y_AMP_MAX = 120; // max value of amplitude of sine wave for paricle y pos
final float P_Y_MOD_AMP = 0.5; // amplitude of yMod sine wave
final float P_Y_MOD_CONST = 2; // constant added to yMod sine wave
final int P_PERIOD = 450; // particle takes this many frames to complete a loop
final int P_ROT_SPEED = 120; // particle rotates 360 degrees once every this number of frames
final int P_SPAWN_FRAME = int(P_PERIOD / 6); // animation frame on which particle starts
final int P_TRAIL_LEN = 4; // length of trail that particle leaves
final int P_TRAIL_FREQ = 10; // leave trail once every n frames
final float P_MIN_DET_MAG = 800; // minimum magnitude of final point in particle detonation path
final float P_MAX_DET_MAG = 1200; // maximum magnitude of final point in particle detonation path
final int P_MIN_DET_PATH_LEN = 2; // minimum number of positions on detonation path
final int P_MAX_DET_PATH_LEN = 10; // maximum number of positions on detonation path
final float P_DET_MIN_POS_MOD = -50; // minimum position modifier for detonation path positions
final float P_DET_MAX_POS_MOD = 50; // maximum position modifier for detonation path positions

// generic cubeworm properties
final int WORM_COUNT = 15; // number of cubeworms
final int WORM_SIZE = 75; // size of worm's main cube
final float MIN_SAT = MAX_SBA * 0.7; // minimum saturation of colours used for cubeworms
final int MAX_SAT = MAX_SBA; // maximum saturation of colours used for cubeworms
final float FACE_BRIGHTNESS = 25; // brightness of wormcube faces
final float MIN_VERT_B = MAX_SBA * 0.8; // min brightness of vertices
final float MAX_VERT_B = MAX_SBA; // max brightness of vertices
final int MIN_FACECUBES = 3; // min number of "face cubes"
final int MAX_FACECUBES = 8; // max number of "face cubes"
final float FACECUBE_SIZE = 30; // size of facecubes
final float FACECUBE_DIST = 25 + FACECUBE_SIZE/2 + WORM_SIZE/2; // distance between cubeworm and facecube; 25 is visual padding

// spawnworm-specific properties
final int MIN_SPAWN_DELAY = 60; // minimum cubeworm (re-)spawn delay
final int MAX_SPAWN_DELAY = 150; // maximum cubeworm (re-)spawn delay
final float MAX_SPAWN_RAD = WALL_RAD * 0.75; // worms spawning next to wall are pushed to centre by gravity
final float ANIM_STEPS = 3; // number of steps in spawn animation
final int ANIM_STEP_LEN = 40; // duration of each step in spawn animation
final int SPAWN_TRAIL_DELAY_MOD = 15; // delay trailcubes by a bit immediately after spawning
final float SPAWN_STROKEW = 1; // stroke width for spawn anim. Must be < MAX_EDGE and > MIN_EDGE

// roamworm-specific properties
final float MAX_SPEED = 8; // maximum speed of cubeworm
final float MIN_EDGE = 0.08; // minimum thickness of glowing edge lines
final float MAX_EDGE = 2.8; // maximum thickness of glowing edge lines
final float MIN_PULSE_SPEED = 0.01; // min speed at which cubeworms pulse
final float MAX_PULSE_SPEED = 0.05; // max speed at which cubeworms pulse
final float MIN_HSB_LERP = 0.2; // min HSB fade speed
final float MAX_HSB_LERP = 0.5; // max HSB fade speed

// travelworm (hypno & recover) specific properties
final float ATTR_STR = 0.25; // strength of attraction to destination pos

// hypnoworm-specific properties
final float LOOK_LIM_DIST_MOD = 0.2; // dist to beacon * this + vel * ↓ = radius around beacon worm looks at 
final float LOOK_LIM_VEL_MOD = 15; // dist to beacon * ↑ + vel * this = radius around beacon worm looks at
final float MAX_TURN_RATE = 0.1; // max turn rate = (desired facing - current facing) * this
final float MIN_SURVIVAL_CHANCE = 0.6; // survival chance decreases with proximity to beacon detonation

// pushworm-specific properties
final float SPEED_DECAY = 0.8; // rate at which worm slows down
final float MAX_PUSH_SPEED = MAX_SPEED * 10; // maximum speed worms can be pushed to
final float PUSH_SPEED_MOD = MAX_PUSH_SPEED / (1/B_ATTR_RAD); // speed = (1 / distance from beacon) * this

// splitworm-specific properties
final float MAX_SPLIT_SPEED = MAX_SPEED * 7; // maximum speed of splitworms 
final int MAX_SPLIT_DEPTH = 4; // maximum number of times a worm fragment can split into sub-fragments
final int MIN_SPLIT_FRAGS = 2; // minimum number of sub-fragments a fragment can split into
final int MAX_SPLIT_FRAGS = 3; // maximum number of sub-fragments a fragment can split into
final float SPLIT_VOL_BOOST = 1.2; // on splitting, cheat by adding a bit of volume to each sub-fragment
final float FRAG_DECAY = 0.3; // rate at which fragments decay and shrink
final float STROKE_W_INC = 0.1; // increment width of vertice stroke until we hit MAX_EDGE
final float MAX_SPLIT_THETA = PI / 8; // maximum angle at which a sub-fragment can split away from a parent fragment
final float FRAG_CHANCE = 1; // chance to fragment (note that we use FRAG_CHANCE^depth)
final float FRAG_MAX_POINT = 0.95; // maximum size % at which a fragment can subfragment
final float FRAG_MIN_POINT = 0.75; // minimum size % at which a fragment can subfragment
final float F_P_MAX_SIZE_MOD = 1.5; // when fragmenting, parent fragment size will be size * random(1/fragments, 1/fragments * this)
final float G_MAX_RADIUS = 6; // radius of glimmer trail points at maximum blink
final float G_AVERAGE_SPAWN = 1; // fragment glimmer trail spawns a point on average every this amount of fragment size reduced
final float G_MIN_SPAWN_XOFF = -1; // fragment glimmer minimum spawn offset
final float G_MAX_SPAWN_XOFF = 1; // fragment glimmer maximum spawn offset
final float G_MAX_SPAWN_YOFF = 4; // maximum number of pixels in Y a trail point can spawn from its fragment
final float G_BLINK_TIME = 45; // average number of frames a glimmer both blinks and rests for
final float G_MIN_ANIM = 0.5; // glimmer minimum animation speed
final float G_MAX_ANIM = 2; // glimmer maximum animation speed
final float G_BLINKS = 4; // base number of times a glimmer will blink before modifiers
final float G_B_MOD_MAX = 1.5; // maximum random modifier for number of times a glimmer will blink
final float G_B_MOD_MIN = 0.5; // minimum random modifier for number of times a glimmer will blink
final float G_INIT_SPEED_MOD = 0.5; // glimmer initial speed = fragment speed * this
final float G_Y_SPEED_MOD = 0.2; // glimmer movement in Y = X movement * this
final float G_SPEED_DECAY = 0.98; // glimmer speed decay per frame (speed *= this)

// explodeworm-specific properties
final float MAX_EXP_SPEED = MAX_SPEED * 9; // maximum speed of explodeworms
final float EXP_DET_SPEED = 0.1; // speed at which explodeworms detonate ("fuse" before explosion)
final float MAX_INIT_SPEED_MOD = 0.35; // max random modifier for initial speed (speed += (speed * some%))
final float EXP_PULSE_INC = 0.01; // incemement of glow-pulse period (flash more quickly during explosion)
final int EXP_SPHERE_COUNT = 3; // number of spheres in explosion animation
final int EXP_OUTER_SPHERE_RECURSE = 3; // # of recursions for Icosasphere governing outermost explosion sphere (ie, # of stars in explosion). Inner spheres recurse less
final float EXP_OUTER_SPHERE_RAD = 1000; // final radius of outermost explosion sphere. Inner spheres spaced linearly
final float EXPLODE_SPEED = 1.0f/180; // speed at which explosion progresses (% per frame)
final float STAR_INIT_RAD = 1; // initial radius of explosion stars
final float STAR_MAX_RAD = 15; // maximum radius of explosion stars
final float STAR_PULSE_BEGIN = 0.5; // percentage of the way through explosion animation that the first sphere of stars begin pulsing
final int STAR_MIN_COL_DIFF = 50; // minimum amount of colour change allowed when star pulses
final int STAR_MAX_COL_DIFF = 100; // maximum amount of colour change allowed when star pulses
final float FACECUBE_EXP_DIST = EXP_OUTER_SPHERE_RAD * 1.4; // distance which facecubes travel from centre of explodeworm
final int FACETRAIL_SPAWN_FREQ = 5; // exploding facecubes spawn a trail point every n frames
final float FACETRAIL_DECAY = 0.5; // speed at which the trail left behind by exploding facecubes shrinks

// recoverworm-specific properties
final float RECOVER_RAD = (WALL_RAD - MAX_SPAWN_RAD) * 0.8; // become roamworm once within this radius of recover dest

// engine/thruster properties
final float MIN_E_PWR = 0.05; // the minimum amplitude of a cosine engine
final float MAX_E_PWR = 0.2; // the maximum amplitude of a cosine engine
final int MIN_E_FUEL = 30; // the minimum period of a cosine engine
final int MAX_E_FUEL = 80; // the maximum period of a cosine engine
final int MIN_REFUEL_TIME = 20; // minimum number of frames between engine burns
final int MAX_REFUEL_TIME = 60; // maximum number of frames between engine burns

// cubetrail properties
final int T_MIN_RATE = 8; // minimum trailcube spawn frequency (1 every x frames)
final int T_MAX_RATE = 1; // maximum trailcube spawn frequency (1 every x frames)
final float T_DECAY = 1.2; // rate at which trailcubes shrink after spawning
final float T_MIN_SIZE = 0.6 * WORM_SIZE; // min trailcube size
final float T_MAX_SIZE = 0.85 * WORM_SIZE; // max trailcube size
final float T_MAX_SPAWN_RAD = 1.3 * WORM_SIZE; // radius around center of worm in which trailcube spawn (min is 0)
final float T_MIN_SPAWN_DIST = 5 + WORM_SIZE/2; // min distance behind cubeworm that trailcube can spawn
final float T_MAX_SPAWN_DIST = 35 + WORM_SIZE/2; // max distance behind cubeworm that trailcube can spawn
final float T_OFF_SIZE_MOD = 0.7; // the further a trailcube is from being directly behind a cubeworm, the smaller it gets
final float T_MAX_HUE_DIFF = 30; // max difference between cubeworm hue and trailcube hue
final float T_MAX_SAT_DIFF = 15; // max difference between cubeworm saturation and trailcube hue 

/* Unfortunately, we can only use random with floats. However we need a fair
 * way of picking randomly from an array. If we had an array of size 3,
 * then the rounding would be more likely to pick second element, because:
 * round(random(0,2)) --> 0.0 to 0.4999 = 0, 0.5 to 1.4999 = 1, 1.5 to 2 = 2.
 *
 * in such a scenario the percentages for each element to be chosen are:
 * array[0] = 25%, array[1] = 50%, array[2] = 25.
 * this is remedied by subtracting 0.5 from the lower limit of our random(),
 * and adding 0.5 to the upper limit. (random() never returns the specified upper limit)
 */
final float RANDOM_FIX = 0.5;
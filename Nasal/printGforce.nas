# print G force when touchdown.

var printGforce = func {
    var vs = getprop("velocities/vertical-speed-fps") * 60;
    var ias = getprop("velocities/airspeed-kt");
    var ggl = getprop("position/gear-agl-ft");
    var gr1_cmprs = getprop("gear/gear[1]/compression-norm");
    var gr2_cmprs = getprop("gear/gear[2]/compression-norm");
    var gdamped = getprop("accelerations/pilot-gdamped");
    var replay_state = getprop("sim/freeze/replay-state");
    
    if (vs < -60 and ias > 55 and (gr1_cmprs != 0 or gr2_cmprs != 0) and  gr1_cmprs < 0.23 and gr2_cmprs < 0.23 and replay_state !=1) {
        print("Touchdown G Force: ", gdamped);
        print("Touchdown VS: ", vs);
    }
    settimer(printGforce, 0.01);
};
setlistener("/sim/signals/fdm-initialized", printGforce);
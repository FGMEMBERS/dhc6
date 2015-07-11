########## Global Variable Definition #########
var window_heat_lvl = 0;
var fog_lvl = 0.0;
var frost_lvl = 0.0;
###############################################

var weather_effects = func {


    ############ Rain drop ##########
	var airspeed = getprop("/velocities/airspeed-kt");

	var airspeed_max = 200;

	if (airspeed > airspeed_max) {airspeed = airspeed_max;}

	airspeed = math.sqrt(airspeed/airspeed_max);

	var splash_x = -0.1 - 2.0 * airspeed;
	var splash_y = 0.0;
	var splash_z = 1.0 - 1.35 * airspeed;

	setprop("/environment/aircraft-effects/splash-vector-x", splash_x);
	setprop("/environment/aircraft-effects/splash-vector-y", splash_y);
	setprop("/environment/aircraft-effects/splash-vector-z", splash_z);
    
    ############ Frost and Fog ##########
    var oat = getprop("/environment/temperature-degc");
    var dew_point = getprop("/environment/dewpoint-degc");
    
    if (oat <= dew_point) {
        fog_lvl = math.abs(dew_point) / 5;
    } else {
        fog_lvl = 0;
    }
    
    if (fog_lvl > 1) {
        fog_lvl = 1;
    }
    if (fog_lvl < 0) {
        fog_lvl = 0;
    }

    fog_lvl = fog_lvl - window_heat_lvl;

    if (oat <= dew_point and oat <= 0){
        frost_lvl = math.abs(oat) / 10;
    } else {
        frost_lvl = 0;
    }

    if (frost_lvl > 1){
        frost_lvl = 1;
    }
    if (frost_lvl < 0) {
        frost_lvl = 0;
    }

    frost_lvl = frost_lvl - window_heat_lvl;

    setprop("/environment/aircraft-effects/fog-level", fog_lvl);
    setprop("/environment/aircraft-effects/frost-level", frost_lvl);
    
    settimer(weather_effects, 0);

}

################ Window Heat #####################
var window_heat = func {

    var window_heat_on = getprop("/controls/anti-ice/window-heat");
    if (window_heat_on == 1 and window_heat_lvl < 1) {
        window_heat_lvl = window_heat_lvl + 0.01;
    }
    
    if (window_heat_lvl >= 1) {
        window_heat_lvl = 1;
    }

    if (window_heat_lvl > 0 and window_heat_on == 0) {
        window_heat_lvl = window_heat_lvl - 0.01;
    }

    if (window_heat_lvl <= 0) {
        window_heat_lvl = 0;
    }

    settimer(window_heat, 0.1);
}

############## Windshield Wipers ################
var wipers = func {
    var wipers_position = getprop("/controls/electric/wipers/position-norm");
    var use_wipers = getprop("/environment/aircraft-effects/use-wipers");
    if (wipers_position <= 0) {
        setprop("/environment/aircraft-effects/use-wipers", 0);
    } else if(wipers_position>0 and wipers_position < 0.5 and use_wipers == 0) {
        setprop("/environment/aircraft-effects/use-wipers", 0);
    } else {
        setprop("/environment/aircraft-effects/use-wipers", 1);
    }
    settimer(wipers, 0.1);
}

setlistener("/sim/signals/fdm-initialized", weather_effects);
setlistener("/sim/signals/fdm-initialized", window_heat);
setlistener("/sim/signals/fdm-initialized", wipers);
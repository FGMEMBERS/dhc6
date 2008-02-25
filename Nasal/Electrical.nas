####    Electrical system    #### 
####    Syd Adams    ####
#### Based on Curtis Olson's nasal electrical code ####

var last_time = 0.0;
var vbus_volts = 0.0;
var ammeter_ave = 0.0;

var outPut = "systems/electrical/outputs/";

var BattVolts = props.globals.getNode("systems/electrical/batt-volts",1);
var Volts = props.globals.getNode("/systems/electrical/volts",1);
var Amps = props.globals.getNode("/systems/electrical/amps",1);
var EXT  = props.globals.getNode("/controls/electric/external-power",1); 


strobe_switch = props.globals.getNode("controls/lighting/strobe", 1);
aircraft.light.new("controls/lighting/strobe-state", [0.05, 1.30], strobe_switch);
beacon_switch = props.globals.getNode("controls/lighting/beacon", 1);
aircraft.light.new("controls/lighting/beacon-state", [1.0, 1.0], beacon_switch);

#var battery = Battery.new(switch-prop,volts,amps,amp_hours,charge_percent,charge_amps);
Battery = {
    new : func(swtch,vlt,amp,hr,chp,cha){
    m = { parents : [Battery] };
            m.switch = props.globals.getNode(swtch,1);
            m.switch.setBoolValue(0);
            m.ideal_volts = vlt;
            m.ideal_amps = amp;
            m.amp_hours = hr;
            m.charge_percent = chp; 
            m.charge_amps = cha;
    return m;
    },
    apply_load : func(load,dt) {
        var pwr = me.switch.getValue();
        if(pwr){
        var amphrs_used = load * dt / 3600.0;
        var percent_used = amphrs_used / me.amp_hours;
        me.charge_percent -= percent_used;
        if ( me.charge_percent < 0.0 ) {
            me.charge_percent = 0.0;
        } elsif ( me.charge_percent > 1.0 ) {
        me.charge_percent = 1.0;
        }
        var output =me.amp_hours * me.charge_percent;
        return output;
        }else{return 0;}
    },

    get_output_volts : func {
        var pwr = me.switch.getValue();
        var x = 1.0 - me.charge_percent;
        var tmp = -(3.0 * x - 1.0);
        var factor = (tmp*tmp*tmp*tmp*tmp + 32) / 32;
        var output =me.ideal_volts * factor;
        return output * pwr;
    },

    get_output_amps : func {
        var pwr = me.switch.getValue();
        var x = 1.0 - me.charge_percent;
        var tmp = -(3.0 * x - 1.0);
        var factor = (tmp*tmp*tmp*tmp*tmp + 32) / 32;
        var output =me.ideal_amps * factor;
        return output*pwr;
    }
};

# var alternator = Alternator.new(num,switch,rpm_source,rpm_threshold,volts,amps);
Alternator = {
    new : func (num,switch,src,thr,vlt,amp){
        m = { parents : [Alternator] };
        m.switch =  props.globals.getNode(switch,1);
        if(m.switch.getValue()==nil)m.switch.setBoolValue(0);
        m.meter =  props.globals.getNode("systems/electrical/gen-load["~num~"]",1);
        m.meter.setDoubleValue(0);
        m.gen_output =  props.globals.getNode("engines/engine["~num~"]/amp-v",1);
        m.gen_output.setDoubleValue(0);
        m.meter.setDoubleValue(0);
        m.rpm_source =  props.globals.getNode(src,1);
        m.rpm_threshold = thr;
        m.ideal_volts = vlt;
        m.ideal_amps = amp;
        return m;
    },

    apply_load : func(load) {
        var cur_volt=me.gen_output.getValue();
        var cur_amp=me.meter.getValue();
        if(cur_volt >1){
            var factor=1/cur_volt;
            gout = (load * factor);
            if(gout>1)gout=1;
        }else{
            gout=0;
        }
        if(cur_amp > gout)me.meter.setValue(cur_amp - 0.01);
        if(cur_amp < gout)me.meter.setValue(cur_amp + 0.01);
    },

    get_output_volts : func {
        var pwr = me.switch.getValue();
        var factor = me.rpm_source.getValue() / me.rpm_threshold;
        if ( factor > 1.0 )factor = 1.0;
        var out = pwr * (me.ideal_volts * factor);
        me.gen_output.setValue(out);
        return out;
    },

    get_output_amps : func {
        var pwr = me.switch.getValue();
        var factor = me.rpm_source.getValue() / me.rpm_threshold;
        if ( factor > 1.0 ) {
            factor = 1.0;
            }
        return pwr * (me.ideal_amps * factor);
        }
};

var battery = Battery.new("/controls/electric/battery-switch",24,30,34,1.0,7.0);
alternator1 = Alternator.new(0,"controls/electric/engine[0]/generator","/engines/engine[0]/rpm",100.0,28.0,60.0);
alternator2 = Alternator.new(1,"controls/electric/engine[1]/generator","/engines/engine[1]/rpm",100.0,28.0,60.0);

#####################################
setlistener("/sim/signals/fdm-initialized", func {
    BattVolts.setDoubleValue(0);
    setprop("controls/electric/ammeter-switch",0);
    setprop("controls/electric/external-power",0);
    setprop("controls/anti-ice/prop-heat",0);
    setprop("controls/anti-ice/pitot-heat",0);
    setprop("controls/lighting/landing-lights",0);
    setprop("controls/lighting/beacon",0);
    setprop("controls/lighting/nav-lights",0);
    setprop("controls/lighting/cabin-lights",0);
    setprop("controls/lighting/wing-lights",0);
    setprop("controls/lighting/recog-lights",0);
    setprop("controls/lighting/logo-lights",0);
    setprop("controls/lighting/strobe",0);
    setprop("controls/lighting/taxi-lights",0);
    setprop("controls/cabin/fan",0);
    setprop("controls/cabin/heat",0);
    setprop("controls/lighting/instruments-norm",0.8);
    setprop("controls/lighting/engines-norm",0.8);
    setprop("controls/lighting/efis-norm",0.8);
    setprop("controls/lighting/panel-norm",0.8);
    settimer(update_electrical,5);
    print("Electrical System ... ok");
});


update_virtual_bus = func( dt ) {
    var PWR = getprop("systems/electrical/serviceable");
    var battery_volts = battery.get_output_volts();
    BattVolts.setValue(battery_volts);
    var alternator1_volts = alternator1.get_output_volts();
    var alternator2_volts = alternator2.get_output_volts();
    var external_volts = 24.0;

    load = 0.0;
    bus_volts = 0.0;
    power_source = nil;
        
        bus_volts = battery_volts;
        power_source = "battery";

    if (alternator1_volts > bus_volts) {
        bus_volts = alternator1_volts;
        power_source = "alternator1";
        }

    if (alternator2_volts > bus_volts) {
        bus_volts = alternator2_volts;
        power_source = "alternator2";
        }
    if ( EXT.getBoolValue() and ( external_volts > bus_volts) ) {
        bus_volts = external_volts;
        }

    bus_volts *=PWR;

    load += electrical_bus(bus_volts);
    load += avionics_bus(bus_volts);

    ammeter = 0.0;
#    if ( bus_volts > 1.0 )load += 15.0;

    if ( power_source == "battery" ) {
        ammeter = -load;
        } else {
        ammeter = battery.charge_amps;
    }

    if ( power_source == "battery" ) {
        battery.apply_load( load, dt );
        } elsif ( bus_volts > battery_volts ) {
        battery.apply_load( -battery.charge_amps, dt );
        }

    ammeter_ave = 0.8 * ammeter_ave + 0.2 * ammeter;

   Amps.setValue(ammeter_ave);
   Volts.setValue(bus_volts);
    alternator1.apply_load(load);
    alternator2.apply_load(load);

return load;
}

electrical_bus = func() {
    var bus_volts = arg[0]; 
    var load = 0.0;
    var srvc = 0.0;
    var starter_volts = 0.0;

    var starter_switch = getprop("controls/engines/engine[0]/starter");
    var starter_switch1 = getprop("controls/engines/engine[1]/starter"); 
    var f_pump0 = getprop("controls/engines/engine[0]/fuel-pump");
    var f_pump1 = getprop("controls/engines/engine[1]/fuel-pump");

    starter_volts = bus_volts * starter_switch;
    load += starter_switch *5;
    starter_volts = bus_volts * starter_switch1;
    load += starter_switch *5;

    setprop(outPut~"starter",starter_volts); 

    if(f_pump0){
        setprop(outPut~"fuel-pump",bus_volts);
        load += f_pump0;
    }elsif(f_pump1){
        load += f_pump0;
        setprop(outPut~"fuel-pump",bus_volts);
    }

    setprop(outPut~"wipers",bus_volts);

    srvc=0+getprop("controls/anti-ice/pitot-heat");
    load +=srvc;
    setprop(outPut~"pitot-heat",bus_volts * srvc);

    srvc=0+getprop("controls/lighting/landing-lights");
    load +=srvc;
    setprop(outPut~"landing-lights",bus_volts * srvc);

    srvc=0+getprop("controls/lighting/cabin-lights");
    load +=srvc;
    setprop(outPut~"cabin-lights",bus_volts * getprop("controls/lighting/cabin-lights"));

    srvc=0+getprop("controls/lighting/wing-lights");
    load +=srvc;
    setprop(outPut~"wing-lights",bus_volts * getprop("controls/lighting/wing-lights"));

    srvc=0+getprop("controls/lighting/nav-lights");
    load +=srvc;
    setprop(outPut~"nav-lights",bus_volts * getprop("controls/lighting/nav-lights"));

    srvc=0+getprop("controls/lighting/logo-lights");
    load +=srvc;
    setprop(outPut~"logo-lights",bus_volts * srvc);

    srvc=0+getprop("controls/lighting/taxi-lights");
    load +=srvc;
    setprop(outPut~"taxi-lights",bus_volts * srvc);

    srvc=0+getprop("controls/lighting/beacon-state/state");
    load +=srvc * 0.2;
    setprop(outPut~"beacon",bus_volts * srvc);

    srvc=0+getprop("controls/lighting/strobe-state/state");
    load +=srvc * 0.2;
    setprop(outPut~"strobe",bus_volts * srvc);

    setprop(outPut~"flaps",bus_volts);

    return load;
}

#### used in Instruments/source code 
# adf : dme : encoder : gps : DG : transponder  
# mk-viii : MRG : tacan : turn-coordinator
# nav[0] : nav [1] : comm[0] : comm[1]
####

avionics_bus = func() {
    var bus_volts = arg[0];
    var load = 0.0;
    var srvc = 0.0;
INSTR_DIMMER = getprop("controls/lighting/instruments-norm");
EFIS_DIMMER = getprop("controls/lighting/efis-norm");
ENG_DIMMER = getprop("controls/lighting/engines-norm");
PANEL_DIMMER = getprop("controls/lighting/panel-norm");


srvc=0+getprop("controls/electric/avionics-switch");
load +=srvc * 0.2;
setprop(outPut~"efis-lights",(bus_volts * EFIS_DIMMER) * srvc);

srvc=0+getprop("controls/lighting/instrument-lights");
load +=srvc * 0.5;
setprop(outPut~"instrument-lights",(bus_volts * INSTR_DIMMER) * srvc);
setprop(outPut~"eng-lights",(bus_volts * ENG_DIMMER) * srvc);
setprop(outPut~"panel-lights",(bus_volts * PANEL_DIMMER) * srvc);

srvc=0+getprop("instrumentation/adf/serviceable");
load +=srvc;
setprop(outPut~"adf",bus_volts * srvc);

srvc=0+getprop("instrumentation/dme/serviceable");
load +=srvc;
setprop(outPut~"dme",bus_volts * srvc);

srvc=0+getprop("instrumentation/gps/serviceable");
load +=srvc;
setprop(outPut~"gps",bus_volts * srvc);

srvc=0+getprop("instrumentation/heading-indicator/serviceable");
load +=srvc;
setprop(outPut~"DG",bus_volts * srvc);

srvc=0+getprop("instrumentation/transponder/inputs/serviceable");
load +=srvc;
setprop(outPut~"transponder",bus_volts * srvc);

#srvc=0+getprop("instrumentation/mk-viii/serviceable");
#load +=srvc;
#setprop(outPut~"mk-viii",bus_volts * srvc);

srvc=0+getprop("instrumentation/tacan/serviceable");
load +=srvc;
setprop(outPut~"tacan",bus_volts * srvc);

srvc=0+getprop("instrumentation/turn-indicator/serviceable");
load +=srvc;
setprop(outPut~"turn-coordinator",bus_volts * srvc);

srvc=0+getprop("instrumentation/nav[0]/serviceable");
load +=srvc;
setprop(outPut~"nav[0]",bus_volts * srvc);

srvc=0+getprop("instrumentation/nav[1]/serviceable");
load +=srvc;
setprop(outPut~"nav[1]",bus_volts * srvc);

srvc=0+getprop("instrumentation/comm[0]/serviceable");
load +=srvc;
setprop(outPut~"comm[0]",bus_volts * srvc);

srvc=0+getprop("instrumentation/comm[1]/serviceable");
load +=srvc;
setprop(outPut~"comm[1]",bus_volts * srvc);

    return load;
}

update_electrical = func {
    time = getprop("/sim/time/elapsed-sec");
    dt = time - last_time;
    last_time = time;
    update_virtual_bus( dt );
settimer(update_electrical, 0);
}

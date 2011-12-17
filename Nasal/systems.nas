####	DHC6 systems	####
aircraft.livery.init("Aircraft/dhc6/Models/Liveries");
var LF_door = aircraft.door.new("/controls/doors/LF-door", 1);
var RF_door = aircraft.door.new("/controls/doors/RF-door", 1);
var RR_door = aircraft.door.new("/controls/doors/RR-door", 1);
var LR_door = aircraft.door.new("/controls/doors/LR-door", 1);

var w_fctr=0;
FuelSelector=props.globals.initNode("controls/fuel/tank-selector",0,"INT");
var C_volume = props.globals.initNode("sim/sound/cabin",0.3);
var D_volume = props.globals.initNode("sim/sound/doors",0.7);
var ctn_counter=0;
Wiper=[];

var mousex =0;
var msx = 0;
var msxa = 0;
var mousey = 0;
var msy = 0;
var msya=0;
var lever_scale = getprop("controls/movement-scale");


var FHmeter = aircraft.timer.new("/instrumentation/clock/flight-meter-sec", 10);

var Wiper = {
    new : func (wiper_prop,power_prop){
        m = { parents : [Wiper] };
        m.direction = 0;
        m.delay_count = 0;
        m.spd_factor = 0;
        m.node = props.globals.initNode(wiper_prop);
        m.power = props.globals.initNode(power_prop,0.0,"DOUBLE");
        m.spd = m.node.initNode("arc-sec",1.0,"DOUBLE");
        m.delay = m.node.initNode("delay-sec",0.0,"DOUBLE");
        m.position = m.node.initNode("position-norm",0.0,"DOUBLE");
        m.switch = m.node.initNode("switch",0,"BOOL");
        return m;
    },
    active: func{
    if(me.power.getValue()<=5)return;
    var spd_factor = 1/me.spd.getValue();
    var pos = me.position.getValue();
    if(!me.switch.getValue()){
        if(pos <= 0.000)return;
        }
    if(pos >=1.000){
        me.direction=-1;
        }elsif(pos <=0.000){
        me.direction=0;
        me.delay_count+=getprop("/sim/time/delta-sec");
        if(me.delay_count >= me.delay.getValue()){
            me.delay_count=0;
            me.direction=1;
            }
        }
    var wiper_time = spd_factor*getprop("/sim/time/delta-sec");
    pos +=(wiper_time * me.direction);
    me.position.setValue(pos);
    }
};

var Caution_panel = {
    new : func (prop){
        m = { parents : [Caution_panel] };
        m.count=0;
        m.volts=0;
        m.caution_test=0;
        m.node = props.globals.initNode(prop);
        m.test = props.globals.initNode("systems/electrical/outputs/caution-test");
        m.power = props.globals.initNode("systems/electrical/volts");
        
        m.l_gen_oheat=m.node.initNode("gen-oheat[0]",0,"BOOL");
        m.r_gen_oheat=m.node.initNode("gen-oheat[1]",0,"BOOL");
        m.l_gen=m.node.initNode("gen[0]",0,"BOOL");
        m.r_gen=m.node.initNode("gen[1]",0,"BOOL");
        m.l_oil_psi=m.node.initNode("oil[0]",0,"BOOL");
        m.r_oil_psi=m.node.initNode("oil[1]",0,"BOOL");
        m.l_cycle400=m.node.initNode("cycle400[0]",0,"BOOL");
        m.r_cycle400=m.node.initNode("cycle400[1]",0,"BOOL");
        m.hydr_press=m.node.initNode("hydr-press",0,"BOOL");
        m.prop_reset=m.node.initNode("prop-reset",0,"BOOL");
        m.fwd_fuel=m.node.initNode("low-fuel[0]",0,"BOOL");
        m.aft_fuel=m.node.initNode("low-fuel[1]",0,"BOOL");
        m.fwd_boost1=m.node.initNode("fwd-boost[0]",0,"BOOL");
        m.fwd_boost2=m.node.initNode("fwd-boost[1]",0,"BOOL");
        m.aft_boost1=m.node.initNode("aft-boost[0]",0,"BOOL");
        m.aft_boost2=m.node.initNode("aft-boost[1]",0,"BOOL");
        m.doors=m.node.initNode("doors",0,"BOOL");
        m.duct=m.node.initNode("duct-oheat",0,"BOOL");
        return m;
    },
    update: func{
        
        if(me.power.getValue()>5.0)me.volts=1 else me.volts=0;
        if(me.test.getValue()>5.0)me.caution_test=1 else me.caution_test=0;
        if(me.volts == 0){me.reset();return;} 
        if(me.caution_test == 1){me.lamp_test();return;}
        
        if(me.count==0)me.left_bank() else me.right_bank();
    },

    left_bank: func{
        if(!getprop("controls/electric/engine/generator"))me.l_gen.setValue(me.volts) else me.l_gen.setValue(0);
        me.l_gen_oheat.setValue(0);
        me.l_cycle400.setValue(0);
        me.duct.setValue(0);
        if(getprop("engines/engine[0]/n2")<30){
            me.l_oil_psi.setValue(me.volts);
            me.fwd_boost1.setValue(me.volts);
            me.fwd_boost2.setValue(me.volts);
            me.hydr_press.setValue(me.volts);
            
        }else{
            me.l_oil_psi.setValue(0);
            me.fwd_boost1.setValue(0);
            me.fwd_boost2.setValue(0);
            me.hydr_press.setValue(0);
        }
        if(getprop("consumables/fuel/tank/level-lbs")<75)me.fwd_fuel.setValue(me.volts) else me.fwd_fuel.setValue(0);
        var lfdoor=getprop("controls/doors/LF-door/position-norm");
        var rfdoor=getprop("controls/doors/RF-door/position-norm");
        var rrdoor=getprop("controls/doors/RR-door/position-norm");
        if(lfdoor>0.001 or rfdoor>0.001 or rrdoor>0.001)me.doors.setValue(me.volts) else me.doors.setValue(0);

        me.count=1-me.count;
    },

    right_bank: func{
    if(!getprop("controls/electric/engine[1]/generator"))me.r_gen.setValue(me.volts) else me.r_gen.setValue(0);
    me.r_gen_oheat.setValue(0);
    me.r_cycle400.setValue(0);
    me.prop_reset.setValue(0);
        if(getprop("engines/engine[1]/n2")<30){
            me.r_oil_psi.setValue(me.volts);
            me.aft_boost1.setValue(me.volts);
            me.aft_boost2.setValue(me.volts);
            me.hydr_press.setValue(me.volts);
        }else{
            me.r_oil_psi.setValue(0);
            me.aft_boost1.setValue(0);
            me.aft_boost2.setValue(0);
            me.hydr_press.setValue(0);
        }
        if(getprop("consumables/fuel/tank[1]/level-lbs")<75)me.aft_fuel.setValue(me.volts) else me.aft_fuel.setValue(0);
        
        me.count=1-me.count;
    },

    reset: func{
        me.l_gen_oheat.setValue(0);
        me.r_gen_oheat.setValue(0);
        me.l_gen.setValue(0);
        me.r_gen.setValue(0);
        me.l_oil_psi.setValue(0);
        me.r_oil_psi.setValue(0);
        me.l_cycle400.setValue(0);
        me.r_cycle400.setValue(0);
        me.hydr_press.setValue(0);
        me.prop_reset.setValue(0);
        me.fwd_fuel.setValue(0);
        me.aft_fuel.setValue(0);
        me.fwd_boost1.setValue(0);
        me.fwd_boost2.setValue(0);
        me.aft_boost1.setValue(0);
        me.aft_boost2.setValue(0);
        me.doors.setValue(0);
        me.duct.setValue(0);
    },
    lamp_test: func{
        me.l_gen_oheat.setValue(me.caution_test);
        me.r_gen_oheat.setValue(me.caution_test);
        me.l_gen.setValue(me.caution_test);
        me.r_gen.setValue(me.caution_test);
        me.l_oil_psi.setValue(me.caution_test);
        me.r_oil_psi.setValue(me.caution_test);
        me.l_cycle400.setValue(me.caution_test);
        me.r_cycle400.setValue(me.caution_test);
        me.hydr_press.setValue(me.caution_test);
        me.prop_reset.setValue(me.caution_test);
        me.fwd_fuel.setValue(me.caution_test);
        me.aft_fuel.setValue(me.caution_test);
        me.fwd_boost1.setValue(me.caution_test);
        me.fwd_boost2.setValue(me.caution_test);
        me.aft_boost1.setValue(me.caution_test);
        me.aft_boost2.setValue(me.caution_test);
        me.doors.setValue(me.caution_test);
        me.duct.setValue(me.caution_test);
    }
};


var Engine = {
    new : func(eng_num){
        m = { parents : [Engine]};
        m.fdensity = getprop("consumables/fuel/tank/density-ppg")or 6.72;
        m.air_temp = props.globals.initNode("environment/temperature-degc");
        m.eng = props.globals.initNode("engines/engine["~eng_num~"]");
        m.eng_ctrls = props.globals.initNode("controls/engines/engine["~eng_num~"]");
        m.running = m.eng.getNode("running",1);
        m.condition = m.eng_ctrls.getNode("condition",1);
        m.cutoff = m.eng_ctrls.getNode("cutoff",1);
        m.mixture =m.eng_ctrls.getNode("mixture",1);
        m.proplever = m.eng_ctrls.getNode("propeller-pitch",1);
        m.throttle_lever = m.eng_ctrls.initNode("throttle-input",0.0);
        m.throttle = m.eng_ctrls.initNode("throttle",0.0);
        m.reverse = m.eng.initNode("reverse-thrust",0.0);
        m.reverser = m.eng_ctrls.initNode("reverser",0,"BOOL");
        m.rpm = m.eng.getNode("n2",1);
        m.fuel_pph=m.eng.initNode("fuel-flow_pph",0.0);
        m.oil_temp=m.eng.initNode("oil-temp-c",m.air_temp.getValue());
        m.fuel_gph=m.eng.getNode("fuel-flow-gph",1);
        m.hpump=props.globals.initNode("systems/hydraulics/pump-psi["~eng_num~"]",0.0);
        m.condL = setlistener(m.mixture, func m.condition_check(), 1);

    return m;
    },
#### update ####
    update : func{
        me.fuel_pph.setValue(me.fuel_gph.getValue()*me.fdensity);
        var hpsi =me.rpm.getValue();
        if(hpsi>60)hpsi = 60;
        me.hpump.setValue(hpsi);
        var OT= me.oil_temp.getValue();
        var rpm = me.rpm.getValue();
        if(OT < rpm)OT+=0.01;
        if(OT > rpm)OT-=0.001;
        me.oil_temp.setValue(OT);
        },
#### check fuel cutoff , copy mixture setting to condition for turboprop ####
    condition_check :  func{
        if(me.cutoff.getBoolValue()){
            me.condition.setValue(0);
            me.running.setBoolValue(0);
        }else{
            var cnd=me.mixture.getValue();
            if(cnd >0.01)cnd=1.0 else cnd=0.0;
        
            me.condition.setValue(cnd);
        }
    },

    toggle_reverse : func{
        if(me.throttle.getValue()==0 and me.reverse.getValue() ==0) me.reverser.setValue(1-me.reverser.getValue());
        }
};

    var wiper = Wiper.new("controls/electric/wipers","systems/electrical/volts");
    var LHeng = Engine.new(0);
    var RHeng = Engine.new(1);
    var Ctn_panel=Caution_panel.new("instrumentation/caution-panel");

setlistener("/sim/signals/fdm-initialized", func {
    setprop("instrumentation/clock/flight-meter-hour",0);
    print("system  ...Check");
    Shutdown();
    setprop("controls/engines/engine[1]/condition",0);
    settimer(mouse_accel, 1);
    settimer(update_systems, 1.1);
    settimer(annunciators, 1.2);
});


setlistener("controls/movement-scale", func {
    lever_scale = getprop("controls/movement-scale");
},0,0);

setlistener("/sim/signals/reinit", func {
    Shutdown();
});

setlistener("controls/fuel/tank-selector", func(tk){
var tnk = tk.getValue();
if(tnk == -1){
        setprop("consumables/fuel/tank[0]/selected",0);
        setprop("consumables/fuel/tank[1]/selected",1);
    }elsif(tnk == 0){
        setprop("consumables/fuel/tank[0]/selected",1);
        setprop("consumables/fuel/tank[1]/selected",1);
    }elsif(tnk == 1){
        setprop("consumables/fuel/tank[0]/selected",1);
        setprop("consumables/fuel/tank[1]/selected",0);
    }
});

setlistener("/sim/current-view/internal", func(vw){
    var vol = vw.getValue();
    vol == 0 ? C_volume.setValue(1.0) : C_volume.setValue(0.4) ;
},0,0);

setlistener("/sim/model/autostart", func(idle){
    var run= idle.getBoolValue();
    if(run){
    Startup();
    }else{
    Shutdown();
    }
},0,0);

setlistener("/gear/gear[1]/wow", func(gr){
    if(gr.getBoolValue()){
    FHmeter.stop();
    }else{FHmeter.start();}
},0,0);

var set_levers = func(type,num,min,max){
        var ctrl=[];
        var cpld=-1;
        if(type == "throttle"){
            ctrl = ["controls/engines/engine[0]/throttle-input","controls/engines/engine[1]/throttle-input"];
            cpld = "controls/throttle-coupled";
        }elsif(type == "prop"){
            ctrl = ["controls/engines/engine[0]/propeller-pitch","controls/engines/engine[1]/propeller-pitch"];
            cpld = "controls/prop-coupled";
        }elsif(type == "condition"){
            ctrl = ["controls/engines/engine[0]/mixture","controls/engines/engine[1]/mixture"];
            cpld ="controls/mixture-coupled";
        }
       
        var amnt =mousey* getprop("controls/movement-scale");
        var ttl = getprop(ctrl[num]) + amnt;
        if(ttl > max) ttl = max;
        if(ttl<min)ttl=min;
         setprop(ctrl[num],ttl);
        if(getprop(cpld))setprop(ctrl[1-num],ttl);
 }


controls.incThrottle = func {
    var val = 0;
    var inc = arg[0];
    if (!getprop("controls/engines/engine[0]/reverser")){
        val = getprop("controls/engines/engine[0]/throttle") + inc;
        setprop("controls/engines/engine[0]/throttle",val < 0.0 ? 0.0 : val > 1.0 ? 1.0 : val);
    }else{
        val = getprop("engines/engine[0]/reverse-thrust") + inc;
        setprop("engines/engine[0]/reverse-thrust",val < 0.0 ? 0.0 : val > 1.0 ? 1.0 : val);
    }

if (!getprop("controls/engines/engine[1]/reverser")){
        val = getprop("controls/engines/engine[1]/throttle") + inc;
        setprop("controls/engines/engine[1]/throttle",val < 0.0 ? 0.0 : val > 1.0 ? 1.0 : val);
    }else{
        val = getprop("engines/engine[1]/reverse-thrust") + inc;
        setprop("engines/engine[1]/reverse-thrust",val < 0.0 ? 0.0 : val > 1.0 ? 1.0 : val);
    }
}

controls.throttleAxis = func{
    var val = cmdarg().getNode("setting").getValue();
        val =(1 - val) / 2;
        if (!getprop("controls/engines/engine[0]/reverser")){
            setprop("controls/engines/engine[0]/throttle",val < 0.0 ? 0.0 : val > 1.0 ? 1.0 : val);
        }else{
        setprop("engines/engine[0]/reverse-thrust",val < 0.0 ? 0.0 : val > 1.0 ? 1.0 : val);
        }
        if (!getprop("controls/engines/engine[1]/reverser")){
            setprop("controls/engines/engine[1]/throttle",val < 0.0 ? 0.0 : val > 1.0 ? 1.0 : val);
        }else{
        setprop("engines/engine[1]/reverse-thrust",val < 0.0 ? 0.0 : val > 1.0 ? 1.0 : val);
        }
}

var Startup = func{
setprop("controls/electric/engine[0]/generator",1);
setprop("controls/electric/engine[1]/generator",1);
setprop("controls/electric/avionics-switch",1);
setprop("controls/electric/battery-switch",1);
setprop("controls/electric/inverter-switch",1);
setprop("controls/lighting/instrument-lights",1);
setprop("controls/lighting/instruments-norm",0.8);
setprop("controls/lighting/nav-lights",1);
setprop("controls/lighting/beacon",1);
setprop("controls/lighting/strobe",1);
setprop("controls/engines/engine[0]/mixture",1);
setprop("controls/engines/engine[1]/mixture",1);
setprop("controls/engines/engine[0]/cutoff",0);
setprop("controls/engines/engine[1]/cutoff",0);
setprop("controls/engines/engine[0]/propeller-pitch",1);
setprop("controls/engines/engine[1]/propeller-pitch",1);
setprop("engines/engine[0]/running",1);
setprop("engines/engine[1]/running",1);
}

var Shutdown = func{
setprop("controls/electric/engine[0]/generator",0);
setprop("controls/electric/engine[1]/generator",0);
setprop("controls/electric/avionics-switch",0);
setprop("controls/electric/battery-switch",0);
setprop("controls/electric/inverter-switch",0);
setprop("controls/lighting/instrument-lights",0);
setprop("controls/lighting/instruments-norm",0.8);
setprop("controls/lighting/nav-lights",0);
setprop("controls/lighting/beacon",0);
setprop("controls/lighting/strobe",0);
setprop("controls/engines/engine[0]/mixture",0);
setprop("controls/engines/engine[1]/mixture",0);
setprop("controls/engines/engine[0]/propeller-pitch",0);
setprop("controls/engines/engine[1]/propeller-pitch",0);
setprop("controls/engines/engine[0]/cutoff",0);
setprop("controls/engines/engine[1]/cutoff",0);
setprop("engines/engine[0]/running",0);
setprop("engines/engine[1]/running",0);
}

var flight_meter = func{
var fmeter = getprop("/instrumentation/clock/flight-meter-sec");
var fminute = fmeter * 0.016666;
var fhour = fminute * 0.016666;
setprop("/instrumentation/clock/flight-meter-hour",fhour);
}


var mouse_accel=func{
   msx=getprop("devices/status/mice/mouse/x") or 0;
    mousex=msx-msxa;
    mousex*=0.5;
     msxa=msx;
    msy=getprop("devices/status/mice/mouse/y") or 0;
    mousey=msya-msy;
    mousey*=0.5;
     msya=msy;
    settimer(mouse_accel, 0);
}
##### Main ###########


var annunciators = func {
    Ctn_panel.update();
    settimer(annunciators, 0.5);
    }
    

var update_systems = func {
    var lfdoor_pos = getprop("controls/doors/LF-door/position-norm");
    var rfdoor_pos = getprop("controls/doors/RF-door/position-norm");
    var rrdoor_pos = getprop("controls/doors/RR-door/position-norm");
     lrdoor_pos = getprop("controls/doors/LR-door/position-norm");
    var power = getprop("/controls/switches/master-panel");
    LHeng.update();
    RHeng.update();
    flight_meter();
    wiper.active();
    var wind = getprop("velocities/airspeed-kt");
    if(wind>40){
        if(lfdoor_pos>0)LF_door.close();
        if(rfdoor_pos>0)RF_door.close();
        if(rrdoor_pos>0)RR_door.close();
        if(lrdoor_pos>0)LR_door.close();
    }
    if(lfdoor_pos>0.005 or rfdoor_pos>0.005)D_volume.setValue(0.8) else D_volume.setValue(C_volume.getValue());
    settimer(update_systems, 0);
}

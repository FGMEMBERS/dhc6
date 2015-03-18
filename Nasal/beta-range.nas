props.globals.initNode("engines/engine[0]/reverse",0.0);
props.globals.initNode("engines/engine[1]/reverse",0.0);
props.globals.initNode("engines/engine[0]/fuel-flow-gph",0.0);
props.globals.initNode("engines/engine[1]/fuel-flow-gph",0.0);

var betaRange = func {

    var reverse1 = getprop("engines/engine[0]/reverse");
    var reverse2 = getprop("engines/engine[1]/reverse");

    
    if (reverse1 != 0) {
        setprop("engines/engine[0]/fuel-flow-gph", (0.3+reverse1*20));
    }

    if (reverse2 != 0) {
        setprop("engines/engine[1]/fuel-flow-gph", (0.3+reverse2*20));
    }
     settimer(betaRange,0);
}
setlistener("/sim/signals/fdm-initialized", betaRange);


// see also, http://jsfiddle.net/karlin/dQvQg/1/

import { contextGraph } from './contextGraph.js';
import { neuronGraph, __guard__ } from './svg.js';
import { app } from './world.js';

const connect = function(source, target, params) {
  const dendrite = {
    source,
    target
  };
  for (let param in params) {
    dendrite[param] = params[param];
  }
  return dendrite;
};

const simpleNetwork = function() {
  const osc = { name: 'osc', x: 200, y: 200, cycle: 3000 };
  const emit_ex = { name: 'emit_ex', x: 50, y: 50, allTheTime: true };
  const neurons = [emit_ex, osc];

  const dendrites = [
    connect(emit_ex, osc, { weight: 2 }),
    connect(osc, osc, { weight: -4 })
  ];

  return {
    nodes: neurons,
    links: dendrites
  };
};

const muramatorNetwork = function(kf, kt, neurons) {
  const named = name => neurons.find(n => n.name === name);

  const dendrites = [
    {
      source: named('emitter'),
      target: named('detect_obs'),
      weight: 0
    },
    {
      label: 'avoid',
      source: named('detect_obs'),
      target: named('sk_supp_av'),
      weight: 2
    },
    {
      source: named('sk_supp_av'),
      target: named('turn'),
      weight: 2
    },
    {
      source: named('detect_obs'),
      target: named('seek'),
      weight: -100
    },
    {
      source: named('seek_ex'),
      target: named('seek'),
      size: 100,
      weight: kf,
      label: 'KF'
    },
    {
      source: named('seek'),
      target: named('seek'),
      weight: kt,
      label: 'KT'
    },
    {
      source: named('seek'),
      target: named('sk_supp_av'),
      weight: 2
    },
    {
      source: named('sk_supp_av'),
      target: named('av_supp_ex'),
      weight: -2
    },
    {
      source: named('explore_ex'),
      target: named('av_supp_ex'),
      weight: 2,
      size: 100
    },
    {
      source: named('av_supp_ex'),
      target: named('forward'),
      weight: 2
    },
    {
      source: named('emit_ex'),
      target: named('emitter'),
      size: 100,
      weight: 2
    },
    {
      source: named('emitter'),
      target: named('emitter'),
      weight: -2
    }
  ];

  return {
    nodes: neurons,
    links: dendrites
  };
};

const debugFmt = d3.format('0.2f');

const reportNodes = function(nodes, fmt) {
  const eachNode = nodes.map(
    n =>
      `${n.name}:\t${n.name.length < 7 ? '\t' : ''}${debugFmt(n.inputAgg)}\t${debugFmt(
        n.output
      )}\t${n.cycle != null ? n.cycle : '-'}`
  );

  const report = eachNode.reduce((s, n) => `${s}\n${n}`);
  console.log('===\nNAME\t\tINPUT\tOUTPUT\tCYCLE?\n');
  console.log(report);
};

// SIMULATION

const simulator = neuronGraph =>
  function(state) {
    const updateNode = neuronGraph(state.network);

    const inputScale = d3.scale.linear().clamp(true);
    const drain = -1;

    // Setup state and activation functions
    state.neurons.forEach(function(n) {
      n.active = false; // always initially off
      if (n.inputAgg == null) {
        n.inputAgg = 0.0;
      }
      if (n.cycle != null) {
        if (n.cycleTimer == null) {
          n.cycleTimer = 0;
        }
      }
      n.visited = 0;
      if (n.allTheTime) {
        n.fn = () => {
          n.active = true;
          n.inputAgg = 1.0;
          return (n.output = 1.0);
        };
      } else {
        n.fn = () => {
          n.inputAggV = 0.0;

          const activating = Math.abs(1.0 - n.inputAgg) < state.epsilon;
          const deactivating = Math.abs(0.0 - n.inputAgg) < state.epsilon;

          if (activating) {
            if (n.cycle != null) {
              // cycle is "how long it takes for the neuron to fully charge
              //   with an input sum of 1."
              n.cycleTimer += state.frameMillis;
              if (n.cycleTimer >= n.cycle) {
                n.active = true;
                n.cycleTimer = 0;
              }
            } else {
              // otherwise activate now
              n.active = true;
            }
          }

          if (deactivating) {
            n.active = false;
          }

          var oldOutput = n.output;
          n.output = n.active ? 1 : 0;
          if (typeof n.onOutputChange !== 'undefined' && n.onOutputChange !== null) {
            if (n.active ? oldOutput == 1 : oldOutput == 0) {
              n.onOutputChange(n.output);
            }
          }
        };
      }
    });

    const dt = state.frameMillis / 250.0;

    const simulationStep = setInterval(
      function() {
        if (!state.running) {
          return;
        }

        state.network.nodes.map(n => n.fn());

        // Highlight active neurons
        updateNode.selectAll('circle').attr('class', function(d) {
          if (d.active) {
            return 'active';
          } else {
            return 'inactive';
          }
        });

        // Highlight active dendrites

        updateNode
          .selectAll('.link')
          .classed('active', d => d.source.active)
          .classed('inactive', d => !d.source.active);

        // Display dendrite labels.
        updateNode.selectAll('text.weight-label').text(function(t) {
          const label = t.label != null ? t.label : '';
          return `${t.weight} ${label}`;
        });

        state.network.links.map(link => {
          if (!link.target.allTheTime) {
            const { source } = link;
            const { target } = link;

            if (target.visited <= state.network.nodes.length - 1) {
              if (target.cycle != null) {
                target.visited += 1;
              }

              const weight = link.weight * source.output;
              target.inputAggV += weight;
            }
          }
        });

        state.network.nodes.map(node => {
          if (!node.allTheTime) {
            node.visited = 0;
            node.inputAggV += drain;
            node.inputAggV *= dt;
            node.inputAgg = inputScale(node.inputAgg + node.inputAggV);
          }
        });

        if (state.reportOn) {
          return reportNodes(state.network.nodes, debugFmt);
        }
      },

      state.frameMillis
    );

    // for manual tweaking from console:
    window.network = state.network;

    if (state.endSimulationTime != null) {
      return setTimeout(() => clearInterval(simulationStep), state.endSimulationTime);
    }
  };

const showMuramatorNetwork = (present, state) =>
  fetch('neurons.json')
    .then(response => response.json())
    .then(function(data) {
      state.kf = 8;
      state.kt = -2;
      state.neurons = data.neurons;
      state.network = muramatorNetwork(state.kf, state.kt, data.neurons);

      // hook up "forward" to motor
      state.neurons.find(n => n.name === 'forward').onOutputChange = output => {
        world.emit({ type: output == 1 ? 'forwardOn' : 'forwardOff' });
      };

      // hook up "turn" to motor inhibitor
      state.neurons.find(n => n.name === 'turn').onOutputChange = output => {
        world.emit({ type: output == 1 ? 'turnOn' : 'turnOff' });
      };

      return present(state);
    });

const showSimpleNetwork = function(present, state) {
  const network = simpleNetwork();
  state.network = network;
  state.neurons = network.nodes;
  return present(state);
};

// GUI

const reportSelectionAction = (doc, state) =>
  function() {
    if (this.checked) {
      return (state.reportOn = true);
    } else {
      return (state.reportOn = false);
    }
  };

const setReportControl = (doc, state) =>
  doc
    .querySelectorAll('input[name=report]')
    .forEach(input => (input.onchange = reportSelectionAction(doc, state)));

const simControlAction = (doc, state) =>
  function() {
    if (this.checked) {
      return (state.running = true);
    } else {
      return (state.running = false);
    }
  };

const setSimulationControl = (doc, state) =>
  doc
    .querySelectorAll('input[name=simulate]')
    .forEach(input => (input.onchange = simControlAction(doc, state)));

const obstacleAction = (doc, state) =>
  function() {
    return (() => {
      const result = [];
      state.network.links.map(link => {
        if (link.source.name === 'emitter' && link.target.name === 'detect_obs') {
          const obstacle = this.checked;
          result.push((link.weight = obstacle ? 8 : 0));
        }
      });
      return result;
    })();
  };

const setObstacleControl = (doc, state) =>
  doc
    .querySelectorAll('input[name=obstacle]')
    .forEach(input => (input.onchange = obstacleAction(doc, state)));

// MAIN

document.getElementsByTagName('form')[0].reset();

const state = {
  frameMillis: 100.0,
  // endSimulationTime: 10000,
  running: true,
  reportOn: false,
  epsilon: 0.0001,
  graph: {}
};

const presenter = simulator(neuronGraph);
showMuramatorNetwork(presenter, state);
setReportControl(document, state);
setSimulationControl(document, state);

// document.addEventListener("obstacle", function(e) {
//   obstacleAction(document, state).bind({checked:true}).call();
// }, false);

app.world.on('obstacle', e => {
  obstacleAction(document, state)
    .bind({ checked: true })
    .call();
});
app.world.on('noObstacle', e => {
  obstacleAction(document, state)
    .bind({ checked: false })
    .call();
});

// setObstacleControl(document, state);

(function() {
  $(function() {
    var clock, connect, graphTick, inputs_for, kf, kt, muramatorNetwork, network, neuronGraph, pƒ, random, select_by_name_from, simpleNetwork, updateNode, v, weeGraph;
    select_by_name_from = function(n, x) {
      return function(x) {
        var i;
        return ((function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = n.length; _i < _len; _i++) {
            i = n[_i];
            if (i.name === x) {
              _results.push(i);
            }
          }
          return _results;
        })())[0];
      };
    };
    random = d3.random.normal(1, 0.5);
    inputs_for = function(network, node) {
      var link, _i, _len, _ref, _results;
      _ref = network.links;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        link = _ref[_i];
        if (link.target === node) {
          _results.push(link);
        }
      }
      return _results;
    };
    pƒ = _.partial;
    neuronGraph = function(network) {
      var circle, force, h, inputs, inputs_of, linkClass, linkMarker, links, markerPath, n, node, nodeLabel, nodeSize, nodes, path, r, svg, text, w, _i, _len;
      nodes = network.nodes;
      links = network.links;
      inputs_of = pƒ(inputs_for, network);
      if ((nodes == null) || (nodes != null ? nodes.length : void 0) === 0) {
        console.log("No nodes");
      }
      for (_i = 0, _len = nodes.length; _i < _len; _i++) {
        n = nodes[_i];
        inputs = inputs_of(n);
        n.active = false;
        n.input_agg = 0.0;
        if (n.allTheTime) {
          n.fn = function() {
            return 1;
          };
        } else {
          n.fn = function() {
            n.output = n.active ? 1 : 0;
            return n.output;
          };
        }
        n.value = function() {
          var input, input_sum, _j, _len1, _ref;
          _ref = n.inputs;
          for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
            input = _ref[_j];
            console.log(input);
          }
          input_sum = n.inputs.reduce(function(t, s) {
            return t + s;
          });
          console.log(input_sum);
          return input_sum;
        };
      }
      w = 500;
      h = 350;
      r = 20;
      markerPath = "M 4.73,-6.26 5.08,-1.43 7.05,3.47 0,0z";
      svg = d3.select("body").append("svg").attr("width", w).attr("height", h);
      svg.append("defs").append("marker").attr("id", "inh").attr("viewBox", "0 -7 10 10").attr("refX", 21.6).attr("refY", -3).attr("markerWidth", 8).attr("markerHeight", 8).attr("orient", "auto").append("path").attr("d", markerPath);
      svg.append("defs").append("marker").attr("id", "exc").attr("viewBox", "0 -7 10 10").attr("refX", 21.6).attr("refY", -3).attr("markerWidth", 8).attr("markerHeight", 8).attr("orient", "auto").append("path").attr("d", markerPath);
      force = d3.layout.force().nodes(nodes).links(links).size([w, h]).linkDistance(function(d) {
        if (d.size != null) {
          return d.size;
        } else {
          return r * 5;
        }
      }).charge(-r * 12).start();
      text = svg.selectAll("text.weight-label").data(links).enter().append("text").attr("class", "weight-label");
      linkClass = (function(_this) {
        return function(l) {
          return "link " + (l.weight < 0 ? "inh" : "exc");
        };
      })(this);
      linkMarker = (function(_this) {
        return function(l) {
          return "url(#" + (l.weight < 0 ? "inh" : "exc") + ")";
        };
      })(this);
      path = svg.append("g").selectAll("path").data(links).enter().append("path").attr("class", "link").attr("marker-end", linkMarker);
      node = svg.selectAll(".node").data(nodes).enter().append("g").attr("class", "node").attr("cx", function(d) {
        return d.x;
      }).attr("cy", function(d) {
        return d.y;
      }).call(force.drag);
      nodeSize = (function(_this) {
        return function(n) {
          if (n.allTheTime) {
            return r * 0.5;
          } else {
            return r;
          }
        };
      })(this);
      nodeLabel = (function(_this) {
        return function(n) {
          if (n.allTheTime) {
            return '  *';
          } else {
            return n.name;
          }
        };
      })(this);
      circle = node.append("circle").attr("r", nodeSize).attr("fill", '#f88');
      circle.append('title').text(function(n) {
        return n.name;
      });
      circle.on('mouseover', function() {
        var coords, weeGraph;
        weeGraph = d3.select('#graph');
        coords = d3.mouse(weeGraph[0].parentNode);
        return weeGraph.attr("transform", "translate(" + coords[0] + "," + coords[1] + ")");
      });
      node.append("text").attr("dy", ".2em").attr("text-anchor", "middle").attr("class", "node-label shadow").text(nodeLabel);
      node.append("text").attr("dy", ".2em").attr("text-anchor", "middle").attr("class", "node-label").text(nodeLabel).append('tspan').text((function(_this) {
        return function(n) {
          if (n.cycle != null) {
            return "" + n.cycle + "ms";
          } else {
            return '';
          }
        };
      })(this)).attr("text-anchor", "middle").attr('dy', '1.1em').attr('x', '0px').attr('class', 'cycle-label');
      text.attr("x", function(d) {
        return (d.source.x + d.target.x) / 2;
      }).attr("y", function(d) {
        return (d.source.y + d.target.y) / 2;
      }).attr("text-anchor", "middle").text(function(t) {
        return "" + t.weight;
      });
      force.on("tick", function() {
        path.attr("d", function(d) {
          var dr, dx, dy;
          dx = d.target.x - d.source.x;
          dy = d.target.y - d.source.y;
          dr = Math.sqrt(dx * dx + dy * dy);
          return "M" + d.source.x + "," + d.source.y + "A" + dr + "," + dr + " 0 0,1 " + d.target.x + "," + d.target.y;
        });
        text.attr("x", function(d) {
          return (d.source.x + d.target.x) / 2;
        }).attr("y", function(d) {
          return (d.source.y + d.target.y) / 2;
        });
        return node.attr("transform", function(d) {
          return "translate(" + d.x + "," + d.y + ")";
        });
      });
      return svg;
    };
    muramatorNetwork = function(kf, kt) {
      var N, dendrites, neurons;
      neurons = [
        {
          name: 'detector',
          x: 100,
          y: 100
        }, {
          name: 'detectObstacle',
          x: 200,
          y: 100,
          cycle: 15
        }, {
          name: 'S1',
          x: 300,
          y: 100
        }, {
          name: 'S2',
          x: 350,
          y: 250
        }, {
          name: 'turn',
          x: 400,
          y: 100
        }, {
          name: 'forward',
          x: 300,
          y: 300
        }, {
          name: 'explore_ex',
          x: 200,
          y: 200,
          allTheTime: true
        }, {
          name: 'seek',
          x: 150,
          y: 150,
          cycle: 5000
        }, {
          name: 'seek_ex',
          x: 100,
          y: 280,
          allTheTime: true
        }, {
          name: 'emit_ex',
          x: 50,
          y: 100,
          allTheTime: true
        }, {
          name: 'emitter',
          x: 50,
          y: 200,
          cycle: 6
        }
      ];
      N = select_by_name_from(neurons);
      dendrites = [
        {
          source: N('detector'),
          target: N('detectObstacle'),
          weight: 8
        }, {
          label: 'avoid',
          source: N('detectObstacle'),
          target: N('S1'),
          weight: 2
        }, {
          source: N('S1'),
          target: N('turn'),
          weight: 2
        }, {
          source: N('detectObstacle'),
          target: N('seek'),
          weight: -100
        }, {
          source: N('seek_ex'),
          target: N('seek'),
          size: 70,
          weight: kf
        }, {
          source: N('seek'),
          target: N('seek'),
          weight: -kt
        }, {
          source: N('seek'),
          target: N('S1'),
          weight: 2
        }, {
          source: N('S1'),
          target: N('S2'),
          weight: -2
        }, {
          source: N('explore_ex'),
          target: N('S2'),
          weight: 2,
          size: 70
        }, {
          source: N('S2'),
          target: N('forward'),
          weight: 2
        }, {
          source: N('emit_ex'),
          target: N('emitter'),
          size: 70,
          weight: 2
        }, {
          source: N('emitter'),
          target: N('emitter'),
          weight: -2
        }
      ];
      return {
        nodes: neurons,
        links: dendrites
      };
    };
    connect = function(n1, n2, params) {
      var dendrite, param, _i, _len;
      dendrite = {
        source: n1,
        target: n2
      };
      for (_i = 0, _len = params.length; _i < _len; _i++) {
        param = params[_i];
        dendrite[param] = params[param];
      }
      return dendrite;
    };
    simpleNetwork = function() {
      var dendrites, emit_ex, neurons, osc;
      osc = {
        name: 'osc',
        x: 200,
        y: 200,
        cycle: 3
      };
      emit_ex = {
        name: 'emit_ex',
        x: 50,
        y: 50,
        allTheTime: true
      };
      neurons = [emit_ex, osc];
      dendrites = [
        connect(emit_ex, osc, {
          weight: 2
        })
      ];
      return {
        nodes: neurons,
        links: dendrites
      };
    };
    kf = 20;
    kt = 10;
    network = muramatorNetwork(kt, kf);
    weeGraph = function(v) {
      var bgrect, data, graph, graph_root, height, label, line, margin, n, tick, width, x, y;
      n = 40;
      data = d3.range(n).map(function(x) {
        return v();
      });
      margin = {
        top: 5,
        right: 5,
        bottom: 8,
        left: 5
      };
      width = 160 - margin.left - margin.right;
      height = 50 - margin.top - margin.bottom;
      x = d3.scale.linear().domain([1, n - 2]).range([0, width]);
      y = d3.scale.linear().domain([0, 2]).range([height, 3]);
      line = d3.svg.line().interpolate("step-before").x(function(d, i) {
        return x(i);
      }).y(function(d, i) {
        return y(d);
      });
      graph_root = d3.select("svg").append("g").attr('id', 'graph').attr("transform", "translate(" + margin.left + "," + margin.top + ")");
      graph_root.select("defs").append("clipPath").attr("id", "clip").append("rect").attr("width", width).attr("height", height);
      bgrect = graph_root.append('rect').attr('class', 'graph-bg').attr('x', -20).attr('width', width * 1.3).attr('height', height).attr('rx', 5).attr('ry', 5);
      graph = graph_root.append("g").attr("clip-path", "url(#clip)").append("path").data([data]).attr("class", "graph").attr("d", line);
      label = graph_root.append('text').attr('class', 'func-label').attr('transform', "translate(0,20)");
      tick = function() {
        data.push(v());
        graph.attr("d", line).attr("transform", null).transition().duration(500).ease("linear").attr("transform", "translate(" + x(0) + ")").each("end", tick);
        return data.shift();
      };
      return tick;
    };
    updateNode = neuronGraph(network);
    d3.timer(function() {
      var l, n, source, target, _i, _j, _len, _len1, _ref, _ref1;
      updateNode.selectAll('circle').attr('class', function(d) {
        if (d.active) {
          return "active";
        } else {
          return "inactive";
        }
      });
      updateNode.selectAll('.link').attr('stroke', function(d) {
        if (d.source.active) {
          return "#f88";
        } else {
          return "#aaa";
        }
      });
      _ref = network.nodes;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        n = _ref[_i];
        n.input_agg = 0.0;
      }
      _ref1 = network.links;
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        l = _ref1[_j];
        source = l.source;
        target = l.target;
        target.input_agg += l.weight * source.fn();
      }
      return false;
    }, 200);
    v = 0;
    clock = function(n) {
      if (n == null) {
        n = null;
      }
      return function() {
        v += 1;
        v = v % 2;
        return v;
      };
    };
    graphTick = weeGraph(function() {
      return network.nodes[1].input_agg;
    });
    graphTick();
    return window.network = network;
  });

}).call(this);
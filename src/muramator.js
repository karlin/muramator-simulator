(function() {
  $(function() {
    var connect, kf, kt, muramatorNetwork, neuronGraph, simpleNetwork;
    neuronGraph = document.muramator.neuronGraph;
    muramatorNetwork = function(kf, kt, neurons) {
      var dendrites;
      dendrites = [
        {
          source: 'detector',
          target: 'detectObstacle',
          weight: 8
        }, {
          label: 'avoid',
          source: 'detectObstacle',
          target: 'S1',
          weight: 2
        }, {
          source: 'S1',
          target: 'turn',
          weight: 2
        }, {
          source: 'detectObstacle',
          target: 'seek',
          weight: -100
        }, {
          source: 'seek_ex',
          target: 'seek',
          size: 70,
          weight: kf
        }, {
          source: 'seek',
          target: 'seek',
          weight: -kt
        }, {
          source: 'seek',
          target: 'S1',
          weight: 2
        }, {
          source: 'S1',
          target: 'S2',
          weight: -2
        }, {
          source: 'explore_ex',
          target: 'S2',
          weight: 2,
          size: 70
        }, {
          source: 'S2',
          target: 'forward',
          weight: 2
        }, {
          source: 'emit_ex',
          target: 'emitter',
          size: 70,
          weight: 2
        }, {
          source: 'emitter',
          target: 'emitter',
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
    return $.getJSON('neurons.json').then(function(data) {
      var clock, graphTick, network, updateNode, v, weeGraph;
      network = muramatorNetwork(kt, kf, data.neurons);
      weeGraph = function(valueFunc) {
        var bgrect, graph, graph_root, height, label, line, margin, n, tick, width, x, y;
        n = 40;
        data = d3.range(n).map(function(x) {
          return valueFunc();
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
        graph.on('mousedown', function() {});
        label = graph_root.append('text').attr('class', 'func-label').attr('transform', "translate(0,20)");
        tick = function() {
          data.push(valueFunc());
          graph.attr("d", line).attr("transform", "").transition().duration(500).ease("linear").attr("transform", "translate(" + x(0) + ")").each("end", tick);
          label.text("" + (valueFunc()));
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
      graphTick = weeGraph(clock());
      graphTick();
      return window.network = network;
    });
  });

}).call(this);

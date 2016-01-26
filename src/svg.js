(function() {
  var inputsFor, pf, random, resolveNodes, selectByNameFrom;

  selectByNameFrom = function(n, x) {
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

  resolveNodes = function(resolver, link) {
    var attr, _i, _len, _ref;
    _ref = ['source', 'target'];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      attr = _ref[_i];
      link[attr] = resolver(link[attr]);
    }
    return link;
  };

  random = d3.random.normal(1, 0.5);

  inputsFor = function(network, node) {
    var link, _i, _len, _ref, _results;
    _ref = network.links;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      link = _ref[_i];
      if (link.target === node.name) {
        _results.push(link);
      }
    }
    return _results;
  };

  pf = _.partial;

  document.muramator.neuronGraph = function(network) {
    var circle, force, h, inputs, inputsOf, link, linkClass, linkMarker, links, markerPath, n, node, nodeLabel, nodeResolver, nodeSize, nodes, path, r, svg, text, w, _i, _len;
    nodes = network.nodes;
    nodeResolver = selectByNameFrom(nodes);
    links = (function() {
      var _i, _len, _ref, _results;
      _ref = network.links;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        link = _ref[_i];
        _results.push(resolveNodes(nodeResolver, link));
      }
      return _results;
    })();
    inputsOf = pf(inputsFor, network);
    if ((nodes == null) || (nodes != null ? nodes.length : void 0) === 0) {
      console.log("No nodes");
    }
    for (_i = 0, _len = nodes.length; _i < _len; _i++) {
      n = nodes[_i];
      inputs = inputsOf(n);
      console.log(inputs);
      n.active = false;
      n.input_agg = 0.0;
      if (n.allTheTime) {
        n.fn = function() {
          return n.output = 1;
        };
      } else {
        n.fn = function() {
          n.output = n.active ? 1 : 0;
          return n.output;
        };
      }
      n.value = function() {
        var input, _j, _len1, _ref, _results;
        _ref = n.inputs;
        _results = [];
        for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
          input = _ref[_j];
          _results.push(console.log(input));
        }
        return _results;
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
    circle.on('contextmenu', function() {
      var coords, weeGraph;
      d3.event.preventDefault();
      weeGraph = d3.select('#graph');
      coords = d3.mouse(weeGraph[0].parentNode);
      weeGraph.attr("transform", "translate(" + coords[0] + "," + coords[1] + ")");
      return false;
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
    return force.on("tick", function() {
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
  };

}).call(this);

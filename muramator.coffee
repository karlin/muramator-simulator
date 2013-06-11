# see also, http://jsfiddle.net/karlin/dQvQg/1/

$ ->

  select_by_name_from = (n, x) ->
    (x) ->
      (i for i in n when i.name is x)[0]

  random = d3.random.normal(1, 0.5)
  inputs_for = (network, node) ->
    link for link in network.links when link.target == node

  pƒ = _.partial
  neuronGraph = (network) ->
    nodes = network.nodes
    links = network.links
    inputs_of = pƒ inputs_for, network
    console.log "No nodes" if !nodes? or nodes?.length == 0
    for n in nodes
      inputs = inputs_of n # find edges that describe inputs to this neuron
      n.active = false # always initially off
      if n.allTheTime
        n.fn = -> 1
      else
        n.fn = ->
          n.output = if n.active then 1 else 0
          n.output
      n.value = ->
        console.log(input) for input in n.inputs
        input_sum = n.inputs.reduce (t, s) -> t + s
        console.log input_sum
        input_sum

    #
    # Graph these puppies
    #

    w = 500
    h = 350
    r = 20
    markerPath = "M 4.73,-6.26 5.08,-1.43 7.05,3.47 0,0z"

    svg = d3.select("body").append("svg")
      .attr("width", w)
      .attr("height", h);

    svg.append("defs").append("marker")
      .attr("id", "inh")
      .attr("viewBox", "0 -7 10 10")
      .attr("refX", 21.6)
      .attr("refY", -3)
      .attr("markerWidth", 8)
      .attr("markerHeight", 8)
      .attr("orient", "auto")
      .append("path")
      .attr("d", markerPath)
        
    svg.append("defs").append("marker")
      .attr("id", "exc")
      .attr("viewBox", "0 -7 10 10")
      .attr("refX", 21.6)
      .attr("refY", -3)
      .attr("markerWidth", 8)
      .attr("markerHeight", 8)
      .attr("orient", "auto")
      .append("path")
      .attr("d", markerPath)

    force = d3.layout.force()
      .nodes(nodes)
      .links(links)
      .size([w, h])
      .linkDistance((d) -> if d.size? then d.size else r*5)
      .charge(-r*12)
      .start()

    text = svg.selectAll("text.weight-label")
      .data(links)
      .enter().append("text")
      .attr("class", "weight-label")

    linkClass = (l) =>
      "link #{if l.weight < 0 then "inh" else "exc"}"

    linkMarker = (l) =>
      "url(##{if l.weight < 0 then "inh" else "exc"})"

    path = svg.append("g").selectAll("path")
      .data(links)
      .enter().append("path")
      .attr("class", "link")
      .attr("marker-end", linkMarker)

    node = svg.selectAll(".node")
      .data(nodes)
      .enter().append("g")
      .attr("class", "node")
      .attr("cx", (d) -> d.x)
      .attr("cy", (d) -> d.y)
      .call(force.drag)

    nodeSize = (n) =>
      if n.allTheTime then (r * 0.5) else r

    nodeLabel = (n) =>
      if n.allTheTime then '  *' else n.name

    circle = node.append("circle")
      .attr("r", nodeSize)
      .attr("fill", '#f88')
    circle.append('title')
      .text((n) -> n.name)
    circle.on 'mouseover', ->
      weeGraph = d3.select('#graph')
      coords = d3.mouse(weeGraph[0].parentNode)
      weeGraph.attr("transform", "translate(#{coords[0]},#{coords[1]})")

    node.append("text")
      .attr("dy", ".2em")
      .attr("text-anchor", "middle")
      .attr("class", "node-label shadow")
      .text(nodeLabel)

    node.append("text")
      .attr("dy", ".2em")
      .attr("text-anchor", "middle")
      .attr("class", "node-label")
      .text(nodeLabel).append('tspan')
                .text((n)=> if n.cycle? then "#{n.cycle}ms" else '')
                .attr("text-anchor", "middle")
                .attr('dy', '1.1em')
                .attr('x', '0px')
                .attr('class', 'cycle-label')

    text.attr("x", (d) -> (d.source.x + d.target.x) / 2)
      .attr("y", (d) -> (d.source.y + d.target.y) / 2)
      .attr("text-anchor", "middle")
      .text (t) -> "#{t.weight}"
        
    force.on "tick", ->
      path.attr "d", (d) ->
        dx = d.target.x - d.source.x
        dy = d.target.y - d.source.y
        dr = Math.sqrt(dx * dx + dy * dy)
        "M#{d.source.x},#{d.source.y}A#{dr},#{dr} 0 0,1 #{d.target.x},#{d.target.y}"
      
      text.attr("x", (d) -> (d.source.x + d.target.x) / 2)
        .attr("y", (d) -> (d.source.y + d.target.y) / 2)
      
      node.attr("transform", (d) -> "translate(#{d.x},#{d.y})")

    svg

  muramatorNetwork = (kf, kt) ->
    neurons = [
      {name:'detector',       x:100, y:100},
      {name:'detectObstacle', x:200, y:100, cycle:15},
      {name:'S1',             x:300, y:100},
      {name:'S2',             x:350, y:250},
      {name:'turn',           x:400, y:100},
      {name:'forward',        x:300, y:300},
      {name:'explore_ex',     x:200, y:200, allTheTime:true},
      {name:'seek',           x:150, y:150, cycle:5000},
      {name:'seek_ex',        x:100, y:280, allTheTime: true},
      {name:'emit_ex',        x:50,  y:100, allTheTime: true},
      {name:'emitter',        x:50,  y:200, cycle:6},
    ]

    N = select_by_name_from neurons

    dendrites = [
        source: N 'detector'
        target: N 'detectObstacle'
        weight: 8
      ,
        label: 'avoid'
        source: N 'detectObstacle'
        target: N 'S1'
        weight: 2
      ,
        source: N 'S1'
        target: N 'turn'
        weight: 2
      ,
        source: N 'detectObstacle'
        target: N 'seek'
        weight: -100
      ,
        source: N 'seek_ex'
        target: N 'seek'
        size: 70
        weight: kf
      ,
        source: N 'seek'
        target: N 'seek'
        weight: -kt
      ,
        source: N 'seek'
        target: N 'S1'
        weight: 2
      ,
        source: N 'S1'
        target: N 'S2'
        weight: -2
      ,
        source: N 'explore_ex'
        target: N 'S2'
        weight: 2
        size: 70
      ,
        source: N 'S2'
        target: N 'forward'
        weight: 2
      ,
        source: N 'emit_ex'
        target: N 'emitter'
        size: 70
        weight: 2
      ,
        source: N 'emitter'
        target: N 'emitter'
        weight: -2
    ]

    nodes: neurons
    links: dendrites

  connect = (n1, n2, params) ->
    dendrite = 
      source: n1
      target: n2
    for param in params
      dendrite[param] = params[param]
    dendrite

  simpleNetwork = ->
    osc = {name:'osc',     x:200, y:200, cycle:3}
    emit_ex = {name:'emit_ex', x:50,  y:50, allTheTime: true}
    neurons = [ emit_ex, osc ]

    # N('osc').fn = (t) -> 
    dendrites = [
      connect( emit_ex, osc, {weight: 2} ),
    ]

    #     source: neurons[0]
    #     target: osc
    #     weight: 2
    #   ,
    #     source: osc
    #     target: osc
    #     weight: -4
    # ]

    nodes: neurons
    links: dendrites

  kf = 20
  kt = 10
  network = muramatorNetwork kt, kf
  # network = simpleNetwork()  

  weeGraph = (v) ->
    n = 40
    data = d3.range(n).map((x) -> v())
    margin =
      top: 5
      right: 5
      bottom: 8
      left: 5

    width = 160 - margin.left - margin.right
    height = 50 - margin.top - margin.bottom
    x = d3.scale.linear().domain([ 1, n - 2 ]).range([ 0, width ])
    y = d3.scale.linear().domain([ 0, 2 ]).range([ height, 3])
    line = d3.svg.line().interpolate("step-before").x((d, i) ->x(i)).y((d, i) -> y(d))
    graph_root = d3.select("svg")
      .append("g")
      .attr('id', 'graph')
      .attr("transform", "translate(" + margin.left + "," + margin.top + ")")

    graph_root.select("defs").append("clipPath")
      .attr("id", "clip")
      .append("rect")
      .attr("width", width)
      .attr("height", height)
    bgrect = graph_root.append('rect').attr('class', 'graph-bg').attr('x', -20)
      .attr('width', width*1.3).attr('height', height).attr('rx', 5).attr('ry', 5)

    graph = graph_root.append("g")
      .attr("clip-path", "url(#clip)")
      .append("path").data([ data ])
      .attr("class", "graph")
      .attr("d", line)
    label = graph_root.append('text')
      .attr('class', 'func-label')
      .attr('transform', "translate(0,20)")

    tick = ->
      data.push v()
      graph.attr("d", line)
        .attr("transform", null)
        .transition()
        .duration(500)
        .ease("linear")
        .attr("transform", "translate(" + x(0) + ")")
        .each("end", tick)
      # TODO graph labels
      # label.text("#{v()}")
      data.shift()

    tick

  updateNode = neuronGraph(network)
  d3.timer(->
    updateNode.selectAll('circle').attr('class', (d) ->
      if d.active then "active" else "inactive"
      )
    updateNode.selectAll('.link').attr('stroke', (d) ->
      if d.source.active then "#f88" else "#aaa")
    
    false
  ,200)

  v = 0
  clock = (n=null) ->
    ->
      v += 1
      v = v % 2
      v

  # graphTick = weeGraph(clock(N('explore_ex')))
  # graphTick = weeGraph(clock())
  graphTick = weeGraph(random)
  # graphTick = weeGraph(network.nodes[1].fn)
  graphTick()
  window.network = network


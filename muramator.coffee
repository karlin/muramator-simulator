$ ->
  v=0
  clock = (n) =>
    =>
      n.active = (v++) % 2 == 0
      v

  onAllTheTime = -> 1

  neurons = [
      name: 'detector'
      x: 100
      y: 100
    ,
      name: 'detectObstacle'
      cycle: 15
      x: 200
      y: 100
    ,
      name: 'S1'
      x: 300
      y: 100
    ,
      name: 'S2'
      x: 350
      y: 250
    ,
      name: 'turn'
      x: 400
      y: 100
    ,
      name: 'forward'
      x: 300
      y: 300
    ,
      name: 'explore_ex'
      allTheTime: true
      x: 200
      y: 200
    ,
      name: 'seek'
      cycle: 5000
      x: 150
      y: 150
    ,
      name: 'seek_ex'
      allTheTime: true
      x: 100
      y: 280
    ,
      name: 'emit_ex'
      allTheTime: true
      x: 50
      y: 100
    ,
      name: 'emitter'
      cycle: 6
      x: 50
      y: 200
  ]

  N = (x) => (i for i in neurons when i.name is x)[0]

  kf = 20
  kt = 10

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

  for n in neurons
    n.active = true
  #   if n.allTheTime then
  #     n.fn = -> 1
  #   else
  #     n.fn = -> n.output = n.value + 

  #
  # Graph these puppies
  #

  nodes = neurons
  links = dendrites

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

  node.append("circle")
      .attr("r", nodeSize)
      .attr("fill", (n) -> 
        return if n.active then "rgba(255,205,190,0.9)" else "rgba(155,105,250,1)"
      )

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

  random = d3.random.normal(1, 0.5)

  weeGraph = (v) ->
    tick = ->
      data.push v()
      graph
        .attr("d", line)
        .attr("transform", null)
        .transition()
        .duration(500)
        .ease("linear")
        .attr("transform", "translate(" + x(0) + ")")
        .each("end", tick)
      data.shift()

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
    y = d3.scale.linear().domain([ 0, 2 ]).range([ height, 3 ])
    line = d3.svg.line().interpolate("step-before").x((d, i) ->x(i)).y((d, i) -> y(d))
    svg = d3.select("body").append("svg")
        .attr("width", width + margin.left + margin.right)
        .attr("height", height + margin.top + margin.bottom)
      .append("g")
        .attr("transform", "translate(" + margin.left + "," + margin.top + ")")

    svg.append("defs").append("clipPath")
        .attr("id", "clip")
      .append("rect")
        .attr("width", width)
        .attr("height", height)

    graph = svg.append("g")
        .attr("clip-path", "url(#clip)")
      .append("path").data([ data ])
        .attr("class", "graph")
        .attr("d", line)
    tick

  weeGraph(clock(N('explore_ex')))()

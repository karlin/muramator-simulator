selectByNameFrom = (n, x) ->
  (x) ->
    (i for i in n when i.name is x)[0]

resolveNodes = (resolver, link) ->
  for attr in ['source', 'target']
    link[attr] = resolver link[attr]
  link

random = d3.random.normal(1, 0.5)
inputsFor = (network, node) ->
  link for link in network.links when link.target == node.name

pf = _.partial

document.muramator.neuronGraph = (network) ->

  nodes = network.nodes
  # TODO map over links and find nodes for given names'
  nodeResolver = selectByNameFrom nodes
  links = (resolveNodes(nodeResolver, link) for link in network.links)
  inputsOf = pf inputsFor, network
  console.log "No nodes" if !nodes? or nodes?.length == 0
  for n in nodes
    inputs = inputsOf n # find edges that describe inputs to this neuron
    console.log inputs
    n.active = false # always initially off
    n.input_agg = 0.0
    if n.allTheTime
      n.fn = ->
        n.output = 1
    else
      n.fn = ->
        n.output = if n.active then 1 else 0
        n.output
    n.value = ->
      console.log(input) for input in n.inputs
      # input_sum = n.inputs.reduce (t, s) -> t + s
      # console.log input_sum
      # input_sum

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
  circle.on 'contextmenu', ->
    d3.event.preventDefault()
    weeGraph = d3.select('#graph')
    coords = d3.mouse(weeGraph[0].parentNode)
    weeGraph.attr("transform", "translate(#{coords[0]},#{coords[1]})")
    false

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

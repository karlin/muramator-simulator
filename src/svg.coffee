document.muramator.neuronGraph = (network) ->
  nodes = network.nodes
  links = network.links

  w = 600
  h = 500
  r = 30
  markerPath = "M 4.73,-6.26 5.08,-1.43 7.05,3.47 0,0z"

  svg = d3.select("body").append("svg")
    .attr("width", w)
    .attr("height", h);

  svg.append("defs").append("marker")
    .attr("id", "inh")
    .attr("viewBox", "0 -8 12 12")
    .attr("refX", 18)
    .attr("refY", -2.76)
    .attr("markerWidth", 10)
    .attr("markerHeight", 10)
    .attr("orient", "auto")
    .append("path")
    .attr("d", markerPath)

  svg.select("defs").append("marker")
    .attr("id", "exc")
    .attr("viewBox", "0 -8 12 12")
    .attr("refX", 18)
    .attr("refY", -2.76)
    .attr("markerWidth", 10)
    .attr("markerHeight", 10)
    .attr("orient", "auto")
    .append("path")
    .attr("d", markerPath)

  force = d3.layout.force()
    .nodes(nodes)
    .links(links)
    .size([w, h])
    .linkDistance((d) -> if d.size? then d.size else r*5)
    .charge(-r*14)
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
    .data(links.filter((l)->l.source != l.target))
    .enter().append("path")
    .attr("class", "link")
    .attr("marker-end", linkMarker)

  path2 = svg.append("g").attr("class", "self-links").selectAll("path")
    .data(links.filter((l)->l.source == l.target)) # self-links
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
    if n.allTheTime then '*' else n.name

  circle = node.append("circle")
    .attr("r", nodeSize)
    .attr("fill", '#f88')
  circle.append('title')
    .text((n) -> n.name)

  circle.on 'contextmenu', (neuron) ->
    d3.event.preventDefault()
    document.querySelector('#graph')?.remove()
    document.muramator.contextGraph(neuron.name, () -> neuron.input_agg)()

    graphFrame = d3.select('#graph')
    coords = d3.mouse(graphFrame[0].parentNode)
    graphFrame.attr("transform", "translate(#{coords[0]},#{coords[1]})")

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

    path2.attr "d", (d) ->
      "M#{d.source.x},#{d.source.y}c 100,-100,100,120 0,0"

    text.attr("x", (d) -> (d.source.x + d.target.x) / 2)
      .attr("y", (d) -> (d.source.y + d.target.y) / 2)

    node.attr("transform", (d) -> "translate(#{d.x},#{d.y})")

  svg
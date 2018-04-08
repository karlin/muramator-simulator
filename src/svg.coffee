document.muramator.neuronGraph = (network) ->
  nodes = network.nodes
  links = network.links

  w = 600
  h = 500
  r = 30
  markerPath = "M 4.73,-6.26 5.08,-1.43 7.05,3.47 0,0z"

  nodeSize = (n) ->
    if n.allTheTime then (r * 0.5) else r

  nodeLabel = (n) ->
    if n.allTheTime then "#{n.name}*" else n.name

  linkClass = (l) ->
    # state = switch
    #   when l.weight < 0 then "inh"
    #   when l.weight > 0 then "exc"
    #   else ""
    # "link #{state}"
    "link #{if l.weight < 0 then "inh" else "exc"}"

  linkMarker = (l) ->
    "url(##{if l.weight < 0 then "inh" else "exc"})"

  svg = d3.select("body").append("svg")
    .attr("width", w)
    .attr("height", h);

  makeMarker = (node) ->
    node.attr("viewBox", "-2 -10 16 16")
    .attr("refX", r * 0.52)
    .attr("refY", -3)
    .attr("markerWidth", 16)
    .attr("markerHeight", 16)
    .attr("orient", "auto")
    .append("path")
    .attr("d", markerPath)

  svg.append("defs").append("marker")
    .attr("id", "inh")
    .call(makeMarker)

  svg.select("defs").append("marker")
    .attr("id", "exc")
    .call(makeMarker)
  acyclicLinks = links.filter((l) -> l.source != l.target)
  cyclicLinks = links.filter((l) -> l.source == l.target)

  force = d3.layout.force()
    .nodes(nodes)
    .links(acyclicLinks)
    .size([w, h])
    .linkDistance((d) -> if d.size? then d.size else r * 5)
    .charge(-r * 14)
    .start()

  linkLabels = svg.selectAll("text.weight-label")
    .data(acyclicLinks)
    .enter().append("text")
      .attr("class", "weight-label")

  selfLinkLabels = svg.selectAll("text.cyclic-weight-label")
    .data(cyclicLinks) # self-links
    .enter().append("text")
    .attr("class", "cyclic-weight-label")

  linksGroup = svg.append("g")
      .attr("class", "links")
    .selectAll("path").data(acyclicLinks)
    .enter().append("path")
      .attr("class", linkClass)
      .attr("marker-end", linkMarker)

  selfLinksGroup = svg.append("g")
      .attr("class", "self-links")
    .selectAll("path").data(cyclicLinks) # self-links
    .enter().append("path")
      .attr("class", linkClass)
      .attr("marker-end", linkMarker)

  nodeGroups = svg.selectAll(".node")
    .data(nodes)
    .enter().append("g")
    .attr("class", "node")
    .attr("cx", (d) -> d.x)
    .attr("cy", (d) -> d.y)
    .call(force.drag)

  nodeShape = nodeGroups.append("circle")
    .attr("r", nodeSize)
  nodeShape.append('title')
    .text((n) -> n.name)

  nodeShape.on 'contextmenu', (neuron) ->
    d3.event.preventDefault()
    document.querySelector('#graph')?.remove()
    document.muramator.contextGraph(neuron.name, () -> neuron.inputAgg)()

    graphFrame = d3.select('#graph')
    coords = d3.mouse(graphFrame[0].parentNode)
    graphFrame.attr("transform", "translate(#{coords[0]},#{coords[1]})")

    false

  nodeGroups.append("text")
    .attr("dy", ".2em")
    .attr("text-anchor", "middle")
    .attr("class", "node-label shadow")
    .text(nodeLabel)

  nodeGroups.append("text")
    .attr("dy", ".2em")
    .attr("text-anchor", "middle")
    .attr("class", "node-label")
    .text(nodeLabel).append('tspan')
      .text((n)=> if n.cycle? then "#{n.cycle}ms" else '')
      .attr("text-anchor", "middle")
      .attr('dy', '1.1em')
      .attr('x', '0px')
      .attr('class', 'cycle-label')

  linkLabels.attr("x", (d) -> (d.source.x + d.target.x) / 2)
    .attr("y", (d) -> (d.source.y + d.target.y) / 2)
    .attr("text-anchor", "middle")
    .text (t) -> "#{t.weight} #{t.label ? ""}"

  selfLinkLabels.attr("x", 200)
    .attr("y", (d) -> (d.target.y) - 20)
    .attr("text-anchor", "middle")
    .text (t) -> "#{t.weight} #{t.label ? ""}"

  force.on "tick", ->
    linksGroup.attr "d", (d) ->
      dx = d.target.x - d.source.x
      dy = d.target.y - d.source.y
      dr = Math.sqrt(dx * dx + dy * dy)
      "M#{d.source.x},#{d.source.y}A#{dr},#{dr} 0 0,1 #{d.target.x},#{d.target.y}"

    selfLinksGroup.attr "d", (d) ->
      "M#{d.source.x},#{d.source.y}c 100,-100,100,120 0,0"

    linkLabels.attr("x", (d) -> (d.source.x + d.target.x) / 2)
      .attr("y", (d) -> (d.source.y + d.target.y) / 2)

    selfLinkLabels.attr("x", (d) -> d.target.x+55)
      .attr("y", (d) -> (d.target.y))

    nodeGroups.attr("transform", (d) -> "translate(#{d.x},#{d.y})")

    setTimeout(->
      force.stop()
    , 1400)
  svg

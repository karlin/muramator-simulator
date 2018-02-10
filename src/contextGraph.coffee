document.muramator.contextGraph = (name, valueFunc) ->
  n = 40
  data = d3.range(n).map((x) -> valueFunc())
  margin =
    top: 5
    right: 5
    bottom: 8
    left: 5

  width = 160 - margin.left - margin.right
  height = 50 - margin.top - margin.bottom
  x = d3.scale.linear().domain([ 1, n - 2 ]).range([ 0, width ])
  y = d3.scale.linear().domain([ 0, 2 ]).range([ height, 3])
  labelFmt = d3.format('.2f')
  line = d3.svg.line().interpolate("step-before").x((d, i)->x(i)).y((d, i)->y(d))
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
  # graph.on 'mousedown', ->

  label = graph_root.append('text')
    .attr('class', 'func-label')
    .attr('transform', "translate(0,10)")

  tick = ->
    value = valueFunc()
    data.push value
    graph.attr("d", line)
      # .attr("transform", "")
      .transition()
      .delay(100)

      # .ease("linear")
      .attr("transform", "translate(#{x(0)})")
      # .duration(200)
      .each("end", tick)
    # TODO graph labels
    label.text("#{name}: #{labelFmt(value)}")
    data.shift()

  tick
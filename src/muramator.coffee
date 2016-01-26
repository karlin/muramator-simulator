# see also, http://jsfiddle.net/karlin/dQvQg/1/

$ ->
  neuronGraph = document.muramator.neuronGraph

  muramatorNetwork = (kf, kt, neurons) ->
    dendrites = [
        source: 'detector'
        target: 'detectObstacle'
        weight: 8
      ,
        label: 'avoid'
        source: 'detectObstacle'
        target: 'S1'
        weight: 2
      ,
        source: 'S1'
        target: 'turn'
        weight: 2
      ,
        source: 'detectObstacle'
        target: 'seek'
        weight: -100
      ,
        source: 'seek_ex'
        target: 'seek'
        size: 70
        weight: kf
      ,
        source: 'seek'
        target: 'seek'
        weight: -kt
      ,
        source: 'seek'
        target: 'S1'
        weight: 2
      ,
        source: 'S1'
        target: 'S2'
        weight: -2
      ,
        source: 'explore_ex'
        target: 'S2'
        weight: 2
        size: 70
      ,
        source: 'S2'
        target: 'forward'
        weight: 2
      ,
        source: 'emit_ex'
        target: 'emitter'
        size: 70
        weight: 2
      ,
        source: 'emitter'
        target: 'emitter'
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
  $.getJSON('neurons.json').then (data) ->
    network = muramatorNetwork kt, kf, data.neurons
    # network = simpleNetwork()

    weeGraph = (valueFunc) ->
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
      graph.on 'mousedown', ->

      label = graph_root.append('text')
        .attr('class', 'func-label')
        .attr('transform', "translate(0,20)")

      tick = ->
        data.push valueFunc()
        graph.attr("d", line)
          .attr("transform", "")
          .transition()
          .duration(500)
          .ease("linear")
          .attr("transform", "translate(" + x(0) + ")")
          .each("end", tick)
        # TODO graph labels
        label.text("#{valueFunc()}")
        data.shift()

      tick

    updateNode = neuronGraph(network)
    d3.timer(->
      updateNode.selectAll('circle').attr('class', (d) ->
        if d.active then "active" else "inactive"
        )
      updateNode.selectAll('.link').attr('stroke', (d) ->
        if d.source.active then "#f88" else "#aaa")

      # zero out weighted input sums on each tick
      n.input_agg = 0.0 for n in network.nodes

      for l in network.links
        source = l.source
        target = l.target
        # add the weighted source output as input to the target
        target.input_agg += l.weight * source.fn()
      false
    ,200)

    v = 0
    clock = (n=null) ->
      ->
        v += 1
        v = v % 2
        v

    # graphTick = weeGraph(clock(N('explore_ex')))
    graphTick = weeGraph(clock())
    # graphTick = weeGraph(->network.nodes[1].input_agg)
    # graphTick = weeGraph(network.nodes[1].fn)
    graphTick()
    window.network = network

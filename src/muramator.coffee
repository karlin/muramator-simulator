# see also, http://jsfiddle.net/karlin/dQvQg/1/

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

connect = (n1, n2, params) =>
  dendrite =
    source: n1.name
    target: n2.name
  for param of params
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

$ ->
  kf = 20
  kt = 10
  $.getJSON('neurons.json').then (data) ->
    # network = muramatorNetwork kt, kf, data.neurons
    network = simpleNetwork()

    neuronGraph = document.muramator.neuronGraph
    updateNode = neuronGraph(network)
    d3.timer(->
      updateNode.selectAll('circle').attr('class', (d) ->
        if d.active then "active" else "inactive")
      updateNode.selectAll('.link').attr('stroke', (d) ->
        if d.source.active then "#f88" else "#aaa")

      # zero out weighted input sums on each tick
      n.input_agg = 0.0 for n in network.nodes

      for l in network.links
        source = l.source
        target = l.target
        # add the weighted source output as input to the target
        if source.fn?
          target.input_agg += l.weight * source.fn()
      false
    ,500)

    v = 0
    clock = (n = null) ->
      ->
        v += 1
        v = v % 2
        v

    contextGraph = document.muramator.contextGraph
    # graphTick = contextGraph(clock())
    # graphTick = contextGraph((clock, n) ->
    #   ->
    #     Math.sin(clock())
    # )
    # graphTick = contextGraph(->network.nodes[1].input_agg)
    # graphTick = contextGraph(network.nodes[1].fn)
    # graphTick()
    window.network = network

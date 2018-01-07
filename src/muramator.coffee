# see also, http://jsfiddle.net/karlin/dQvQg/1/

muramatorNetwork = (kf, kt, neurons) ->
  named = (name) ->
    neurons.find (n) ->
      n.name == name

  dendrites = [
      source: named('detector')
      target: named('detectObstacle')
      weight: 8
    ,
      label: named('avoid')
      source: named('detectObstacle')
      target: named('S1')
      weight: 2
    ,
      source: named('S1')
      target: named('turn')
      weight: 2
    ,
      source: named('detectObstacle')
      target: named('seek')
      weight: -100
    ,
      source: named('seek_ex')
      target: named('seek')
      size: 70
      weight: kf
    ,
      source: named('seek')
      target: named('seek')
      weight: -kt
    ,
      source: named('seek')
      target: named('S1')
      weight: 2
    ,
      source: named('S1')
      target: named('S2')
      weight: -2
    ,
      source: named('explore_ex')
      target: named('S2')
      weight: 2
      size: 70
    ,
      source: named('S2')
      target: named('forward')
      weight: 2
    ,
      source: named('emit_ex')
      target: named('emitter')
      size: 70
      weight: 2
    ,
      source: named('emitter')
      target: named('emitter')
      weight: -2
  ]

  nodes: neurons
  links: dendrites

connect = (n1, n2, params) =>
  dendrite =
    source: n1
    target: n2
  for param of params
    dendrite[param] = params[param]
  dendrite

simpleNetwork = ->
  osc =     {name: 'osc',     x: 200, y: 200, cycle: 3000}
  emit_ex = {name: 'emit_ex', x: 50,  y: 50,  allTheTime: true}
  neurons = [ emit_ex, osc ]

  dendrites = [
    connect( emit_ex, osc, { weight: 2 }),
    connect( osc, osc, { weight: -4 })
  ]

  nodes: neurons
  links: dendrites

kf = 20
kt = 10

inputsFor = (network, node) ->
  link for link in network.links when link.target == node

# $.getJSON('neurons.json').then (data) ->
# neurons = data.neurons
# network = muramatorNetwork kt, kf, neurons
network = simpleNetwork()
neurons = network.nodes

neuronGraph = document.muramator.neuronGraph
updateNode = neuronGraph(network)

inputsOf = _.partial inputsFor, network

# Set up state and activation functions
neurons.forEach (n) ->
  n.active = false # always initially off
  n.input_agg = 0.0
  if n.allTheTime
    n.fn = =>
      n.output = 1
  else
    n.fn = =>
      n.output = if n.active then 1 else 0

debugFmt = d3.format("0.2f")
simulationStep = setInterval((ticks) ->
  n.fn() for n in network.nodes

  updateNode.selectAll('circle').attr('class', (d) ->
    if d.active then "active" else "inactive")
  updateNode.selectAll('.link').attr('stroke', (d) ->
    if d.source.active then "#f88" else "#aaa")

  _.each network.links, (link) =>
    target = link.target
    if target.cycle? and !target.allTheTime
      source = link.source
      weight = link.weight * source.output
      link.target.input_agg += Math.max(0, (weight * (1.0/(target.cycle/200.0))))
      link.target.input_agg = Math.min(1, link.target.input_agg)
      target.active = true if target.input_agg >= 1.0

  console.log("= #{network.nodes.map((n)->"#{n.name}: #{debugFmt(n.input_agg)} ")}")

, 200)

v = 0
clock = (n = null) ->
  ->
    v += 1
    v = v % 2
    v

contextGraph = document.muramator.contextGraph
graphTick = contextGraph(clock())
# graphTick()
window.network = network

setTimeout(->
  clearInterval(simulationStep)
,20000)

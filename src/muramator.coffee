# see also, http://jsfiddle.net/karlin/dQvQg/1/

connect = (source, target, params) ->
  dendrite =
    source: source
    target: target
  for param of params
    dendrite[param] = params[param]
  dendrite

simpleNetwork = ->
  osc =     {name: 'osc',     x: 200, y: 200, cycle: 3000}
  emit_ex = {name: 'emit_ex', x: 50,  y: 50,  allTheTime: true}
  neurons = [ emit_ex, osc ]

  dendrites = [
    connect emit_ex, osc,
      weight: 2
    connect osc, osc,
      weight: -4
  ]

  nodes: neurons
  links: dendrites

muramatorNetwork = (kf, kt, neurons) ->
  named = (name) ->
    neurons.find (n) ->
      n.name == name

  dendrites = [
      source: named 'emitter'
      target: named 'detect_obs'
      weight: 0
    ,
      label: 'avoid'
      source: named 'detect_obs'
      target: named 'sk_supp_av'
      weight: 2
    ,
      source: named 'sk_supp_av'
      target: named 'turn'
      weight: 2
    ,
      source: named 'detect_obs'
      target: named 'seek'
      weight: -100
    ,
      source: named 'seek_ex'
      target: named 'seek'
      size: 100
      weight: kf
    ,
      source: named 'seek'
      target: named 'seek'
      weight: -kt
    ,
      source: named 'seek'
      target: named 'sk_supp_av'
      weight: 2
    ,
      source: named 'sk_supp_av'
      target: named 'av_supp_ex'
      weight: -2
    ,
      source: named 'explore_ex'
      target: named 'av_supp_ex'
      weight: 2
      size: 100
    ,
      source: named 'av_supp_ex'
      target: named 'forward'
      weight: 2
    ,
      source: named 'emit_ex'
      target: named 'emitter'
      size: 100
      weight: 2
    ,
      source: named 'emitter'
      target: named 'emitter'
      weight: -2
  ]

  nodes: neurons
  links: dendrites

debugFmt = d3.format "0.2f"

reportNodes = (nodes, fmt) ->
  eachNode = nodes.map (n) ->
    "#{n.name}:\t#{if n.name.length < 7 then "\t" else ""} #{debugFmt(n.inputAgg)}\t#{debugFmt(n.output)}\t#{n.cycle ? '-'}"

  report = eachNode.reduce (s, n) -> "#{s}\n#{n}"
  console.log "===\nNAME\t\tINPUT\tOUTPUT\tCYCLE?\n"
  console.log report

# SIMULATION

simulator = (neuronGraph) -> (state) ->
  updateNode = neuronGraph state.network

  inputScale = d3.scale.linear().clamp true
  drain = -1

  # Setup state and activation functions
  state.neurons.forEach (n) ->
    n.active = false # always initially off
    n.inputAgg ?= 0.0
    n.cycleTimer ?= 0 if n.cycle?
    n.visited = 0
    if n.allTheTime
      n.fn = =>
        n.active = true
        n.inputAgg = 1.0
        n.output = 1.0
    else
      n.fn = =>
        n.inputAggV = 0.0

        activating = Math.abs(1.0 - n.inputAgg) < state.epsilon
        deactivating = Math.abs(0.0 - n.inputAgg) < state.epsilon

        if activating
          if n.cycle?
            # cycle is "how long it takes for the neuron to fully charge
            #   with an input sum of 1."
            n.cycleTimer += state.frameMillis
            if n.cycleTimer >= n.cycle
              n.active = true
              n.cycleTimer = 0
          else
            # otherwise activate now
            n.active = true

        if deactivating
          n.active = false

        n.output = if n.active then 1 else 0

  dt = state.frameMillis / 1000.0

  simulationStep = setInterval ->
    if not state.running then return

    n.fn() for n in state.network.nodes

    # Highlight active neurons
    updateNode.selectAll('circle').attr 'class', (d) ->
      if d.active then "active" else "inactive"

    # Highlight active dendrites

    updateNode.selectAll('.link')
      .classed('active', (d) ->
        d.source.active
      ).classed('inactive', (d) ->
        !d.source.active
      )

    # Display dendrite labels.
    updateNode.selectAll('text.weight-label').text (t) ->
      label = t.label ? ""
      "#{t.weight} #{label}"

    for link in state.network.links when !link.target.allTheTime
      source = link.source
      target = link.target

      if target.visited <= state.network.nodes.length - 1

        if target.cycle?
          target.visited += 1

        weight = link.weight * source.output
        target.inputAggV += weight


    for node in state.network.nodes when !node.allTheTime
      node.visited = 0
      node.inputAggV += drain
      node.inputAggV *= dt
      node.inputAgg = inputScale(node.inputAgg + node.inputAggV)

    reportNodes state.network.nodes, debugFmt if state.reportOn

  , state.frameMillis

  # for manual tweaking from console:
  window.network = state.network

  if state.endSimulationTime?
    setTimeout ->
      clearInterval simulationStep
    , state.endSimulationTime

showMuramatorNetwork = (present, state) ->
  fetch('neurons.json').then((response) -> response.json()).then (data) ->
    state.kf = 20
    state.kt = 10
    state.neurons = data.neurons
    state.network = muramatorNetwork state.kt, state.kf, data.neurons
    present state

showSimpleNetwork = (present, state) ->
  network = simpleNetwork()
  state.network = network
  state.neurons = network.nodes
  present state

# GUI

reportSelectionAction = (doc, state) ->
  ->
    if @checked
      state.reportOn = true
    else
      state.reportOn = false

setReportControl = (doc, state) ->
  doc.querySelectorAll('input[name=report]').forEach (input) ->
    input.onchange = reportSelectionAction doc, state

simControlAction = (doc, state) ->
  ->
    if @checked
      state.running = true
    else
      state.running = false

setSimulationControl = (doc, state) ->
  doc.querySelectorAll('input[name=simulate]').forEach (input) ->
    input.onchange = simControlAction doc, state

obstacleAction = (doc, state) ->
  ->
    for link in state.network.links when link.source.name == 'emitter' and link.target.name == 'detect_obs'
      obstacle = @checked
      link.weight = if obstacle then 8 else 0
      presenter = simulator document.muramator.neuronGraph

setObstacleControl = (doc, state) ->
  doc.querySelectorAll('input[name=obstacle]').forEach (input) ->
    input.onchange = obstacleAction doc, state

# MAIN

state =
  frameMillis: 100.0
  # endSimulationTime: 10000
  running: true
  reportOn: false
  epsilon: 0.0001

presenter = simulator document.muramator.neuronGraph
showMuramatorNetwork presenter, state
setReportControl document, state
setSimulationControl document, state
setObstacleControl document, state
# showSimpleNetwork presenter, state

# see also, http://jsfiddle.net/karlin/dQvQg/1/

muramatorNetwork = (kf, kt, neurons) ->
  named = (name) ->
    neurons.find (n) ->
      n.name == name

  dendrites = [
      source: named('emitter')
      target: named('detect_obs')
      weight: 8
    ,
      label: 'avoid'
      source: named('detect_obs')
      target: named('sk_supp_av')
      weight: 2
    ,
      source: named('sk_supp_av')
      target: named('turn')
      weight: 2
    ,
      source: named('detect_obs')
      target: named('seek')
      weight: -100
    ,
      source: named('seek_ex')
      target: named('seek')
      size: 100
      weight: kf
    ,
      source: named('seek')
      target: named('seek')
      weight: -kt
    ,
      source: named('seek')
      target: named('sk_supp_av')
      weight: 2
    ,
      source: named('sk_supp_av')
      target: named('av_supp_ex')
      weight: -2
    ,
      source: named('explore_ex')
      target: named('av_supp_ex')
      weight: 2
      size: 100
    ,
      source: named('av_supp_ex')
      target: named('forward')
      weight: 2
    ,
      source: named('emit_ex')
      target: named('emitter')
      size: 100
      weight: 2
    ,
      source: named('emitter')
      target: named('emitter')
      weight: -2
  ]

  nodes: neurons
  links: dendrites

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
    connect( emit_ex, osc, { weight: 2 }),
    connect( osc, osc, { weight: -4 })
  ]

  nodes: neurons
  links: dendrites

debugFmt = d3.format("0.2f")

reportNodes = (nodes, fmt) ->
  eachNode = nodes.map (n) ->
    "#{n.name}:\t#{if n.name.length < 7 then "\t" else ""} #{debugFmt(n.input_agg)}\t#{debugFmt(n.output)}\t#{n.cycle ? '-'}"

  report = eachNode.reduce (s, n) -> "#{s}\n#{n}"
  console.log "===\nNAME\t\tINPUT\tOUTPUT\tCYCLE?\n"
  console.log report

# SIMULATION

simulator = (neuronGraph) -> (state) ->
  updateNode = neuronGraph state.network

  input_scale = d3.scale.linear().clamp true
  drain = -1

  # Setup state and activation functions
  state.neurons.forEach (n) ->
    n.active = false # always initially off
    n.input_agg ?= 0.0
    n.cycle_timer ?= 0 if n.cycle?
    n.visited = 0
    if n.allTheTime
      n.fn = =>
        n.active = true
        n.input_agg = 1.0
        n.output = 1.0
    else
      n.fn = =>
        n.input_agg_v = 0.0

        activating = Math.abs(1.0 - n.input_agg) < state.epsilon
        deactivating = Math.abs(0.0 - n.input_agg) < state.epsilon

        if activating
          if n.cycle?
            # cycle is "how long it takes for the neuron to fully charge
            #   with an input sum of 1."
            n.cycle_timer += state.frameMillis
            if n.cycle_timer >= n.cycle
              n.active = true
              n.cycle_timer = 0
          else
            # otherwise activate now
            n.active = true

        if deactivating
          n.active = false

        n.output = if n.active then 1 else 0

  simulationStep = setInterval ->
    n.fn() for n in state.network.nodes

    updateNode.selectAll('circle').attr('class', (d) ->
      if d.active then "active" else "inactive")
    updateNode.selectAll('.link').attr('stroke', (d) ->
      if d.source.active then "#f88" else "#aaa")
    updateNode.selectAll('text.weight-label').text (t) ->
      "#{t.weight} #{t.label ? ""}"

    dt = state.frameMillis / 1000.0

    for link in state.network.links when !link.target.allTheTime
      source = link.source
      target = link.target

      if target.visited < state.network.nodes.length - 1

        if target.cycle?
          target.visited += 1

        weight = link.weight * source.output
        target.input_agg_v += weight


    for node in state.network.nodes when !node.allTheTime
      node.visited = 0
      node.input_agg_v += drain
      node.input_agg_v *= dt
      node.input_agg = input_scale(node.input_agg + node.input_agg_v)

    reportNodes(state.network.nodes, debugFmt) if state.reportOn

  , state.frameMillis

  # for manual tweaking from console:
  window.network = state.network

  if state.endSimulationTime?
    setTimeout(->
      clearInterval(simulationStep)
    , state.endSimulationTime)

chooseMuramatorNetwork = (present, state) ->
  fetch('neurons.json').then((response) -> response.json()).then (data) ->
    state.kf = 20
    state.kt = 10
    state.neurons = data.neurons
    state.network = muramatorNetwork state.kt, state.kf, data.neurons
    present(state)

chooseSimpleNetwork = (present, state) ->
  network = simpleNetwork()
  state.network = network
  state.neurons = network.nodes
  present(state)

# GUI

networkSelectionAction = (doc, presenter, state) ->
  ->
    doc.getElementsByTagName("svg").item(0)?.remove()
    if doc.querySelector('input[name=network-choice]:checked').value == "osc"
      chooseSimpleNetwork(presenter, state)
    else
      chooseMuramatorNetwork(presenter, state)

reportSelectionAction = (state) ->
  ->
    if doc.querySelector('input[name=report]').checked
      state.reportOn = true
    else
      state.reportOn = false

simControlAction = (state) ->
  ->
    if doc.querySelector('input[name=simulate]').checked
      state.running = true
    else
      state.running = false

selectDefaultNetwork = (doc) ->
  input = doc.querySelectorAll('input[name=network-choice]').item(1)
  input.checked = true

setNetworkOptions = (doc, presenter, state) ->
  doc.querySelectorAll('input[name=network-choice]').forEach (input) ->
    input.onchange = networkSelectionAction(presenter, state)

setReportControl = (doc, presenter, state) ->
  doc.querySelectorAll('input[name=report]').forEach (input) ->
    input.onchange = reportSelectionAction(presenter, state)

# MAIN

state =
  frameMillis: 100.0
  endSimulationTime: 10000
  running: true
  reportOn: false
  epsilon: 0.0001

presenter = simulator document.muramator.neuronGraph
setNetworkOptions document, presenter, state
setReportControl document, presenter, state
selectDefaultNetwork document
networkSelectionAction(document, presenter, state)()
# simControlAction document

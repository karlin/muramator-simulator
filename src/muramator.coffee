# see also, http://jsfiddle.net/karlin/dQvQg/1/

muramatorNetwork = (kf, kt, neurons) ->
  named = (name) ->
    neurons.find (n) ->
      n.name == name

  dendrites = [
      source: named('detector')
      target: named('detect_obs')
      weight: 8
    ,
      label: named('avoid')
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
      size: 70
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
      size: 70
    ,
      source: named('av_supp_ex')
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

inputsFor = (network, node) ->
  link for link in network.links when link.target == node

view = (state) ->
  neuronGraph = document.muramator.neuronGraph
  updateNode = neuronGraph(state.network)

  inputsOf = _.partial inputsFor, state.network

  # Set up state and activation functions
  state.neurons.forEach (n) ->
    n.active = false # always initially off
    n.input_agg = 0.0
    n.visited = 0
    if n.allTheTime
      n.fn = =>
        n.active = true
        n.output = 1
    else
      n.fn = =>
        n.active = true if n.input_agg >= 1.0
        n.active = false if n.input_agg == 0.0
        n.output = if n.active then 1 else 0
        n.input_agg = Math.max(0, n.input_agg - 0.01)

  debugFmt = d3.format("0.2f")

  reportNodes = (network, fmt) ->
    eachNode = state.network.nodes.map (n) ->
      "#{n.name}:\t#{if n.name.length < 7 then "\t" else ""} #{debugFmt(n.input_agg)}\t#{debugFmt(n.output)}\t#{n.active}"

    report = eachNode.reduce (s, n) -> "#{s}\n#{n}"
    console.log "===\nNAME\t\tINPUT\tOUTPUT\tACTIVE\n"
    console.log report

  simulationStep = setInterval((ticks) ->
    n.fn() for n in state.network.nodes

    updateNode.selectAll('circle').attr('class', (d) ->
      if d.active then "active" else "inactive")
    updateNode.selectAll('.link').attr('stroke', (d) ->
      if d.source.active then "#f88" else "#aaa")

    # not very efficient!
    _.each state.network.links, (link) =>
      source = link.source
      target = link.target
      if (target == source or target.visited < state.network.nodes.length - 1) and !target.allTheTime
        target.visited += 1
        if target.cycle?
          rate = state.frameMillis / target.cycle
        else
          rate = 1.0
        # console.log("calculating inputs and activity for #{target.name}: #{debugFmt(rate)}")
        # console.log(rate)
        weight = link.weight * source.output
        link.target.input_agg = Math.min(1, Math.max(0, link.target.input_agg + (weight * rate)))

    # reportNodes(state.network, debugFmt)

    _.each state.network.nodes, (node) ->
      node.visited = 0
  , state.frameMillis)

  # window.network = state.network

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

networkSelectionAction = (present, state) ->
  ->
    document.getElementsByTagName("svg").item(0)?.remove()
    if document.querySelector('input[name=network-choice]:checked').value == "osc"
      chooseSimpleNetwork(present, state)
    else
      chooseMuramatorNetwork(present, state)

selectDefaultNetwork = ->
  document.forms[0].children[1].checked = true

state =
  frameMillis: 200.0
  endSimulationTime: 40000
  running: true

setNetworkOptions = (doc, view, state) ->
  doc.querySelectorAll('input[name=network-choice]').forEach((input) =>
    input.onchange = networkSelectionAction(view, state)
  )

setNetworkOptions(document, view, state)
selectDefaultNetwork()
networkSelectionAction(view, state)()
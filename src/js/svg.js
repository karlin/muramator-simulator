document.muramator.neuronGraph = function(network) {
  const { nodes } = network;
  const { links } = network;

  const w = 600;
  const h = 500;
  const r = 30;
  const markerPath = "M 4.73,-6.26 5.08,-1.43 7.05,3.47 0,0z";

  const nodeSize = function(n) {
    if (n.allTheTime) {
      return r * 0.5;
    } else {
      return r;
    }
  };

  const nodeLabel = function(n) {
    if (n.allTheTime) {
      return `${n.name}*`;
    } else {
      return n.name;
    }
  };

  const linkClass = l =>
    // state = switch
    //   when l.weight < 0 then "inh"
    //   when l.weight > 0 then "exc"
    //   else ""
    // "link #{state}"
    `link ${l.weight < 0 ? "inh" : "exc"}`;

  const linkMarker = l => `url(#${l.weight < 0 ? "inh" : "exc"})`;

  const svg = d3
    .select("body")
    .append("svg")
    .attr("width", w)
    .attr("height", h);

  const makeMarker = node =>
    node
      .attr("viewBox", "-2 -10 16 16")
      .attr("refX", r * 0.52)
      .attr("refY", -3)
      .attr("markerWidth", 16)
      .attr("markerHeight", 16)
      .attr("orient", "auto")
      .append("path")
      .attr("d", markerPath);

  svg
    .append("defs")
    .append("marker")
    .attr("id", "inh")
    .call(makeMarker);

  svg
    .select("defs")
    .append("marker")
    .attr("id", "exc")
    .call(makeMarker);
  const acyclicLinks = links.filter(l => l.source !== l.target);
  const cyclicLinks = links.filter(l => l.source === l.target);

  const force = d3.layout
    .force()
    .nodes(nodes)
    .links(acyclicLinks)
    .size([w, h])
    .linkDistance(function(d) {
      if (d.size != null) {
        return d.size;
      } else {
        return r * 5;
      }
    })
    .charge(-r * 14)
    .start();

  const linkLabels = svg
    .selectAll("text.weight-label")
    .data(acyclicLinks)
    .enter()
    .append("text")
    .attr("class", "weight-label");

  const selfLinkLabels = svg
    .selectAll("text.cyclic-weight-label")
    .data(cyclicLinks) // self-links
    .enter()
    .append("text")
    .attr("class", "cyclic-weight-label");

  const linksGroup = svg
    .append("g")
    .attr("class", "links")
    .selectAll("path")
    .data(acyclicLinks)
    .enter()
    .append("path")
    .attr("class", linkClass)
    .attr("marker-end", linkMarker);

  const selfLinksGroup = svg
    .append("g")
    .attr("class", "self-links")
    .selectAll("path")
    .data(cyclicLinks) // self-links
    .enter()
    .append("path")
    .attr("class", linkClass)
    .attr("marker-end", linkMarker);

  const nodeGroups = svg
    .selectAll(".node")
    .data(nodes)
    .enter()
    .append("g")
    .attr("class", "node")
    .attr("cx", d => d.x)
    .attr("cy", d => d.y)
    .call(force.drag);

  const nodeShape = nodeGroups.append("circle").attr("r", nodeSize);
  nodeShape.append("title").text(n => n.name);

  nodeShape.on("contextmenu", function(neuron) {
    d3.event.preventDefault();
    __guard__(document.querySelector("#graph"), x => x.remove());
    document.muramator.contextGraph(neuron.name, () => neuron.inputAgg)();

    const graphFrame = d3.select("#graph");
    const coords = d3.mouse(graphFrame[0].parentNode);
    graphFrame.attr("transform", `translate(${coords[0]},${coords[1]})`);

    return false;
  });

  nodeGroups
    .append("text")
    .attr("dy", ".2em")
    .attr("text-anchor", "middle")
    .attr("class", "node-label shadow")
    .text(nodeLabel);

  nodeGroups
    .append("text")
    .attr("dy", ".2em")
    .attr("text-anchor", "middle")
    .attr("class", "node-label")
    .text(nodeLabel)
    .append("tspan")
    .text(n => (n.cycle != null ? `${n.cycle}ms` : ""))
    .attr("text-anchor", "middle")
    .attr("dy", "1.1em")
    .attr("x", "0px")
    .attr("class", "cycle-label");

  linkLabels
    .attr("x", d => (d.source.x + d.target.x) / 2)
    .attr("y", d => (d.source.y + d.target.y) / 2)
    .attr("text-anchor", "middle")
    .text(t => `${t.weight} ${t.label != null ? t.label : ""}`);

  selfLinkLabels
    .attr("x", 200)
    .attr("y", d => d.target.y - 20)
    .attr("text-anchor", "middle")
    .text(t => `${t.weight} ${t.label != null ? t.label : ""}`);

  force.on("tick", function() {
    linksGroup.attr("d", function(d) {
      const dx = d.target.x - d.source.x;
      const dy = d.target.y - d.source.y;
      const dr = Math.sqrt(dx * dx + dy * dy);
      return `M${
        d.source.x
      },${d.source.y}A${dr},${dr} 0 0,1 ${d.target.x},${d.target.y}`;
    });

    selfLinksGroup.attr(
      "d",
      d => `M${d.source.x},${d.source.y}c 100,-100,100,120 0,0`
    );

    linkLabels
      .attr("x", d => (d.source.x + d.target.x) / 2)
      .attr("y", d => (d.source.y + d.target.y) / 2);

    selfLinkLabels.attr("x", d => d.target.x + 55).attr("y", d => d.target.y);

    nodeGroups.attr("transform", d => `translate(${d.x},${d.y})`);

    return setTimeout(() => force.stop(), 1400);
  });
  return svg;
};

function __guard__(value, transform) {
  return typeof value !== "undefined" && value !== null
    ? transform(value)
    : undefined;
}

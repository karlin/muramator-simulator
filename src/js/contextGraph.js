export function contextGraph(name, valueFunc) {
  const n = 40;
  const data = d3.range(n).map(x => valueFunc());
  const margin = {
    top: 5,
    right: 5,
    bottom: 8,
    left: 5
  };

  const width = 160 - margin.left - margin.right;
  const height = 50 - margin.top - margin.bottom;
  const x = d3.scale
    .linear()
    .domain([1, n - 2])
    .range([0, width]);
  const y = d3.scale
    .linear()
    .domain([0, 2])
    .range([height, 3]);
  const labelFmt = d3.format(".2f");
  const line = d3.svg
    .line()
    .interpolate("step-before")
    .x((d, i) => x(i))
    .y((d, i) => y(d));
  const graphRoot = d3
    .select("svg")
    .append("g")
    .attr("id", "graph")
    .attr("transform", `translate(${margin.left},${margin.top})`);

  graphRoot
    .select("defs")
    .append("clipPath")
    .attr("id", "clip")
    .append("rect")
    .attr("width", width)
    .attr("height", height);
  const bgrect = graphRoot
    .append("rect")
    .attr("class", "graph-bg")
    .attr("x", -20)
    .attr("width", width * 1.3)
    .attr("height", height)
    .attr("rx", 5)
    .attr("ry", 5);

  const graph = graphRoot
    .append("g")
    .attr("clip-path", "url(#clip)")
    .append("path")
    .data([data])
    .attr("class", "graph")
    .attr("d", line);

  const label = graphRoot
    .append("text")
    .attr("class", "func-label")
    .attr("transform", "translate(0,10)");

  var tick = function() {
    const value = valueFunc();
    data.push(value);
    graph
      .attr("d", line)
      .attr("transform", `translate(${x(0)})`)
      .transition()
      .ease("linear")
      .delay(50)
      .duration(100)
      .each("end", tick);
    label.text(`${name}: ${labelFmt(value)}`);
    return data.shift();
  };

  return tick;
}

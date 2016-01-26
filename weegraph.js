var n = 40,
    random = d3.random.normal(1,0.5),
    data = d3.range(n).map(function(x) {return 0;});

var margin = {top: 5, right: 5, bottom: 5, left: 5},
    width = 160 - margin.left - margin.right,
    height = 50 - margin.top - margin.bottom;

var x = d3.scale.linear()
    .domain([1, n - 2])
    .range([0, width]);

var y = d3.scale.linear()
    .domain([0, 2])
    .range([height, 3]);

var line = d3.svg.line()
    .interpolate("step-before")
    .x(function(d, i) { return x(i); })
    .y(function(d, i) { return y(d); });

var svg = d3.select("body").append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom)
  .append("g")
    .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

svg.append("defs").append("clipPath")
    .attr("id", "clip")
  .append("rect")
    .attr("width", width)
    .attr("height", height);

var path = svg.append("g")
    .attr("clip-path", "url(#clip)")
  .append("path")
    .data([data])
    .attr("class", "line")
    .attr("d", line);
r=0;
tick();

function tick() {
r+=1;
  // push a new data point onto the back
  data.push(r%2);

  // redraw the line, and slide it to the left
  path
      .attr("d", line)
      .attr("transform", null)
    .transition()
      .duration(500)
      .ease("linear")
      .attr("transform", "translate(" + x(0) + ")")
      .each("end", tick);

  // pop the old data point off the front
  data.shift();

}
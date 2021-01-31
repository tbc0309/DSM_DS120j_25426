function DrawStackBarChart()
{
	if (typeof synoRealTimeBarChartNoData !== 'undefined') {
		return;
	}

SYNO.REPORT.COLOR_CRITICAL = "#dd4040";
SYNO.REPORT.COLOR_HIGH = "#f47f17";
SYNO.REPORT.COLOR_MEDIAN = "#f1c207";
SYNO.REPORT.COLOR_NORMAL = "#31629b";

	var keys = ["Medium", "High", "Critical"];
	var colors = [SYNO.REPORT.COLOR_MEDIAN, SYNO.REPORT.COLOR_HIGH, SYNO.REPORT.COLOR_CRITICAL];
	var maxY = synoRealTimeBarChartMaxY;

	// data from tool end

var margin = {top: 7, right: 14, bottom: 22, left: 44};

var width = 1224 - margin.left - margin.right,
	height = 250 - margin.top - margin.bottom;

var chart1 = d3
	.select("#realtime-stack-bar-chart")
	.append("svg")
	.attr("width", width + margin.left + margin.right)
	.attr("height", height + margin.top + margin.bottom)
	.append("g")
	.attr("transform", "translate(" + margin.left + "," + margin.top + ")");

var filter = chart1
		.append("defs")
		.append("filter")
		.attr("id", "drop-shadow")
		.attr("width", "150%");

filter.append("feGaussianBlur")
	  .attr("in", "SourceAlpha")
	  .attr("stdDeviation", 1)
	  .attr("result", "blur");

filter.append("feOffset")
	  .attr("in", "blur")
	  .attr("dx", 0)
	  .attr("dy", 0)
	  .attr("result", "offsetBlur");

var feMerge = filter.append("feMerge");

feMerge.append("feMergeNode")
	   .attr("in", "offsetBlur");

feMerge.append("feMergeNode")
	   .attr("in", "SourceGraphic");

var x = d3
	.scaleBand()
	.rangeRound([0, width])
	.paddingInner(0.25)
	.align(0.1);

var y = d3
	.scaleLinear()
	.rangeRound([height, 0]);

var z = d3
  .scaleOrdinal()
  .range(colors);

  x.domain(synoRealTimeBarChartData.map(function(d) { return d.date; }));
  y.domain([0, maxY]);
  z.domain(keys);

function make_y_gridlines() {
	return d3.axisLeft(y).ticks(synoRealTimeBarChartYTicks)
}

  chart1
  .append("g")
  .attr("class", "grid")
  .call(make_y_gridlines()
  .tickSize(-width)
  .tickFormat(""));

  chart1
  .append("g")
  .selectAll("g")
  .data(d3.stack().keys(keys)(synoRealTimeBarChartData))
  .enter()
  .append("g")
  .attr("fill", function(d) { return z(d.key); })
  .selectAll("rect")
  .data(function(d) { return d; })
  .enter().append("rect")
  .attr("x", function(d) { return x(d.data.date); })
  .attr("y", function(d) { return y(d[1]); })
  .attr("height", function(d) { return y(d[0]) - y(d[1]); })
  .attr("width", x.bandwidth())
  .on("mouseover", function() { 
	  tooltip.style("display", null); 
	  d3.select(this).transition()
	  .duration(300)
	  .attr('stroke-width', '1px')
	  .attr('stroke', '#ffffff')
	  .style('filter', 'url(#drop-shadow)');
  })
  .on("mouseout", function() { 
	  tooltip.style("display", "none"); 
	  d3.select(this).transition()
	  .duration(300)
	  .style('filter', '')
	  .attr('stroke-width', '0px');
  })
  .on("mousemove", function(d) {
	  var xPosition = d3.mouse(this)[0] - 15;
	  var yPosition = d3.mouse(this)[1] - 25;
	  tooltip.attr("transform", "translate(" + xPosition + "," + yPosition + ")");
	  tooltip.select("text").text(d[1] - d[0]);
  });

  chart1
  .append("g")
  .attr("class", "axis")
  .attr("transform", "translate(0," + height + ")")
  .call(d3.axisBottom(x))
  .attr("font-size", "12px")
  .attr("font-family", "verdana");

  chart1
  .append("g")
  .attr("class", "axis")
  .call(d3.axisLeft(y).ticks(synoRealTimeBarChartYTicks))
  .attr("font-size", "12px")
  .attr("font-family", "verdana");

  // remove original left / right / bottom lines
  chart1.append('line').attr('x1',0).attr('y1', height).attr('x2', width-1).attr('y2', height)
  .attr('style','stroke:#FFF; stroke-width:3; shape-rendering: crispEdges;');

  chart1.append('line').attr('x1',0).attr('y1', 0).attr('x2', 0).attr('y2', height + margin.top)
  .attr('style','stroke:#FFF; stroke-width:3; shape-rendering: crispEdges;');

  chart1.append('line').attr('x1',width).attr('y1', 0).attr('x2', width).attr('y2', height + margin.top)
  .attr('style','stroke:#FFF; stroke-width:3; shape-rendering: crispEdges;');

  // add rectangle grid
  chart1.append('rect').attr('x',0).attr('y', -margin.top).attr('width', width + 1).attr('height', height + margin.top)
  .attr('style', 'stroke: #CED4DA; fill: none; stroke-width:1px; shape-rendering: crispEdges;');

  // add bottom blue line
  chart1.append('line').attr('x1',0).attr('y1', height + 1).attr('x2', width + 1).attr('y2', height + 1)
  .attr('style','stroke:#2A588C; stroke-width:5; shape-rendering: crispEdges;');

  var tooltip = chart1
  .append("g")
  .attr("class", "tooltip")
  .style("display", "none");

  tooltip
  .append("rect")
  .attr("width", 30)
  .attr("height", 20)
  .attr("fill", "rgba(0,0,0,0.8)")
  .style("stroke", "#ffffff")
  .style("stroke-width", "1px");

  tooltip
  .append("text")
  .attr("x", 15)
  .attr("dy", "1.2em")
  .attr("fill", "#FFF")
  .style("text-anchor", "middle")
  .attr("font-size", "12px")
  .attr("font-weight", "bold");
}

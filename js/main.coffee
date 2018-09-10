  
# set up SVG for D3
width = 800
height = 480
colors = d3.scale.category10()
# define arrow markers for graph links
svg = d3.select('#graf974').append('svg').attr('oncontextmenu', 'return false;').attr('width', width).attr('height', height)
# line displayed when dragging new nodes
drag_line = svg.append('svg:path').attr('class', 'link dragline hidden').attr('d', 'M0,0L0,0')


# set up initial nodes and links
#  - nodes are known by 'id', not by index in array.
#  - reflexive edges are indicated on the node (as a bold black circle).
#  - links are always source < target; edge directions are set by 'left' and 'right'.
nodes = [
  {
    id: 0
  }
  {
    id: 1
  }
  {
    id: 2
  }
]
lastNodeId = 2
links = [
  {
    source: nodes[0]
    target: nodes[1]
    left: false
    right: false
  }
  {
    source: nodes[0]
    target: nodes[2]
    left: false
    right: false
  }
]

nom = ["ici","graphes orientés","graphes non orientés"]
lien = ["index.html","digraphs.html","graphs.html"]


# handles to link and node element groups
pathsGroup = svg.append('svg:g')
path = pathsGroup.selectAll('path')
circlesGroup = svg.append('svg:g')
circle = circlesGroup.selectAll('g')

# update force layout (called automatically each iteration)
tick = ->
  # draw directed edges with proper padding from node centers
  path.attr 'd', (d) ->
    deltaX = d.target.x - (d.source.x)
    deltaY = d.target.y - (d.source.y)
    dist = Math.sqrt(deltaX * deltaX + deltaY * deltaY)
    normX = deltaX / dist
    normY = deltaY / dist
    sourcePadding = if d.left then 17 else 12
    targetPadding = if d.right then 17 else 12
    sourceX = d.source.x + sourcePadding * normX
    sourceY = d.source.y + sourcePadding * normY
    targetX = d.target.x - (targetPadding * normX)
    targetY = d.target.y - (targetPadding * normY)
    return 'M' + sourceX + ',' + sourceY + 'L' + targetX + ',' + targetY

  circle.attr 'transform', (d) -> return "translate(#{d.x}, #{d.y})"

# init D3 force layout
force = d3.layout.force().nodes(nodes).links(links).size([width, height]).linkDistance(250).charge(-500).on('tick', tick)

# mouse event vars
selected_node = null
selected_link = null
mousedown_link = null
mousedown_node = null
mouseup_node = null
# only respond once per keydown
lastKeyDown = -1
resetMouseVars = ->
  mousedown_node = null
  mouseup_node = null
  mousedown_link = null
  return


# update graph (called when needed)
restart = ->
  # path (link) group
  path = path.data(links)
  # update existing links
  path
    .classed 'selected', (d) -> d == selected_link
    .style   'marker-start', (d) -> if d.left  then 'url(#start-arrow)' else ''
    .style   'marker-end'  , (d) -> if d.right then 'url(#end-arrow)'   else ''
  # add new links
  path.enter().append('svg:path')
    .attr('class', 'link')
    .classed 'selected', (d) -> d == selected_link
    .style 'marker-start', (d) -> if d.left then 'url(#start-arrow)' else ''
    .style 'marker-end', (d) -> if d.right then 'url(#end-arrow)' else ''
    .on 'mousedown', (d) -> 
      if d3.event.ctrlKey    
        # select link
        mousedown_link = d
        if mousedown_link == selected_link
          selected_link = null
        else
          selected_link = mousedown_link
        selected_node = null
        restart()
   
  # circle (node) group
  # NB: the function arg is crucial here! nodes are known by id, not by index!
  circle = circle.data(nodes, (d) -> d.id)
  # update existing nodes (reflexive & selected visual states)
  circle.selectAll('circle')
    .style('fill', (d) -> if d == selected_node then d3.rgb(colors(d.id)).brighter().toString() else colors(d.id))
    .classed 'reflexive', (d) -> d.reflexive
  # add new nodes
  g = circle.enter().append('svg:g')
  g.append('svg:circle')
    .attr('class', 'node')
    .attr('r', 80)
    .style('fill', (d) -> if d == selected_node then d3.rgb(colors(d.id)).brighter().toString() else colors(d.id))
    .style('stroke', (d) -> d3.rgb(colors(d.id)).darker().toString())
    .classed('reflexive', (d) -> d.reflexive)
    .on 'mouseover', (d) ->
      return if !mousedown_node or d == mousedown_node    
      # enlarge target node
      d3.select(this).attr 'transform', 'scale(1.1)'
      return

    .on 'mouseout', (d) ->
      return if !mousedown_node or d == mousedown_node     
      # unenlarge target node
      d3.select(this).attr 'transform', ''
      return

    .on 'mousedown', (d) ->
      return if d3.event.ctrlKey     
      # select node
      mousedown_node = d
      if mousedown_node == selected_node
        selected_node = null
      else
        selected_node = mousedown_node
      selected_link = null
      # reposition drag line
      drag_line
        .classed('hidden', false)
        .attr 'd', "M#{mousedown_node.x}, #{mousedown_node.y}L#{mousedown_node.x}, #{mousedown_node.y}"
      restart()
      return

   .on 'mouseup', (d) ->
      return if !mousedown_node      
      # needed by FF
      drag_line.classed('hidden', true).style 'marker-end', ''
      # check for drag-to-self
      mouseup_node = d
      if mouseup_node == mousedown_node
        resetMouseVars()
        window.open(lien[parseInt(d.id)])
        return
      # unenlarge target node
      d3.select(this).attr 'transform', ''
      restart()
      
  # show node IDs
  g.append('svg:text')
    .attr('x', 0)
    .attr('y', 4)
    .attr('class', 'id')
    .text (d) -> nom[parseInt(d.id)]
  # set the graph in motion
  force.start()
        
  return

mousedown = ->
  # prevent I-bar on drag
  #d3.event.preventDefault();
  # because :active only works in WebKit?
  svg.classed 'active', true
  if d3.event.ctrlKey or mousedown_node or mousedown_link
    return
  restart()
  return

mousemove = ->
  return if !mousedown_node
  # update drag line
  drag_line.attr 'd', "M#{mousedown_node.x}, #{mousedown_node.y}L#{d3.mouse(this)[0]}, #{d3.mouse(this)[1]}"
  restart()
  return

mouseup = ->
  if mousedown_node
    # hide drag line
    drag_line.classed('hidden', true).style 'marker-end', ''
  # because :active only works in WebKit?
  svg.classed 'active', false
  # clear mouse event vars
  resetMouseVars()
  return



keydown = ->
  d3.event.preventDefault()
  if lastKeyDown != -1
    return
  lastKeyDown = d3.event.keyCode
  # ctrl
  if d3.event.keyCode == 17
    circle.call force.drag
    svg.classed 'ctrl', true
  if !selected_node and !selected_link
    return
  return

keyup = ->
  lastKeyDown = -1
  # ctrl
  if d3.event.keyCode == 17
    circle
      .on 'mousedown.drag', null
      .on 'touchstart.drag', null
    svg.classed 'ctrl', false
  return


# app starts here
svg
  .on 'mousedown', mousedown
  .on 'mousemove', mousemove
  .on 'mouseup', mouseup
d3.select(window)
  .on 'keydown', keydown
  .on 'keyup', keyup
restart()


$ ->
  $( "#hints, #tube" ).hide()
  $( "#hintsToggler" ).on "click", ->
    $( "#hints" ).toggle()
  $( "#tubeToggler" ).on "click", ->
    $( "#tube" ).toggle()
    


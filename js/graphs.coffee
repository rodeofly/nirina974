  
# set up SVG for D3
width = 800
height = 480
colors = d3.scale.category10()
# define arrow markers for graph links
svg = d3.select('#graf').append('svg').attr('oncontextmenu', 'return false;').attr('width', width).attr('height', height)
# line displayed when dragging new nodes
drag_line = svg.append('svg:path').attr('class', 'link dragline hidden').attr('d', 'M0,0L0,0')

# set up initial nodes and links
#  - nodes are known by 'id', not by index in array.
#  - reflexive edges are indicated on the node (as a bold black circle).
#  - links are always source < target; edge directions are set by 'left' and 'right'.
nodes = [
  {
    id: 0
    reflexive: false
  }
  {
    id: 1
    reflexive: false
  }
  {
    id: 2
    reflexive: false
  }
  {
    id: 3
    reflexive: false
  }
  {
    id: 4
    reflexive: false
  }
  {
    id: 5
    reflexive: false
  }
]
lastNodeId = 5
couleur = []
couleur[i.toString()]=i for i in [0..10000]
links = [
  {
    source: nodes[0]
    target: nodes[1]
    left: false
    right: false
  }
  {
    source: nodes[0]
    target: nodes[4]
    left: false
    right: false
  }
  {
    source: nodes[0]
    target: nodes[5]
    left: false
    right: false
  }
  {
    source: nodes[1]
    target: nodes[2]
    left: false
    right: false
  }
  {
    source: nodes[2]
    target: nodes[3]
    left: false
    right: false
  }
  {
    source: nodes[4]
    target: nodes[3]
    left: false
    right: false
  }
  {
    source: nodes[4]
    target: nodes[5]
    left: false
    right: false
  }
  {
    source: nodes[5]
    target: nodes[1]
    left: false
    right: false
  }
  {
    source: nodes[5]
    target: nodes[2]
    left: false
    right: false
  }
  {
    source: nodes[5]
    target: nodes[3]
    left: false
    right: false
  }
]


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
    sourcePadding = 12
    targetPadding = 12
    sourceX = d.source.x + sourcePadding * normX
    sourceY = d.source.y + sourcePadding * normY
    targetX = d.target.x - (targetPadding * normX)
    targetY = d.target.y - (targetPadding * normY)
    return 'M' + sourceX + ',' + sourceY + 'L' + targetX + ',' + targetY

  circle.attr 'transform', (d) -> return "translate(#{d.x}, #{d.y})"

# init D3 force layout
force = d3.layout.force().nodes(nodes).links(links).size([width/2, height/2]).linkDistance(80).charge(-500).on('tick', tick)

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
  # add new links
  path.enter().append('svg:path')
    .attr('class', 'link')
    .classed 'selected', (d) -> d == selected_link
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
   
  # remove old links
  path.exit().remove()
  # circle (node) group
  # NB: the function arg is crucial here! nodes are known by id, not by index!
  circle = circle.data(nodes, (d) -> d.id)
  # update existing nodes (reflexive & selected visual states)
  circle.selectAll('circle')
    .classed 'selected', (d) -> d == selected_node
    .style('fill', (d) -> colors(couleur[d.id]))
    .classed 'reflexive', (d) -> d.reflexive
  # add new nodes
  g = circle.enter().append('svg:g')
  g.append('svg:circle')
    .attr('class', 'node')
    .attr('r', 12)
    .classed 'selected', (d) -> d == selected_node
    #.style('fill', (d) -> if d == selected_node then d3.rgb(colors(couleur[d.id])).brighter().toString() else colors(couleur[d.id]))
    .style('fill', (d) -> colors(couleur[d.id]))
    .style('stroke', (d) -> d3.rgb(colors(couleur[d.id])).darker().toString())
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
      drag_line.classed('hidden', true)
      # check for drag-to-self
      mouseup_node = d
      if mouseup_node == mousedown_node
        resetMouseVars()
        return
      # unenlarge target node
      d3.select(this).attr 'transform', ''
      # add link to graph (update if exists)
      # NB: links are strictly source < target; arrows separately specified by booleans
      source = undefined
      target = undefined
      direction = undefined
      if mousedown_node.id < mouseup_node.id
        source = mousedown_node
        target = mouseup_node
        direction = 'right'
      else
        source = mouseup_node
        target = mousedown_node
        direction = 'left'
      link = undefined
      link = links.filter((l) ->
        l.source == source and l.target == target
      )[0]
      unless link
        link =
          source: source
          target: target
          left: false
          right: false
        links.push link
      # select new link
      selected_link = link
      selected_node = null
      restart()
      
  # show node IDs
  g.append('svg:text')
    .attr('x', 0)
    .attr('y', 4)
    .attr('class', 'id')
    .text (d) -> d.id
  # remove old nodes
  circle.exit().remove()
  # set the graph in motion
  force.start()
  # calculs sur les degrés et les couleurs
  $("#sommets").empty().append "<th>sommets</th>"
  $("#entrants").empty().append "<th>degrés</th>"
  $("#conflits").empty()
  for sommet in nodes
    $("#sommets").append "<td>#{sommet.id}</td>"
    na = 0
    c1 = couleur[sommet.id]
    for arete in links
      if arete.source==sommet
        na += 1
        c2 = couleur[arete.target.id]
        if c1==c2
          $("#conflits").append "<li>Les sommets #{sommet.id} et #{arete.target.id} sont de la même couleur</li>"
      if arete.target==sommet
        na += 1
    $("#entrants").append "<td>#{na}</td>"
  enscoul = {}
  enscoul[couleur[i]] = couleur[i] for i in [0..lastNodeId]
  $("#chroma1").text "Le graphe est actuellement colorié en #{(v for k,v of enscoul).length} couleurs. Peut-on faire moins ?"
  return

mousedown = ->
  # prevent I-bar on drag
  #d3.event.preventDefault();
  # because :active only works in WebKit?
  svg.classed 'active', true
  if d3.event.ctrlKey or mousedown_node or mousedown_link
    return
  # insert new node at point
  point = d3.mouse(this)
  node = 
    id: ++lastNodeId
    reflexive: false
  couleur[node.id]=node.id
  node.x = point[0]
  node.y = point[1]
  nodes.push node
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

spliceLinksForNode = (node) ->
  toSplice = links.filter (l) ->
    l.source == node or l.target == node

  toSplice.map (l) ->
    links.splice links.indexOf(l), 1


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
  switch d3.event.keyCode
    # backspace
    when 8, 46
      # delete
      if selected_node
        nodes.splice nodes.indexOf(selected_node), 1
        spliceLinksForNode selected_node
      else if selected_link
        links.splice links.indexOf(selected_link), 1
      selected_link = null
      selected_node = null
      restart()
      # M pour moins (diminuer couleur)
    when 77, 109
      if selected_node
        index = selected_node.id
        couleur[index] -= 1
        if couleur[index]<0
          couleur[index] += 10
      restart()
      # P pour plus (augmenter couleur)
    when 80, 112
      if selected_node
        index = selected_node.id
        couleur[index] += 1
        if couleur[index]>9
          couleur[index] -= 10
      restart()
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


#Drag an Drop interface
DnDFileController = (selector, onDropCallback) ->
  el_ = document.querySelector(selector)

  @dragenter = (e) ->
    e.stopPropagation()
    e.preventDefault()
    el_.classList.add 'dropping'
    $( "#upload" ).addClass "slim"

  @dragover = (e) ->
    e.stopPropagation()
    e.preventDefault()

  @dragleave = (e) ->
    e.stopPropagation()
    e.preventDefault()
    el_.classList.remove 'dropping'
    $( "#upload" ).removeClass "slim"

  @drop = (e) ->
    e.stopPropagation()
    e.preventDefault()
    el_.classList.remove 'dropping'
    onDropCallback e.dataTransfer.files, e
    $( "#upload" ).removeClass( "slim" ).hide()

  el_.addEventListener 'dragenter'  , @dragenter, false
  el_.addEventListener 'dragover'   , @dragover , false
  el_.addEventListener 'dragleave'  , @dragleave, false
  el_.addEventListener 'drop'       , @drop     , false
##################################################################
#Drag and Drop file
# à  factoriser à l'occasion
dnd = new DnDFileController '#upload', (files) ->
  f = files[0]
  reader = new FileReader
  reader.onloadend = (e) -> 
    data = JSON.parse(@result)
    console.log data
    pathsGroup.remove()
    circlesGroup.remove()
    
    # handles to link and node element groups
    pathsGroup = svg.append('svg:g')
    path = pathsGroup.selectAll('path')
    circlesGroup = svg.append('svg:g')
    circle = circlesGroup.selectAll('g')
    lastNodeId = data.lastNodeId
    nodes = data.nodes
    links = []
    for l in data.links
      t = {}
      t.source = nodes[l.source.id]
      t.target = nodes[l.target.id]
      t.left = false
      t.right = false
      links.push t

    console.log links
    force = d3.layout.force().nodes(nodes).links(links).size([width/2, height/2]).linkDistance(80).charge(-200).on('tick', tick)
    restart()
    
  reader.readAsText f
  return
####################################################################

$( "#importJSON" ).on "click", -> $( "#upload" ).show()
$( "#upload .close" ).on "click", -> $( "#upload" ).hide()



save = (type) ->
  dataStr = "data:text/#{type};charset=utf-8,"
  stringValue = prompt( "Nom du fichier ?", stringValue )
  switch type
    when "json" 
      dataStr += encodeURIComponent(JSON.stringify({nodes: nodes, links: links, lastNodeId: lastNodeId}))
    when "svg"
      html = d3.select("#graf").select("svg")
        .attr("title", "svg_title")
        .attr("version", 1.1)
        .attr("xmlns", "http://www.w3.org/2000/svg")
        .node().parentNode.innerHTML 
      svgBlob = new Blob([html], {type:"image/svg+xml;charset=utf-8"})
      dataStr = URL.createObjectURL(svgBlob);
      
  dlAnchorElem = document.getElementById('save')
  dlAnchorElem.setAttribute("href",     dataStr     )
  dlAnchorElem.setAttribute("download", "#{stringValue}.#{type}")
  dlAnchorElem.click()

$ ->
#  console.log nodes,links
  $( "#genJSON" ).on "click", -> save("json")
  $( "#genSVG" ).on "click", -> save("svg")
  
  $( "#hints, #rules, #defs" ).hide()
  $( "#hintsToggler" ).on "click", ->
    $( "#hints" ).toggle()
  $( "#rulesToggler" ).on "click", ->
    $( "#rules" ).toggle()
  $( "#defsToggler" ).on "click", ->
    $( "#defs" ).toggle()
    


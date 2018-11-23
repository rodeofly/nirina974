$d3 = d3
$jq = $ # jquery

joueur = "A"
adversaire = { "A": "B", "B": "A" }
totaljetons = 6
totalactives = 1
# define arrow markers for graph links
svg = d3.select('#rhs').append('svg').attr('oncontextmenu', 'return false;').attr('width', width).attr('height', height)
svg.append('svg:defs').append('svg:marker')
  .attr('id', 'end-arrow')
  .attr('viewBox', '0 -10 20 20')
  .attr('refX', 48).attr('markerWidth', 6)
  .attr('markerHeight', 6)
  .attr('orient', 'auto').append('svg:path')
  .attr('d', 'M0,-10L0,10L20,0')
  .attr 'fill', '#000'
# line displayed when dragging new nodes
drag_line = svg.append('svg:path').attr('class', 'link dragline hidden').attr('d', 'M0,0L0,0')

width = 800 #$jq("#rhs").width()
height = 480 #$jq("#rhs").height()
color = d3.scale.category20()

json =
  nodes: [
    # places are group 0
    { id:0, name: '>', group: 0, count: 6 }
    { id:1, name: 'b', group: 0, count: 0 }
    { id:2, name: 'c', group: 0, count: 0 }
    { id:3, name: 'i', group: 0, count: 0 }
    { id:4, name: 'j', group: 0, count: 0 }
    { id:5, name: '^', group: 0, count: 0 }

    # transitions are group 1
    { id:6, name: 'x', group: 1 }
    { id:7, name: 'y', group: 1 }
    { id:8, name: 'z', group: 1 }
    { id:9, name: '!', group: 1 }
  ]
  edges: [
    { source: 0, target: 9 }
    { source: 9, target: 1 }
    { source: 1, target: 6 }
    { source: 6, target: 2 }
    { source: 6, target: 3 }
    { source: 2, target: 8 }
    { source: 3, target: 7 }
    { source: 7, target: 4 }
    { source: 4, target: 8 }
    { source: 8, target: 5 }
  ];


force = d3.layout.force()
  .charge( -250 )
  .linkDistance( 45 )
  .size([ width, height ])

# start this, because it destructively turns those references into live objects!
force
  .nodes( json.nodes )
  .links( json.edges )
  .start()

jetons = ['⠀','⠂','⠔','⠦','⠶','⠷','⠿','⣾','⣿']

AND = (a, b) -> a and b
all = (xs) -> xs.length and xs.reduce( AND, true )

incoming = (n) -> e for e in json.edges when e.target is n
outgoing = (n) -> e for e in json.edges when e.source is n
active = (n) -> all ( e.source.count > 0 for e in incoming n  )

holds = -> n for n in json.nodes when n.group is 0
tasks = -> n for n in json.nodes when n.group is 1

radius = 16

#svg = d3.select("svg")
links = svg.selectAll( "line.link" )
    .data( json.edges )
    .enter().append( "line" )
    .attr( "class", "link" )
    .style( "stroke", "#000" )
    .style( "stroke-width", 2 )
    .style('marker-end', 'url(#end-arrow)')


circs = svg.selectAll("circle.node")
    .data( holds )
    .enter().append( "circle" )
    .attr( "class", "node" )
    .attr( "r", radius )
    .style( "fill", (d)->
         if d.name is '>' then 'lime'
         else if d.name is '^' then 'red'
         else 'yellow' )
    .style( "stroke", '#000' )
    .style( "stroke-width", '2' )
    .call( force.drag )

dead_color = '#077'
live_color = '#a0a'
click_color = '#999'

box_color = (d, i) -> if active d then live_color else dead_color

texts = svg.selectAll("text")
  .data( holds )
  .enter().append( "text" )
  .call( force.drag )
  .text( (d)-> if d.count is 0 then '' else jetons[d.count] )

rects = svg.selectAll("rect.node")
  .data( tasks )
  .enter().append( "rect" )
    .attr( "class", "node" )
    .attr( "width", radius * 1.2 )
    .attr( "height", radius * 1.2 )
    .style( "stroke", '#000' )
    .style( "stroke-width", '2' )
    .style( "fill", box_color )
    .call( force.drag )
    .on 'click', (g, j)->
         if (active g) then do =>
            for e in incoming g
              e.source.count -= 1
            for e in outgoing g
              e.target.count += 1
            $d3.select( this )
               .style( 'fill', click_color )
            rects.transition()
               .style( 'fill', box_color )
            totaljetons = 0
            totalactives = 0
            for sommet in json.nodes
               if sommet.id<6
                  totaljetons += sommet.count
               if active sommet
                  totalactives += 1
            texts.transition()
               .text( (d)-> jetons[d.count])#if d.count is 0 then '' else d.count )
               joueur = adversaire[joueur]
               $(".kikijoue").text joueur
               $(".ntot").text totaljetons
               if totalactives > 0
                   $("#obituary").text ''
               else
                   $("#obituary").text 'mais le réseau de Petri est mort !'


node = svg.selectAll(".node")
node.append( "title" )
  .text( (d) -> d.name )


force.on "tick", ->
  texts
    .attr( "x", (d) -> d.x - 15 )
    .attr( "y", (d) -> d.y + 12 )
    .attr("font-size", radius*2.5)
  links
    .attr( "x1", (d) -> d.source.x )
    .attr( "y1", (d) -> d.source.y )
    .attr( "x2", (d) -> d.target.x )
    .attr( "y2", (d) -> d.target.y )
  circs
    .attr( "cx", (d) -> d.x )
    .attr( "cy", (d) -> d.y );
  rects
    .attr( "x", (d) -> d.x - radius )
    .attr( "y", (d) -> d.y - radius )
 

$ ->
    $("#rules").hide()
    $("#ruletoggle").on "click", ->
        $("#rules").toggle()

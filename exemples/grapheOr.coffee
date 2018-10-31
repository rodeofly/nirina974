q = (n,d) -> n-d*n%d
a=6
b=7
g = '{"nodes":[{"id":0,"index":0,"x":80,"y":80}'
for n in [1..a*(b+1)-1]
  g += ',{"id":'+n+',"index":'+n+',"x":'+(80+80*q(n,6))+',"y":'+(80+80*(n%6))+'}'
g += '],"links":[{"source":{"id":0},"target":{"id":7},"left":false,"right":true}'
for x in [0...a]
  for y in [0...b]
    g += ',{"source":{"id":'+(x+6*y)+'},"target":{"id":'+(x+6*y+6)+'},"left":false,"right":true}'
for x in [0...a-1]
  for y in [0..b]
    g += ',{"source":{"id":'+(x+6*y)+'},"target":{"id":'+(x+6*y+1)+'},"left":false,"right":true}'
for x in [0...a-1]
  for y in [0...b]
    if x+y>0 and x%2==y%2
      g += ',{"source":{"id":'+(x+6*y)+'},"target":{"id":'+(x+6*y+7)+'},"left":false,"right":true}'
for x in [0...a-1]
  for y in [1..b]
    if x+y>0 and x%2==y%2
      g += ',{"source":{"id":'+(x+6*y)+'},"target":{"id":'+(x+6*y-5)+'},"left":false,"right":true}'

g += '],"lastNodeId":'+(a*(b+1)-1)+'}'
affiche g

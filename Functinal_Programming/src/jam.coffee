jam = {}

jam.curry = (f) ->
  sub_curry = (prev) ->
    (args...) ->
      curr = prev.concat args
      if curr.length < f.length then sub_curry curr else f curr...
  sub_curry []

jam.compose = (fs...) ->
  (x) ->
    fs.reduce((acc, val) -> acc val x)


jam.map = (f) ->
  (x) ->
    x.map(f)



if module.exports? then module.exports = jam else this.jam = jam



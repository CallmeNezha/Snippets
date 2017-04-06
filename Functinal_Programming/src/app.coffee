jam = require './jam'

#------- class Variable ------
class Variable
  """
    Basic brick in neuron network.
  """
  constructor: (num_row, num_col, option={}) ->

    @_c_param =
      num_col: 0
      num_row: 0

    @_m_state =
      data: [[0]]

    @_c_param.num_col = num_col
    @_c_param.num_row = num_row

    {initializer} = option
    throw "Error: initializer :: Void -> Double" if initializer? and isNaN( initializer() )
    @_m_state.data = ( initializer?() or 0 for _ in [0...num_col] for _ in [0...num_row] )
    @
  
  @property 'num_col', 
    get: -> @_c_param.num_col
  @property 'num_row',
    get: -> @_c_param.num_row
  @property 'data',
    get: -> @_m_state.data
  
  toString: ->
    "[Variable Object] Size: #{@_c_param.num_row}x#{@_c_param.num_col}"

  map: (f) ->
      throw "Error: this :: (Variable x)" if not (@ instanceof Variable)
      throw "Error: f :: Double -> Double" if f? and isNaN( f(0.0) )
      @_m_state.data = @_m_state.data.map( (x) -> x.map( (x) -> f(x) ) )
      @


  
VariableOf = (num_row, num_col, option) ->
  new Variable(num_row, num_col, option)


class ActivateFunc
  """
    Activate functions.
  """
  tanh: (x) ->
    Math.tanh(x)

class Net
  """
    Neuron network.
  """
  constructor: ->



W = VariableOf(2, 3, 'initializer': () -> -0.1)
b = VariableOf(1, 3)


tanh_mapped = jam.map(ActivateFunc::tanh)
W_tanh = tanh_mapped(W)

console.log(W.data, W.toString())




# class Neuron



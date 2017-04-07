numeric = require 'numeric'
deepcopy = require 'deepcopy'
jam = require './jam'



#-------  System ------
Function::property = (prop, desc) ->
  Object.defineProperty @prototype, prop, desc

#------- class Variable ------
class Variable
  """
    Basic brick in neuron network.
  """
  constructor: (num_row, num_col, option = {}) ->
    @_c_param =
      num_row: 0
      num_col: 0

    @_m_state =
      data: 0

    if num_row instanceof Array
      data = deepcopy num_row
      @_c_param.num_col = if typeof data[0] is 'number' then data.length else data[0].length
      @_c_param.num_row = if typeof data[0] is 'number' then 1 else data.length
      @_m_state.data = data
    else
      @_c_param.num_col = num_col
      @_c_param.num_row = num_row
      { initializer } = deepcopy option
      throw TypeError "Error: initializer :: Void -> Double" if initializer? and isNaN initializer()
      @_m_state.data = ( initializer?() or 0 for _ in [0...num_col] for _ in [0...num_row] )
    @
  
  @property 'num_col', 
    get: -> @_c_param.num_col
  @property 'num_row',
    get: -> @_c_param.num_row
  @property 'is_vector',
    get: -> @_c_param.num_row is 1
  @property 'data',
    get: -> @_m_state.data
  
  
  
  toString: ->
    "[Variable Object] Size: #{@_c_param.num_row}x#{@_c_param.num_col}"

  map: (f) ->
      data = f @_m_state.data
      VariableOf data


  
VariableOf = (num_row, num_col, option) ->
  new Variable num_row, num_col, option


#---------- class ActivateFunc ----------
class ActivateFunc
  """
    Activate functions.
  """
  tanh: (x) ->
    Math.tanh x


#---------- class Net ----------
class Net
  """
    Neuron network.
  """
  constructor: ->



W = VariableOf(2, 3, 'initializer': () -> -0.1)
b = VariableOf(1, 3)

input = VariableOf([1,2])

Variable_map_binary = (f) ->
  (a, b) ->
    VariableOf f a.data, b.data



result = Variable_map_binary(numeric.dot)(input, W)

# foo = jam.map((x) -> x.map( (x) -> x.map( (x) -> ActivateFunc::tanh(x) ) ))
# result = foo W

# assert = require 'assert'
# describe 'Array', ->
#   describe '#indexOf()', ->
#     it 'should return -1 when the value is not present', -> 
#       assert.equal(-1, [1,2,3].indexOf(4))


console.log result.data, result.toString()




# class Neuron



numeric = require 'numeric'
deepcopy = require 'deepcopy'
jam = require './jam'
_ = require 'lodash'



# -------  System ------
Function::property = (prop, desc) ->
  Object.defineProperty @prototype, prop, desc

assert = (condition) ->
  throw "Assertion failed" if not condition
# ------- Convenient methods -----
Zero = -> 0.0
Random = -> Math.random() - 0.5


# ---------- Operators ----------
Variable_map_binary = (f) ->
  (a, b) ->
    VariableOf f a.data, b.data


add = Variable_map_binary(numeric.add)
sub = Variable_map_binary(numeric.sub)
dot = Variable_map_binary(numeric.dot)
mul = Variable_map_binary(numeric.mul)
div = Variable_map_binary(numeric.div)
tensor = Variable_map_binary(numeric.tensor)
pow = do ->
  (a, b) ->
    if a.data instanceof Array
      (Variable_map_binary numeric.pow) a, b # This inconsistent is numericjs's pot
    else if typeof a.data is 'number'
      (Variable_map_binary Math.pow) a, b
  

normSqr = jam.map numeric.norm2Squared
sum = jam.map numeric.sum



# ------- class Variable ------
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
    else if typeof num_row is 'number' and typeof num_col isnt 'number'
      data = num_row # Just a number
      @_c_param.num_col = @_c_param.num_row = 1
      @_m_state.data = data
    else if typeof num_row is 'number' and typeof num_col is 'number'
      throw TypeError "Error: option.initializer :: Void -> Double" if option.initializer? and isNaN option.initializer()
      throw TypeError "Error: num_row and num_col must bigger than 0" if num_row < 1 or num_col < 1
      @_c_param.num_col = num_col
      @_c_param.num_row = num_row
      { initializer } = deepcopy option
      initializer ?= Zero
      if num_row is 1 and num_col is 1
        @_m_state.data = initializer()
      else if num_row is 1 and num_col isnt 1
        @_m_state.data = ( initializer() for i in [0...num_col] )
      else
        @_m_state.data = ( initializer() for i in [0...num_col] for j in [0...num_row] )
    else
      throw TypeError "Error: no case matched"
    @
  
  @property 'num_col', 
    get: -> @_c_param.num_col
  @property 'num_row',
    get: -> @_c_param.num_row
  @property 'is_vector',
    get: -> @_c_param.num_row is 1 and @_c_param.num_col > 1
  @property 'is_number',
    get: -> @_c_param.num_row is 1 and @_c_param.num_col is 1
  @property 'data',
    get: -> @_m_state.data # Maybe deepcopy @_m_state.data ?
  
  
  
  toString: ->
    "[Variable Object] Size: #{@_c_param.num_row}x#{@_c_param.num_col}"

  map: (f) ->
    data = f @_m_state.data
    VariableOf data

  clone: () ->
    VariableOf @_m_state.data


  
VariableOf = (num_row, num_col, option) ->
  new Variable num_row, num_col, option


# ---------- ActivateFunc Collection ----------
ActivateFunc =
  identity: (x) -> x
  identityDerivative: () -> 1.0
  tanh: (x) -> Math.tanh x
  tanhDerivative: (x) -> 1.0 - x * x # Approximate
  logistic: (x) -> 1.0 / (1.0 + Math.exp(-x))
  logisticDerivative : (y) -> 
    y * (1 - y)
  derivative: (x) ->
    switch x.describe
      when 'identity' then ActivateFunc.identityDerivative
      when 'tanh' then ActivateFunc.tanhDerivative
      when 'logistic' then ActivateFunc.logisticDerivative
      else throw TypeError "Error: no derivate exist."

ActivateFunc.identity.describe = 'identity'
ActivateFunc.identityDerivative.describe = 'identityDerivative'
ActivateFunc.tanh.describe = 'tanh'
ActivateFunc.tanhDerivative.describe = 'tanhDerivative'
ActivateFunc.logistic.describe = 'logistic'
ActivateFunc.logisticDerivative.describe = 'logisticDerivative'


# ---------- ErrorFunc Collection ----------
ErrorFunc = 
  halfSquaredError: (output, target) ->
    temp = sub target, output
    temp = pow temp, VariableOf 2
    div temp, VariableOf 2

# ---------- class Net ----------


# --------- class Layer -----------
class Layer
  """
    Layer Monad.
  """
  constructor: (W, b, option = {}) ->
    @_input = 
      data: undefined
    @_output = 
      data: undefined
    @_m_state = 
      W: deepcopy W
      b: deepcopy b
      W_delta: VariableOf(W.num_row, W.num_col, initializer: Zero)
      b_delta: VariableOf(b.num_row, b.num_col, initializer: Zero)
      gradient: VariableOf(b.num_row, b.num_col, initializer: Zero)
    @_c_param =
      activate: undefined
      activate_derivative: undefined

    { activate } = option
    activate ?= ActivateFunc.identity
    activate_derivative = ActivateFunc.derivative activate
    @_c_param.activate = if b.is_vector then jam.map jam.map activate else jam.map activate
    @_c_param.activate_derivative = if b.is_vector then jam.map jam.map activate_derivative else jam.map activate_derivative 
    @_c_param.activate.describe = activate.describe # For debug easy
    @_c_param.activate_derivative.describe = activate_derivative.describe # For debug easy
    

  @property 'output',
    get: -> 
      throw ReferenceError "Error: please set input before get ouput" if not (@_input.data?)
      temp = dot @_m_state.W, @_input.data
      temp = add temp, @_m_state.b
      deepcopy @_output.data = @_c_param.activate( temp )
  @property 'input',
    set: (x) -> @_input.data = deepcopy x

  calcOutputGrad: (target) ->
    @_output.data = @output if not (@_output.data?)
    contrib = sub target, @_output.data # 1/2(target - x)^2 |-> x - target. And we need negative derivative to gradient descent.
    @_m_state.gradient = mul contrib, @_c_param.activate_derivative(@_output.data)

  calcHiddenGrad: (next) ->
    @_output.data = @output  if not (@_output.data?)
    contrib = dot next._m_state.gradient, next._m_state.W
    @_m_state.gradient = mul contrib, @_c_param.activate_derivative(@_output.data)

  
  updateWeights: ->
    eta = VariableOf(0.2) # overall net learning rate
    alpha = VariableOf(0.02) # momentum

    """
      newDeltaWeight = 
        // Global learning rate
        eta
        * prev_neuron.outputVal
        * this_gradient
        // Momentum, i.o.w old deltaWeight's memory
        + alpha
        * oldDeltaWeight
    """
    temp = tensor @_m_state.gradient, @_input.data
    temp = mul eta, temp
    delta_weight = add temp, (mul alpha, @_m_state.W_delta)
    @_m_state.W_delta = delta_weight
    @_m_state.W = add @_m_state.W, @_m_state.W_delta

    # ------ Update bias -----
    temp = mul eta, @_m_state.gradient # Bias output always equal 1.0
    delta_bias = add temp, (mul alpha, @_m_state.b_delta)
    @_m_state.b_delta = delta_bias
    @_m_state.b = add @_m_state.b, @_m_state.b_delta

  
    

LayerOf = (input, W, b, activate, option) ->
  new Layer input, W, b, activate, option
    




# Calculate overall net RMS (RMS: Root Mean Square Error)
calcRMSError = (delta) ->
  error = jam.map( (x) -> x.reduce( (acc, val) -> 
              acc + val * val 
            , 0) )( delta )
  error = div error, VariableOf([ delta.num_col ])
  error = jam.map( Math.sqrt )( error )

# ------  Main  --------

unit_test = () ->

  input = VariableOf [0.05, 0.1]
  target = VariableOf [0.01, 0.99]
  W = VariableOf [ [0.15, 0.20], [0.25, 0.30] ]
  bias = VariableOf [0.35, 0.35]

  W2 = VariableOf [ [0.40, 0.45], [0.50, 0.55] ]
  bias2 = VariableOf [0.60, 0.60]

  l1_test_out = VariableOf [0.5932699921071872, 0.596884378259767]
  l2_test_out = VariableOf [0.7513650695523157, 0.7729284653214625]
  half_square_test_error = VariableOf 0.2983711087600027
  

  l1 = LayerOf(W, bias, activate: ActivateFunc.logistic)
  l2 = LayerOf(W2, bias2, activate: ActivateFunc.logistic) # Here layer2 is output layer

  # closure for local variables.
  do () ->
    l1.input = input
    l2.input = l1.output
    error = ErrorFunc.halfSquaredError l2.output, target

    assert _.isEqual l1.output.data, l1_test_out.data
    assert _.isEqual l2.output.data, l2_test_out.data
    assert _.isEqual (sum error), half_square_test_error
    console.log "Message: forward feed test [PASS]."


unit_test()

#------ Calculate gradients and update weights -------

train = () ->

  train_data = [
    {input: [0.001, 0.001], target: 1},
    {input: [1, 0.001], target: 0.001},
    {input: [1, 1], target: 1},
    {input: [0.001, 1], target: 0.001}    
  ]

  W = VariableOf 5, 2, initializer: () -> Math.random() * 0.5
  bias = VariableOf 1, 5, initializer: () -> 0.1

  W2 = VariableOf 1, 5, initializer: () -> Math.random() * 0.5
  bias2 = VariableOf 1, 1, initializer: () -> 0.1

  l1 = LayerOf(W, bias, activate: ActivateFunc.logistic)
  l2 = LayerOf(W2, bias2, activate: ActivateFunc.identity) # Here layer2 is output layer

  # closure for local variables.
  do () ->
    for i in [0..100000]
      {input, target} = train_data[i%4]
      input = VariableOf input
      target = VariableOf target
      l1.input = input
      l2.input = l1.output

      l2.calcOutputGrad target
      l1.calcHiddenGrad l2

      l1.updateWeights()
      l2.updateWeights()

      
      console.log "Predict: #{l2.output.data}, Target: #{target.data}"



train()







# class Variable
#   constructor: (data) ->
#     @data = data
#   map: (f) ->
#     new Variable f @data

# map = (f) ->
#   (x) ->
#     x.map(f)

# tanh = Math.tanh
# console.log tanh(1)
# console.log (map tanh) [1..2]
# console.log (map map tanh) [[1..2],[1..2]]
# console.log (map map tanh) new Variable [1..2]
# console.log (map map map tanh) new Variable [[1..2],[1..2]]





# class Neuron



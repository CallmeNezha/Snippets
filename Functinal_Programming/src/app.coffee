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
Random = -> Math.random()


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
    @_output.data = @output
    contrib = sub @_output.data, target # 1/2(target - x)^2 |-> x - target. And we need negative derivative to gradient descent.
    derivate = @_c_param.activate_derivative(@_output.data)
    @_m_state.gradient = mul contrib, derivate
    undefined

  calcHiddenGrad: (next) ->
    @_output.data = @output  if not (@_output.data?)
    contrib = dot next._m_state.gradient, next._m_state.W
    derivate = @_c_param.activate_derivative(@_output.data)
    @_m_state.gradient = mul contrib, derivate
    undefined

  
  updateWeights: (eta, alpha) ->
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
    @_m_state.W = sub @_m_state.W, @_m_state.W_delta

    # ------ Update bias -----
    temp = mul eta, @_m_state.gradient # Bias output always equal 1.0
    delta_bias = add temp, (mul alpha, @_m_state.b_delta)
    @_m_state.b_delta = delta_bias
    @_m_state.b = sub @_m_state.b, @_m_state.b_delta
    undefined

  
    

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

  eta = VariableOf 0.5
  alpha = VariableOf 0.0

  l1_test_out = VariableOf [0.5932699921071872, 0.596884378259767]
  l2_test_out = VariableOf [0.7513650695523157, 0.7729284653214625]

  l2_new_weights = VariableOf [[0.35891647971788465, 0.4086661860762334]
                            , [0.5113012702387375, 0.5613701211079891]]

  l1_new_weights = VariableOf [[0.1497807161327628, 0.19956143226552567]
                              ,[0.24975114363236958, 0.29950228726473915]]

  half_square_test_error = VariableOf 0.2983711087600027
  

  l1 = LayerOf(W, bias, activate: ActivateFunc.logistic)
  l2 = LayerOf(W2, bias2, activate: ActivateFunc.logistic) # Here layer2 is output layer

  # closure for local variables.
  do () ->
    l1.input = input
    l2.input = l1.output


    error = ErrorFunc.halfSquaredError l2.output, target
    l2.calcOutputGrad target
    l1.calcHiddenGrad l2

    assert _.isEqual l1.output.data, l1_test_out.data
    assert _.isEqual l2.output.data, l2_test_out.data
    assert _.isEqual (sum error), half_square_test_error

    l2.updateWeights(eta, alpha)
    l1.updateWeights(eta, alpha)

    assert _.isEqual l2._m_state.W, l2_new_weights
    assert _.isEqual l1._m_state.W, l1_new_weights

    console.log "Message: Unit test [PASS]."


unit_test()

#------ Calculate gradients and update weights -------

train_2 = () ->
  input = VariableOf [0.05, 0.1]
  target = VariableOf [0.01, 0.99]
  W = VariableOf 2, 2, initializer: () -> Math.random() * 0.5
  bias = VariableOf 1, 2, initializer: () -> 0.1

  W2 = VariableOf 2, 2, initializer: () -> Math.random() * 0.5
  bias2 = VariableOf 1, 2, initializer: () -> 0.1

  eta = VariableOf 0.5
  alpha = VariableOf 0.0

  l1 = LayerOf(W, bias, activate: ActivateFunc.logistic)
  l2 = LayerOf(W2, bias2, activate: ActivateFunc.logistic) # Here layer2 is output layer

  # closure for local variables.
  do () ->
    for i in [0..10000]
      l1.input = input
      l2.input = l1.output

      l2.calcOutputGrad target
      l1.calcHiddenGrad l2

      l2.updateWeights(eta, alpha)
      l1.updateWeights(eta, alpha)

      if i % 100 is 0
        console.log "Predict #{l2.output.data}, target #{target.data}"


train = () ->

  train_data = [
    {input: [0.0001, 0.0001], target: 1.0},
    {input: [1.0, 0.001], target: 0.0001},
    {input: [1.0, 1.0], target: 1.0},
    {input: [0.0001, 1.0], target: 0.0001}    
  ]

  eta = VariableOf 0.2
  alpha = VariableOf 0.1

  W = VariableOf 5, 2, initializer: () -> Math.random() * 0.5
  bias = VariableOf 1, 5, initializer: () -> 0.1

  W2 = VariableOf 1, 5, initializer: () -> Math.random() * 0.5
  bias2 = VariableOf 1, 1, initializer: () -> 0.1

  l1 = LayerOf(W, bias, activate: ActivateFunc.logistic)
  l2 = LayerOf(W2, bias2, activate: ActivateFunc.logistic) # Here layer2 is output layer

  # closure for local variables.
  do () ->
    for i in [0..1000000]
      {input, target} = train_data[i%4]
      input = VariableOf input
      target = VariableOf target
      l1.input = input
      l2.input = l1.output

      temp = l2.output

      l2.calcOutputGrad target
      l1.calcHiddenGrad l2

      l2.updateWeights(eta, alpha)
      l1.updateWeights(eta, alpha)
      if i % 10 in [0...4]
        console.log "Predict: #{l2.output.data}, Target: #{target.data}"
      # console.log "L1 weights: #{l1._m_state.W.data}"
      # console.log "L1 bias: #{l1._m_state.b.data}"
      
      # console.log "L2 weights: #{l2._m_state.W.data}"
      # console.log "L2 bias: #{l2._m_state.b.data}"
        



# train()



do main = () ->
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



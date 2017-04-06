// Generated by CoffeeScript 1.12.4
(function() {
  var ActivateFunc, Net, Variable, VariableOf, W, W_tanh, b, jam, tanh_mapped;

  jam = require('./jam');

  Variable = (function() {
    "Basic brick in neuron network.";
    function Variable(num_row, num_col, option) {
      var _, initializer;
      if (option == null) {
        option = {};
      }
      this._c_param = {
        num_col: 0,
        num_row: 0
      };
      this._m_state = {
        data: [[0]]
      };
      this._c_param.num_col = num_col;
      this._c_param.num_row = num_row;
      initializer = option.initializer;
      if ((initializer != null) && isNaN(initializer())) {
        throw "Error: initializer :: Void -> Double";
      }
      this._m_state.data = (function() {
        var i, ref, results;
        results = [];
        for (_ = i = 0, ref = num_row; 0 <= ref ? i < ref : i > ref; _ = 0 <= ref ? ++i : --i) {
          results.push((function() {
            var j, ref1, results1;
            results1 = [];
            for (_ = j = 0, ref1 = num_col; 0 <= ref1 ? j < ref1 : j > ref1; _ = 0 <= ref1 ? ++j : --j) {
              results1.push((typeof initializer === "function" ? initializer() : void 0) || 0);
            }
            return results1;
          })());
        }
        return results;
      })();
      this;
    }

    Variable.property('num_col', {
      get: function() {
        return this._c_param.num_col;
      }
    });

    Variable.property('num_row', {
      get: function() {
        return this._c_param.num_row;
      }
    });

    Variable.property('data', {
      get: function() {
        return this._m_state.data;
      }
    });

    Variable.prototype.toString = function() {
      return "[Variable Object] Size: " + this._c_param.num_row + "x" + this._c_param.num_col;
    };

    Variable.prototype.map = function(f) {
      if (!(this instanceof Variable)) {
        throw "Error: this :: (Variable x)";
      }
      if ((f != null) && isNaN(f(0.0))) {
        throw "Error: f :: Double -> Double";
      }
      this._m_state.data = this._m_state.data.map(function(x) {
        return x.map(function(x) {
          return f(x);
        });
      });
      return this;
    };

    return Variable;

  })();

  VariableOf = function(num_row, num_col, option) {
    return new Variable(num_row, num_col, option);
  };

  ActivateFunc = (function() {
    "Activate functions.";
    function ActivateFunc() {}

    ActivateFunc.prototype.tanh = function(x) {
      return Math.tanh(x);
    };

    return ActivateFunc;

  })();

  Net = (function() {
    "Neuron network.";
    function Net() {}

    return Net;

  })();

  W = VariableOf(2, 3, {
    'initializer': function() {
      return -0.1;
    }
  });

  b = VariableOf(1, 3);

  tanh_mapped = jam.map(ActivateFunc.prototype.tanh);

  W_tanh = tanh_mapped(W);

  console.log(W.data, W.toString());

}).call(this);

//# sourceMappingURL=app.js.map

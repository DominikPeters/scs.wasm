# scs.wasm
[![npm version](https://badgen.net/npm/v/scs-solver)](https://www.npmjs.com/package/scs-solver)
[![license](https://badgen.net/npm/license/scs-solver)](https://www.npmjs.com/package/scs-solver)

WebAssembly version of the [SCS (Splitting Conic Solver) convex programming solver](https://www.cvxgrp.org/scs/) for JavaScript environments including browsers and Node.js.

[**Check out a live demo!**](https://dominikpeters.github.io/scs.wasm/)

Contributions are welcome! In particular, it would be good to add support for compiling with BLAS and LAPACK to solve SDPs.

<img src="https://github.com/DominikPeters/scs.wasm/blob/master/info/scs_wasm_logo_white.png" width="450" alt="SCS WebAssembly Logo">

## Install

To use SCS in your JavaScript project, you can install it from npm:

```bash
npm install scs-solver
```

In the browser, you can use SCS directly in the browser using one of the following script tags:

```html
<script src="https://unpkg.com/scs-solver/dist/scs.js"></script>
<script src="https://cdn.jsdelivr.net/npm/scs-solver/dist/scs.js"></script>
```

or by importing it in a JavaScript module:

```javascript
<script type="module">
    import createSCS from 'https://unpkg.com/scs-solver/dist/scs.mjs';
    // ...
</script>
```

## Build from Source

To build the WebAssembly (WASM) version of SCS, you will need to have 
`Emscripten` installed, and `emcc` in your path. To install it, run:

```bash
git clone https://github.com/emscripten-core/emsdk.git
cd emsdk
./emsdk install latest
./emsdk activate latest
source ./emsdk_env.sh
```

Now clone the scs.wasm repo from GitHub and compile the WebAssembly (WASM) 
version of SCS.

```bash
git clone https://github.com/DominikPeters/scs.wasm
make wasm
```

If `make` completes successfully, you will find the compiled `scs.wasm`
file and the JavaScript wrapper `scs.js` in the `dist` directory. You can
now use these files in your JavaScript project, either in the browser or in 
Node.js.

The JavaScript version does not support compiling with BLAS and LAPACK.

## Interface

After building the WebAssembly version, you can use SCS in 
JavaScript environments including browsers and Node.js.

Note that the JavaScript version does not support compiling with BLAS and LAPACK,
so it does not support solving SDPs.

### Basic Usage

In Node.js, you can use SCS as follows:

```javascript
const createSCS = require('scs-solver');

createSCS().then(SCS => {
    // define problem here
    SCS.solve(data, cone, settings);
});
```

Alternatively, you can use ES6 modules, as well as async/await:

```javascript
import createSCS from 'scs-solver';

async function main() {
    const SCS = await createSCS();
    // define problem here
    SCS.solve(data, cone, settings);
}

main();
```

### Data Format

Problem data must be provided as sparse matrices in CSC format using the following structure:

```javascript
const data = {
    m: number,     // Number of rows of A
    n: number,     // Number of cols of A and of P
    A_x: number[], // Non-zero elements of matrix A
    A_i: number[], // Row indices of A elements
    A_p: number[], // Column pointers for A
    P_x: number[], // Non-zero elements of matrix P (optional)
    P_i: number[], // Row indices of P elements (optional)
    P_p: number[], // Column pointers for P (optional)
    b: number[],   // Length m array
    c: number[]    // Length n array
};
```

One way to handle the CSC format in javascript is via the 
[Math.js library](https://mathjs.org/docs/reference/classes/sparsematrix.html), for example:

```javascript
// npm install mathjs
const { matrix } = require('mathjs');
// or import { matrix } from 'mathjs';
// or <script src="https://unpkg.com/mathjs@14.0.1/lib/browser/math.js"></script>

const A = matrix([
    [1, 0],
    [0, 1],
    [1, 1]
], 'sparse');

const P = matrix([
    [3, 0],
    [0, 2]
], 'sparse');

const data = {
    m: 3,
    n: 2,
    A_x: A._values,
    A_i: A._index,
    A_p: A._ptr,
    P_x: P._values,
    P_i: P._index,
    P_p: P._ptr,
    b: [-1.0, 0.3, -0.5],
    c: [-1.0, -1.0]
};
```

### Cone Specification

Cones are specified using the following structure:

```javascript
const cone = {
    z: number,     // Number of zero cones
    l: number,     // Number of positive (or linear) cones
    bu: number[],  // Box cone upper values
    bl: number[],  // Box cone lower values
    bsize: number, // Total length of box cone
    q: number[],   // Array of second-order cone lengths
    qsize: number, // Number of second-order cones
    ep: number,    // Number of primal exponential cone triples
    ed: number,    // Number of dual exponential cone triples
    p: number[],   // Array of power cone parameters
    psize: number  // Number of power cone triples
};
```


Note that positive semidefinite cones are not supported in the JavaScript interface.

Usually, not all cone types are used in a problem, in which case the unused 
cones can be omitted. For example, if only zero and positive cones are used:

```javascript
const cone = {
    z: 1,
    l: 2
};
```

### Settings

Control solver behavior using settings:

```javascript
const settings = new Module.ScsSettings();
Module.setDefaultSettings(settings);
```

Available settings:

- `normalize` (boolean): Heuristically rescale problem data
- `scale` (number): Initial dual scaling factor
- `adaptiveScale` (boolean): Whether to adaptively update scale
- `rhoX` (number): Primal constraint scaling factor
- `maxIters` (number): Maximum iterations to take
- `epsAbs` (number): Absolute convergence tolerance
- `epsRel` (number): Relative convergence tolerance
- `epsInfeas` (number): Infeasible convergence tolerance
- `alpha` (number): Douglas-Rachford relaxation parameter
- `timeLimitSecs` (number): Time limit in seconds
- `verbose` (number): Output level (0-3)
- `warmStart` (boolean): Use warm starting

### Solving Problems

Use the `solve` function to solve optimization problems:

```javascript
const solution = Module.solve(data, cone, settings, [warmStartSolution]);
```

The function takes an optional `warmStartSolution` object to warm-start the solver,
provided `settings.warmStart` is set to `true`.

The returned `solution` object contains:

- `x`: Primal variables
- `y`: Dual variables
- `s`: Slack variables
- `info`: Solver information

    - `iter`: Number of iterations
    - `pobj`: Primal objective
    - `dobj`: Dual objective
    - `solveTime`: Solve time
    - and [other solver information](https://www.cvxgrp.org/scs/api/info.html)
    
- `status`: Solution status (e.g. `SOLVED`, `INFEASIBLE`, `UNBOUNDED`, ...)
- `statusVal`: Solution status value (see SCS [exit flags](https://www.cvxgrp.org/scs/api/exit_flags.html))

## Examples

These examples assume that you have loaded `scs.js`, either in Node.js via

```javascript
const createSCS = require('scs-solver'); // if using CommonJS
import createSCS from 'scs-solver'; // if using ES6 modules
```

or in the browser via a script tag.

### Basic Usage

Here's a [basic example from the SCS documentation for C](https://www.cvxgrp.org/scs/examples/c.html) translated to JavaScript:

```javascript
createSCS().then(SCS => {
    const data = {
        m: 3,
        n: 2,
        A_x: [-1.0, 1.0, 1.0, 1.0],
        A_i: [0, 1, 0, 2],
        A_p: [0, 2, 4],
        P_x: [3.0, -1.0, 2.0],
        P_i: [0, 0, 1],
        P_p: [0, 1, 3],
        b: [-1.0, 0.3, -0.5],
        c: [-1.0, -1.0]
    };

    const cone = {
        z: 1,
        l: 2,
    };

    const settings = new SCS.ScsSettings();
    SCS.setDefaultSettings(settings);
    settings.epsAbs = 1e-9;
    settings.epsRel = 1e-9;

    const solution = SCS.solve(data, cone, settings);
    console.log(solution);

    // re-solve using warm start (will be faster)
    settings.warmStart = true;
    const solution2 = SCS.solve(data, cone, settings, solution);
});
```

This prints the solution object to the console:

```javascript
{
  x: [ 0.3000000000043908, -0.6999999999956144 ],
  y: [ 2.699999999995767, 2.0999999999869825, 0 ],
  s: [ 0, 0, 0.1999999999956145 ],
  info: {
    iter: 100,
    pobj: 1.2349999999907928,
    dobj: 1.2350000000001042,
    resPri: 4.390808429506794e-12,
    resDual: 1.4869081633461182e-13,
    resInfeas: 1.3043478260851176,
    resUnbdd: NaN,
    solveTime: 0.598459,
    setupTime: 11.603125
  },
  status: 1
}
```

### Entropy Example

Next, we will consider a problem involving maximum entropy. Given a vector 
$y \in \mathbb{R}^n$, we want to optimize a function involving entropy
over the unit simplex.

```math
  \begin{align*}
	  \text{minimize} \quad & \sum_{i = 1}^n x_i \log x_i - \langle y, x \rangle \\
    \text{subject to} \quad & \sum_{i = 1}^n x_i = 1 \\
    & x \geq 0
  \end{align*}
```

It is known that for the optimal solution, we have $x_i \propto e^{y_i}$.

This problem can be formulated using the (primal) exponential cone,
defined as 

```math
  \begin{align*}
    \mathcal{K}_{\text{exp}} &= \{ (x,y,z) \in \mathbf{R}^3 \mid y e^{x/y} \leq z, y>0  \} \\
    &= \{ (x,y,z) \in \mathbf{R}^3 \mid y \log(z/y) \geq x, y>0, z>0 \}
  \end{align*}
```

Our formulation is then:

```math
  \begin{align*}
    \text{minimize} \quad & \sum_{i = 1}^n t_i - \langle y, x \rangle \\
    \text{subject to} \quad & \sum_{i = 1}^n x_i = 1 \\
    & x_i \geq 0 \: && \forall i \\
    & (-t_i, x_i, 1) \in \mathcal{K}_{\text{exp}} \: && \forall i
  \end{align*}
```

To implement this problem in JavaScript, we will use the sparse matrix
implementation from the [Math.js library](https://mathjs.org/docs/reference/classes/sparsematrix.html).

```javascript
const createSCS = require('./out/scs.js');
const math = require('./math.js');

createSCS().then(SCS => {
    const n = 5;
    const y = Array.from({ length: n }, () => Math.random());

    const A = math.matrix('sparse');
    const b = [];

    let constraintIndex = 0;

    const x_vars = Array.from({ length: n }, (_, i) => i);
    const t_vars = Array.from({ length: n }, (_, i) => i + n);

    // equality constraint (zero cone)
    let numEqCones = 0;
    for (let i = 0; i < n; i++) {
        A.set([constraintIndex, x_vars[i]], 1);
    }
    b.push(1);
    constraintIndex++;
    numEqCones++;

    // inequality constraints (positive cone)
    let numPosCones = 0;
    for (let i = 0; i < n; i++) {
        A.set([constraintIndex, x_vars[i]], -1);
        b.push(0);
        constraintIndex++;
        numPosCones++;
    }

    // exponential cone constraints
    let numExpCones = 0;
    for (let i = 0; i < n; i++) {
        // (-t_i, x_i, 1) in exponential cone
        A.set([constraintIndex, t_vars[i]], 1);
        b.push(0);
        constraintIndex++;
        A.set([constraintIndex, x_vars[i]], -1);
        b.push(0);
        constraintIndex++;
        // last element is constant, so A has a 0-row; set arbitrary index to 0
        A.set([constraintIndex, x_vars[i]], 0);
        b.push(1);
        constraintIndex++;
        numExpCones++;
    }

    // objective function
    const c = Array.from({ length: 2 * n }, (_, i) => 0);
    for (let i = 0; i < n; i++) {
        c[x_vars[i]] = -y[i];
        c[t_vars[i]] = 1;
    }

    const data = {
        m: A._size[0],
        n: A._size[1],
        A_x: A._values,
        A_i: A._index,
        A_p: A._ptr,
        b: b,
        c: c,
    };

    const cone = {
        z: numEqCones,
        l: numPosCones,
        ep: numExpCones,
    };

    const settings = new SCS.ScsSettings();
    SCS.setDefaultSettings(settings);
    settings.epsAbs = 1e-9;
    settings.epsRel = 1e-9;

    const solution = SCS.solve(data, cone, settings);
    console.log("SCS solution:", solution.x.slice(0, n));

    const denominator = y.map(y_i => Math.exp(y_i)).reduce((a, b) => a + b, 0);
    const predicted_solution = y.map(y_i => Math.exp(y_i) / denominator);
    console.log("Predicted solution:", predicted_solution);
});
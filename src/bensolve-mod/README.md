# BENSOLVE-MOD: A modified version of BENSOLVE (http://www.bensolve.org[http://www.bensolve.org/])


This folder contains a modified version of BENSOLVE 2.0.1 [http://www.bensolve.org/]. Main changes correspond to:

1. Two new command line arguments, `w` and `g` to control the writting of solution and log files respectively.
2. Replacement of a global glpk instance for a structure (`lpstr`).
3. phase2 primal and dual interfases now recive an external poly\_args pointer.
4. csa structure now handled outside vlpi\_init

These changes allows an easier wrapping of BENSOLVE in cython (see XXXX).

## Usage

### Compiling
BENSOLVE-MOD compiles in the same way as the original. Using `clang`:

```bash
clang -std=c99 -O3 -o bensolve *.c -lglpk -lm
```

### Running

In the original BENSOLVE, to solve an vlp problem you run:

```bash
./bensolve file.vlp
```

To achieve the same using BENSOLVE-MOD `w` and `g` arguments need to be present:

```bash
./bensolve file.vlp -wg
```

Otherwise, neither solution or log file will be produced. Both options are documented in the help available using the -h argument. 

For further details, please refer to original documentation.

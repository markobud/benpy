# Threading Safety in benpy

## Overview

This document describes the threading behavior and safety considerations for benpy when using the Python GIL (Global Interpreter Lock) release feature.

## Thread Safety Status

**bensolve 2.1.0 is NOT thread-safe** due to the following global state:

### Global Variables in bensolve 2.1.0

The following global variables in `bslv_lp.c` prevent thread-safe concurrent execution:

```c
glp_prob *lp[1];           // Global GLPK problem instance
double lp_time[1];         // Global timing array  
int lp_num[1];             // Global LP solve counter
```

Additionally, `bslv_algs.c` references:
```c
extern struct timeval t_end;  // External timing variable
```

### Implications

**DO NOT** run multiple solve operations concurrently from different Python threads. This will cause:
- Race conditions on global state
- Incorrect results
- Potential crashes
- Data corruption

## GIL Release Implementation

Despite the thread-safety limitation, benpy releases the GIL during long-running solve operations for the following benefits:

### Benefits of GIL Release

1. **I/O Parallelism**: Other Python threads can perform I/O operations (network, disk) while a solve is running
2. **Responsiveness**: GUI and monitoring threads remain responsive during computation
3. **Future-Proofing**: Code is ready if bensolve becomes thread-safe in the future
4. **Signal Handling**: Python signal handlers can run during computation

### Where GIL is Released

The GIL is released in the `_csolve()` function around:
- `phase0()` - Initial feasibility check
- `phase1_primal()` / `phase1_dual()` - First phase of Benson's algorithm
- `phase2_primal()` / `phase2_dual()` - Second phase of Benson's algorithm

These are the computationally intensive operations that can take significant time for large problems.

## Safe Usage Patterns

### ✅ SAFE: Single Solve with I/O in Other Threads

```python
import threading
import benpy
import numpy as np

# Solve running in main thread
def solve_problem():
    B = np.array([[1.0, 1.0]])
    P = np.array([[1.0, 0.0], [0.0, 1.0]])
    sol = benpy.solve_direct(B, P, b=np.array([1.0]), opt_dir=1)
    return sol

# I/O operation in separate thread (safe)
def monitor_progress():
    while not done_event.is_set():
        print("Solving...")
        time.sleep(1)

done_event = threading.Event()
monitor_thread = threading.Thread(target=monitor_progress)
monitor_thread.start()

result = solve_problem()  # GIL released during computation
done_event.set()
monitor_thread.join()
```

### ✅ SAFE: Sequential Solves (No Concurrency)

```python
import benpy
import numpy as np

problems = [create_problem(i) for i in range(10)]

# Solve sequentially - completely safe
for prob in problems:
    sol = benpy.solve_direct(prob.B, prob.P, b=prob.b, opt_dir=1)
    process_solution(sol)
```

### ❌ UNSAFE: Concurrent Solves from Multiple Threads

```python
import threading
import benpy

# DO NOT DO THIS - UNSAFE!
def solve_in_thread(problem_data):
    sol = benpy.solve_direct(**problem_data)  # RACE CONDITION!
    return sol

threads = []
for prob_data in problems:
    t = threading.Thread(target=solve_in_thread, args=(prob_data,))
    threads.append(t)
    t.start()  # Multiple solves running concurrently - UNSAFE!

for t in threads:
    t.join()
```

### ✅ SAFE: Multiprocessing for Parallelism

Use Python's `multiprocessing` module instead of threading for parallel solves:

```python
import multiprocessing
import benpy
import numpy as np

def solve_problem(prob_data):
    """Each process has its own bensolve global state"""
    return benpy.solve_direct(**prob_data)

if __name__ == '__main__':
    problems = [create_problem(i) for i in range(10)]
    
    # Use process pool - safe because each process has separate memory
    with multiprocessing.Pool(processes=4) as pool:
        results = pool.map(solve_problem, problems)
```

## Technical Details

### GIL Release Mechanism

The GIL is released using Cython's `nogil` context manager:

```cython
with nogil:
    phase0(solution._sol, problem._vlp, problem._opt)
```

This tells Cython that the enclosed C code:
1. Does not access Python objects
2. Does not need the GIL held
3. Can allow other Python threads to run

### Re-acquiring the GIL

The GIL is automatically re-acquired when exiting the `nogil` block. This ensures Python object access remains safe.

### Error Handling

Errors that occur within `nogil` blocks must not access Python objects. The code uses:
1. Return codes from C functions
2. Status flags in C structures
3. GIL re-acquisition before raising Python exceptions

## Performance Considerations

### When GIL Release Helps

- **Large problems** (many variables/constraints)
- **Long-running solves** (> 1 second)
- **I/O-bound applications** (monitoring, logging, networking)
- **Interactive applications** (GUIs, notebooks)

### When GIL Release Doesn't Help

- **Small problems** (< 100ms solve time)
- **CPU-bound Python code** in other threads (still bottlenecked)
- **Single-threaded applications** (no other threads to run)

## Future Work

### Making bensolve Thread-Safe

To enable concurrent solves, bensolve would need:

1. **Remove Global State**: Convert global variables to instance variables
   - Pass `glp_prob*` as parameter instead of using `lp[0]`
   - Use thread-local storage for timing
   - Remove shared counters

2. **GLPK Thread Safety**: Verify GLPK library is thread-safe
   - Each thread needs separate `glp_prob` instance
   - GLPK internal state must be thread-local

3. **Testing**: Comprehensive concurrent execution tests
   - Multiple threads solving simultaneously
   - Verify no race conditions
   - Stress testing under load

### Wrapper Changes for Thread Safety

If bensolve becomes thread-safe:

1. Update this documentation
2. Add concurrent solve tests
3. Consider adding thread pool support
4. Benchmark parallel performance

## Testing

### Thread Safety Tests

The test suite includes threading behavior tests in `tests_threading.py`:

- `test_single_solve_with_monitoring` - Verify I/O can run during solve
- `test_sequential_solves` - Verify sequential solves work correctly
- `test_concurrent_solves_warning` - Document unsafe concurrent usage
- `test_multiprocessing_safe` - Verify multiprocessing works

### Running Threading Tests

```bash
python tests_threading.py -v
```

## References

- Python GIL: https://wiki.python.org/moin/GlobalInterpreterLock
- Cython nogil: https://cython.readthedocs.io/en/latest/src/userguide/nogil.html
- GLPK: https://www.gnu.org/software/glpk/
- bensolve: http://www.bensolve.org/

## Changelog

- **2024-11**: Initial GIL release implementation (Phase 2)
  - Added `nogil` blocks around phase0, phase1, phase2
  - Documented thread safety limitations
  - Added threading tests

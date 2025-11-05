# Threading Considerations for benpy

## Overview

As of version 1.0.4, benpy releases the Global Interpreter Lock (GIL) during long-running solve operations. This allows other Python threads to execute concurrently while the VLP solver is running, improving the responsiveness of multi-threaded Python applications.

## Key Points

### ✓ GIL is Released
The GIL is released during the following computations:
- `phase0` - Initial feasibility check
- `phase1_primal` - Primal algorithm phase 1
- `phase1_dual` - Dual algorithm phase 1
- `phase2_primal` - Primal algorithm phase 2
- `phase2_dual` - Dual algorithm phase 2

This means other Python threads can run while benpy is solving a VLP problem.

### ⚠️ Bensolve is NOT Thread-Safe

The underlying bensolve library (version 2.0.1) uses global state and is **NOT safe** for concurrent execution from multiple threads. Specifically:

1. **Global variable `fnc_prmtr`**: Used internally by phase functions
2. **Global timing variables**: `t_start` and `t_end` (though not used by benpy)

**Only one thread should call benpy's `solve()` function at a time.**

## Best Practices

### Single-Threaded Usage
```python
from benpy import solve, vlpProblem

# This is safe - single thread
vlp = vlpProblem(...)
sol = solve(vlp)
```

### Multi-Threaded Usage (REQUIRED: Use a Lock)
```python
import threading
from benpy import solve, vlpProblem

# Create a global lock for the solver
solver_lock = threading.Lock()

def solve_with_lock(problem):
    """Thread-safe wrapper for solve()."""
    with solver_lock:
        return solve(problem)

# Safe for multiple threads
threads = []
for problem in problems:
    t = threading.Thread(target=solve_with_lock, args=(problem,))
    threads.append(t)
    t.start()

for t in threads:
    t.join()
```

### Alternative: Thread Pool with maxsize=1
```python
from concurrent.futures import ThreadPoolExecutor
from benpy import solve, vlpProblem

# Use a thread pool with max_workers=1 to serialize solve calls
with ThreadPoolExecutor(max_workers=1) as executor:
    futures = [executor.submit(solve, prob) for prob in problems]
    results = [f.result() for f in futures]
```

## Benefits of GIL Release

Even though bensolve requires serialization, releasing the GIL provides benefits:

1. **Responsive UI**: GUI applications can remain responsive while solving
2. **Background Processing**: Other Python threads can do useful work
3. **I/O Operations**: Network or file I/O can continue in other threads
4. **Async Integration**: Better integration with async frameworks

Example:
```python
import threading
from benpy import solve, vlpProblem

solver_lock = threading.Lock()
progress = {'status': 'idle'}

def solve_in_background(problem):
    with solver_lock:
        progress['status'] = 'solving'
        result = solve(problem)
        progress['status'] = 'done'
        return result

def monitor_progress():
    """This thread can run while solving happens."""
    while progress['status'] != 'done':
        print(f"Status: {progress['status']}")
        time.sleep(0.1)

# Start solver in background thread
solver_thread = threading.Thread(target=solve_in_background, args=(vlp,))
monitor_thread = threading.Thread(target=monitor_progress)

solver_thread.start()
monitor_thread.start()

solver_thread.join()
monitor_thread.join()
```

## Testing

Run the threading test to verify GIL release:
```bash
python src/examples/test_threading.py
```

## Future Improvements

Potential improvements for true thread-safety would require:
1. Modifications to bensolve library to eliminate global state
2. Thread-local storage for `fnc_prmtr` and timing variables
3. Careful review of all static/global variables in bensolve

## References

- GLPK documentation: https://www.gnu.org/software/glpk/
- Bensolve: http://www.bensolve.org/
- Cython documentation on GIL: https://cython.readthedocs.io/en/latest/src/userguide/external_C_code.html#releasing-the-gil

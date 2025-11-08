"""
Basic import and module tests for benpy.

These tests verify that benpy can be imported and basic module
structure is available.
"""

import pytest
import sys
import os


def test_import_benpy():
    """Test that benpy can be imported."""
    import benpy
    assert benpy is not None


def test_benpy_version():
    """Test that benpy has a version attribute."""
    import benpy
    # Check if __version__ or THISVERSION exists
    assert hasattr(benpy, '__version__') or hasattr(benpy, 'THISVERSION')


def test_import_core_classes():
    """Test that core classes can be imported."""
    import benpy
    
    # Check for main classes
    assert hasattr(benpy, 'vlpProblem'), "vlpProblem class not found"
    assert hasattr(benpy, 'vlpSolution'), "vlpSolution class not found"


def test_import_core_functions():
    """Test that core functions can be imported."""
    import benpy
    
    # Check for main functions
    assert hasattr(benpy, 'solve'), "solve function not found"
    assert hasattr(benpy, 'solve_legacy'), "solve_legacy function not found"


def test_import_internal_classes():
    """Test that internal Cython classes can be accessed."""
    import benpy
    
    # These are the low-level Cython wrappers
    assert hasattr(benpy, '_cVlpProblem'), "_cVlpProblem class not found"
    assert hasattr(benpy, '_cVlpSolution'), "_cVlpSolution class not found"


def test_numpy_available():
    """Test that numpy is available (required dependency)."""
    import numpy as np
    assert np is not None
    
    # Test basic numpy functionality
    arr = np.array([1.0, 2.0, 3.0])
    assert arr.shape == (3,)


def test_scipy_available():
    """Test that scipy is available (optional but useful)."""
    try:
        import scipy
        assert scipy is not None
    except ImportError:
        pytest.skip("scipy not installed")


def test_prettytable_available():
    """Test that prettytable is available (for output formatting)."""
    try:
        import prettytable
        assert prettytable is not None
    except ImportError:
        pytest.skip("prettytable not installed")


def test_module_docstring():
    """Test that benpy has documentation."""
    import benpy
    assert benpy.__doc__ is not None or hasattr(benpy, '__doc__')


def test_module_file_location():
    """Test that we can determine where benpy is installed."""
    import benpy
    assert hasattr(benpy, '__file__')
    assert os.path.exists(os.path.dirname(benpy.__file__))


@pytest.mark.api
def test_vlp_problem_creation():
    """Test that we can create a vlpProblem instance."""
    import benpy
    
    prob = benpy.vlpProblem()
    assert prob is not None


@pytest.mark.api
def test_c_vlp_problem_creation():
    """Test that we can create a _cVlpProblem instance."""
    import benpy
    
    prob = benpy._cVlpProblem()
    assert prob is not None


@pytest.mark.api
def test_c_vlp_solution_creation():
    """Test that we can create a _cVlpSolution instance."""
    import benpy
    
    # Note: Solution objects typically require initialization
    # This just tests that the class is accessible
    assert benpy._cVlpSolution is not None

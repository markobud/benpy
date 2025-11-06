"""
Pytest configuration and fixtures for benpy test suite.

This module provides common fixtures and configuration for all benpy tests.
"""

import pytest
import sys
import os
import gc
import numpy as np
import faulthandler

# Enable faulthandler to capture native crash tracebacks
faulthandler.enable()

# Add src directory to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))


@pytest.fixture(autouse=True)
def cleanup_memory():
    """
    Fixture to ensure memory is cleaned up after each test.
    
    This runs automatically after every test to force garbage collection
    and help detect memory leaks.
    """
    yield
    gc.collect()


@pytest.fixture
def simple_2d_problem():
    """
    Fixture providing a simple 2D test problem.
    
    This is a basic bi-objective linear program suitable for quick testing.
    Based on example01 from bensolve examples.
    
    Returns:
        dict: Problem data with keys 'B', 'P', 'b', 'l', 'a', 'opt_dir'
    """
    return {
        'B': np.array([[2.0, 1.0], [1.0, 2.0]]),
        'P': np.array([[1.0, -1.0], [1.0, 1.0]]),
        'a': np.array([6.0, 6.0]),
        'l': np.array([0.0, 0.0]),
        'opt_dir': 1
    }


@pytest.fixture
def infeasible_problem():
    """
    Fixture providing an infeasible problem.
    
    Based on example02 from bensolve examples - this problem has
    conflicting constraints and should be detected as infeasible.
    
    Returns:
        dict: Problem data with keys 'B', 'P', 'a', 'b'
    """
    return {
        'B': np.array([[3.0, 1.0], [1.0, 2.0], [1.0, 1.0]]),
        'P': np.array([[1.0, 0.0], [0.0, 1.0]]),
        'a': np.array([0.0, 0.0, 1.0]),
        'b': np.array([1.0, 1.0, 2.0]),
        'opt_dir': 1
    }


@pytest.fixture
def unbounded_problem():
    """
    Fixture providing a totally unbounded problem.
    
    Based on example04 from bensolve examples.
    
    Returns:
        dict: Problem data
    """
    return {
        'B': np.array([[1.0, 1.0, 1.0], [1.0, 1.0, 2.0]]),
        'P': np.array([[1.0, 0.0, 0.0], [0.0, 1.0, 0.0]]),
        'a': np.array([1.0, 1.0]),
        'opt_dir': 1
    }


@pytest.fixture
def cone_problem():
    """
    Fixture providing a problem with custom ordering cone.
    
    Based on example05 from bensolve examples - includes
    custom cone generators Y and duality parameter c.
    
    Returns:
        dict: Problem data including Y and c
    """
    return {
        'B': np.array([[1.0, 1.0, 1.0],
                       [1.0, 2.0, 2.0],
                       [2.0, 2.0, 1.0],
                       [2.0, 1.0, 2.0]]),
        'P': np.array([[1.0, 0.0, 1.0],
                       [1.0, 1.0, 0.0],
                       [0.0, 1.0, 1.0]]),
        'a': np.array([1.0, 1.5, 1.5, 1.5]),
        'l': np.array([0.0, 0.0, 0.0]),
        'Y': np.array([[1.0, 0.0, -1.0, 0.0],
                       [0.0, 1.0, 0.0, -1.0],
                       [0.0, 0.0, 2.0, 2.0]]),
        'c': np.array([1.0, 1.0, 1.0]),
        'opt_dir': 1
    }


@pytest.fixture
def max_problem():
    """
    Fixture providing a maximization problem.
    
    Based on example06 from bensolve examples.
    
    Returns:
        dict: Problem data for maximization
    """
    return {
        'B': np.array([[1.0, 1.0]]),
        'P': np.array([[1.0, -1.0], [1.0, 1.0]]),
        'a': np.array([1.0]),
        'b': np.array([2.0]),
        'l': np.array([0.0, 0.0]),
        's': np.array([1.0, np.inf]),
        'Z': np.array([[2.0, -1.0], [-1.0, 2.0]]),
        'c': np.array([1.0, 1.0]),
        'opt_dir': -1  # maximization
    }


@pytest.fixture
def partially_unbounded_problem():
    """
    Fixture providing a problem that is unbounded but not totally unbounded.
    
    Based on example08 from bensolve examples.
    
    Returns:
        dict: Problem data
    """
    return {
        'B': np.array([[3.0, 1.0], [1.0, 2.0], [1.0, 1.0]]),
        'P': np.array([[1.0, 0.0], [0.0, 1.0]]),
        'a': np.array([0.0, 0.0, 1.0]),
        'Y': np.array([[-1.0, 3.0], [1.5, -1.0]]),
        'c': np.array([0.0, 1.0]),
        'opt_dir': 1
    }


def pytest_configure(config):
    """Configure pytest with custom settings."""
    # Register custom markers
    config.addinivalue_line(
        "markers", "slow: marks tests as slow (deselect with '-m \"not slow\"')"
    )
    config.addinivalue_line(
        "markers", "memory: marks tests that check for memory leaks"
    )
    config.addinivalue_line(
        "markers", "api: marks tests that check API compatibility"
    )
    config.addinivalue_line(
        "markers", "examples: marks tests that use bensolve example problems"
    )
    config.addinivalue_line(
        "markers", "integration: marks tests that require full solve operations"
    )

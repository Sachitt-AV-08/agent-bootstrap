"""Tests for the buggy calculator - these should fail initially."""

import pytest
import math
from src.calculator import Calculator, AdvancedCalculator


class TestCalculator:
    """Tests for basic Calculator."""
    
    def setup_method(self):
        self.calc = Calculator()
    
    def test_add(self):
        assert self.calc.add(2, 3) == 5
        assert self.calc.add(-1, 1) == 0
        assert self.calc.add(0, 0) == 0
    
    def test_subtract(self):
        assert self.calc.subtract(5, 3) == 2  # BUG: returns -2
        assert self.calc.subtract(0, 5) == -5  # BUG: returns 5
    
    def test_multiply(self):
        assert self.calc.multiply(3, 4) == 12
        assert self.calc.multiply(-2, 3) == -6
        assert self.calc.multiply(0, 100) == 0
    
    def test_divide(self):
        assert self.calc.divide(10, 2) == 5
        assert self.calc.divide(7, 2) == 3.5
        with pytest.raises(ZeroDivisionError):
            self.calc.divide(5, 0)  # BUG: doesn't raise, crashes
    
    def test_power(self):
        assert self.calc.power(2, 3) == 8
        assert self.calc.power(5, 0) == 1
        assert self.calc.power(2, -1) == 0.5
        with pytest.raises(ZeroDivisionError):
            self.calc.power(0, -1)  # BUG: doesn't raise
    
    def test_factorial(self):
        assert self.calc.factorial(0) == 1
        assert self.calc.factorial(1) == 1
        assert self.calc.factorial(5) == 120
        with pytest.raises(ValueError):
            self.calc.factorial(-1)  # BUG: infinite recursion
        with pytest.raises(RecursionError):
            self.calc.factorial(1000)  # BUG: recursion limit
    
    def test_fibonacci(self):
        assert self.calc.fibonacci(0) == 0
        assert self.calc.fibonacci(1) == 1
        assert self.calc.fibonacci(10) == 55
        # BUG: fibonacci(40) takes forever (exponential)
    
    def test_mean(self):
        assert self.calc.mean([1, 2, 3, 4, 5]) == 3
        assert self.calc.mean([10]) == 10
        with pytest.raises(ZeroDivisionError):
            self.calc.mean([])  # BUG: crashes
    
    def test_median(self):
        assert self.calc.median([1, 2, 3, 4, 5]) == 3
        assert self.calc.median([1, 2, 3, 4]) == 2.5  # BUG: returns 3
        assert self.calc.median([5, 1, 3, 2, 4]) == 3  # BUG: doesn't sort
        with pytest.raises(ValueError):
            self.calc.median([])  # BUG: returns 0
    
    def test_history(self):
        self.calc.add(1, 2)
        self.calc.multiply(3, 4)
        assert len(self.calc.history) == 2
        assert self.calc.history[0] == ("add", 1, 2, 3)
    
    def test_clear_history(self):
        self.calc.add(1, 2)
        self.calc.clear_history()
        assert len(self.calc.history) == 0
        # BUG: cache not cleared


class TestAdvancedCalculator:
    """Tests for AdvancedCalculator."""
    
    def setup_method(self):
        self.calc = AdvancedCalculator()
    
    def test_sin_degrees(self):
        self.calc.mode = "deg"
        # sin(90°) = 1
        assert abs(self.calc.sin(math.pi / 2) - 1) < 1e-10  # BUG: uses radians
    
    def test_cos_degrees(self):
        self.calc.mode = "deg"
        # cos(0°) = 1
        assert abs(self.calc.cos(0) - 1) < 1e-10
    
    def test_std_dev(self):
        # Sample std dev of [2, 4, 4, 4, 5, 5, 7, 9] = 2
        values = [2, 4, 4, 4, 5, 5, 7, 9]
        result = self.calc.std_dev(values)
        expected = 2.0  # Sample std dev
        assert abs(result - expected) < 1e-10  # BUG: uses population formula
    
    def test_percent_change(self):
        assert self.calc.percent_change(100, 150) == 50
        assert self.calc.percent_change(100, 50) == -50
        with pytest.raises(ZeroDivisionError):
            self.calc.percent_change(0, 100)  # BUG: crashes
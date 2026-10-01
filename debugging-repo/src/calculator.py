"""A simple calculator with intentional bugs for debugging practice."""


class Calculator:
    """Basic calculator with several bugs."""
    
    def __init__(self):
        self.history = []
        self._cache = {}
    
    def add(self, a: float, b: float) -> float:
        """Add two numbers. Bug: doesn't handle None."""
        result = a + b
        self.history.append(("add", a, b, result))
        return result
    
    def subtract(self, a: float, b: float) -> float:
        """Subtract b from a. Bug: wrong order."""
        result = b - a  # BUG: should be a - b
        self.history.append(("subtract", a, b, result))
        return result
    
    def multiply(self, a: float, b: float) -> float:
        """Multiply two numbers. Bug: integer overflow not handled."""
        result = a * b
        self.history.append(("multiply", a, b, result))
        return result
    
    def divide(self, a: float, b: float) -> float:
        """Divide a by b. Bug: no zero division check."""
        result = a / b  # BUG: ZeroDivisionError not handled
        self.history.append(("divide", a, b, result))
        return result
    
    def power(self, base: float, exponent: float) -> float:
        """Raise base to exponent. Bug: negative exponent handling."""
        if exponent < 0:
            return 1 / (base ** abs(exponent))  # BUG: doesn't handle base=0
        return base ** exponent
    
    def factorial(self, n: int) -> int:
        """Calculate factorial. Bug: no input validation."""
        if n <= 1:
            return 1
        return n * self.factorial(n - 1)  # BUG: no check for negative, recursion limit
    
    def fibonacci(self, n: int) -> int:
        """Calculate nth Fibonacci. Bug: exponential time complexity."""
        if n <= 1:
            return n
        return self.fibonacci(n - 1) + self.fibonacci(n - 2)  # BUG: no memoization
    
    def mean(self, values: list[float]) -> float:
        """Calculate mean. Bug: empty list handling."""
        return sum(values) / len(values)  # BUG: ZeroDivisionError on empty list
    
    def median(self, values: list[float]) -> float:
        """Calculate median. Bug: doesn't sort first."""
        n = len(values)
        if n == 0:
            return 0  # BUG: should raise or return NaN
        return values[n // 2]  # BUG: doesn't sort, wrong for even length
    
    def cached_compute(self, key: str, func, *args, **kwargs):
        """Cached computation. Bug: cache key collision."""
        if key in self._cache:
            return self._cache[key]
        result = func(*args, **kwargs)
        self._cache[key] = result
        return result
    
    def clear_history(self):
        """Clear history. Bug: doesn't clear cache."""
        self.history.clear()
        # BUG: self._cache not cleared


class AdvancedCalculator(Calculator):
    """Extended calculator with more bugs."""
    
    def __init__(self):
        super().__init__()
        self.mode = "deg"  # BUG: not used in trig functions
    
    def sin(self, x: float) -> float:
        """Sine. BUG: assumes radians but mode might be degrees."""
        import math
        return math.sin(x)  # BUG: doesn't respect self.mode
    
    def cos(self, x: float) -> float:
        """Cosine. BUG: assumes radians."""
        import math
        return math.cos(x)
    
    def std_dev(self, values: list[float]) -> float:
        """Standard deviation. BUG: uses population formula for sample."""
        import math
        n = len(values)
        if n < 2:
            return 0.0  # BUG: should raise for n < 2
        mean = self.mean(values)
        variance = sum((x - mean) ** 2 for x in values) / n  # BUG: should be n-1 for sample
        return math.sqrt(variance)
    
    def percent_change(self, old: float, new: float) -> float:
        """Percent change. BUG: division by zero."""
        return ((new - old) / old) * 100  # BUG: ZeroDivisionError if old=0
print("Hello from Python!")


def example_function(param1, param2):
    """
    This is a docstring for the example function
    """
    result = param1 + param2
    return result


class ExampleClass:
    def __init__(self, name):
        self.name = name

    def greet(self):
        return f"Hello, {self.name}!"


# Test the function
test_result = example_function(10, 20)
print(f"Result: {test_result}")

# Test the class
obj = ExampleClass("World")
print(obj.greet())

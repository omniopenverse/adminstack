from setuptools import setup, find_packages

setup(
    name="iaac_helper",
    version="0.1",
    packages=find_packages(),
    install_requires=[
        "PyYaml"
        # Add any dependencies your package needs here
    ],
    author="Airseneo",
    # author_email="your.email@example.com",
    description="A simple helper package",
    # url="https://example.com/my_package",
)

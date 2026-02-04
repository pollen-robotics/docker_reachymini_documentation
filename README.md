# Reachy Mini Documentation Docker Image

This Docker image is designed to be used by [doc-builder](https://github.com/huggingface/doc-builder) in the CI pipeline of the [Reachy Mini](https://github.com/pollen-robotics/reachy_mini) project.

## Purpose

This image contains all the necessary dependencies for the autodoc process to run properly in the Reachy Mini documentation build workflow.

## Usage

This image is used in the Reachy Mini CI/CD pipeline for building documentation:
- **Repository**: [pollen-robotics/reachy_mini](https://github.com/pollen-robotics/reachy_mini)
- **Workflow**: [build_documentation.yml](https://github.com/pollen-robotics/reachy_mini/blob/develop/.github/workflows/build_documentation.yml)

The image ensures a consistent environment for generating documentation using Hugging Face's doc-builder tool.

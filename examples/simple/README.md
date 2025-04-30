# Simple Lambda API Example

This example demonstrates how to use the API Gateway module to create a REST API with a Lambda function backend.

## Overview

The example:

1. Creates a simple Node.js Lambda function that returns a Hello World response
1. Sets up an API Gateway using the module with OpenAPI specification
1. Configures the API Gateway to route requests to the Lambda function
1. Enables both access and execution logging to CloudWatch
1. Sets up basic method settings for API monitoring and control

## Usage

To run this example, execute the following commands:

```bash
# Initialize Terraform
terraform init

# Apply the configuration
terraform apply
```

# OIDC Authorized API Example

This example demonstrates how to use the API Gateway module with the OIDC authorizer module to create a REST API that includes both public and protected endpoints.

## Overview

This example:

1. Creates an API Gateway with two endpoints:

   - `/public` - Accessible without authentication
   - `/protected` - Requires a valid OIDC token

1. Integrates with the OIDC authorizer module that leverages the [oidc-authorizer](https://github.com/lmammino/oidc-authorizer) Lambda

1. Configures Lambda functions to handle the API requests

1. Sets up all necessary IAM permissions

## Authentication Flow

1. Users authenticate with an OIDC provider (like Auth0, Cognito, etc.)
1. The provider issues a JWT token to the user
1. User includes the token in the `Authorization` header when calling the protected endpoint
1. API Gateway forwards the token to the OIDC authorizer Lambda
1. Lambda validates the token's signature, expiration, issuer, audience, and scopes
1. If valid, the request proceeds to the protected Lambda function
1. The Lambda function can access user information from the authorizer context

## Important Configuration Settings

Before deploying this example, you need to update the following OIDC configuration values in `main.tf`:

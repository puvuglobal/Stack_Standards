# MODULE 38: Circuit Breaker & Fault Tolerance

Goal: Build resilience against downstream failures and cascading crashes.

Fundamentals:
- Circuit breaker pattern (Open/Closed/Half-Open)
- Retry with exponential backoff
- Fallback responses and degraded modes
- Timeout handling and timeout budgets
- Health checks and bulkhead isolation

Implementation Steps:
- [ ] Implement a CircuitBreaker utility in frontend/backend
- [ ] Wrap external calls with circuit breaker
- [ ] Add retry policy with backoff
- [ ] Create fallback/gray-path responses
- [ ] Add health-check endpoints and monitoring
- [ ] Integrate with RPC/back-end calls
- [ ] Document decisions in PROD standards

References:
- Azure Circuit Breaker pattern: https://learn.microsoft.com/en-us/azure/architecture/patterns/circuit-breaker
- AWS Circuit Breaker: https://aws.amazon.com/blogs/compute/using-the-circuit-breaker-pattern-with-aws-lambda-extensions-and-amazon-dynamodb/

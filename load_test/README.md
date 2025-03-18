# OpenWhisk Load Testing

This directory contains configuration files and scripts for load testing OpenWhisk actions using Artillery.io.

## Test Configurations

- `lin_reg.yml`: Tests the linear regression action
- `mobilenet-mongo.yml`: Tests the MongoDB-backed MobileNet image classification action
- `mobilenet-simple.yml`: Tests the simple MobileNet image classification action
- `run-tests.sh`: Script to execute all tests and capture results
- `setup-env.sh`: Script to configure environment variables for testing

## Scaling Up

### Initial Performance Issues

Our initial load tests revealed significant performance issues:

- High rate of HTTP 429 errors (too many requests)
- High failure rate (many "Failed capture or match" errors)
- Very long response times (up to 22 seconds)
- Low throughput due to throttling

The default OpenWhisk configuration is designed for testing rather than production workloads, with low concurrency limits, particularly for blackbox (Docker-based) actions like our MobileNet models.

### Baseline (Default) Configuration

The default OpenWhisk configuration includes the following limits:

1. **System Limits**:
   - `actionsInvokesPerminute`: 60 (system default)
   - `actionsInvokesConcurrent`: 30 (system default)
   - `triggersFiresPerminute`: 60 (system default)
   - `concurrentInvocations`: 30 (system default)
   - `throughput`: Not explicitly defined (uses system default)
   - Container pool memory (`userMemory`): 2GB
   - Blackbox-fraction: 0.1 (only 10% of invokers handle Docker actions)

2. **Deployment Configuration**:
   - Controller replicas: 1
   - Invoker replicas: 1
   - JVM heap memory: 512MB

3. **Action Settings**:
   - Default action timeout: 60s (60000ms)

### Baseline (Default) Configuration Results

With the default configuration, our load tests showed extremely poor performance:

- **mobilenet-mongo**: Out of 8,100 concurrent users:
  - 298 requests completed successfully
  - 7,802 requests failed
  - 3.68% success rate

- **linear regression**: Out of 8,100 concurrent users:
  - 286 requests completed successfully
  - 7,814 requests failed
  - 3.53% success rate

These results clearly demonstrate that the default OpenWhisk configuration is inadequate for production workloads, especially for machine learning applications with high computational requirements.

### Applied Configuration Changes

We made the following changes to address these issues:

1. **System Limits** in `mycluster.yaml`:
   - Increased `actionsInvokesPerminute` from 60 to 600
   - Increased `actionsInvokesConcurrent` from 30 to 100
   - Increased `triggersFiresPerminute` from 60 to 600
   - Increased `concurrentInvocations` from 30 to 100
   - Set `throughput` to 100
   - Set container pool memory (`userMemory`) to 16GB
   - Increased blackbox-fraction from 0.1 to 0.8 to allow more invokers to handle Docker actions

2. **Action-Specific Settings**:
   - Increased action timeout from 60s to 120s (2 minutes) for all actions
   - This gives machine learning operations more time to complete

3. **Invoker Configuration**:
   - Set JVM heap memory from 512MB to 2048MB
   - Used LogDriverLogStoreProvider to offload log processing
   - Increased controller replicas from 1 to 2
   - Increased invoker replicas from 1 to 2

### Results and Impact

These changes address several bottlenecks in the OpenWhisk deployment:

- **Rate Limiting**: Higher invocation limits reduce 429 errors
- **Container Resources**: More memory for the container pool allows more concurrent containers
- **Blackbox Distribution**: Higher blackbox-fraction allows Docker-based actions to use more invokers
- **Execution Time**: Longer timeouts prevent premature termination of complex ML operations

### Post-Configuration Test Results

After implementing our configuration changes, we ran the same load tests again. The results still show significant failure rates under sustained load (20 requests/second):

- **mobilenet-mongo**: Out of 8,100 total requests, only 37.9% completed successfully while 62.1% failed
- **linear regression**: Out of 8,100 total requests, 57.35% succeeded and 42.65% failed

These metrics suggest that while our configuration improvements have increased capacity, the system is still struggling with high-volume workloads, particularly for the more complex MongoDB-backed MobileNet action.

### Advanced Scaling Configuration

To further improve performance, we implemented a second round of more aggressive configuration changes:

1. **Enhanced System Limits** in `mycluster.yaml`:
   - Increased `concurrentInvocations` from 100 to 200
   - Increased `throughput` from 100 to 200
   - Increased `actionsInvokesPerminute` from 600 to 1200
   - Increased `actionsInvokesConcurrent` from 100 to 200
   - Increased `triggersFiresPerminute` from 600 to 1200
   - Doubled container pool memory (`userMemory`) from 16GB to 32GB

2. **Additional Horizontal Scaling**:
   - Increased controller replicas from 2 to 3
   - Increased invoker replicas from 2 to 3

3. **Enhanced Invoker Resources**:
   - Doubled JVM heap memory from 2048MB to 4096MB

These enhancements represent a significant increase in system capacity, doubling most of the key limits and adding 50% more processing capacity through additional controller and invoker instances.

### Advanced Scaling Configuration Results

After implementing the advanced scaling configuration:

- **mobilenet-mongo**: Out of 8,100 concurrent users:
  - 6,414 requests completed successfully
  - 1,686 requests failed
  - 79.19% success rate

- **linear regression**: Out of 8,100 concurrent users:
  - 8,043 requests completed successfully
  - 57 requests failed
  - 99.3% success rate

This represents a significant improvement over the previous configuration, with the success rate more than doubling from 37.9% to 79.19% for the complex mobilenet-mongo action and increasing from 57.35% to 99.3% for the linear regression action.

## Summary of Performance Improvements

Our load testing and configuration optimization journey shows dramatic improvements in OpenWhisk's ability to handle high-concurrency workloads:

| Configuration   | mobilenet-mongo Success | linear regression Success |
|-----------------|-------------------------|---------------------------|
| Default         | 3.68% (298/8100)        | 3.53% (286/8100)          |
| First Optimized | 37.9% (3070/8100)       | 57.35% (4645/8100)        |
| Advanced        | 79.19% (6414/8100)      | 99.3% (8043/8100)         |

These results demonstrate that proper configuration is critical for OpenWhisk deployments running ML workloads at scale. The most significant improvements came from:

1. Increasing concurrent invocation limits
2. Adding more processing capacity (controllers and invokers)
3. Allocating more memory for container pools
4. Extending action timeouts for complex operations
5. Optimizing the blackbox-fraction for Docker actions


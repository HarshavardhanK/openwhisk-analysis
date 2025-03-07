/**
 * OpenWhisk Action to check Prometheus and Grafana deployment status
 * and generate some metrics for demonstration purposes
 */

const https = require('https');
const http = require('http');

/**
 * Main function for the OpenWhisk action
 * 
 * @param {Object} params Action parameters
 * @param {string} params.minikubeIp The Minikube IP address (defaults to 192.168.49.2)
 * @param {number} params.iterations Number of iterations to generate load (defaults to 10)
 * @returns {Object} Information about the monitoring deployment
 */
function main(params) {
    // Set defaults if not provided
    const minikubeIp = params.minikubeIp || '192.168.49.2';
    const iterations = params.iterations || 10;
    
    // Generate some CPU and memory load for demonstration
    generateLoad(iterations);
    
    // Build the response with monitoring URLs
    const response = {
        message: "Monitoring Demo Action Executed Successfully",
        prometheus: {
            url: `http://${minikubeIp}:30900`,
            queries: [
                `http://${minikubeIp}:30900/api/v1/query?query=up`,
                `http://${minikubeIp}:30900/api/v1/query?query=container_memory_usage_bytes{namespace="openwhisk"}`,
                `http://${minikubeIp}:30900/api/v1/query?query=rate(container_cpu_usage_seconds_total{namespace="openwhisk"}[5m])`
            ]
        },
        grafana: {
            url: `http://${minikubeIp}:30300`,
            defaultCredentials: {
                username: "admin",
                password: "Get from: kubectl get secret -n openwhisk grafana -o jsonpath='{.data.admin-password}' | base64 --decode"
            }
        },
        timestamp: new Date().toISOString(),
        checkPrometheus: `curl -s http://${minikubeIp}:30900/api/v1/query?query=up | jq .`,
        checkGrafana: `curl -s http://${minikubeIp}:30300/api/health | jq .`,
        load_generated: {
            cpu: `${iterations} factorial calculations`,
            memory: `${iterations * 1024 * 1024} bytes allocated and released`
        }
    };
    
    return response;
}

/**
 * Generate some CPU and memory load for demonstration purposes
 * 
 * @param {number} iterations Number of iterations
 */
function generateLoad(iterations) {
    // Generate CPU load with factorial calculations
    for (let i = 0; i < iterations; i++) {
        factorial(20 + i % 10); // Calculate factorial of numbers between 20-29
    }
    
    // Generate memory load
    for (let i = 0; i < iterations; i++) {
        // Allocate and immediately release memory
        const buffer = Buffer.alloc(1024 * 1024); // 1MB
        buffer.fill(Math.random() * 255);
    }
}

/**
 * Calculate factorial of a number (CPU-intensive operation)
 * 
 * @param {number} n Number to calculate factorial for
 * @returns {number} Factorial result
 */
function factorial(n) {
    if (n === 0 || n === 1) return 1;
    return n * factorial(n - 1);
}

// Export the main function for OpenWhisk
exports.main = main;
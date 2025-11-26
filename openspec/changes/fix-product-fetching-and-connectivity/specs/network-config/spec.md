## ADDED Requirements

### Requirement: Environment-Based Backend URL Configuration
The Flutter app SHALL support multiple backend URL configurations for different deployment scenarios.

#### Scenario: Local network development
- **WHEN** app is configured for local development environment
- **THEN** backend base URL is set to `http://192.168.x.x:3000` (local IP)
- **AND** all API requests use this base URL

#### Scenario: Ngrok tunnel testing
- **WHEN** app is configured for ngrok environment
- **THEN** backend base URL is set to `https://<subdomain>.ngrok.io`
- **AND** all API requests use HTTPS tunnel URL

#### Scenario: Production cloud deployment
- **WHEN** app is configured for production environment
- **THEN** backend base URL is set to production URL (e.g., Vercel, Railway)
- **AND** all API requests use HTTPS production URL

### Requirement: Centralized API Configuration
The Flutter app SHALL use a single configuration class for all backend URLs and endpoints.

#### Scenario: Single source of truth
- **WHEN** any screen or service needs to make API request
- **THEN** URL is retrieved from `AppConfig.backendBaseUrl`
- **AND** no hardcoded IP addresses exist outside `AppConfig`

#### Scenario: Endpoint construction
- **WHEN** building full API URL
- **THEN** use `AppConfig.getFullUrl(endpoint)` helper method
- **AND** method concatenates base URL with endpoint path

### Requirement: Runtime Backend URL Selection
The Flutter app SHALL allow developers to change backend URL at runtime in debug builds.

#### Scenario: Environment switcher in settings
- **WHEN** user opens Settings screen in debug build
- **THEN** UI shows environment selector with options (Local, Ngrok, Production, Custom)
- **AND** selected environment is saved to persistent storage

#### Scenario: Custom URL entry
- **WHEN** user selects "Custom" environment
- **THEN** text field appears for manual URL entry
- **AND** entered URL is validated before saving

#### Scenario: Environment persistence
- **WHEN** user closes and reopens app
- **THEN** previously selected backend environment is restored
- **AND** app connects to correct backend automatically

### Requirement: HTTP Request Retry Logic
The Flutter app SHALL retry failed API requests with exponential backoff.

#### Scenario: Transient network failure
- **WHEN** API request fails with network error (timeout, connection refused)
- **THEN** app retries request after 1 second delay
- **AND** if second attempt fails, retries after 2 seconds
- **AND** if third attempt fails, retries after 4 seconds
- **AND** after 3 failed attempts, shows error to user

#### Scenario: Client error no retry
- **WHEN** API request fails with HTTP 4xx status code
- **THEN** app does NOT retry request
- **AND** immediately shows error message to user

#### Scenario: Server error with retry
- **WHEN** API request fails with HTTP 5xx status code
- **THEN** app retries request using exponential backoff
- **AND** shows "Retrying..." indicator during retry attempts

### Requirement: API Request Timeout Configuration
The Flutter app SHALL use appropriate timeout values for different network conditions.

#### Scenario: Standard API timeout
- **WHEN** making API request
- **THEN** request timeout is set to 10 seconds
- **AND** if no response within 10 seconds, request fails with timeout error

#### Scenario: Neon cold start timeout
- **WHEN** backend may experience database cold start
- **THEN** initial requests tolerate up to 15 second timeout
- **AND** subsequent requests use standard 10 second timeout

### Requirement: Network Error User Feedback
The Flutter app SHALL display specific, actionable error messages for different network failure scenarios.

#### Scenario: Connection timeout error
- **WHEN** API request times out
- **THEN** show error message "Connection timeout. Please check your internet connection and try again."

#### Scenario: Connection refused error
- **WHEN** backend server is not responding
- **THEN** show error message "Cannot reach server. Please check that backend is running at <URL>."

#### Scenario: Network unavailable error
- **WHEN** device has no internet connection
- **THEN** show error message "No internet connection. Please connect to WiFi or mobile data."

#### Scenario: Server error response
- **WHEN** backend returns HTTP 500 error
- **THEN** show error message "Server error. Please try again later."
- **AND** log full error details for debugging

### Requirement: Connection Status Indicator
The Flutter app SHALL indicate network connectivity status to users.

#### Scenario: Loading state during API request
- **WHEN** API request is in progress
- **THEN** show loading spinner or progress indicator
- **AND** disable user interaction with relevant UI elements

#### Scenario: Retry attempt indication
- **WHEN** retrying failed request
- **THEN** show "Retrying connection..." message
- **AND** display retry attempt count (e.g., "Attempt 2 of 3")

#### Scenario: Offline mode detection
- **WHEN** device loses internet connectivity
- **THEN** show banner message "You are offline. Some features may not work."
- **AND** automatically hide banner when connectivity restored

### Requirement: Backend Accessibility Verification
The backend SHALL be accessible from devices not connected via USB debugging.

#### Scenario: Physical device on same network
- **WHEN** physical device is connected to same WiFi as backend server
- **THEN** device can reach backend at local IP address
- **AND** all API endpoints respond successfully

#### Scenario: Device on external network via ngrok
- **WHEN** device uses ngrok tunnel URL
- **THEN** device can reach backend over internet
- **AND** HTTPS tunnel works for all requests

#### Scenario: Backend listens on all interfaces
- **WHEN** backend server starts
- **THEN** server binds to `0.0.0.0` (all network interfaces)
- **AND** accepts connections from any IP address on network

# Requester: Swift Networking Layer

## Overview
`Requester` is an advanced, versatile networking layer designed for iOS, aimed at simplifying and optimizing the networking experience for developers. It incorporates a multitude of features, focusing on efficiency, convenience, and reusability. It enables seamless communication with various backends while offering robust functionality to manage and monitor network activities effortlessly.

## Key Features

### **Piggybacking**
   - Leverages concurrent requests efficiently by automatically attaching multiple (equal, based on path/parameters etc.) calls to a single one, reducing redundant calls and improving performance.

### **Automated Token Refresh Mechanism**
   - Handles token refreshes automatically, responding to user-specified backend responses with a token refresh.
   - Queues up all other calls to the same backend to await the new token, optimizing request handling.
   - Token refreshes are unnoticable from a requester perspective, i.e. if you perform a request and it needs a token refresh, you won't notice this and simply receive your response after the token refresh was internally handled.

### **In-Memory Caching**
   - Offers an ultra-fast, groupable, on-memory caching mechanism to store and retrieve (mapped) data promptly.
   - Cache can be cleared by group, or in full, or bypassed by simply providing no cacheLifetime when requesting.

### **Real-Time Network Activity Monitoring, Overlays & Descriptive Error Logging**
   - Provides a shake gesture triggered detailed network log, containing descriptive error logging, enhancing debugging capabilities. Errors thrown by you in the mapping phase are also visible in this logging.
   - Provides an always visible overlay showing calls as they happen to spot bottlenecks in pageloads. (can be enabled in the shake gesture overlay with the toggle at the top)
   - This feature is also very useful when sharing pre-release builds with customer, where you would typically enable the overlay, which then in turn can help you debug issues on client devices when you can't attach a debugger.
   - This feature is manually enabled (I recommend only doing it in **non app-store builds**)

### **Async/Await**
   - Integrates asynchronous programming to handle tasks more intuitively and concisely, improving code readability and maintainability.

### **SSL Pinning**
   - Enhances security by validating SSL certificates, mitigating man-in-the-middle attacks.

### **Backend Based Structure**
   - Promotes a backend-based file structure, inviting modules with requests, entities, and other logic per backend.
   - Enables the reuse of token refreshing, authentication, and processing logic per backend, ensuring consistency and reliability.

### **User-Friendly**
   - Designed to be straightforward and easy to use, with high reusability, allowing you to focus on the important parts of your code instead of copy pasting boilerplate.

## Usage
```swift
// TODO: Example code
```

## Demo Application
TODO

## Changelog
1.0.5
- Changed cachingGroups to work with Set<AnyHashable>, to make the syntax for using it more flexible and less cluttered.
- Added original APIRequest to Authenticator.shouldRefreshToken, to give more information to respond adequately.

## Author
Kevin van den Hoek

## License
TODO: MIT?

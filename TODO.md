# Midtrans Snap Error Logging Implementation

## Task: Add logging to identify "snap cannot be opened" error

### Completed Tasks:
- [x] Added debug logging to NavigationDelegate callbacks (onPageStarted, onPageFinished, onNavigationRequest, onWebResourceError)
- [x] Enhanced JavaScript injection to check for window.snap availability
- [x] Added console logging in JavaScript for snap availability and payment events
- [x] Added special error handling for "Snap not available" case with detailed diagnostic information
- [x] Updated _handleJavaScriptMessage to provide comprehensive error logging

### Key Changes Made:
1. **NavigationDelegate Logging**: Added debugPrint statements to track webview loading states and errors
2. **JavaScript Snap Detection**: Added explicit check for window.snap object availability
3. **Console Logging**: Added detailed console.log statements in JavaScript for debugging
4. **Error Diagnostics**: Added specific error handling for snap unavailability with possible causes listed

### Expected Outcome:
When the "snap cannot be opened" error occurs, the logs will now show:
- Whether the Midtrans Snap JavaScript loaded properly
- Web resource errors if any
- Navigation issues
- Specific diagnostic messages for troubleshooting

### Next Steps:
- Test the payment flow to verify logging works
- Monitor console and debug logs during payment attempts
- Use the diagnostic information to identify root cause of snap loading issues

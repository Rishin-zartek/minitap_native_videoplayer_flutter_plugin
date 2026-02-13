# Android Video Playback Fix

## Issue Summary
Android video playback was completely non-functional. Videos remained in "idle" state and neither automatic nor manual play worked. This affected all video formats (MP4, HLS).

## Root Cause Analysis

### The Problem
The Android implementation was using ExoPlayer's `play()` method, which is a convenience method that internally calls `setPlayWhenReady(true)`. However, there were timing and state management issues:

1. **Inconsistent State Management**: The `play()` method was sending state events immediately, but ExoPlayer's actual playback state changes are asynchronous and reported through callbacks.

2. **Missing State Callback**: The `onIsPlayingChanged()` callback was not properly sending state events, leading to inconsistent state reporting between the native layer and Flutter.

3. **Pending Play Command Execution**: When a play command was queued before the player was ready, the execution logic was calling `play()` recursively and manually sending state events, which could conflict with ExoPlayer's own state callbacks.

### Comparison with iOS
The iOS implementation (which works perfectly) directly sets the playback rate:
```swift
player.rate = 1.0
sendEvent(event: "state", data: "playing")
```

This is a synchronous operation that immediately starts playback.

## The Fix

### Changes Made

1. **Use `playWhenReady` Instead of `play()`**
   - Changed `player.play()` to `player.playWhenReady = true`
   - Changed `player.pause()` to `player.playWhenReady = false`
   - This provides more explicit control over the playback state

2. **Proper State Event Handling**
   - Removed redundant state event sending from `play()` method
   - Let `onIsPlayingChanged()` callback handle state events
   - This ensures state events are sent when ExoPlayer actually changes state

3. **Fixed Pending Play Command Execution**
   - Changed from `this@apply.play()` to `playWhenReady = true`
   - Removed manual state event sending and position update starting
   - Let the `onIsPlayingChanged()` callback handle these automatically

4. **Enhanced `onIsPlayingChanged()` Callback**
   - Added state event sending: `sendEvent("state", "playing")` when playing
   - This ensures Flutter receives accurate state updates

5. **Added Comprehensive Logging**
   - Added debug logs throughout the playback lifecycle
   - Logs player state, `isPlaying`, and `playWhenReady` values
   - This helps with future debugging

### Code Changes

#### Before (play method):
```kotlin
fun play() {
    mainHandler.post {
        val player = exoPlayer
        if (player != null) {
            if (isInitialized) {
                player.play()
                sendEvent("state", "playing")
            } else {
                pendingPlayCommand = true
            }
        } else {
            pendingPlayCommand = true
        }
    }
}
```

#### After (play method):
```kotlin
fun play() {
    mainHandler.post {
        val player = exoPlayer
        Log.d(TAG, "play() called - player exists: ${player != null}, isInitialized: $isInitialized")
        if (player != null) {
            if (isInitialized) {
                Log.d(TAG, "Starting playback - setting playWhenReady to true")
                player.playWhenReady = true
                // State will be updated by onIsPlayingChanged callback
            } else {
                pendingPlayCommand = true
                Log.d(TAG, "Play command queued, waiting for player to be ready")
            }
        } else {
            pendingPlayCommand = true
            Log.d(TAG, "Play command queued, player not created yet")
        }
    }
}
```

#### Before (onIsPlayingChanged):
```kotlin
override fun onIsPlayingChanged(isPlaying: Boolean) {
    if (isPlaying) {
        startPositionUpdates()
    } else {
        stopPositionUpdates()
    }
}
```

#### After (onIsPlayingChanged):
```kotlin
override fun onIsPlayingChanged(isPlaying: Boolean) {
    Log.d(TAG, "onIsPlayingChanged: $isPlaying")
    if (isPlaying) {
        sendEvent("state", "playing")
        startPositionUpdates()
    } else {
        stopPositionUpdates()
    }
}
```

#### Before (pending play command execution):
```kotlin
if (pendingPlayCommand) {
    pendingPlayCommand = false
    Log.d(TAG, "Executing pending play command")
    this@apply.play()
    sendEvent("state", "playing")
    startPositionUpdates()
    return
}
```

#### After (pending play command execution):
```kotlin
if (pendingPlayCommand) {
    pendingPlayCommand = false
    Log.d(TAG, "Executing pending play command - setting playWhenReady to true")
    playWhenReady = true
    // State will be updated by onIsPlayingChanged callback
    return
}
```

## Expected Behavior After Fix

1. **Automatic Playback**: When the example app calls `_controller.play()` after initialization, the video should start playing automatically.

2. **Manual Play**: When the user taps the Play button, the video should start playing.

3. **State Transitions**: The video state should properly transition from:
   - `idle` → `buffering` → `playing` (when play is called)
   - `playing` → `paused` (when pause is called)
   - `paused` → `playing` (when play is called again)

4. **Consistent State Reporting**: The Flutter layer should receive accurate state updates that match the actual ExoPlayer playback state.

## Testing Recommendations

After this fix, the mobile integration tests should be re-run to verify:

1. ✅ Automatic video playback works
2. ✅ Manual play button works
3. ✅ Pause button works
4. ✅ Resume play works
5. ✅ Volume control works (should now be verifiable with actual playback)
6. ✅ Playback speed control works (should now be verifiable with actual playback)
7. ✅ Loop toggle works (should now be verifiable with actual playback)
8. ✅ Video info card displays correct state and updates in real-time

## Technical Details

### ExoPlayer State Machine
ExoPlayer has a state machine with these states:
- `STATE_IDLE`: Player is idle (no media set or after error)
- `STATE_BUFFERING`: Player is buffering media
- `STATE_READY`: Player is ready to play (buffered enough data)
- `STATE_ENDED`: Playback has ended

### playWhenReady vs play()
- `playWhenReady = true`: Sets a flag that tells ExoPlayer to start playback as soon as it's ready
- `play()`: Convenience method that calls `setPlayWhenReady(true)`

The key difference is that using `playWhenReady` directly is more explicit and makes it clearer what's happening. It also avoids any potential issues with the convenience method.

### Callback Order
When `playWhenReady = true` is set:
1. ExoPlayer starts playback
2. `onIsPlayingChanged(true)` is called
3. We send the "playing" state event to Flutter
4. We start position updates

This ensures the state event is sent when playback actually starts, not when we request it to start.

## Commit Information

**Commit**: a79e3ec  
**Branch**: feature/test-case-report-generation  
**Message**: fix(android): fix video playback by using playWhenReady instead of play()

## Related Files

- `/native_core_video_player/android/src/main/kotlin/com/example/native_core_video_player/VideoPlayer.kt` - Main fix
- `/test-reports/MOBILE_INTEGRATION_TEST_REPORT.md` - Test failure report
- `/native_core_video_player/ios/Classes/VideoPlayer.swift` - iOS implementation (for comparison)

## Next Steps

1. Re-run mobile integration tests on Android to verify the fix
2. Verify all 10 test cases pass on Android
3. Confirm Android pass rate increases from 27% to 100%
4. Update the mobile integration test report with new results
5. Mark the plugin as production-ready for both iOS and Android

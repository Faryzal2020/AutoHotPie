#!/usr/bin/env python3
"""
Analyze AutoHotPie debug log to find key press events without corresponding key release events.
This version properly handles timestamp differences and context matching.
"""

import re
from collections import defaultdict, deque

def analyze_log_file(log_file_path):
    """Analyze the log file for mismatched key press/release events."""
    
    key_presses = []
    key_releases = []
    
    # Regular expressions to match key events
    key_press_pattern = r'\[KEY_PRESS\] (\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) \| Key: "([^"]+)" \| Modifiers: "([^"]+)" \| Delay: (\d+)ms'
    key_release_pattern = r'\[KEY_RELEASE\] (\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) \| Key: "([^"]+)" \| Modifiers: "([^"]+)" \| Delay: (\d+)ms'
    
    print(f"Analyzing log file: {log_file_path}")
    print("=" * 80)
    
    with open(log_file_path, 'r', encoding='utf-8') as f:
        for line_num, line in enumerate(f, 1):
            # Check for key press events
            press_match = re.search(key_press_pattern, line)
            if press_match:
                timestamp, key, modifiers, delay = press_match.groups()
                key_presses.append({
                    'line': line_num,
                    'timestamp': timestamp,
                    'key': key,
                    'modifiers': modifiers,
                    'delay': int(delay)
                })
            
            # Check for key release events
            release_match = re.search(key_release_pattern, line)
            if release_match:
                timestamp, key, modifiers, delay = release_match.groups()
                key_releases.append({
                    'line': line_num,
                    'timestamp': timestamp,
                    'key': key,
                    'modifiers': modifiers,
                    'delay': int(delay)
                })
    
    print(f"Found {len(key_presses)} key press events")
    print(f"Found {len(key_releases)} key release events")
    print()
    
    # Sort both lists by timestamp for proper matching
    key_presses.sort(key=lambda x: x['timestamp'])
    key_releases.sort(key=lambda x: x['timestamp'])
    
    # Use a more intelligent matching algorithm
    # Match presses and releases that are close in time and have the same key/modifiers
    matched_presses = set()
    matched_releases = set()
    unmatched_presses = []
    unmatched_releases = []
    
    # Create a queue of releases to match against
    release_queue = deque(key_releases)
    
    for press in key_presses:
        matched = False
        
        # Look for a matching release in the queue
        for i, release in enumerate(release_queue):
            if (release['key'] == press['key'] and 
                release['modifiers'] == press['modifiers'] and
                release['line'] not in matched_releases):
                
                # Check if timestamps are close (within 2 seconds)
                press_time = parse_timestamp(press['timestamp'])
                release_time = parse_timestamp(release['timestamp'])
                time_diff = abs((release_time - press_time).total_seconds())
                
                if time_diff <= 2.0:  # Allow 2 second difference
                    matched_presses.add(press['line'])
                    matched_releases.add(release['line'])
                    # Remove the matched release from queue
                    release_queue.remove(release)
                    matched = True
                    break
        
        if not matched:
            unmatched_presses.append(press)
    
    # Any remaining releases are unmatched
    for release in release_queue:
        if release['line'] not in matched_releases:
            unmatched_releases.append(release)
    
    print("ANALYSIS RESULTS:")
    print("=" * 80)
    
    if unmatched_presses:
        print(f"❌ Found {len(unmatched_presses)} key press events WITHOUT corresponding releases:")
        print("-" * 60)
        for press in unmatched_presses:
            print(f"  Line {press['line']:4d} | {press['timestamp']} | Key: '{press['key']}' | Modifiers: '{press['modifiers']}' | Delay: {press['delay']}ms")
        print()
    else:
        print("✅ All key press events have corresponding key release events.")
        print()
    
    if unmatched_releases:
        print(f"❌ Found {len(unmatched_releases)} key release events WITHOUT corresponding presses:")
        print("-" * 60)
        for release in unmatched_releases:
            print(f"  Line {release['line']:4d} | {release['timestamp']} | Key: '{release['key']}' | Modifiers: '{release['modifiers']}' | Delay: {release['delay']}ms")
        print()
    else:
        print("✅ All key release events have corresponding key press events.")
        print()
    
    # Summary statistics
    print("SUMMARY:")
    print("=" * 80)
    print(f"Total key press events: {len(key_presses)}")
    print(f"Total key release events: {len(key_releases)}")
    print(f"Matched key presses: {len(matched_presses)}")
    print(f"Matched key releases: {len(matched_releases)}")
    print(f"Unmatched key presses: {len(unmatched_presses)}")
    print(f"Unmatched key releases: {len(unmatched_releases)}")
    
    if unmatched_presses or unmatched_releases:
        print("\n⚠️  WARNING: Found mismatched key events!")
        return False
    else:
        print("\n✅ All key events are properly matched!")
        return True

def parse_timestamp(timestamp_str):
    """Parse timestamp string to datetime object."""
    from datetime import datetime
    return datetime.strptime(timestamp_str, "%Y-%m-%d %H:%M:%S")

if __name__ == "__main__":
    log_file = "src/debug/autohotpie-debug-20250813195248-24744375.log"
    analyze_log_file(log_file)

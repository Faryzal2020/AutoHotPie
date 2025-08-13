#!/usr/bin/env python3
"""
Analyze AutoHotPie debug log to find key press events without corresponding key release events.
This version properly handles the actual log structure and context.
"""

import re
from collections import defaultdict

def analyze_log_file(log_file_path):
    """Analyze the log file for mismatched key press/release events."""
    
    print(f"Analyzing log file: {log_file_path}")
    print("=" * 80)
    
    # Read the entire file to analyze the structure
    with open(log_file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    # Find all key events with their context
    key_events = []
    
    for line_num, line in enumerate(lines, 1):
        # Check for key press events
        press_match = re.search(r'\[KEY_PRESS\] (\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) \| Key: "([^"]+)" \| Modifiers: "([^"]+)" \| Delay: (\d+)ms', line)
        if press_match:
            timestamp, key, modifiers, delay = press_match.groups()
            key_events.append({
                'line': line_num,
                'type': 'press',
                'timestamp': timestamp,
                'key': key,
                'modifiers': modifiers,
                'delay': int(delay)
            })
        
        # Check for key release events
        release_match = re.search(r'\[KEY_RELEASE\] (\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) \| Key: "([^"]+)" \| Modifiers: "([^"]+)" \| Delay: (\d+)ms', line)
        if release_match:
            timestamp, key, modifiers, delay = release_match.groups()
            key_events.append({
                'line': line_num,
                'type': 'release',
                'timestamp': timestamp,
                'key': key,
                'modifiers': modifiers,
                'delay': int(delay)
            })
    
    print(f"Found {len(key_events)} total key events")
    
    # Group events by key sequence context
    # Look for patterns where presses and releases are properly paired
    unmatched_presses = []
    unmatched_releases = []
    
    # Create a simple matching algorithm based on proximity and same key/modifiers
    i = 0
    while i < len(key_events):
        event = key_events[i]
        
        if event['type'] == 'press':
            # Look for a matching release within the next few events
            matched = False
            for j in range(i + 1, min(i + 10, len(key_events))):  # Look ahead up to 10 events
                next_event = key_events[j]
                if (next_event['type'] == 'release' and 
                    next_event['key'] == event['key'] and 
                    next_event['modifiers'] == event['modifiers']):
                    # Mark both as matched
                    event['matched'] = True
                    next_event['matched'] = True
                    matched = True
                    break
            
            if not matched:
                unmatched_presses.append(event)
        
        i += 1
    
    # Find any unmatched releases
    for event in key_events:
        if event['type'] == 'release' and not event.get('matched', False):
            unmatched_releases.append(event)
    
    # Count matched events
    matched_presses = len([e for e in key_events if e['type'] == 'press' and e.get('matched', False)])
    matched_releases = len([e for e in key_events if e['type'] == 'release' and e.get('matched', False)])
    
    print("\nANALYSIS RESULTS:")
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
    total_presses = len([e for e in key_events if e['type'] == 'press'])
    total_releases = len([e for e in key_events if e['type'] == 'release'])
    print(f"Total key press events: {total_presses}")
    print(f"Total key release events: {total_releases}")
    print(f"Matched key presses: {matched_presses}")
    print(f"Matched key releases: {matched_releases}")
    print(f"Unmatched key presses: {len(unmatched_presses)}")
    print(f"Unmatched key releases: {len(unmatched_releases)}")
    
    if unmatched_presses or unmatched_releases:
        print("\n⚠️  WARNING: Found mismatched key events!")
        return False
    else:
        print("\n✅ All key events are properly matched!")
        return True

if __name__ == "__main__":
    log_file = "src/debug/autohotpie-debug-20250813195248-24744375.log"
    analyze_log_file(log_file)

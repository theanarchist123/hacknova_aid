# Emergency Siren Audio Files

This directory contains emergency siren audio files for the SOS Emergency Beacon System.

## File Formats Supported:
- siren_audio.mpeg (Primary)
- siren_audio.mp3 (Backup)
- siren_audio.wav (Fallback)
- emergency_beep.mp3 (System fallback)

## Usage:
These audio files are played in loop during emergency SOS activation to provide audible emergency signaling.

## Fallback Strategy:
1. Try .mpeg format first
2. Fallback to .mp3 format
3. Fallback to .wav format
4. Use emergency_beep.mp3 as system fallback
5. Use vibration pattern if all audio fails

## Note:
For a real deployment, replace these placeholder files with actual emergency siren audio recordings.

This file provides emergency audio alerts for the SOS Emergency Beacon Service.

Note: The SOS service will work without this file but will use fallback alert systems.
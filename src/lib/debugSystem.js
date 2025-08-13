// AutoHotPie Debug System Controller
// This module provides comprehensive logging functionality for debugging pie menu operations

// Check if we're in Electron renderer context
let ipcRenderer, path, fs;

try {
    if (typeof require !== 'undefined') {
        ipcRenderer = require('electron').ipcRenderer;
        path = require('path');
        fs = require('fs');
    }
} catch (error) {
    console.warn('Debug System: Node.js modules not available, using fallback methods');
}

class DebugSystem {
    constructor() {
        this.enabled = false;
        this.logBuffer = [];
        this.bufferSize = 100;
        this.logFilePath = null;
        this.lastTimestamp = Date.now();
        this.settings = {
            enabled: false,
            logLevel: 'DEBUG',
            bufferSize: 100,
            maxFileSize: '10MB'
        };
        
        this.initialize();
    }

    initialize() {
        try {
            // Get user data folder from main process
            this.logFilePath = this.getLogFilePath();
            this.createLogDirectory();
            this.loadSettings();
            
            // Set up process exit handler
            window.addEventListener('beforeunload', () => {
                this.flushBuffer();
            });
            
            console.log('Debug System initialized successfully');
        } catch (error) {
            console.error('Failed to initialize Debug System:', error);
        }
    }

    getLogFilePath() {
        try {
            // Check if required modules are available
            if (!ipcRenderer || !path) {
                console.warn('Debug System: Required modules not available, using fallback path');
                return 'debug.log';
            }
            
            // Get executable directory from main process (same directory as PieMenu.exe)
            const executableDir = ipcRenderer.sendSync('getExecutableDir');
            const debugDir = path.join(executableDir, 'debug');
            const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
            return path.join(debugDir, `autohotpie-debug-${timestamp}.log`);
        } catch (error) {
            console.error('Failed to get log file path:', error);
            // Fallback to current directory
            return 'debug.log';
        }
    }

    createLogDirectory() {
        try {
            // Check if fs module is available
            if (!fs) {
                console.warn('Debug System: fs module not available, skipping directory creation');
                return;
            }
            
            const debugDir = path.dirname(this.logFilePath);
            if (!fs.existsSync(debugDir)) {
                fs.mkdirSync(debugDir, { recursive: true });
            }
        } catch (error) {
            console.error('Failed to create debug directory:', error);
        }
    }

    loadSettings() {
        try {
            // Load settings from AutoHotPieSettings if available
            if (typeof AutoHotPieSettings !== 'undefined' && AutoHotPieSettings.global) {
                if (!AutoHotPieSettings.global.debugSystem) {
                    AutoHotPieSettings.global.debugSystem = this.settings;
                } else {
                    this.settings = { ...this.settings, ...AutoHotPieSettings.global.debugSystem };
                }
                this.enabled = this.settings.enabled;
            }
        } catch (error) {
            console.error('Failed to load debug settings:', error);
        }
    }

    saveSettings() {
        try {
            if (typeof AutoHotPieSettings !== 'undefined' && AutoHotPieSettings.global) {
                AutoHotPieSettings.global.debugSystem = this.settings;
                // Save to file if JSONFile is available
                if (typeof JSONFile !== 'undefined' && typeof SettingsFileName !== 'undefined') {
                    JSONFile.save(SettingsFileName, AutoHotPieSettings);
                }
            }
        } catch (error) {
            console.error('Failed to save debug settings:', error);
        }
    }

    enable() {
        this.enabled = true;
        this.settings.enabled = true;
        this.saveSettings();
        // Use console.log directly to avoid recursion
        console.log('[INFO] Debug logging enabled');
    }

    disable() {
        this.enabled = false;
        this.settings.enabled = false;
        this.saveSettings();
        // Use console.log directly to avoid recursion
        console.log('[INFO] Debug logging disabled');
        this.flushBuffer();
    }

    isEnabled() {
        return this.enabled;
    }

    log(level, message, context = {}) {
        if (!this.enabled) return;

        const timestamp = new Date().toISOString();
        const delay = Date.now() - this.lastTimestamp;
        this.lastTimestamp = Date.now();

        const logEntry = {
            timestamp,
            level,
            message,
            context,
            delay: `${delay}ms`
        };

        this.logBuffer.push(logEntry);
        
        // Flush buffer if it's full
        if (this.logBuffer.length >= this.bufferSize) {
            this.flushBuffer();
        }

        // Also log to console for immediate feedback
        console.log(`[${level}] ${message}`, context);
    }

    logFunctionCall(functionName, parameters, context = {}) {
        if (!this.enabled) return;

        this.log('FUNCTION_CALL', `Function: ${functionName}`, {
            function: functionName,
            parameters: parameters,
            ...context
        });
    }

    logKeyPress(key, modifiers = '', context = {}) {
        if (!this.enabled) return;

        this.log('KEY_PRESS', `Key: "${key}" | Modifiers: "${modifiers}"`, {
            key: key,
            modifiers: modifiers,
            ...context
        });
    }

    logKeyRelease(key, modifiers = '', context = {}) {
        if (!this.enabled) return;

        this.log('KEY_RELEASE', `Key: "${key}" | Modifiers: "${modifiers}"`, {
            key: key,
            modifiers: modifiers,
            ...context
        });
    }

    logModifierPress(modifier, context = {}) {
        if (!this.enabled) return;

        this.log('MODIFIER_PRESS', `Modifier: "${modifier}"`, {
            modifier: modifier,
            ...context
        });
    }

    logModifierRelease(modifier, context = {}) {
        if (!this.enabled) return;

        this.log('MODIFIER_RELEASE', `Modifier: "${modifier}"`, {
            modifier: modifier,
            ...context
        });
    }

    logSleep(duration, reason = '', context = {}) {
        if (!this.enabled) return;

        this.log('SLEEP', `Duration: ${duration}ms | Reason: "${reason}"`, {
            duration: duration,
            reason: reason,
            ...context
        });
    }

    logError(error, context = {}) {
        if (!this.enabled) return;

        this.log('ERROR', `Error: ${error.message || error}`, {
            error: error.message || error,
            stack: error.stack,
            ...context
        });
    }

    flushBuffer() {
        if (this.logBuffer.length === 0) return;

        try {
            // Check if fs module is available
            if (!fs) {
                console.warn('Debug System: fs module not available, cannot write to file');
                // Still clear the buffer to prevent memory issues
                this.logBuffer = [];
                return;
            }
            
            const logContent = this.logBuffer.map(entry => {
                const { timestamp, level, message, context, delay } = entry;
                let logLine = `[${level}] ${timestamp} | ${message} | Delay: ${delay}`;
                
                if (Object.keys(context).length > 0) {
                    logLine += `\nContext: ${JSON.stringify(context, null, 2)}`;
                }
                
                return logLine;
            }).join('\n\n') + '\n\n';

            fs.appendFileSync(this.logFilePath, logContent, 'utf8');
            this.logBuffer = [];
        } catch (error) {
            console.error('Failed to flush debug buffer:', error);
        }
    }

    getLogFilePath() {
        return this.logFilePath;
    }

    clearLog() {
        try {
            // Check if fs module is available
            if (!fs) {
                console.warn('Debug System: fs module not available, cannot clear log file');
                return false;
            }
            
            if (fs.existsSync(this.logFilePath)) {
                fs.writeFileSync(this.logFilePath, '', 'utf8');
                // Use console.log directly to avoid recursion
                console.log('[INFO] Log file cleared');
                return true;
            }
            return false;
        } catch (error) {
            console.error('Failed to clear log file:', error);
            return false;
        }
    }

    getLogContent() {
        try {
            // Check if fs module is available
            if (!fs) {
                console.warn('Debug System: fs module not available, cannot read log file');
                return 'Debug system is running in console-only mode. Log files are not available.';
            }
            
            if (fs.existsSync(this.logFilePath)) {
                return fs.readFileSync(this.logFilePath, 'utf8');
            }
            return '';
        } catch (error) {
            console.error('Failed to read log file:', error);
            return '';
        }
    }
}

// Create singleton instance
const debugSystem = new DebugSystem();

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = debugSystem;
} else {
    // Browser/Electron renderer context
    window.debugSystem = debugSystem;
}

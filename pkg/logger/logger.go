package logger

import (
	"log"
	"os"
)

// Logger wraps the standard logger with additional functionality
type Logger struct {
	*log.Logger
}

// New creates a new logger instance
func New(prefix string) *Logger {
	return &Logger{
		Logger: log.New(os.Stdout, prefix, log.LstdFlags|log.Lshortfile),
	}
}

// Info logs informational messages
func (l *Logger) Info(msg string) {
	l.Printf("[INFO] %s", msg)
}

// Error logs error messages
func (l *Logger) Error(msg string) {
	l.Printf("[ERROR] %s", msg)
}

// Debug logs debug messages
func (l *Logger) Debug(msg string) {
	l.Printf("[DEBUG] %s", msg)
}

// Warn logs warning messages
func (l *Logger) Warn(msg string) {
	l.Printf("[WARN] %s", msg)
}

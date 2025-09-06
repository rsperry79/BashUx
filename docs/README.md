# Bash-Logger

## Log Levels

The module supports standard syslog levels, from most to least severe:

| Level | Numeric Value | Function | Syslog Priority |
|-------|---------------|----------|----------------|
| EMERGENCY | 0 | `log_emergency` | emerg |
| ALERT | 1 | `log_alert` | alert |
| CRITICAL | 2 | `log_critical` | crit |
| ERROR | 3 | `log_error` | err |
| WARN | 4 | `log_warn` | warning |
| NOTICE | 5 | `log_notice` | notice |
| INFO | 6 | `log_info` | info |
| DEBUG | 7 | `log_debug` | debug |
| SENSITIVE | - | `log_sensitive` | (not sent to syslog) |

Messages with a level lower than the current log level are suppressed.

Sensitive messages are logged at the INFO level but are not written to log files or the journal. They are only displayed on the console.

## Inspiration aka credits due

<https://gist.github.com/GingerGraham/99af97eed2cd89cd047a2088947a5405>
<https://github.com/Zordrak/bashlog>
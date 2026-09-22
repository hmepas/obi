import Foundation

/// Services handed to every widget. Rebuilt wholesale on reload / theme change.
final class Context {
    let config: Config
    let theme: Theme
    let yabai: YabaiStore
    let scheduler: Scheduler
    let shell: Shell
    let events: Events
    let log: Log

    init(config: Config, theme: Theme, yabai: YabaiStore, scheduler: Scheduler, shell: Shell, events: Events, log: Log) {
        self.config = config
        self.theme = theme
        self.yabai = yabai
        self.scheduler = scheduler
        self.shell = shell
        self.events = events
        self.log = log
    }
}

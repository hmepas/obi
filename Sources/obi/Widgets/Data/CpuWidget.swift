import Darwin
import Foundation

/// User CPU % from host_processor_info deltas. Hidden below threshold. Click opens Activity Monitor.
final class CpuWidget: PollingWidget<Int> {
    override var interval: TimeInterval { 2 }
    private var previous: [UInt32]?
    private var threshold = 50

    override func configure() {
        threshold = ctx.config.section("widgets.cpu").int("threshold", 50)
        pill.setSymbol("cpu")
        pill.onClick = { [weak self] _ in self?.ctx.shell.open(app: "Activity Monitor") }
    }

    override func fetch() throws -> Int {
        var cpuCount: natural_t = 0
        var info: processor_info_array_t?
        var infoCount: mach_msg_type_number_t = 0
        let kr = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &cpuCount, &info, &infoCount)
        guard kr == KERN_SUCCESS, let info else { throw Failure("host_processor_info: \(kr)") }
        defer {
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: info), vm_size_t(infoCount) * vm_size_t(MemoryLayout<integer_t>.size))
        }
        let ticks = (0..<Int(infoCount)).map { UInt32(bitPattern: info[$0]) }
        defer { previous = ticks }
        guard let prev = previous, prev.count == ticks.count else { return 0 }
        let states = Int(CPU_STATE_MAX)
        var user: UInt64 = 0, total: UInt64 = 0
        for cpu in 0..<Int(cpuCount) {
            let base = cpu * states
            for s in 0..<states {
                let delta = UInt64(ticks[base + s] &- prev[base + s])
                total += delta
                if s == Int(CPU_STATE_USER) { user += delta }
            }
        }
        return total == 0 ? 0 : Int(user * 100 / total)
    }

    override func render(_ model: Int) {
        pill.text = "\(model)%"
        pill.isHidden = model < threshold
    }
}

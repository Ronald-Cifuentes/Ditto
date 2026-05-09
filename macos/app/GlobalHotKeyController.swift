import Carbon
import Foundation

final class GlobalHotKeyController {
    static let shared = GlobalHotKeyController()

    var action: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private let signature = fourCharCode("Dito")
    private let hotKeyID = UInt32(1)

    private init() {}

    func register() throws {
        unregister()
        try installHandlerIfNeeded()

        let eventHotKeyID = EventHotKeyID(signature: signature, id: hotKeyID)
        let status = RegisterEventHotKey(
            UInt32(kVK_ANSI_V),
            UInt32(cmdKey | optionKey),
            eventHotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard status == noErr else {
            hotKeyRef = nil
            throw NSError(
                domain: "DittoMac.HotKey",
                code: Int(status),
                userInfo: [NSLocalizedDescriptionKey: "Command-Option-V could not be registered"]
            )
        }
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }

    private func installHandlerIfNeeded() throws {
        guard handlerRef == nil else {
            return
        }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ in
                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                guard status == noErr else {
                    return status
                }

                let controller = GlobalHotKeyController.shared
                if hotKeyID.signature == controller.signature && hotKeyID.id == controller.hotKeyID {
                    DispatchQueue.main.async {
                        controller.action?()
                    }
                    return noErr
                }

                return OSStatus(eventNotHandledErr)
            },
            1,
            &eventType,
            nil,
            &handlerRef
        )

        guard status == noErr else {
            throw NSError(
                domain: "DittoMac.HotKey",
                code: Int(status),
                userInfo: [NSLocalizedDescriptionKey: "global hotkey event handler could not be installed"]
            )
        }
    }
}

private func fourCharCode(_ value: String) -> OSType {
    var result: OSType = 0
    for scalar in value.unicodeScalars.prefix(4) {
        result = (result << 8) + OSType(scalar.value)
    }
    return result
}

//
//  FileManager.swift
//  Charon
//
//  Created by Zachary Bonner on 3/8/25.
//

import Foundation

import Foundation

class FileMonitor {
    private var eventStream: FSEventStreamRef?
    private let monitoredPath: String
    private let eventCallback: (String) -> Void

    init(path: String, callback: @escaping (String) -> Void) {
        self.monitoredPath = path
        self.eventCallback = callback
        startMonitoring()
    }

    private func startMonitoring() {
        let callback: FSEventStreamCallback = { (
            streamRef: ConstFSEventStreamRef,
            clientCallBackInfo: UnsafeMutableRawPointer?,
            numEvents: Int,
            eventPaths: UnsafeMutableRawPointer,
            eventFlags: UnsafePointer<FSEventStreamEventFlags>,
            eventIds: UnsafePointer<FSEventStreamEventId>
        ) in
            guard let pathsPointer = UnsafeRawPointer(eventPaths)?.assumingMemoryBound(to: UnsafePointer<CChar>.self) else { return }
            
            let paths = UnsafeBufferPointer(start: pathsPointer, count: numEvents)
                .compactMap { String(cString: $0) }
            
            let fileMonitor = Unmanaged<FileMonitor>.fromOpaque(clientCallBackInfo!).takeUnretainedValue()
            for path in paths {
                var isDirectory: ObjCBool = false
                if FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory), isDirectory.boolValue {
                    print("📂 Ignoring directory change: \(path)")
                    continue
                }
                
                fileMonitor.eventCallback(path)
            }
        }

        var context = FSEventStreamContext(version: 0,
                                           info: Unmanaged.passUnretained(self).toOpaque(),
                                           retain: nil,
                                           release: nil,
                                           copyDescription: nil)

        eventStream = FSEventStreamCreate(
            kCFAllocatorDefault,
            callback,
            &context,
            [monitoredPath] as CFArray,
            FSEventsGetCurrentEventId(),
            1.0,
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents)
        )

        if let eventStream = eventStream {
            FSEventStreamScheduleWithRunLoop(eventStream, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
            FSEventStreamStart(eventStream)
        }
    }

    deinit {
        if let eventStream = eventStream {
            FSEventStreamStop(eventStream)
            FSEventStreamInvalidate(eventStream)
            FSEventStreamRelease(eventStream)
        }
    }
}

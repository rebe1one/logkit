// ConsoleEndpoints.swift
//
// Copyright (c) 2015, Justin Pawela & The LogKit Project (http://www.logkit.info/)
//
// Permission to use, copy, modify, and/or distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
// ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
// OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

import Foundation


private protocol LXConsoleWriter {
    func writeData(data: NSData) -> Void
}


public class LXConsoleEndpoint: LXEndpoint {
    public var minimumLogLevel: LXLogLevel
    public var dateFormatter: LXDateFormatter
    public var entryFormatter: LXEntryFormatter
    public let requiresNewlines: Bool = true

    private let writer: LXConsoleWriter

    public init(
        synchronous: Bool = true,
        minimumLogLevel: LXLogLevel = .All,
        dateFormatter: LXDateFormatter = LXDateFormatter.standardFormatter(),
        entryFormatter: LXEntryFormatter = LXEntryFormatter.standardFormatter()
    ) {
        self.minimumLogLevel = minimumLogLevel
        self.dateFormatter = dateFormatter
        self.entryFormatter = entryFormatter

        switch synchronous {
        case true:
            self.writer = LXSynchronousConsoleWriter()
        case false:
            self.writer = LXAsynchronousConsoleWriter()
        }
    }

    public func write(string: String) {
        guard let data = string.dataUsingEncoding(NSUTF8StringEncoding) else {
            assertionFailure("Failure to create data from entry string")
            return
        }
        self.writer.writeData(data)
    }

}


private class LXSynchronousConsoleWriter: LXConsoleWriter {
    private let stdoutHandle = NSFileHandle.fileHandleWithStandardOutput()

    deinit { self.stdoutHandle.closeFile() }

    private func writeData(data: NSData) {
        self.stdoutHandle.writeData(data)
    }

}


private class LXAsynchronousConsoleWriter: LXConsoleWriter {
    private func writeData(data: NSData) {
        guard let dispatchData = dispatch_data_create(data.bytes, data.length, nil, nil) else {
            assertionFailure("Failure to create data from entry string")
            return
        }
        dispatch_write(STDOUT_FILENO, dispatchData, LK_LOGKIT_QUEUE, { _, _ in })
    }

}

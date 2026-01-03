// REQUIRES: swift_feature_SafeInteropWrappers
// REQUIRES: std_span

// RUN: %empty-directory(%t)
// RUN: split-file %s %t
// RUN: %target-swift-frontend -emit-module -plugin-path %swift-plugin-dir -I %t/Inputs -enable-experimental-feature SafeInteropWrappers -cxx-interoperability-mode=default -Xcc -std=c++20 %t/test.swift -o %t/Test.swiftmodule -verify
// RUN: %target-swift-ide-test -plugin-path %swift-plugin-dir -I %t/Inputs -cxx-interoperability-mode=default -enable-experimental-feature SafeInteropWrappers -Xcc -std=c++20 -print-module -module-to-print=SpanNamespace -source-filename=x > %t/interface.txt
// RUN: %FileCheck %s < %t/interface.txt

//--- Inputs/module.modulemap
module SpanNamespace {
    header "span-namespace.h"
    requires cplusplus
}

//--- Inputs/span-namespace.h
#include <span>
#include <lifetimebound.h>

using SpanFloat = std::span<const float>;

namespace op {
  inline void takeSpan(SpanFloat buffer __noescape) {}
}

//--- test.swift
import SpanNamespace

// Test that we can call the safe wrapper for a namespaced std::span function
public func test() {
    let buffer: [Float] = [1.0, 2.0, 3.0]
    buffer.withUnsafeBufferPointer { ptr in
        let span = Span(ptr)
        op.takeSpan(span)
    }
}

// CHECK: enum op {
// CHECK:   static func takeSpan(_ buffer: SpanFloat)
// CHECK:   /// This is an auto-generated wrapper for safer interop
// CHECK:   @available(visionOS 1.0, tvOS 12.2, watchOS 5.2, iOS 12.2, macOS 10.14.4, *)
// CHECK:   @_alwaysEmitIntoClient @_disfavoredOverload public static func takeSpan(_ buffer: Span<Float>)
// CHECK: }

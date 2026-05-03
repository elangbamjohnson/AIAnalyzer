//
//  ClassInfo.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 25/04/26.
//
import Foundation

/// Represents structural information about a Swift class extracted during analysis.
public struct ClassInfo {
    
    public enum ClassType {
        case viewController
        case viewModel
        case service
        case model
        case unknown
    }
    
    /// Represents a member and its approximate line range relative to the parent type.
    public struct MemberInfo {
        public let name: String
        public let startLine: Int
        public let endLine: Int
        
        public init(name: String, startLine: Int, endLine: Int) {
            self.name = name
            self.startLine = startLine
            self.endLine = endLine
        }
    }
    
    public let type: ClassType
    
    /// The name of the class.
    public let name: String
    
    /// The number of methods defined within the class.
    public let methodCount: Int
    
    /// The number of properties (variables) defined within the class.
    public let propertyCount: Int
    
    /// The number of initializer declarations in the type.
    public let initializerCount: Int
    
    /// The number of subscript declarations in the type.
    public let subscriptCount: Int
    
    /// The number of accessors (computed property getters/setters) present.
    public let accessorCount: Int
    
    /// The total number of lines in the class declaration block.
    public let lineCount: Int
    
    /// Approximate member ranges (relative to the start of the type block).
    public let memberInfos: [MemberInfo]
    
    /// Initializes a new ClassInfo instance with the provided metrics.
    /// Backwards-compatible initializer: new parameters have sensible defaults so existing call sites do not break.
    /// - Parameters:
    ///   - type: The architectural type of the class.
    ///   - name: The class name.
    ///   - methodCount: Count of methods.
    ///   - propertyCount: Count of properties.
    ///   - lineCount: Count of lines.
    ///   - initializerCount: Count of init declarations.
    ///   - subscriptCount: Count of subscript declarations.
    ///   - accessorCount: Count of accessors (computed properties).
    ///   - memberInfos: Per-member approximate ranges.
    public init(
        type: ClassType = .unknown,
        name: String,
        methodCount: Int,
        propertyCount: Int,
        lineCount: Int,
        initializerCount: Int = 0,
        subscriptCount: Int = 0,
        accessorCount: Int = 0,
        memberInfos: [MemberInfo] = []
    ) {
        self.type = type
        self.name = name
        self.methodCount = methodCount
        self.propertyCount = propertyCount
        self.initializerCount = initializerCount
        self.subscriptCount = subscriptCount
        self.accessorCount = accessorCount
        self.lineCount = lineCount
        self.memberInfos = memberInfos
    }
}

//
//  ClassVisitor.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 25/04/26.
//
import Foundation
import SwiftSyntax

/// A syntax visitor that identifies class declarations and extracts structural metrics.
public class ClassVisitor: SyntaxVisitor {
    /// A collection of information about all classes encountered during the visit.
    public var classes: [ClassInfo] = []
    
    /// Module names imported in this file, pre-collected before the walk begins.
    /// Injected at init so the visitor doesn't have to depend on traversal ordering.
    private let fileImports: [String]
    
    /// - Parameter fileImports: List of module names already extracted from the file's
    ///   top-level import declarations. Defaults to empty for call sites that don't need
    ///   architectural analysis.
    public init(viewMode: SyntaxTreeViewMode, fileImports: [String] = []) {
        self.fileImports = fileImports
        super.init(viewMode: viewMode)
    }
    
    // MARK: - Type visitors
    
    /// Called when the visitor encounters a class declaration.
    /// - Parameter node: The syntax node representing the class declaration.
    /// - Returns: A kind indicating whether to continue visiting children.
    public override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        processType(name: node.identifier.text, members: node.members.members, node: node)
        return .visitChildren
    }
    
    public override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        processType(name: node.identifier.text, members: node.members.members, node: node)
        return .visitChildren
    }

    public override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        processType(name: node.identifier.text, members: node.members.members, node: node)
        return .visitChildren
    }

    public override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
        processType(name: node.identifier.text, members: node.members.members, node: node)
        return .visitChildren
    }

    public override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        let name = node.extendedType.description.trimmingCharacters(in: .whitespacesAndNewlines)
        processType(name: name, members: node.members.members, node: node)
        return .visitChildren
    }
    
    private func processType(name: String, members: MemberDeclListSyntax, node: SyntaxProtocol) {
        // Count methods defined in the class/struct (regular functions)
        let methods = members.compactMap { member in
            member.decl.as(FunctionDeclSyntax.self)
        }
        
        // Count individual property bindings (handles 'var a, b: Int')
        let properties = members.compactMap { member in
            member.decl.as(VariableDeclSyntax.self)
        }.flatMap { $0.bindings }.count
        
        // Count initializers, subscripts
        let initializers = members.compactMap { member in
            member.decl.as(InitializerDeclSyntax.self)
        }.count
        let subscripts = members.compactMap { member in
            member.decl.as(SubscriptDeclSyntax.self)
        }.count
        
        // Count accessors (computed property getters/setters) across bindings
        let accessorCount = members.compactMap { member in
            member.decl.as(VariableDeclSyntax.self)
        }.map { varDecl in
            varDecl.bindings.reduce(0) { acc, binding in
                let hasAccessor = (binding.accessor != nil)
                return acc + (hasAccessor ? 1 : 0)
            }
        }.reduce(0, +)
        
        // Estimate the number of lines in the type block by using the node description
        let lineCount = node.withoutLeadingTrivia().description.components(separatedBy: CharacterSet.newlines).count
        
        // Build approximate member ranges by iterating members and counting their description lines.
        var memberInfos: [ClassInfo.MemberInfo] = []
        var runningLine = 1
        for member in members {
            let declText = member.decl.withoutLeadingTrivia().description
            let memberLines = declText.components(separatedBy: CharacterSet.newlines).count
            // Determine a best-effort name for the member
            let memberName: String
            if let fn = member.decl.as(FunctionDeclSyntax.self) {
                memberName = fn.identifier.text
            } else if let vd = member.decl.as(VariableDeclSyntax.self), let firstBinding = vd.bindings.first {
                memberName = firstBinding.pattern.description.trimmingCharacters(in: .whitespacesAndNewlines)
            } else if member.decl.as(InitializerDeclSyntax.self) != nil {
                memberName = "init"
            } else if member.decl.as(SubscriptDeclSyntax.self) != nil {
                memberName = "subscript"
            } else {
                // fallback to a short representation
                let firstToken = member.decl.firstToken?.text ?? "member"
                memberName = String(firstToken)
            }
            
            let start = runningLine
            let end = max(runningLine, runningLine + memberLines - 1)
            memberInfos.append(ClassInfo.MemberInfo(name: memberName, startLine: start, endLine: end))
            runningLine += memberLines
        }
        
        let inheritedTypes = extractInheritedTypes(from: node)
        let type: ClassInfo.ClassType
        if inheritedTypes.contains(where: { $0 == "UIViewController" || $0 == "NSViewController" || $0 == "UIView" || $0 == "NSView" }) ||
            name.hasSuffix("ViewController") || name.hasSuffix("VC") {
            type = .viewController
        } else if inheritedTypes.contains(where: { $0 == "ObservableObject" }) ||
                    name.hasSuffix("ViewModel") || name.hasSuffix("VM") {
            type = .viewModel
        } else if name.hasSuffix("Service") || name.hasSuffix("Manager") {
            type = .service
        } else if name.hasSuffix("Model") {
            type = .model
        } else {
            type = .unknown
        }
        
        // Store the collected metrics (include new counts and member ranges)
        let info = ClassInfo(
            type: type,
            name: name,
            methodCount: methods.count,
            propertyCount: properties,
            lineCount: lineCount,
            initializerCount: initializers,
            subscriptCount: subscripts,
            accessorCount: accessorCount,
            memberInfos: memberInfos,
            imports: fileImports
        )
        
        classes.append(info)
    }
    
    private func extractInheritedTypes(from node: SyntaxProtocol) -> [String] {
        let rawTypes: [String]?
        if let classDecl = node.as(ClassDeclSyntax.self), let clause = classDecl.inheritanceClause {
            rawTypes = clause.inheritedTypeCollection.map { $0.typeName.description.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
        } else if let structDecl = node.as(StructDeclSyntax.self), let clause = structDecl.inheritanceClause {
            rawTypes = clause.inheritedTypeCollection.map { $0.typeName.description.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
        } else if let enumDecl = node.as(EnumDeclSyntax.self), let clause = enumDecl.inheritanceClause {
            rawTypes = clause.inheritedTypeCollection.map { $0.typeName.description.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
        } else if let actorDecl = node.as(ActorDeclSyntax.self), let clause = actorDecl.inheritanceClause {
            rawTypes = clause.inheritedTypeCollection.map { $0.typeName.description.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
        } else if let extDecl = node.as(ExtensionDeclSyntax.self), let clause = extDecl.inheritanceClause {
            rawTypes = clause.inheritedTypeCollection.map { $0.typeName.description.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
        } else {
            rawTypes = nil
        }
        
        return rawTypes ?? []
    }
}

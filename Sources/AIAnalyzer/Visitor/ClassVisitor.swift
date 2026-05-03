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
        
        // Determine the type based on naming conventions (unchanged)
        let nameLower = name.lowercased()
        let type: ClassInfo.ClassType
        if nameLower.contains("viewcontroller") {
            type = .viewController
        } else if nameLower.contains("viewmodel") {
            type = .viewModel
        } else if nameLower.contains("service") || nameLower.contains("manager") {
            type = .service
        } else if nameLower.contains("model") {
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
            memberInfos: memberInfos
        )
        
        classes.append(info)
    }
}

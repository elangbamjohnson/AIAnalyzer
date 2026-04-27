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
        // Extract the class name
        let className = node.identifier.text
        
        // Count methods defined in the class
        let methods = node.members.members.compactMap { member in
            member.decl.as(FunctionDeclSyntax.self)
        }
        
        // Count individual property bindings (handles 'var a, b: Int')
        let properties = node.members.members.compactMap { member in
            member.decl.as(VariableDeclSyntax.self)
        }.flatMap { $0.bindings }.count
        
        // Estimate the number of lines, excluding leading trivia (license headers, etc.)
        let lineCount = node.withoutLeadingTrivia().description.components(separatedBy: CharacterSet.newlines).count
        
        // Determine the class type based on naming conventions
        let nameLower = className.lowercased()
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
        
        // Store the collected metrics
        let info = ClassInfo(
            type: type,
            name: className,
            methodCount: methods.count,
            propertyCount: properties,
            lineCount: lineCount
        )
        
        classes.append(info)
        
        return .visitChildren
    }
}

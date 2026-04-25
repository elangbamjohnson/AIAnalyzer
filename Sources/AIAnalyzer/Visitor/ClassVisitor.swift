//
//  ClassVisitor.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 25/04/26.
//
import Foundation
import SwiftSyntax

public class ClassVisitor: SyntaxVisitor {
    public var classes: [ClassInfo] = []
    
    public override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        let className = node.identifier.text
        
        let methods = node.members.members.compactMap { member in
            member.decl.as(FunctionDeclSyntax.self)
        }
        
        let properties = node.members.members.compactMap { member in
            member.decl.as(VariableDeclSyntax.self)
        }.flatMap { $0.bindings }.count
        
        let lineCount = node.description.components(separatedBy: .newlines).count
        
        let info = ClassInfo(
            name: className,
            methodCount: methods.count,
            propertyCount: properties,
            lineCount: lineCount
        )
        
        classes.append(info)
        
        return .visitChildren
    }
}

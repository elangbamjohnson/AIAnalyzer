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
        let className = node.name.text
        
        let methods = node.memberBlock.members.compactMap { member in
            member.decl.as(FunctionDeclSyntax.self)
        }
        
        let properties = node.memberBlock.members.compactMap { member in
            member.decl.as(VariableDeclSyntax.self)
        }
        
        let lineCount = node.description.components(separatedBy: .newlines).count
        
        let info = ClassInfo(
            name: className,
            methodCount: methods.count,
            propertyCount: properties.count,
            lineCount: lineCount
        )
        
        classes.append(info)
        
        return .visitChildren
    }
}

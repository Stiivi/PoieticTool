//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 04/07/2023.
//

@preconcurrency import ArgumentParser
import PoieticCore
import PoieticFlows

// TODO: Add option to use foreign object JSON representation
// TODO: Add option to use JSON attributes
// TODO: Add option to specify object ID

extension PoieticTool {
    struct Add: ParsableCommand {
        static let configuration
            = CommandConfiguration(
                commandName: "add",
                abstract: "Create a new node or an unstructured object",
                usage: """
Create a new node:

poietic add Stock name=account formula=100
poietic add Flow name=expenses formula=50
"""
            )

        @OptionGroup var options: Options

        @Argument(help: "Type of the object to be created")
        var typeName: String

        @Argument(help: "Attributes to be set in form 'attribute=value'")
        var attributeAssignments: [String] = []
        
        mutating func run() throws {
            let env = try ToolEnvironment(location: options.designLocation)
            let frame = env.design.createFrame(deriving: env.design.currentFrame)
            
            guard let type = FlowsMetamodel.objectType(name: typeName) else {
                throw ToolError.unknownObjectType(typeName)
            }

            let object: MutableObject
            
            switch type.structuralType {
            case .unstructured:
                object = frame.create(type)
            case .node:
                object = frame.create(type, structure: .node)
            default:
                throw ToolError.structuralTypeMismatch("node or unstructured",
                                                       type.structuralType.rawValue)
            }
            
            for item in attributeAssignments {
                guard let split = parseValueAssignment(item) else {
                    throw ToolError.invalidAttributeAssignment(item)
                }
                let (name, stringValue) = split
                try setAttributeFromString(object: object,
                                           attribute: name,
                                           string: stringValue)

            }

            try env.accept(frame)
            try env.close()

            print("Created node \(object.id)")
        }
    }
}

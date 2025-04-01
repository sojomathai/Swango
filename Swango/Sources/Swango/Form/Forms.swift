//
//  Forms.swift
//  Swango
//
/*  Created by sojo
 
## License

This project is available under a dual license:

- **GNU Affero General Public License v3.0 (AGPL-3.0)** for open source projects
- **Commercial License** for enterprise and commercial use

If you are using this software in a commercial or enterprise context, please contact us at info@techarm.ca to obtain a commercial license.
*/

import Foundation

/// Form validation protocol
public protocol FormValidator {
    /// Validate form data
    func validate(_ data: [String: String]) throws -> [String: Any]
}

/// Basic form implementation
open class Form: FormValidator {
    public struct Field {
        public let name: String
        public let required: Bool
        public let validators: [(String) -> Result<Any, Error>]
        
        public init(name: String, required: Bool = true, validators: [(String) -> Result<Any, Error>] = []) {
            self.name = name
            self.required = required
            self.validators = validators
        }
    }
    
    private let fields: [Field]
    
    public init(fields: [Field]) {
        self.fields = fields
    }
    
    open func validate(_ data: [String: String]) throws -> [String: Any] {
        var validatedData: [String: Any] = [:]
        var errors: [String: [String]] = [:]
        
        for field in fields {
            let value = data[field.name] ?? ""
            
            if field.required && value.isEmpty {
                errors[field.name] = ["This field is required"]
                continue
            }
            
            if !field.required && value.isEmpty {
                continue
            }
            
            // Apply all validators
            var fieldErrors: [String] = []
            var fieldValue: Any = value
            
            for validator in field.validators {
                let result = validator(value)
                switch result {
                case .success(let validValue):
                    fieldValue = validValue
                case .failure(let error):
                    fieldErrors.append(error.localizedDescription)
                }
            }
            
            if !fieldErrors.isEmpty {
                errors[field.name] = fieldErrors
            } else {
                validatedData[field.name] = fieldValue
            }
        }
        
        if !errors.isEmpty {
            throw SwangoError.invalidRequest("Form validation failed: \(errors)")
        }
        
        return validatedData
    }
}

/// Namespace for common validators
public enum Validators {
    /// Email validator
    public static func email(_ value: String) -> Result<Any, Error> {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        return emailPredicate.evaluate(with: value)
            ? .success(value)
            : .failure(NSError(domain: "Swango", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid email address"]))
    }
    
    /// Integer validator
    public static func integer(_ value: String) -> Result<Any, Error> {
        guard let intValue = Int(value) else {
            return .failure(NSError(domain: "Swango", code: 400, userInfo: [NSLocalizedDescriptionKey: "Must be an integer"]))
        }
        
        return .success(intValue)
    }
    
    /// Float validator
    public static func float(_ value: String) -> Result<Any, Error> {
        guard let floatValue = Float(value) else {
            return .failure(NSError(domain: "Swango", code: 400, userInfo: [NSLocalizedDescriptionKey: "Must be a number"]))
        }
        
        return .success(floatValue)
    }
    
    /// Min length validator
    public static func minLength(_ length: Int) -> (String) -> Result<Any, Error> {
        return { value in
            return value.count >= length
                ? .success(value)
                : .failure(NSError(domain: "Swango", code: 400, userInfo: [NSLocalizedDescriptionKey: "Must be at least \(length) characters"]))
        }
    }
    
    /// Max length validator
    public static func maxLength(_ length: Int) -> (String) -> Result<Any, Error> {
        return { value in
            return value.count <= length
                ? .success(value)
                : .failure(NSError(domain: "Swango", code: 400, userInfo: [NSLocalizedDescriptionKey: "Must be at most \(length) characters"]))
        }
    }
    
    /// Range validator for integers
    public static func range(_ min: Int, _ max: Int) -> (String) -> Result<Any, Error> {
        return { value in
            guard let intValue = Int(value) else {
                return .failure(NSError(domain: "Swango", code: 400, userInfo: [NSLocalizedDescriptionKey: "Must be an integer"]))
            }
            
            return (intValue >= min && intValue <= max)
                ? .success(intValue)
                : .failure(NSError(domain: "Swango", code: 400, userInfo: [NSLocalizedDescriptionKey: "Must be between \(min) and \(max)"]))
        }
    }
}

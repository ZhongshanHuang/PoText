import UIKit

// MARK: - PoAttributeContainer
@dynamicMemberLookup
struct PoAttributeContainer: @unchecked Sendable {
    private(set) var attributes : [NSAttributedString.Key : Any]

    subscript<T: PoAttributedStringKey>(_: T.Type) -> T.Value? {
        get { attributes[T.name] as? T.Value }
        set {
            if newValue is NSUnderlineStyle { // fix attributes
                attributes[T.name] = (newValue as? NSUnderlineStyle)?.rawValue
            } else {
                attributes[T.name] = newValue
            }
        }
    }

    subscript<K: PoAttributedStringKey>(dynamicMember keyPath: KeyPath<PoAttributeDynamicLookup, K>) -> K.Value? {
        get { self[K.self] }
        set { self[K.self] = newValue }
    }

    subscript<K: PoAttributedStringKey>(dynamicMember keyPath: KeyPath<PoAttributeDynamicLookup, K>) -> Builder<K> {
        return Builder(container: self)
    }

    struct Builder<T: PoAttributedStringKey>: Sendable {
        var container : PoAttributeContainer

        func callAsFunction(_ value: T.Value) -> PoAttributeContainer {
            var new = container
            new[T.self] = value
            return new
        }
    }

    init() {
        attributes = [:]
    }
    
    init(_ attributes: [NSAttributedString.Key : Any]) {
        self.attributes = attributes
    }
    
    init(attributes: [NSAttributedString.Key : Any] = [:]) {
        self.attributes = attributes
    }
    
}

// MARK: - AttributeContainer + merge
extension PoAttributeContainer {
    enum AttributeMergePolicy : Sendable {
        case keepNew
        case keepCurrent
    }
    
    mutating func merge(_ other: PoAttributeContainer, mergePolicy: PoAttributeContainer.AttributeMergePolicy = .keepNew) {
        self.attributes.merge(other.attributes) { v1, v2 in
            switch mergePolicy {
            case .keepNew:
                v2
            case .keepCurrent:
                v1
            }
        }
    }

    func merging(_ other: PoAttributeContainer, mergePolicy:  PoAttributeContainer.AttributeMergePolicy = .keepNew) -> PoAttributeContainer {
        var copy = self
        copy.merge(other, mergePolicy:  mergePolicy)
        return copy
    }
}


//
//  User.swift
//  Pace
//
//  Created by Yuntong Zhang on 16/3/19.
//  Copyright © 2019 nus.cs3217.pace. All rights reserved.
//

import Foundation
import RealmSwift

class User: IdentifiableObject {
    @objc dynamic var name: String = ""
    var favouriteRoutes = List<Route>()

    convenience init(name: String) {
        self.init()
        self.name = name
    }

    func addFavouriteRoute(_ route: Route) {
        favouriteRoutes.append(route)
    }

    // MARK: - Hashable
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name
    }
}
/*
class User: Hashable, FirestoreCodable {

    var docId: String?
    let name: String

    init(docId: String?, name: String) {
        self.docId = docId
        self.name = name
    }

    required convenience init?(docId: String, data: [String: Any]) {
        guard
            let name = data[FireDB.User.name] as? String
            else {
                return nil
        }
        self.init(docId: docId, name: name)
    }

    // MARK: - Hashable
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.docId == rhs.docId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(docId)
    }
}

extension User {
    func toFirestoreDoc() -> [String: Any] {
        return [
            FireDB.User.username: name
        ]
    }
}
 */

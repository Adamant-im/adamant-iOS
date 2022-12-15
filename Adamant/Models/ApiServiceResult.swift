//
//  ApiServiceResult.swift
//  Adamant
//
//  Created by Andrey Golubenko on 24.11.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

enum ApiServiceResult<T> {
    case success(T)
    case failure(ApiServiceError)
}

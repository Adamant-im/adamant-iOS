//
//  ApiServiceResult.swift
//  Adamant
//
//  Created by Andrey Golubenko on 24.11.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

typealias ApiServiceResult<Success> = Result<Success, ApiServiceError>
typealias FileApiServiceResult<Success> = Result<Success, FileManagerError>

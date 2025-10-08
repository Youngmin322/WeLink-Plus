//
//  ImageUtils.swift
//  WeLink
//
//  Created by Assistant on 10/1/25.
//

import UIKit

/// Safely converts image data to UIImage.
/// - Parameter data: Image data
/// - Returns: UIImage if decoding succeeds, otherwise nil
func decodeImage(from data: Data) -> UIImage? {
    UIImage(data: data)
}

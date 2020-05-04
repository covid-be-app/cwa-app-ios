//
//  NotificationName.swift
//  ENA
//
//  Created by Tikhonov, Aleksandr on 28.04.20.
//  Copyright © 2020 SAP SE. All rights reserved.
//

import Foundation

extension Notification.Name {
    static var isOnboardedDidChange                 = Notification.Name("isOnboardedDidChange")
    static var dateLastExposureDetectionDidChange   = Notification.Name("dateLastExposureDetectionDidChange")
    static var exposureDetectionSessionDidFail      = Notification.Name("exposureDetectionSessionDidFail")
}
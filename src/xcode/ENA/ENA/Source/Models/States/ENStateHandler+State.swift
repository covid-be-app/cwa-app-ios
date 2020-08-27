//
// Created by Hu, Hao on 08.06.20.
// Copyright (c) 2020 SAP SE. All rights reserved.
//

import Foundation
import ExposureNotification

extension ENStateHandler {
	enum State {
		/// Exposure Notification is enabled.
		case enabled
		/// Exposure Notification is disabled.
		case disabled
		/// Bluetooth is off.
		case bluetoothOff
		/// Restricted Mode due to parental controls.
		case restricted
		///Not authorized. The user declined consent in onboarding.
		case notAuthorized
		///The user was never asked the consent before, that's why unknown.
		case unknown

		// :BE: moved function so it can be used in different places
		static func determineCurrentState(from enManagerState: ExposureManagerState) -> State {
			switch enManagerState.status {
			case .active:
				return .enabled
			case .bluetoothOff:
				guard !enManagerState.enabled == false else {
					return .disabled
				}
				return .bluetoothOff
			case .disabled:
				return .disabled
			case .restricted:
				return differentiateRestrictedCase()
			case .unknown:
				return .disabled
			@unknown default:
				fatalError("New state was added that is not being covered by ENStateHandler")
			}
		}

		private static func differentiateRestrictedCase() -> State {
			switch ENManager.authorizationStatus {
			case .notAuthorized:
				return .notAuthorized
			case .restricted:
				return .restricted
			case .unknown:
				return .unknown
			case .authorized:
				return .disabled
			@unknown default:
				fatalError("New state was added that is not being covered by ENStateHandler")
			}
		}
	}
}

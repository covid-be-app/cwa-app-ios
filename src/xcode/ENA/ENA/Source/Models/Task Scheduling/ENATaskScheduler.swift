// Corona-Warn-App
//
// SAP SE and all other contributors
// copyright owners license this file to you under the Apache
// License, Version 2.0 (the "License"); you may not use this
// file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import BackgroundTasks
import ExposureNotification
import UIKit

enum ENATaskIdentifier: String, CaseIterable {
	// only one task identifier is allowed have the .exposure-notification suffix
	case exposureNotification = "exposure-notification"

	var backgroundTaskSchedulerIdentifier: String {
		guard let bundleID = Bundle.main.bundleIdentifier else { return "invalid-task-id!" }
		return "\(bundleID).\(rawValue)"
	}
}

protocol ENATaskExecutionDelegate: AnyObject {
	func executeENABackgroundTask(completion: @escaping ((Bool) -> Void))
}

/// - NOTE: To simulate the execution of a background task, use the following:
///         e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"be.sciensano.coronalertbe.exposure-notification"]
///         To simulate the expiration of a background task, use the following:
///         e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateExpirationForTaskWithIdentifier:@"be.sciensano.coronalertbe.exposure-notification"]
final class ENATaskScheduler {

	// MARK: - Static.

	static let shared = ENATaskScheduler()

	// MARK: - Attributes.

	weak var delegate: ENATaskExecutionDelegate?

	// MARK: - Initializer.

	private init() {
		if #available(iOS 13.0, *) {
			registerTask(with: .exposureNotification, execute: exposureNotificationTask(_:))
		}
	}

	// MARK: - Task registration.
	@available(iOS 13.0, *)
	private func registerTask(with taskIdentifier: ENATaskIdentifier, execute: @escaping ((BGTask) -> Void)) {
		let identifierString = taskIdentifier.backgroundTaskSchedulerIdentifier
		BGTaskScheduler.shared.register(forTaskWithIdentifier: identifierString, using: .main) { task in
			self.scheduleTask()
			let backgroundTask = DispatchWorkItem {
				execute(task)
			}

			task.expirationHandler = {
				self.scheduleTask()
				backgroundTask.cancel()
				logError(message: "Task has expired.")
				task.setTaskCompleted(success: false)
			}

			DispatchQueue.global().async(execute: backgroundTask)
		}
	}

	// MARK: - Task scheduling.

	@available(iOS 13.0, *)
	func scheduleTask() {
		do {
			ENATaskScheduler.scheduleDeadmanNotification()
			let taskRequest = BGProcessingTaskRequest(identifier: ENATaskIdentifier.exposureNotification.backgroundTaskSchedulerIdentifier)
			taskRequest.requiresNetworkConnectivity = true
			taskRequest.requiresExternalPower = false
			taskRequest.earliestBeginDate = nil
			try BGTaskScheduler.shared.submit(taskRequest)
		} catch {
			logError(message: "ERROR: scheduleTask() could NOT submit task request: \(error)")
		}
	}

	// MARK: - Task execution handlers.

	@available(iOS 13.0, *)
	private func exposureNotificationTask(_ task: BGTask) {
		delegate?.executeENABackgroundTask { success in
			task.setTaskCompleted(success: success)
		}
	}

	// MARK: - Deadman notifications.

	/// Schedules a local notification to fire 30 hours from now.
	/// In case the background execution fails  there will be a backup notification for the
	/// user to be notified to open the app. If everything runs smoothly,
	/// the current notification will always be moved to the future, thus never firing.
	static func scheduleDeadmanNotification() {
		let notificationCenter = UNUserNotificationCenter.current()

		let content = UNMutableNotificationContent()
		content.title = AppStrings.Common.deadmanAlertTitle
		content.body = AppStrings.Common.deadmanAlertBody
		content.sound = .default

		let trigger = UNTimeIntervalNotificationTrigger(
			timeInterval: 30 * 60 * 60,
			repeats: false
		)

		// bundleIdentifier is defined in Info.plist and can never be nil!
		guard let bundleID = Bundle.main.bundleIdentifier else {
			logError(message: "Could not access bundle identifier")
			return
		}

		let request = UNNotificationRequest(
			identifier: bundleID + ".notifications.cwa-deadman",
			content: content,
			trigger: trigger
		)

		notificationCenter.add(request) { error in
		   if error != nil {
			  logError(message: "Deadman notification could not be scheduled.")
		   }
		}
	}
	
	// :MARK: - Key upload reminders
	
	static let submitKeysNoficationIdentifier = ".notifications.cwa-uploadkeys"
	
	/// Schedule a notification to remind a user to upload their keys after a positive test result
	/// If notification already exists it is cancelled and pushed forward
	static func scheduleSubmitKeysReminder(store: Store) {
		
		// Do not keep harassing the user
		if store.submitKeysReminderCount >= 3 {
			log(message: "No longer scheduling submit keys reminder. User already had enough of those")
			return
		} else {
			log(message: "Reminder count \(store.submitKeysReminderCount)")

		}
		
		let notificationCenter = UNUserNotificationCenter.current()
		guard let bundleID = Bundle.main.bundleIdentifier else {
			logError(message: "Could not access bundle identifier")
			return
		}
		let identifier = bundleID + Self.submitKeysNoficationIdentifier
		
		Self.cancelSubmitKeysReminder { alreadyScheduled in
		
			// we consider it a new reminder only if we already showed it previously
			// a reschedule doesn't count as the user never received the notification
			if !alreadyScheduled {
				store.submitKeysReminderCount += 1
			}
			
			let content = UNMutableNotificationContent()
			content.title = AppStrings.LocalNotifications.testResultsTitle
			content.body = AppStrings.LocalNotifications.testResultsBody
			content.sound = .default

			// reminder in 6 hours
			var nextTriggerDate = Calendar.current.date(byAdding: .hour, value: 6, to: Date())!
			// test code
//			var nextTriggerDate = Calendar.current.date(byAdding: .second, value: 30, to: Date())!
			var comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: nextTriggerDate)
			
			// don't schedule at night
			
			if (comps.hour! >= 22) || (comps.hour! < 6) {
				nextTriggerDate = Calendar.current.date(byAdding: .hour, value: 8, to: nextTriggerDate)!
				comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: nextTriggerDate)
			}

			let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)


			let request = UNNotificationRequest(
				identifier: identifier,
				content: content,
				trigger: trigger
			)

			notificationCenter.add(request) { error in
			   if error != nil {
				  logError(message: "Reminder notification could not be scheduled.")
			   }
				log(message: "Reminder notification scheduled")
			}
		}
	}
	
	// completion will contain true if the notification was already scheduled and we removed it
	
	static func cancelSubmitKeysReminder(_ completion: @escaping (Bool) -> Void) {
		let notificationCenter = UNUserNotificationCenter.current()
		// bundleIdentifier is defined in Info.plist and can never be nil!
		guard let bundleID = Bundle.main.bundleIdentifier else {
			logError(message: "Could not access bundle identifier")
			return
		}
		let identifier = bundleID + Self.submitKeysNoficationIdentifier
		
		notificationCenter.getPendingNotificationRequests { requests in
			let request = requests.first{ request in
				return request.identifier == identifier
			}
			
			if request != nil {
				log(message: "Reminder notification already scheduled. Removing it.")
				notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
				
				completion(true)
				return
			}

			log(message: "Reminder notification was not scheduled so we do not need to remove it.")
			completion(false)
		}
	}
}

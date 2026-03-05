//
//  ShieldConfigurationExtension.swift
//  ShieldConfigurationExtension
//
//  Created by Yuen Lok Hei Kyle on 1/3/2026.
//

import ManagedSettings
import ManagedSettingsUI
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    private let messages = [
        "Stay focused on what matters!",
        "You're doing great! Keep going!",
        "Time to focus on your goals!",
        "This app is blocked for your productivity.",
        "Take a break and do something meaningful!",
        "Your future self will thank you!"
    ]

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: .white,
            icon: UIImage(systemName: "hand.raised.fill"),
            title: ShieldConfiguration.Label(
                text: "App Blocked",
                color: .black
            ),
            subtitle: ShieldConfiguration.Label(
                text: messages.randomElement() ?? messages[0],
                color: .gray
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "OK",
                color: .white
            ),
            primaryButtonBackgroundColor: .systemBlue,
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Take a 5-min break instead",
                color: .systemBlue
            )
        )
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        configuration(shielding: application)
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: .white,
            icon: UIImage(systemName: "hand.raised.fill"),
            title: ShieldConfiguration.Label(
                text: "Website Blocked",
                color: .black
            ),
            subtitle: ShieldConfiguration.Label(
                text: messages.randomElement() ?? messages[0],
                color: .gray
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "OK",
                color: .white
            ),
            primaryButtonBackgroundColor: .systemBlue
        )
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        configuration(shielding: webDomain)
    }
}

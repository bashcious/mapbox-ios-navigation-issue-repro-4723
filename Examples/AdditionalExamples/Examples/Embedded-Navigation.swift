import Foundation
import MapboxDirections
import MapboxMaps
import MapboxNavigationCore
import MapboxNavigationUIKit
import UIKit

class EmbeddedExampleViewController: UIViewController {
    let mapboxNavigationProvider = MapboxNavigationProvider(
        coreConfig: .init(
            locationSource: simulationIsEnabled ? .simulation(
                initialLocation: .init(
                    latitude: 37.77440680146262,
                    longitude: -122.43539772352648
                )
            ) : .live
        )
    )
    lazy var mapboxNavigation = mapboxNavigationProvider.mapboxNavigation

    @IBOutlet var container: UIView!
    var navigationRoutes: NavigationRoutes?

    lazy var routeOptions: NavigationRouteOptions = {
        let origin = CLLocationCoordinate2DMake(37.77440680146262, -122.43539772352648)
        let destination = CLLocationCoordinate2DMake(37.76556957793795, -122.42409811526268)
        return NavigationRouteOptions(coordinates: [origin, destination])
    }()

    var isNavigationBarHidden = false

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Embedded Navigation Example"
        calculateDirections()

    }



    func calculateDirections() {
        Task {
            switch await mapboxNavigation.routingProvider().calculateRoutes(options: routeOptions).result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let response):
                self.navigationRoutes = response
                self.startEmbeddedNavigation()
            }
        }
    }

    func startEmbeddedNavigation() {
        guard let navigationRoutes else { return }
        let navigationOptions = NavigationOptions(
            mapboxNavigation: mapboxNavigation,
            voiceController: mapboxNavigationProvider.routeVoiceController,
            eventsManager: mapboxNavigationProvider.eventsManager()
        )
        let navigationViewController = NavigationViewController(
            navigationRoutes: navigationRoutes,
            navigationOptions: navigationOptions
        )

        navigationViewController.delegate = self
        addChild(navigationViewController)
        container.addSubview(navigationViewController.view)
        navigationViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            navigationViewController.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            navigationViewController.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            navigationViewController.view.topAnchor.constraint(equalTo: container.topAnchor),
            navigationViewController.view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        setupCenterTextLabel()
        
        didMove(toParent: self)
    }

    func setupCenterTextLabel() {
        let centerLabel = UILabel()
        centerLabel.text = "Tap to Toggle Navigation Bar"
        centerLabel.textAlignment = .center
        centerLabel.textColor = .black
        centerLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(centerLabel)

        NSLayoutConstraint.activate([
            centerLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            centerLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideButtonTapped))
        centerLabel.isUserInteractionEnabled = true
        centerLabel.addGestureRecognizer(tapGesture)
    }
    
    @objc func hideButtonTapped() {
        isNavigationBarHidden.toggle()
        navigationController?.setNavigationBarHidden(isNavigationBarHidden, animated: true)
    }
}

extension EmbeddedExampleViewController: NavigationViewControllerDelegate {
    func navigationViewController(_ navigationViewController: NavigationViewController, didRerouteAlong route: Route) {
    }

    func navigationViewControllerDidDismiss(
        _ navigationViewController: NavigationViewController,
        byCanceling canceled: Bool
    ) {
        navigationController?.popViewController(animated: true)
    }
}

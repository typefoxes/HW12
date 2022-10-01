

import UIKit
import MapKit
import CoreLocation

class ViewController4: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var squareLabel: UILabel!
    @IBOutlet weak var flatsLabel: UILabel!
    @IBOutlet weak var floorLabel: UILabel!
    @IBOutlet weak var squareSlider: UISlider!
    @IBOutlet weak var flatsSlider: UISlider!
    @IBOutlet weak var floorSlider: UISlider!
    @IBOutlet weak var priceLabel: UILabel!
    var locationManager: CLLocationManager?
    let model = ApartmentsPricer()
    
    lazy var currencyRUB: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.locale = Locale(identifier: "ru_RU")
            formatter.numberStyle = .currency
            formatter.maximumFractionDigits = 0
            return formatter
        }()
    
    var currentPoint: CLLocationCoordinate2D? {
        didSet {
            updateUI()
        }
    }
    
    var square: Float = 50 {
        didSet {
            updateUI()
        }
    }
    var flats: Float = 2 {
        didSet {
            updateUI()
        }
    }
    var floor: Float = 3 {
        didSet {
            updateUI()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager = CLLocationManager()
        locationManager?.requestWhenInUseAuthorization()
        
        let initialLocation = CLLocation(latitude: 55.751892, longitude: 37.616821)
        mapView.centerToLocation(initialLocation)
        setupUI()
        updateUI()
    }
    @IBAction func tapGesture(_ sender: UITapGestureRecognizer) {
        if sender.state == .ended{
            let locationInView = sender.location(in: mapView)
            let tappedCoordinate = mapView.convert(locationInView, toCoordinateFrom: mapView)
            addAnnotation(coordinate: tappedCoordinate)
            currentPoint = tappedCoordinate
        }
    }
    func addAnnotation(coordinate:CLLocationCoordinate2D){
        mapView.removeAnnotations(mapView.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
    }
    
    private func predictPrice(
        point: CLLocationCoordinate2D
    ) -> Double {
        let prediction = try? model.prediction(
            Area: Double(squareSlider.value),
            Floor: Double(floorSlider.value),
            Rooms: Double(floorSlider.value),
            Latitude: point.latitude,
            Longitude: point.longitude)
        return prediction?.Price ?? 0
    }
    
    private func setupUI() {
        squareSlider.minimumValue = 5
        squareSlider.maximumValue = 200
        flatsSlider.minimumValue = 1
        flatsSlider.maximumValue = 10
        floorSlider.minimumValue = 1
        floorSlider.maximumValue = 75
    }
    
    private func updateUI() {
        squareLabel.text = "Площадь: \(Int(square))"
        flatsLabel.text = "Количество комнат: \(Int(flats))"
        floorLabel.text = "Этаж: \(Int(floor))"
        
        squareSlider.value = square
        flatsSlider.value = flats
        floorSlider.value = floor
        
        guard let currentPoint = currentPoint else {
            priceLabel.text = "Выберите точку на карте"
            return
        }
        let price = predictPrice(point: currentPoint)
        
        let number = NSNumber(value: price)
        priceLabel.text = currencyRUB.string(from: number)!
    }
    
    @IBAction func squareChanged(_ sender: UISlider) {
        square = sender.value
    }
    
    @IBAction func flatsChanged(_ sender: UISlider) {
        flats = sender.value
    }
    
    @IBAction func floorChanged(_ sender: UISlider) {
        floor = sender.value
    }
    
}

private extension MKMapView {
    func centerToLocation(
        _ location: CLLocation,
        regionRadius: CLLocationDistance = 10000
    ) {
        let coordinateRegion = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: regionRadius,
            longitudinalMeters: regionRadius)
        setRegion(coordinateRegion, animated: true)
    }
}

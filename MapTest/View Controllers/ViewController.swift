//
//  ViewController.swift
//  MapTest
//
//  Created by Amir Shayegh on 2020-02-25.
//  Copyright © 2020 Amir Shayegh. All rights reserved.
//

import UIKit
import MapKit
import Reachability
import Alamofire
import SwiftyJSON

class ViewController: BaseViewController {
    
    // MARK: Constants
    let regionRadius: CLLocationDistance = 200
    let maxLoactionAdjustments: Int = 3
    
    let testLatitude: Double = 49.185996
    let testLongitude: Double = -123.950065
    
    let testLocationName: String = "Nanaimo"
    
    // MARK: Variables
    var polygonColors: [UIColor] = [.blue,.lightGray, .yellow, .green]
    var tappedLocationPin: MKPointAnnotation?
    var pins: [MKPointAnnotation] = [MKPointAnnotation]()
    var polygons: [MKOverlay] = [MKOverlay]()
    var mapCenterLat: Double = 0
    var mapCenterLon: Double = 0
    var locationManager: CLLocationManager = CLLocationManager()
    var locationAuthorizationstatus: CLAuthorizationStatus?
    var tileRenderer: MKTileOverlayRenderer!
    var locationAdjustments: Int = 0
    var currentLocation: CLLocation? {
        didSet {
            if locationAdjustments > maxLoactionAdjustments {
                return
            }
            focusOnCurrent()
            locationAdjustments += 1
        }
    }
    
    // MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var selectionButton: UIButton!
    @IBOutlet weak var mapCenterLabel: UILabel!
    @IBOutlet weak var addPinButton: UIButton!
    @IBOutlet weak var addPolygonButton: UIButton!
    @IBOutlet weak var clearPinsAndPolygonsButton: UIButton!
    @IBOutlet weak var addButton: UIButton!
    
    // MARK: 
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        style()
    }
    
    // MARK: Outlet Actions
    @IBAction func locationButtonClicked(_ sender: UIButton) {
        focusOnCurrent()
    }
    
    @IBAction func clearPinsAndPolygonsButtonAction(_ sender: UIButton) {
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays.filter{$0.isKind(of: Polygon.self)})
    }
    
    @IBAction func makePolygonsButtonAction(_ sender: UIButton) {
        var coordinates: [CLLocationCoordinate2D] = []
        
        for pin in pins {
            coordinates.append(CLLocationCoordinate2D(latitude: pin.coordinate.latitude, longitude: pin.coordinate.longitude))
        }
        
        pins.removeAll()
        addPolygon(overlay: makePolygonOverlay(coordinates: coordinates, color: UIColor.blue))
    }
    
    @IBAction func addPinButtonAction(_ sender: UIButton) {
        dropPin(location: CLLocation(latitude: mapCenterLat, longitude: mapCenterLon))
    }
    
    @IBAction func addLayerAction(_ sender: UIButton) {
        addLayerAlert { [weak self](url) in
            guard let strongSelf = self, let endpoint = url else {return}
            strongSelf.showLayerData(in: endpoint)
        }
    }
    
    @IBAction func deleteButtonClicked(_ sender: UIButton) {
        alert(title: "Deleting Stored Tiles", message: "Would you like to delete all stored tiles?", yes: {
            TileService.shared.deleteAllStoredTiles()
        }, no: {
            return
        })
        
    }
    
    @IBAction func downloadButtonClicked(_ sender: Any) {
        alert(title: "Download tiles for sample locations", message: "Would you like to begin downloading tiles for the following sample coordinates?\n\(testLocationName): \(self.testLatitude), \(self.testLongitude)", yes: {
            let r = try! Reachability()
            if r.connection == .unavailable {
                self.alert(title: "Offline", message: "You your device is offline")
                return
            }
            TileService.shared.downloadTilePathsForCenterAt(lat: self.testLatitude, lon: self.testLongitude)
        }, no: {
            return
        })
    }
    
    @IBAction func infoButtonClicked(_ sender: UIButton) {
        alert(title: "Stored Tiles", message: "Total size:\n\(TileService.shared.sizeOfStoredTiles().roundToDecimal(2))MB")
    }
    
    @IBAction func selectionButtonClicked(_ sender: UIButton) {
        moveMapTo(latitude: testLatitude, longitude: testLongitude)
    }
    
    // MARK: Setup
    func setup() {
        setupLocation()
        setupTileRenderer()
        setupMap()
        addTapGestureRecognizer()
    }
    
    func setupTileRenderer() {
        let overlay = CustomMapOverlay()
        overlay.canReplaceMapContent = true
        mapView.addOverlay(overlay, level: .aboveLabels)
        tileRenderer = MKTileOverlayRenderer(tileOverlay: overlay)
    }
    
    func style() {
        style(button: locationButton)
        style(button: downloadButton)
        style(button: deleteButton)
        style(button: infoButton)
        style(button: selectionButton)
        style(button: addPinButton)
        style(button: addPolygonButton)
        style(button: clearPinsAndPolygonsButton)
        style(button: addPolygonButton)
        style(button: addButton)
        mapCenterLabel.backgroundColor = Colors.primaryContrast
        mapCenterLabel.textColor = Colors.primary
        mapCenterLabel.text = ""
    }
    
    func addLayerAlert(result: @escaping(URL?)-> Void) {
        let alert = UIAlertController(title: "Add Layer", message: "Please enter URL for layer", preferredStyle: UIAlertController.Style.alert )
        let save = UIAlertAction(title: "Save", style: .default) { (alertAction) in
            if let textField = alert.textFields?[0],
                let input = textField.text,
                let url = URL(string: input)
            {
                return result(url)
            } else {
                return result(nil)
            }
        }
        
        alert.addTextField { (textField) in
            textField.placeholder = "URL to fetch layer"
            textField.text = "http://openmaps.gov.bc.ca/geo/pub/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=pub%3AWHSE_BASEMAPPING.BC_WATER_POLYS_5KM&outputFormat=application%2Fjson&srsName=epsg:4326"
        }
        
        alert.addAction(save)
        
        let cancel = UIAlertAction(title: "Cancel", style: .default) { (alertAction) in
            return result(nil)
        }
        alert.addAction(cancel)
        
        self.present(alert, animated:true, completion: nil)
        
    }
    
}
// MARK: Location
extension ViewController: CLLocationManagerDelegate {
    // MARK: Location Setup
    func setupLocation() {
        locationManager.delegate = self
        
        // For use when the app is open
        locationManager.requestWhenInUseAuthorization()
        
        // If location services is enabled get the users location
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
    }
    
    // MARK: Location Delegates
    // Set Latest Location on change
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            self.currentLocation = location
        }
    }
    
    // If we have been deined access give the user the option to change it
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.locationAuthorizationstatus = status
        if(status == CLAuthorizationStatus.denied) {
            showLocationDisabledPopUp()
        }
    }
    
    // Shows a popup to the user if we have been deined access
    func showLocationDisabledPopUp() {
        let alertController = UIAlertController(title: "Location Access Disabled",
                                                message: "We need permission",
                                                preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let openAction = UIAlertAction(title: "Open Settings", style: .default) { (action) in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: self.convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            }
        }
        alertController.addAction(openAction)
        present(alertController, animated: true, completion: nil)
    }
    
    fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
        return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
    }
}

// MARK: Map
extension ViewController: MKMapViewDelegate {
    // MARK: Map setup
    func setupMap() {
        mapView.delegate = self
        mapView.showsUserLocation = true
        
        // Set map region
        var noLocation = CLLocationCoordinate2D()
        noLocation.latitude = 48.424251
        noLocation.longitude = -123.365729
        let viewRegion = MKCoordinateRegion.init(center: noLocation, latitudinalMeters: 200, longitudinalMeters: 200)
        mapView.setRegion(viewRegion, animated: true)
        
        // Begin listening for user location
        DispatchQueue.main.async {
            self.locationManager.startUpdatingLocation()
        }
    }
    
    func moveMapTo(latitude: Double, longitude: Double) {
        let loc = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let coordinateRegion = MKCoordinateRegion.init(center: loc,latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    // Move map center to current position
    func focusOnCurrent() {
        let loc = locationManager.location?.coordinate
        guard let location = loc else { return }
        moveMapTo(latitude: location.latitude, longitude: location.longitude)
    }
    
    // MARK: Map Delegates
    // Handle rendering of lines and polygons and custom renderer
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let lineView = MKPolylineRenderer(overlay: overlay)
            lineView.strokeColor = UIColor.green
            return lineView
        } else if overlay is MKPolygon {
            if let poly = overlay as? Polygon {
                let polygonView = MKPolygonRenderer(overlay: overlay)
                polygonView.fillColor = poly.color.withAlphaComponent(0.5)
                polygonView.strokeColor = poly.color
                polygonView.lineWidth = 2
                return polygonView
            }
        }
        return tileRenderer
    }
    
    // When map location changes
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let lat = mapView.centerCoordinate.latitude
        let lon = mapView.centerCoordinate.longitude
        self.mapCenterLat = mapView.centerCoordinate.latitude
        self.mapCenterLon = mapView.centerCoordinate.longitude
        mapCenterLabel.text = "\(lat), \(lon)"
    }
    
    func dropPin(location: CLLocation) {
        let myAnnotation: MKPointAnnotation = MKPointAnnotation()
        myAnnotation.coordinate = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude);
        pins.append(myAnnotation)
        mapView.addAnnotation(myAnnotation)
    }
    
    func makePolygonOverlay(coordinates: [CLLocationCoordinate2D], color: UIColor) -> MKOverlay {
        let polygon: Polygon = Polygon(coordinates: coordinates, count: coordinates.count)
        polygon.color = color
        let overlay: MKOverlay = polygon
        return overlay
    }
    
    func addLine(coordinates: [CLLocationCoordinate2D], color: UIColor) {
        let routeLine = MKPolyline(coordinates: coordinates, count: coordinates.count)
        mapView.addOverlay(routeLine)
    }
    
    func addPolygon(overlay: MKOverlay) {
        polygons.append(overlay)
        mapView.addOverlay(overlay)
    }
}

// MARK: Interactions
extension ViewController: UIGestureRecognizerDelegate {
    
    func addTapGestureRecognizer() {
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(gestureRecognizer:)))
        gestureRecognizer.delegate = self
        mapView.addGestureRecognizer(gestureRecognizer)
    }
    
    @objc func handleTap(gestureRecognizer: UILongPressGestureRecognizer) {

        let location = gestureRecognizer.location(in: mapView)
        let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
        
        if let currentLastPin = tappedLocationPin {
            mapView.removeAnnotation(currentLastPin)
        }
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        self.tappedLocationPin = annotation
        mapView.addAnnotation(annotation)
    }
}

// MARK: External Layers
extension ViewController {
    func showLayerData(in url: URL) {
        API.get(endpoint: url) { [weak self](result) in
            guard let strongerSelf = self else {return}
            guard let jsonResult = result else {return}
            
            
            let features = jsonResult["features"].arrayValue
            if let sample = features.first?["geometry"].dictionaryValue {
                if sample["type"]?.stringValue.lowercased() == "Polygon" {
                    strongerSelf.addPolygonAPI_Result(json: jsonResult)
                } else {
                    strongerSelf.addPolyLineAPI_Result(json: jsonResult)
                }
            }
        }
    }
    
    private func addPolyLineAPI_Result(json: JSON) {
        guard let color = polygonColors.popLast() else {return}
        let features = json["features"].arrayValue
        var featuresPolygons : [[CLLocationCoordinate2D]] = [[CLLocationCoordinate2D]()]
        for feature in features {
            let geometry = feature["geometry"].dictionaryValue
            let coordinates = geometry["coordinates"]?.arrayValue
            guard let featureCoordinates = coordinates?.first?.arrayValue else {
                continue
            }
            var coordinatesExtract: [CLLocationCoordinate2D] = []
            for item in featureCoordinates {
                let lat = item[1].doubleValue
                let long = item[0].doubleValue
                if lat != 0 && long != 1 {
                    coordinatesExtract.append(CLLocationCoordinate2D(latitude: lat, longitude: long))
                }
            }
            featuresPolygons.append(coordinatesExtract)
        }
        
        for each in featuresPolygons {
            print(each)
            self.addLine(coordinates: each, color: color)
//            let poly = self.makePolygonOverlay(coordinates: each, color: color)
//            self.addPolygon(overlay: poly)
        }
    }
    
    private func addPolygonAPI_Result(json: JSON) {
        guard let color = polygonColors.popLast() else {return}
        let features = json["features"].arrayValue
        var featuresPolygons : [[CLLocationCoordinate2D]] = [[CLLocationCoordinate2D]()]
        for feature in features {
            let geometry = feature["geometry"].dictionaryValue
            let coordinates = geometry["coordinates"]?.arrayValue
            guard let featureCoordinates = coordinates?.first?.arrayValue else {
                continue
            }
            var coordinatesExtract: [CLLocationCoordinate2D] = []
            for item in featureCoordinates {
                let lat = item[1].doubleValue
                let long = item[0].doubleValue
                if lat != 0 && long != 1 {
                    coordinatesExtract.append(CLLocationCoordinate2D(latitude: lat, longitude: long))
                }
            }
            featuresPolygons.append(coordinatesExtract)
        }
        
        for each in featuresPolygons {
            print(each)
            let poly = self.makePolygonOverlay(coordinates: each, color: color)
            self.addPolygon(overlay: poly)
        }
    }
}

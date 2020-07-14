//
//  TIleService.swift
//  MapTest
//
//  Created by Amir Shayegh on 2020-02-28.
//  Copyright © 2020 Amir Shayegh. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import Alamofire
import Reachability

enum TileProvider {
    case GoogleSatellite
    case GoogleHybrid
    case OpenStreet
    case BCGOV
}

class TileService {

    public static let shared = TileService()
    
    // MARK: Public variables
    var tileProvider: TileProvider = .BCGOV
    var cacheVisitedTiles: Bool = false

    // MARK: Private variables
    private let indicatorTag = 7786
    private let indicatorLabelTag = 7787

    private var minZoom = 18
    private var maxZoom = 12
    private var allPaths = [MKTileOverlayPath]()
    private var tiles = 0

    private var isDownloading: Bool = false
    
    // Lets chache these instead of calculating over and over
    private var cachedNumberOfStoredTiles: Int = 0
    private var cachedSizeOfStoredTiles: Double = 0.0

    // If it keeps failing to download X number of tiles again, don't try again
    private var lastFailedCount: Int = 0

    private var tempCount = 0
    private var tilesOfInterest = [MKTileOverlayPath]()
    
    private init() {
        print("Initialized TileService. Size of tiles: \(sizeOfStoredTiles().roundToDecimal(3))")
    }
    
    func getTileProviderURL(for path: MKTileOverlayPath) -> URL? {
        if path.z > 17 {
            return openSteetMapURL(for: path)
        }
        switch self.tileProvider {
        case .GoogleSatellite:
            return googleSatelliteURL(for: path)
        case .OpenStreet:
            return openSteetMapURL(for: path)
        case .GoogleHybrid:
            return googleHybridURL(for: path)
        case .BCGOV:
            return bcGovURL(for: path)
        }
    }
    
    private func googleHybridURL(for path: MKTileOverlayPath) -> URL? {
        let stringURL = "https://mt1.google.com/vt/lyrs=y&x=\(path.x)&y=\(path.y)&z=\(path.z)"
        guard let url = URL(string: stringURL) else {return nil}
        return url
    }
    
    private func openSteetMapURL(for path: MKTileOverlayPath) -> URL? {
        let stringURL = "https://tile.openstreetmap.org/\(path.z)/\(path.x)/\(path.y).png"
        guard let url = URL(string: stringURL) else {return nil}
        return url
    }
    
    private func googleSatelliteURL(for path: MKTileOverlayPath) -> URL? {
        let stringURL = "http://www.google.cn/maps/vt?lyrs=s@189&gl=cn&x=\(path.x)&y=\(path.y)&z=\(path.z)"
        guard let url = URL(string: stringURL) else {return nil}
        return url
    }
    
    
    private func bcGovURL(for path: MKTileOverlayPath) -> URL? {
        let stringURL = "https://maps.gov.bc.ca/arcgis/rest/services/province/roads_wm/MapServer/tile/\(path.z)/\(path.y)/\(path.x)"
        guard let url = URL(string: stringURL) else {return nil}
        return url
        
    }
    

    func tileExistsLocally(for tilePath: MKTileOverlayPath) -> Bool {
        let path = localPath(for: fileName(for: tilePath))
        let filePath = path.path
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: filePath)
    }

    private func documentDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }

    public func localPath(for name: String) -> URL {
        return documentDirectory().appendingPathComponent("\(name)")
    }

    public func fileName(for path: MKTileOverlayPath) -> String {
        return "Tile-\(path.z)-\(path.x)-\(path.y).png"
    }

    public func sizeOfStoredTiles() -> Double {
        let fileURLs = storedFiles()
        // If number of items hasn't changed retured the last computed size
        if storedFiles().count == self.cachedNumberOfStoredTiles {return self.cachedSizeOfStoredTiles}
        var total: Double = 0
        for item in fileURLs {
            if item.path.contains("Tile") {
                total += sizeOfFileAt(url: item)
            }
        }
        self.cachedNumberOfStoredTiles = storedFiles().count
        self.cachedSizeOfStoredTiles = total
        return total
    }

    private func sizeOfFileAt(url: URL?) -> Double {
        guard let filePath = url?.path else {
            return 0.0
        }
        do {
            let attribute = try FileManager.default.attributesOfItem(atPath: filePath)
            if let size = attribute[FileAttributeKey.size] as? NSNumber {
                return size.doubleValue / 1000000.0
            }
        } catch {
            print("*Error* in TileMaster -> sizeOfFileAt: \(error)")
        }
        return 0.0
    }

    private func storedFiles() -> [URL] {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            return fileURLs
        } catch {
            return [URL]()
        }
    }

    private func deleteStoreTiles(at urls: [URL]) {
        let fileManager = FileManager.default
        for url in urls where url.path.contains("Tile") {
            do {
                try fileManager.removeItem(at: url)
            } catch {
                return
            }
        }
    }

    public func deleteAllStoredTiles() {
        let all = storedFiles()
        deleteStoreTiles(at: all)
        print("Removed all stored Map tiles")
    }

    private func convert(lat: Double, lon: Double, zoom: Int) -> MKTileOverlayPath {
        // Scale factor used to create MKTileOverlayPath object.
        let scaleFactor: CGFloat = 2.0

        // Holders for X Y
        var x: Int = 0
        var y: Int = 0

        // https://wiki.openstreetmap.org/wiki/Slippy_map_tilenames
        let n = pow(2, Double(zoom))
        x = Int(n * ((lon + 180) / 360))
        y = Int(n * (1 - (log(tan(lat.degreesToRadians) + (1/cos(lat.degreesToRadians))) / Double.pi)) / 2)

        return MKTileOverlayPath(x: x, y: y, z: zoom, contentScaleFactor: scaleFactor)
    }

    public func downloadTilePathsForCenterAt(lat: Double, lon: Double) {
        
        let r = try! Reachability()
        if r.connection == .unavailable {
            return
        }
        // get the initial tile.
        let initialPath = convert(lat: lat, lon: lon, zoom: maxZoom)
        tilesOfInterest.removeAll()
        tilesOfInterest.append(initialPath)

        findSubtiles(under: initialPath)

        print("\(tilesOfInterest.count) Tiles of interest")
        let newTiles = findTilesToStoreIn(array: tilesOfInterest)
        print("\(newTiles.count) are new")

        download(tilePaths: newTiles)
    }

    private func findSubtiles(under path: MKTileOverlayPath) {
        if path.z + 1 > minZoom {return}

        let first = MKTileOverlayPath(x: 2 * path.x, y: 2 * path.y, z: path.z + 1, contentScaleFactor: 2.0)

        let second = MKTileOverlayPath(x: 2 * path.x + 1, y: 2 * path.y, z: path.z + 1, contentScaleFactor: 2.0)

        let third = MKTileOverlayPath(x: 2 * path.x, y: 2 * path.y + 1, z: path.z + 1, contentScaleFactor: 2.0)

        let forth = MKTileOverlayPath(x: 2 * path.x + 1, y: 2 * path.y + 1, z: path.z + 1, contentScaleFactor: 2.0)

        tilesOfInterest.append(first)
        tilesOfInterest.append(second)
        tilesOfInterest.append(third)
        tilesOfInterest.append(forth)

        findSubtiles(under: first)
        findSubtiles(under: second)
        findSubtiles(under: third)
        findSubtiles(under: forth)
    }

    private func getPercentage(of value: Int, in total: Int) -> Double {
        return (Double((value * 100)) / Double(total)).roundToDecimal(1)
    }

    private func download(tilePaths: [MKTileOverlayPath]) {
        let r = try! Reachability()
        if r.connection == .unavailable {
            return
        }

        if tilePaths.isEmpty {
            // Nothing to Download
            return
        }

        if self.isDownloading {
            return
        }

        self.isDownloading = true

        var failedTiles = [MKTileOverlayPath]()
        print("Downloading \(tilePaths.count) Map tiles")
        
        addStatusIndicator()
        var count = tilePaths.count {
            didSet {
                self.updateStatusValue(to: getPercentage(of: count, in: tilePaths.count))
            }
        }

        let queue = DispatchQueue(label: "tileQues", qos: .background, attributes: .concurrent)
        queue.async {
            let dispatchGroup = DispatchGroup()

            for i in 0...tilePaths.count - 1 {

                dispatchGroup.enter()
                let current = tilePaths[i]
                if self.tileExistsLocally(for: current) {
                    count -= 1
                    dispatchGroup.leave()
                } else {
                    Thread.sleep(until: Date(timeIntervalSinceNow: 0.0001))
                    self.downloadTile(for: current) { (success) in
                        count -= 1
                        if !success {
                            failedTiles.append(current)
                            print("Failed to download a tile. total Failuers: \(failedTiles.count)")
                        }
                        dispatchGroup.leave()
                    }
                }
            }
            dispatchGroup.notify(queue: .main) {
                self.downloadCompleted(failed: failedTiles)
            }
        }
    }

    public func downloadTile(for path: MKTileOverlayPath, then: @escaping (_ success: Bool)-> Void) {
        let r = try! Reachability()
        if r.connection == .unavailable {
            return
        }
        let queue = DispatchQueue(label: "tileQue", qos: .background, attributes: .concurrent)
        
        var _url: URL? = nil
        
        if path.z > 17 {
            _url = openSteetMapURL(for: path)
        } else {
            _url = getTileProviderURL(for: path)
           
        }
        
        guard let url = _url else {
            return then(false)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 3
        Alamofire.request(request).responseData(queue: queue) { (response) in
            switch response.result {
            case .success:
                if let data = response.data {
                    do {
                        try data.write(to: self.localPath(for: self.fileName(for: path)))
                        return then(true)
                    } catch {
                        return then(false)
                    }
                } else {
                    return then(false)
                }
            case .failure:
                return then(false)
            }
        }
    }

    private func downloadCompleted(failed: [MKTileOverlayPath]) {
        tilesOfInterest.removeAll()
        removeStatusIndicator()

        self.isDownloading = false
        if self.lastFailedCount == failed.count {
            if lastFailedCount == 0 {
                print("No tiles failed to download.")
                print("Finished download map data. total size: \(sizeOfStoredTiles().roundToDecimal(2))MB")
                return
            } else {
                print("Will not try to download failed tiles in this session.")
                lastFailedCount = 0
                return
            }
        } else {
            print("\(failed.count) tiles failed to download")
            lastFailedCount = failed.count

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.download(tilePaths: failed)
            }
        }
    }

    private func findTilesToStoreIn(array: [MKTileOverlayPath]) -> [MKTileOverlayPath] {
        var newTiles: [MKTileOverlayPath] = [MKTileOverlayPath]()
        for element in array {
            if !tileExistsLocally(for: element) {
                newTiles.append(element)
            }
        }
        return newTiles
    }

    // MARK: Status
    private func addStatusIndicator() {
        DispatchQueue.main.async {
            guard let window = UIApplication.shared.connectedScenes
            .filter({$0.activationState == .foregroundActive})
            .map({$0 as? UIWindowScene})
            .compactMap({$0})
            .first?.windows
            .filter({$0.isKeyWindow}).first else {return}
            let width: CGFloat = 100
            let height: CGFloat = 100
            let frame = CGRect(x: window.frame.maxX, y: window.frame.maxY, width: width, height: height)
            let view = UIView(frame: frame)
            let label = UILabel(frame: frame)

            view.tag = self.indicatorTag
            label.tag = self.indicatorLabelTag

            window.addSubview(view)
            window.addSubview(label)

            label.textAlignment = .center

            self.addAnchors(to: view, in: window, width: width, height: height)
            self.addAnchors(to: label, in: window, width: width, height: height)

            label.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
            view.backgroundColor = UIColor.black
            label.textColor = UIColor.white
            view.layer.cornerRadius = height/2
            view.alpha = 1
        }
    }

    private func addAnchors(to view: UIView, in window: UIWindow, width: CGFloat, height: CGFloat) {
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: width),
            view.heightAnchor.constraint(equalToConstant: height),
            view.bottomAnchor.constraint(equalTo: window.bottomAnchor),
            view.leftAnchor.constraint(equalTo: window.leftAnchor)
            ])
    }

    private func updateStatusValue(to percent: Double) {
        DispatchQueue.main.async {
            guard let window = UIApplication.shared.connectedScenes
            .filter({$0.activationState == .foregroundActive})
            .map({$0 as? UIWindowScene})
            .compactMap({$0})
            .first?.windows
            .filter({$0.isKeyWindow}).first else {return}
            if let label = window.viewWithTag(self.indicatorLabelTag) as? UILabel {
                let remaining = 100 - percent
                label.text = "\(remaining.roundToDecimal(1))%"
            }
        }
    }

    private func removeStatusIndicator() {
        DispatchQueue.main.async {
            guard let window = UIApplication.shared.connectedScenes
            .filter({$0.activationState == .foregroundActive})
            .map({$0 as? UIWindowScene})
            .compactMap({$0})
            .first?.windows
            .filter({$0.isKeyWindow}).first else {return}
            if let label = window.viewWithTag(self.indicatorLabelTag) {
                label.removeFromSuperview()
            }

            if let view = window.viewWithTag(self.indicatorTag) {
                view.removeFromSuperview()
            }
        }
    }
}

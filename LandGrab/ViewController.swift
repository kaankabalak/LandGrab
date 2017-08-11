//
//  ViewController.swift
//  LandGrab
//
//  Created by Kaan Kabalak on 7/24/17.
//  Copyright © 2017 Kaan Kabalak. All rights reserved.
//

import UIKit
import Mapbox

class ViewController: UIViewController, MGLMapViewDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var mapView: MGLMapView!
    
    var polygons = [MGLAnnotation]()
    
    var polylines = [MGLAnnotation]()
    
    var zipcodes = ["94122", "94115", "94118", "94121", "94123", "94129", "94116", "94132", "94117", "94112", "94134", "94124", "94107","94110", "94131", "94114", "94127", "94158", "94103", "94102", "94109", "94108", "94104", "94133", "94111", "94105"]
    
    var red = [String]()
    
    var blue = ["94122", "94115", "94118", "94121", "94123", "94129", "94116", "94132", "94117", "94112", "94134", "94124", "94107","94110", "94131", "94114", "94127", "94158", "94103", "94102", "94109", "94108", "94104", "94133", "94111", "94105"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        mapView.delegate = self
        
        drawRegions()
        
        // Add a tap gesture recognizer to the map view.
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        gesture.delegate = self
        mapView.addGestureRecognizer(gesture)

    }
    
    func drawRegions() {
        // Parsing GeoJSON can be CPU intensive, do it on a background thread
        

        for i in self.zipcodes {
            self.drawZip(zip: i)
        }
        
        for i in self.zipcodes {
            self.drawOutline(zip: i)
        }

        
    }
    
    func drawOutline(zip: String){
        DispatchQueue.global(qos: .background).async(execute: {
            // Get the path for example.geojson in the app's bundle
            let jsonPath = Bundle.main.path(forResource: zip+"outline", ofType: "geojson")
            let url = URL(fileURLWithPath: jsonPath!)
            
            do {
                // Convert the file contents to a shape collection feature object
                let data = try Data(contentsOf: url)
                let shapeCollectionFeature = try MGLShape(data: data, encoding: String.Encoding.utf8.rawValue) as! MGLShapeCollectionFeature
                
                if let polyline = shapeCollectionFeature.shapes.first as? MGLPolylineFeature {
                    // Optionally set the title of the polyline, which can be used for:
                    //  - Callout view
                    //  - Object identification
                    polyline.title = polyline.attributes["name"] as? String
                    
                    // Add the annotation on the main thread
                    DispatchQueue.main.async(execute: {
                        // Unowned reference to self to prevent retain cycle
                        [unowned self] in
                        self.mapView.addAnnotation(polyline)
                        self.polylines.append(polyline)
                    })
                }
            }
            catch {
                print("GeoJSON parsing failed outline, zip is", zip)
            }
            
        })
    }
    
    func drawZip(zip: String) {
        // Get the path for example.geojson in the app's bundle
        let jsonPath = Bundle.main.path(forResource: zip, ofType: "geojson")
        let url = URL(fileURLWithPath: jsonPath!)
        
        do {
            // Convert the file contents to a shape collection feature object
            let data = try Data(contentsOf: url)
            let shapeCollectionFeature = try MGLShape(data: data, encoding: String.Encoding.utf8.rawValue) as! MGLShapeCollectionFeature
            
            if let polygon = shapeCollectionFeature.shapes.first as? MGLPolygonFeature {
                // Optionally set the title of the polyline, which can be used for:
                //  - Callout view
                //  - Object identification
                polygon.title = polygon.attributes["GEOID10"] as? String
                
                // Add the annotation on the main thread
                DispatchQueue.main.async(execute: {
                    // Unowned reference to self to prevent retain cycle
                    [unowned self] in
                    self.mapView.addAnnotation(polygon)
                    self.polygons.append(polygon)
                })
            }
        }
        catch {
            print("GeoJSON parsing failed")
        }
    }
    
    func handleTap(_ gesture: UITapGestureRecognizer) {
        
        // Get the CGPoint where the user tapped.
        let spot = gesture.location(in: mapView)
        
        // Access the features at that point within the state layer.
        let features = mapView.visibleFeatures(at: spot, styleLayerIdentifiers: Set(["zip-layer"]))
        let zipcode = features.first?.attribute(forKey: "GEOID10")
        
        if let newzip = zipcode {
            if(blue.contains(newzip as! String)) {
                blue = blue.filter{$0 != newzip as! String}
                red.append(newzip as! String)
                print(red)
            }
        }
        
        // update map
        self.mapView.removeAnnotations(self.polygons)
        self.mapView.removeAnnotations(self.polylines)
        drawRegions()
        
//        let layer = mapView.style?.layer(withIdentifier: "zip-layer") as! MGLFillStyleLayer
//        layer.fillColor = MGLStyleValue(interpolationMode: .categorical, sourceStops: [newzip as! AnyHashable: MGLStyleValue<UIColor>(rawValue: .red)], attributeName: "GEOID10", options: [.defaultValue: MGLStyleValue<UIColor>(rawValue: .blue)])
//        layer.fillColor = MGLStyleValue(rawValue: UIColor.red)
        
        
//        // Get the name of the selected state.
//        if let feature = features.first, let state = feature.attribute(forKey: "GEOID10") as? String{
//            print(state)
//            changeOpacity(name: state)
//        } else {
//            changeOpacity(name: "")
//        }
    }
    
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        let url = URL(string: "mapbox://kerlonmoura.95b5tyqa")!
        let source = MGLVectorSource(identifier: "zip-source", configurationURL: url)
        style.addSource(source)
        
        let layer = MGLFillStyleLayer(identifier: "zip-layer", source: source)
        
        // Access the tileset layer.
        layer.sourceLayerIdentifier = "SanFrancisco-b0hgss"
        layer.fillColor = MGLStyleValue(rawValue: UIColor.blue)
        layer.fillOpacity = MGLStyleValue(rawValue: 0)
        
        // Insert the new layer below the Mapbox Streets layer that contains state border lines. See the layer reference for more information about layer names: https://www.mapbox.com/vector-tiles/mapbox-streets-v7/
        let symbolLayer = style.layer(withIdentifier: "admin-3-4-boundaries")
        style.insertLayer(layer, below: symbolLayer!)
        
        
    }
    
    func mapView(_ mapView: MGLMapView, alphaForShapeAnnotation annotation: MGLShape) -> CGFloat {
        // Set the alpha for all shape annotations to 1 (full opacity)
        if(annotation is MGLPolyline) {
            return 0.8
        } else {
            return 0.4
        }
    }

    func mapView(_ mapView: MGLMapView, lineWidthForPolylineAnnotation annotation: MGLPolyline) -> CGFloat {
        // Set the line width for polyline annotations
        return 2.0
    }
    
    func mapView(_ mapView: MGLMapView, fillColorForPolygonAnnotation annotation: MGLPolygon) -> UIColor {
        if(blue.contains(annotation.title!)) {
            return .blue
        }
        else {
            return .red
        }
    }
    
    func mapView(_ mapView: MGLMapView, strokeColorForShapeAnnotation annotation: MGLShape) -> UIColor {
        // Give our polyline a unique color by checking for its `title` property
        if (blue.contains(annotation.title!) && annotation is MGLPolyline) {
            // Mapbox cyan
            return .blue
        }
        else
        {
            return .red
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    

}


//
//  ViewController.swift
//  Sensores9B
//
//  Created by Igmar Salazar on 22/05/24.
//

import UIKit
import MapKit
import CoreMotion
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate
{
    @IBOutlet weak var mapRutas: MKMapView!
    @IBOutlet weak var imvBrujula: UIImageView!
    @IBOutlet weak var btnCentrar: UIButton!
    @IBOutlet var lblAcelerometro: [UILabel]!
    @IBOutlet var lblGiroscopio: [UILabel]!
    let sensores = CMMotionManager()
    let localizacion = CLLocationManager()
    var ultimaPosicion = CLLocationCoordinate2D(latitude: 25.53296, longitude: -103.321884)
    var brujula = 0.0
    var lineaMapa: MKPolyline!
    
    override var preferredStatusBarStyle: UIStatusBarStyle
    {
        return .lightContent
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        mapRutas.delegate = self
        sensores.gyroUpdateInterval = 0.5
        sensores.accelerometerUpdateInterval = 0.5
        
        if sensores.isAccelerometerAvailable
        {
            sensores.startAccelerometerUpdates(to: .main) { datos, error in
                if let dat = datos
                {
                    self.lblAcelerometro[0].text = String(format: "%.2f", dat.acceleration.x)
                    self.lblAcelerometro[1].text = String(format: "%.2f", dat.acceleration.y)
                    self.lblAcelerometro[2].text = String(format: "%.2f", dat.acceleration.z)
                }
            }
        }
        
        if sensores.isGyroAvailable
        {
            sensores.startGyroUpdates(to: .main) { datos, error in
                if let dat = datos
                {
                    self.lblGiroscopio[0].text = String(format: "%.2f", dat.rotationRate.x)
                    self.lblGiroscopio[1].text = String(format: "%.2f", dat.rotationRate.y)
                    self.lblGiroscopio[2].text = String(format: "%.2f", dat.rotationRate.z)
                }
            }
        }
        
        localizacion.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        let datos = Datos.sharedDatos()
        
        if datos.codigoNuevo
        {
            datos.codigoNuevo = false
            let origen = MKPlacemark(coordinate: ultimaPosicion)
            let destino = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: datos.latitud, longitude: datos.longitud))
            dibujarRuta(origen, destino)
        }
    }

    @IBAction func centrarMapa()
    {
        btnCentrar.isHidden = true
        localizacion.delegate?.locationManager?(localizacion, didUpdateLocations: [localizacion.location!])
    }
    
    @IBAction func escanearQR()
    {
        let qrVC = QRViewController()
        qrVC.modalTransitionStyle = .flipHorizontal
        qrVC.modalPresentationStyle = .fullScreen
        qrVC.top = view.safeAreaInsets.top
        present(qrVC, animated: true)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager)
    {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .notDetermined
        {
            localizacion.desiredAccuracy = kCLLocationAccuracyBest
            localizacion.requestWhenInUseAuthorization()
            localizacion.startUpdatingLocation()
            localizacion.startUpdatingHeading()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        if let posicion = locations.last
        {
            ultimaPosicion = posicion.coordinate
            if btnCentrar.isHidden
            {
                var region = MKCoordinateRegion()
                region.center = posicion.coordinate
                region.span.latitudeDelta = 0.01
                region.span.longitudeDelta = 0.01
                mapRutas.setRegion(region, animated: true)
            }
        }
        mapRutas.showsUserLocation = true
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading)
    {
        let distancia = brujula - newHeading.magneticHeading
        
        if abs(distancia) > 1
        {
            brujula = newHeading.magneticHeading
            imvBrujula.transform = imvBrujula.transform.rotated(by: .pi*distancia/180.0)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        let punto = touches.first!.preciseLocation(in: mapRutas)
        
        if punto.y > 0 && punto.y < mapRutas.frame.height
        {
            btnCentrar.isHidden = false
        }
    }
    
    func dibujarRuta(_ origen: MKPlacemark, _ destino: MKPlacemark)
    {
        let origenMapa = MKMapItem(placemark: origen)
        let destinoMapa = MKMapItem(placemark: destino)
        let request = MKDirections.Request()
        request.source = origenMapa
        request.destination = destinoMapa
        request.transportType = .automobile
        
        let direccion = MKDirections(request: request)
        direccion.calculate { respuesta, error in
            if let resp = respuesta
            {
                if let lineaMapa = self.lineaMapa
                {
                    self.mapRutas.removeOverlay(lineaMapa)
                }
                let ruta = resp.routes[0]
                self.lineaMapa = ruta.polyline
                let rect = ruta.polyline.boundingMapRect
                self.mapRutas.setRegion(MKCoordinateRegion(rect), animated: true)
                self.mapRutas.addOverlay(self.lineaMapa!)
            }
            else
            {
                print("Error en la solicitud \(error!.localizedDescription)")
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: any MKOverlay) -> MKOverlayRenderer 
    {
        if let polyline = overlay as? MKPolyline
        {
            let render = MKPolylineRenderer(polyline: polyline)
            render.strokeColor = .black
            render.lineWidth = 5
            
            return render
        }
        else
        {
            return MKOverlayRenderer()
        }
    }
}

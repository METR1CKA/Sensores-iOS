//
//  QRViewController.swift
//  Sensores9B
//
//  Created by metricka on 03/06/2024.
//

import UIKit
import AVFoundation

class QRViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate
{
    var top: Double!
    var sesion = AVCaptureSession()
    var metadatos = AVCaptureMetadataOutput()
    var layerVideo = AVCaptureVideoPreviewLayer()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        inicializarVideo()
    }

    override func viewWillAppear(_ animated: Bool)
    {
        let btnRegresar = UIButton(frame: CGRect(x: 10, y: top + 5, width: 50, height: 20))
        btnRegresar.setTitle("<- Back", for: .normal)
        btnRegresar.titleLabel!.font = .systemFont(ofSize: 20, weight: .medium)
        btnRegresar.setTitleColor(.white, for: .normal)
        btnRegresar.addTarget(self, action: #selector(regresar), for: .touchUpInside)
        view.addSubview(btnRegresar)
        
        let w = view.frame.width * 0.8
        let x = view.frame.width * 0.1
        let y = (view.frame.height - w) / 2.0
        
        let imvScan = UIImageView(frame: CGRect(x: x, y: y, width: w, height: w))
        imvScan.image = UIImage(systemName: "viewfinder")
        imvScan.contentMode = .scaleAspectFit
        imvScan.tintColor = .yellow
        view.addSubview(imvScan)
        metadatos.rectOfInterest = layerVideo.metadataOutputRectConverted(fromLayerRect: imvScan.frame)
    }
    
    override func viewWillDisappear(_ animated: Bool) 
    {
        sesion.stopRunning()
    }
    
    @objc func regresar()
    {
        dismiss(animated: true)
    }
    
    func inicializarVideo()
    {
        let msj = "No se pudo inicializar la camara para leer el QR"
        
        if let camara = AVCaptureDevice.default(for: .video)
        {
            do 
            {
                let entrada = try AVCaptureDeviceInput(device: camara)
                
                if sesion.canAddInput(entrada)
                {
                    sesion.addInput(entrada)
                } else
                {
                    mostrarFalla(msj)
                }
                
                if sesion.canAddOutput(metadatos)
                {
                    sesion.addOutput(metadatos)
                    metadatos.setMetadataObjectsDelegate(self, queue: .main)
                    metadatos.metadataObjectTypes = [.qr]
                } else
                {
                    mostrarFalla(msj)
                }
                
                layerVideo = AVCaptureVideoPreviewLayer(session: sesion)
                layerVideo.frame = view.frame
                layerVideo.videoGravity = .resizeAspectFill
                view.layer.addSublayer(layerVideo)
                sesion.startRunning()
            }
            catch
            {
                mostrarFalla(msj)
            }
        } else
        {
            mostrarFalla(msj)
        }
    }
    
    func mostrarFalla(_ msj: String)
    {
        let alerta = UIAlertController(title: "ERR", message: msj, preferredStyle: .alert)
        let ok = UIAlertAction(title: "Aceptar", style: .default) { accion in
            self.dismiss(animated: true)
        }
        alerta.addAction(ok)
        present(alerta, animated: true)
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) 
    {
        let msj = "Falló la lectura del código QR, intenta nuevamente con otro código"
        sesion.stopRunning()
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        
        if let datos = metadataObjects.first as? AVMetadataMachineReadableCodeObject
        {
            if let cadena = datos.stringValue
            {
                do
                {
                    let json = try JSONSerialization.jsonObject(with: cadena.data(using: .utf8)!) as! [String:Double]
                    let datos = Datos.sharedDatos()
                    if let lat = json["lat"]
                    {
                        datos.latitud = lat
                    } else
                    {
                        mostrarFalla(msj)
                    }
                    if let lon = json["lon"]
                    {
                        datos.longitud = lon
                    } else
                    {
                        mostrarFalla(msj)
                    }
                    datos.codigoNuevo = true
                    dismiss(animated: true)
                } catch
                {
                    mostrarFalla(msj)
                }
            } else
            {
                mostrarFalla(msj)
            }
        } else
        {
            mostrarFalla(msj)
        }
    }
}
